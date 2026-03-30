#!/usr/bin/env bash
# tests/test_new.sh — Tests for scripts/new.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

NEW_SH="${PROJECT_ROOT}/scripts/new.sh"

describe "new.sh — argument validation"

it "exits 1 with no arguments"
output=$("${NEW_SH}" 2>&1); code=$?
assert_exit_fail $code

it "prints usage hint when called without args"
output=$("${NEW_SH}" 2>&1 || true)
assert_contains "Usage" "$output"

describe "new.sh — task creation"

setup_workspace

TEST_PROJECT="testproj"
VAULT="${TEST_REPO}/vault/projects/${TEST_PROJECT}"
mkdir -p "${TEST_REPO}/vault/templates"
mkdir -p "${VAULT}/00-inbox" "${VAULT}/canvas"
cp "${PROJECT_ROOT}/vault/templates/brief.md" "${TEST_REPO}/vault/templates/brief.md"
cp "${PROJECT_ROOT}/vault/templates/init-brief.md" "${TEST_REPO}/vault/templates/init-brief.md"
echo '{"nodes":[],"edges":[]}' > "${VAULT}/canvas/project-board.canvas"
mkdir -p "${TEST_REPO}/scripts"
cp "${PROJECT_ROOT}/scripts/new.sh" "${TEST_REPO}/scripts/new.sh"
cp "${PROJECT_ROOT}/scripts/canvas-add.sh" "${TEST_REPO}/scripts/canvas-add.sh"
cp "${PROJECT_ROOT}/scripts/project.sh" "${TEST_REPO}/scripts/project.sh"

mkdir -p "${TEST_REPO}/.ai/projects" "${TEST_REPO}/.ai/state"
echo "{\"name\":\"${TEST_PROJECT}\",\"path\":\"${TEST_REPO}\",\"description\":\"test\",\"added\":\"2026-01-01\"}" \
    > "${TEST_REPO}/.ai/projects/${TEST_PROJECT}.json"
echo -n "${TEST_PROJECT}" > "${TEST_REPO}/.ai/state/current"

export EDITOR="true"

INIT_TASK_ID="INIT-001"
init_output=$(cd "${TEST_REPO}" && bash scripts/new.sh --type init "${INIT_TASK_ID}" 2>&1)
init_code=$?

it "exits 0 for a fresh init task"
assert_exit_ok $init_code

it "--type init creates brief file in vault/projects/<project>/00-inbox/"
assert_file_exists "${VAULT}/00-inbox/${INIT_TASK_ID}.md"

it "--type init creates .ai/runs/<project>/<TASK-ID>/ directory"
assert_dir_exists "${TEST_REPO}/.ai/runs/${TEST_PROJECT}/${INIT_TASK_ID}"

it "--type init uses the init brief template"
assert_file_contains "${VAULT}/00-inbox/${INIT_TASK_ID}.md" "# Init Brief:"

it "--type init writes type: init to frontmatter"
assert_file_contains "${VAULT}/00-inbox/${INIT_TASK_ID}.md" "type: init"

it "--type init includes an init-specific section"
assert_file_contains "${VAULT}/00-inbox/${INIT_TASK_ID}.md" "## Business context"

it "--type init still creates a canvas card"
assert_file_contains "${VAULT}/canvas/project-board.canvas" "${INIT_TASK_ID}"

it "prints success message for init task"
assert_contains "Task created" "$init_output"

describe "new.sh — invalid type handling"

it "--type foobar exits non-zero"
invalid_output=$(cd "${TEST_REPO}" && bash scripts/new.sh --type foobar "BAD-001" 2>&1); invalid_code=$?
assert_exit_fail $invalid_code

it "--type foobar prints Unknown type"
assert_contains "Unknown type" "$invalid_output"

describe "new.sh — default type regression"

FEATURE_TASK_ID="TEST-001"
feature_output=$(cd "${TEST_REPO}" && bash scripts/new.sh "${FEATURE_TASK_ID}" 2>&1)
feature_code=$?

it "calling new.sh without --type still exits 0"
assert_exit_ok $feature_code

it "calling new.sh without --type still creates a brief"
assert_file_exists "${VAULT}/00-inbox/${FEATURE_TASK_ID}.md"

it "calling new.sh without --type still writes type: feature"
assert_file_contains "${VAULT}/00-inbox/${FEATURE_TASK_ID}.md" "type: feature"

it "calling new.sh without --type still uses the standard brief template"
assert_file_contains "${VAULT}/00-inbox/${FEATURE_TASK_ID}.md" "# Brief:"

it "calling new.sh without --type still has Acceptance criteria"
assert_file_contains "${VAULT}/00-inbox/${FEATURE_TASK_ID}.md" "Acceptance criteria"

it "calling new.sh without --type still creates a canvas card"
assert_file_contains "${VAULT}/canvas/project-board.canvas" "${FEATURE_TASK_ID}"

it "calling new.sh without --type still prints success"
assert_contains "Task created" "$feature_output"

describe "new.sh — idempotency guard"

it "exits non-zero if brief already exists"
output2=$(cd "${TEST_REPO}" && bash scripts/new.sh "${FEATURE_TASK_ID}" 2>&1); code2=$?
assert_exit_fail $code2

it "prints 'already exists' message on duplicate"
assert_contains "already exists" "$output2"

describe "new.sh — requires active project"

rm -f "${TEST_REPO}/.ai/state/current"
it "exits non-zero when no active project"
output3=$(cd "${TEST_REPO}" && bash scripts/new.sh "TEST-002" 2>&1); code3=$?
assert_exit_fail $code3

it "prints helpful error when no active project"
assert_contains "No active project" "$output3"

teardown_workspace
print_summary
