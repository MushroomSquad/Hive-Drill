#!/usr/bin/env bash
# tests/test_go_pipeline.sh — Integration tests for scripts/go.sh
# Mocks claude/codex to avoid real API calls

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

GO_SH="${PROJECT_ROOT}/scripts/go.sh"

# Helper: copy ALL scripts into TEST_REPO/scripts/ so SCRIPT_DIR resolves correctly
setup_pipeline_workspace() {
    setup_workspace
    mkdir -p "${TEST_REPO}/scripts"
    cp "${PROJECT_ROOT}/scripts/"*.sh "${TEST_REPO}/scripts/"
    chmod +x "${TEST_REPO}/scripts/"*.sh

    # Active project context (required by go.sh project system)
    TEST_PROJECT="testproject"
    mkdir -p "${TEST_REPO}/.ai/state"
    echo "${TEST_PROJECT}" > "${TEST_REPO}/.ai/state/current"
    export ACTIVE_PROJECT="${TEST_PROJECT}"

    # Project registry — empty path so go.sh falls through to WORKSPACE/.env
    mkdir -p "${TEST_REPO}/.ai/projects"
    printf '{"name":"%s","path":"","description":"test"}\n' \
        "${TEST_PROJECT}" \
        > "${TEST_REPO}/.ai/projects/${TEST_PROJECT}.json"

    # Vault structure — project-namespaced (mirrors go.sh path logic)
    VAULT="${TEST_REPO}/vault/projects/${TEST_PROJECT}"
    mkdir -p "${VAULT}/00-inbox" "${VAULT}/01-active" "${VAULT}/02-done" "${VAULT}/templates" "${VAULT}/canvas"
    cp "${PROJECT_ROOT}/vault/templates/plan.md" "${VAULT}/templates/plan.md" 2>/dev/null || true
    cp "${PROJECT_ROOT}/vault/templates/findings.md" "${VAULT}/templates/findings.md" 2>/dev/null || true
    echo '{"nodes":[],"edges":[]}' > "${VAULT}/canvas/project-board.canvas"
    export VAULT TEST_PROJECT
}

# Shorthand for project-namespaced run dir
run_dir() { echo "${TEST_REPO}/.ai/runs/${TEST_PROJECT}/${1}"; }

describe "go.sh — argument validation"

it "exits 1 with no arguments"
output=$("${GO_SH}" 2>&1); code=$?
assert_exit_fail $code

it "prints Usage when called without args"
assert_contains "Usage" "$output"

it "exits 1 for --from-stage with unknown extra arg"
output=$("${GO_SH}" TASK-001 --unknown 2>&1); code=$?
assert_exit_fail $code

describe "go.sh — stage 0: brief not found"

setup_pipeline_workspace

TASK_ID="PIPE-001"
# Do NOT create brief — should fail at stage 0
output=$(cd "${TEST_REPO}" && bash scripts/go.sh "${TASK_ID}" 2>&1); code=$?

it "exits 1 when brief file does not exist"
assert_exit_fail $code

it "explains where it expects the brief"
assert_contains "00-inbox" "$output"

describe "go.sh — stage 0: brief found but status not ready"

cat > "${VAULT}/00-inbox/${TASK_ID}.md" <<'EOF'
---
task_id: PIPE-001
status: draft
---
# Brief: Test
## Goal
Nothing.
EOF

output2=$(cd "${TEST_REPO}" && EDITOR=true bash scripts/go.sh "${TASK_ID}" </dev/null 2>&1) || true

it "warns when brief status is not ready"
assert_contains "draft" "$output2"

describe "go.sh — stage 1 to 6 with mocked agents"

# Update brief to ready
${HIVE_SED_I} 's/status: draft/status: ready/' "${VAULT}/00-inbox/${TASK_ID}.md"

# Set up a dummy workspace so guard_workspace doesn't trigger
mkdir -p "${TEST_REPO}/workspace/testapp"
echo "WORKSPACE=workspace/testapp" > "${TEST_REPO}/.env"

