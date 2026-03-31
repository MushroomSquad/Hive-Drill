#!/usr/bin/env bash
# tests/test_package_pr.sh — Tests for scripts/package-pr.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

PACKAGE_PR_SH="${PROJECT_ROOT}/scripts/package-pr.sh"

describe "package-pr.sh — argument validation"

it "exits 1 with no arguments"
output=$("${PACKAGE_PR_SH}" 2>&1); code=$?
assert_exit_fail $code

it "exits 1 when run dir does not exist"
output=$(cd /tmp && bash "${PACKAGE_PR_SH}" NONEXISTENT-TASK-XYZ 2>&1); code=$?
assert_exit_fail $code

describe "package-pr.sh — full run with APPROVED findings"

setup_workspace

TASK_ID="PR-001"
RUN_DIR="${TEST_REPO}/.ai/runs/${TASK_ID}"
mkdir -p "${RUN_DIR}"

# Write required artifacts
cat > "${RUN_DIR}/brief.md" <<'EOF'
---
task_id: PR-001
status: done
---
# Brief: PR-001

## Goal
Test the package-pr script.

## Acceptance criteria
- [ ] pr-body.md created
EOF

cat > "${RUN_DIR}/verification.md" <<'EOF'
# Verification: PR-001

## Check results
- lint: PASS
- tests: PASS

## Manual verification
- [x] Feature works as described
EOF

cat > "${RUN_DIR}/findings.md" <<'EOF'
---
task_id: PR-001
verdict: APPROVED
---
# Review Findings: PR-001

## Verdict
> **APPROVED**
EOF

# Mock 'gh' so it does not try to create a real PR
mock_cmd "gh" 0 "PR created"
prepend_mock_bin

# Run (pipe 'n' to skip interactive gh pr create prompt)
output=$(echo "n" | (cd "${TEST_REPO}" && bash "${PACKAGE_PR_SH}" "${TASK_ID}" 2>&1))
code=$?

it "exits 0 with complete artifacts"
assert_exit_ok $code

it "creates pr-body.md"
assert_file_exists "${RUN_DIR}/pr-body.md"

it "pr-body.md contains task id"
assert_file_contains "${RUN_DIR}/pr-body.md" "${TASK_ID}"

it "pr-body.md has Summary section"
assert_file_contains "${RUN_DIR}/pr-body.md" "## Summary"

it "pr-body.md has Test plan section"
assert_file_contains "${RUN_DIR}/pr-body.md" "## Test plan"

describe "package-pr.sh — namespaced run dir argument"

TASK_ID_NS="T-001"
RUN_DIR_NS="${TEST_REPO}/.ai/runs/testproject/${TASK_ID_NS}"
mkdir -p "${RUN_DIR_NS}"

cat > "${RUN_DIR_NS}/brief.md" <<'EOF'
---
task_id: T-001
status: done
---
# Brief: T-001

## Goal
Use namespaced run dir.
EOF

cat > "${RUN_DIR_NS}/verification.md" <<'EOF'
# Verification: T-001
EOF

cat > "${RUN_DIR_NS}/findings.md" <<'EOF'
---
verdict: APPROVED
---
# Findings
> **APPROVED**
EOF

output_ns=$(echo "n" | (cd "${TEST_REPO}" && bash "${PACKAGE_PR_SH}" "${TASK_ID_NS}" ".ai/runs/testproject/${TASK_ID_NS}" 2>&1))
code_ns=$?

it "exits 0 when given a namespaced run dir"
assert_exit_ok $code_ns

it "creates pr-body.md in the namespaced run dir"
assert_file_exists "${RUN_DIR_NS}/pr-body.md"

describe "package-pr.sh — legacy flat run dir fallback"

TASK_ID_LEGACY="T-002"
RUN_DIR_LEGACY="${TEST_REPO}/.ai/runs/${TASK_ID_LEGACY}"
mkdir -p "${RUN_DIR_LEGACY}"

cat > "${RUN_DIR_LEGACY}/brief.md" <<'EOF'
---
task_id: T-002
status: done
---
# Brief: T-002

## Goal
Use legacy flat run dir.
EOF

cat > "${RUN_DIR_LEGACY}/verification.md" <<'EOF'
# Verification: T-002
EOF

cat > "${RUN_DIR_LEGACY}/findings.md" <<'EOF'
---
verdict: APPROVED
---
# Findings
> **APPROVED**
EOF

output_legacy=$(echo "n" | (cd "${TEST_REPO}" && bash "${PACKAGE_PR_SH}" "${TASK_ID_LEGACY}" 2>&1))
code_legacy=$?

it "exits 0 when only the legacy flat path exists"
assert_exit_ok $code_legacy

it "creates pr-body.md in the legacy flat run dir"
assert_file_exists "${RUN_DIR_LEGACY}/pr-body.md"

describe "package-pr.sh — blocked by non-approved findings"

TASK_ID2="PR-002"
RUN_DIR2="${TEST_REPO}/.ai/runs/${TASK_ID2}"
mkdir -p "${RUN_DIR2}"

cat > "${RUN_DIR2}/brief.md" <<'EOF'
---
task_id: PR-002
---
# Brief: PR-002
## Goal
Blocked test.
EOF

cat > "${RUN_DIR2}/findings.md" <<'EOF'
---
verdict: BLOCKED
---
# Findings
> **BLOCKED**
EOF

cat > "${RUN_DIR2}/verification.md" <<'EOF'
# Verification
EOF

it "exits 1 when findings verdict is BLOCKED"
output2=$(cd "${TEST_REPO}" && bash "${PACKAGE_PR_SH}" "${TASK_ID2}" 2>&1); code2=$?
assert_exit_fail $code2

it "prints error about non-APPROVED verdict"
assert_contains "APPROVED" "$output2"

describe "package-pr.sh — missing artifacts warning + continuation"

TASK_ID3="PR-003"
RUN_DIR3="${TEST_REPO}/.ai/runs/${TASK_ID3}"
mkdir -p "${RUN_DIR3}"

cat > "${RUN_DIR3}/brief.md" <<'EOF'
---
task_id: PR-003
---
# Brief: PR-003
## Goal
Test missing artifacts.
EOF

# No verification.md, no findings.md — user says 'y' to continue, 'n' to skip gh pr
it "warns about missing artifacts but continues when user says y"
output3=$(printf 'y\nn\n' | (cd "${TEST_REPO}" && bash "${PACKAGE_PR_SH}" "${TASK_ID3}" 2>&1)); code3=$?
assert_exit_ok $code3

it "still creates pr-body.md even with missing optional artifacts"
assert_file_exists "${RUN_DIR3}/pr-body.md"

teardown_workspace
print_summary