# Mock external tools in TEST_MOCK_BIN and prepend to PATH
prepend_mock_bin

# Mock claude: output a valid plan.md regardless of args
mock_cmd_script "claude" '
echo "---"
echo "task_id: PIPE-001"
echo "status: draft"
echo "agent: claude"
echo "created: 2026-03-27"
echo "---"
echo "# Plan: Test"
echo "## Chosen approach"
echo "Option A — do the thing"
echo "## Implementation steps"
echo "1. Do the thing"
exit 0
'

# Mock codex: no-op
mock_cmd "codex" 0 "codex mock"

# Feed 'y' answers to both gates (plan + review)
output=$(printf 'y\ny\n' | (cd "${TEST_REPO}" && bash scripts/go.sh "${TASK_ID}" 2>&1))
code=$?

it "pipeline runs to completion"
assert_exit_ok $code

it "brief passes through 01-active/ stage (checked via 02-done/)"
# After full pipeline: brief goes inbox → 01-active → 02-done
assert_file_exists "${VAULT}/02-done/${TASK_ID}.md"

it "creates run directory with artifacts"
assert_dir_exists "$(run_dir ${TASK_ID})"

it "generates plan.md"
assert_file_exists "$(run_dir ${TASK_ID})/plan.md"

it "generates tasks.md"
assert_file_exists "$(run_dir ${TASK_ID})/tasks.md"

it "generates test-report.md"
assert_file_exists "$(run_dir ${TASK_ID})/test-report.md"

it "generates findings.md"
assert_file_exists "$(run_dir ${TASK_ID})/findings.md"

it "prints Pipeline complete message"
assert_contains "Pipeline complete" "$output"

describe "go.sh — --from-stage flag"

TASK_ID2="PIPE-002"
mkdir -p "$(run_dir ${TASK_ID2})"
cat > "$(run_dir ${TASK_ID2})/brief.md" <<'EOF'
---
task_id: PIPE-002
status: ready
---
# Brief: PIPE-002
## Goal
Skip to review.
EOF

cat > "$(run_dir ${TASK_ID2})/plan.md" <<'EOF'
---
task_id: PIPE-002
status: approved
agent: claude
created: 2026-03-27
---
# Plan: PIPE-002
## Chosen approach
Done.
EOF

it "skips earlier stages when --from-stage 5 given"
output2=$(printf 'y\n' | (cd "${TEST_REPO}" && bash scripts/go.sh "${TASK_ID2}" --from-stage 5 2>&1))
assert_contains "Skipping stage" "$output2"

describe "go.sh — WORKSPACE support"

# Create a separate 'workspace' directory acting as the target project
WORKSPACE_DIR="${TEST_REPO}/workspace/myapp"
mkdir -p "${WORKSPACE_DIR}"
cat > "${WORKSPACE_DIR}/package.json" <<'EOF'
{"name":"myapp","scripts":{"test":"exit 0"}}
EOF
# Write .env so go.sh picks up WORKSPACE
echo "WORKSPACE=workspace/myapp" > "${TEST_REPO}/.env"

TASK_ID3="PIPE-003"
mkdir -p "${VAULT}/00-inbox"
cat > "${VAULT}/00-inbox/${TASK_ID3}.md" <<'EOF'
---
task_id: PIPE-003
status: ready
---
# Brief: PIPE-003
## Goal
Test workspace routing.
EOF

output3=$(printf 'y\ny\n' | (cd "${TEST_REPO}" && bash scripts/go.sh "${TASK_ID3}" 2>&1))
code3=$?

it "exits 0 with WORKSPACE set"
assert_exit_ok $code3

it "prints Workspace path in header"
assert_contains "workspace/myapp" "$output3"

it "detects package.json in workspace (not in roi root)"
assert_contains "npm" "$output3"

it "still writes run artifacts to .ai/runs/ inside roi"
assert_file_exists "$(run_dir ${TASK_ID3})/plan.md"

teardown_workspace
print_summary
