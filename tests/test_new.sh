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

# Build a fake project tree in TEST_REPO
VAULT="${TEST_REPO}/vault"
mkdir -p "${VAULT}/templates" "${VAULT}/00-inbox"
cp "${PROJECT_ROOT}/vault/templates/brief.md" "${VAULT}/templates/brief.md"
mkdir -p "${TEST_REPO}/scripts"
cp "${PROJECT_ROOT}/scripts/new.sh" "${TEST_REPO}/scripts/new.sh"
cp "${PROJECT_ROOT}/scripts/canvas-add.sh" "${TEST_REPO}/scripts/canvas-add.sh"
mkdir -p "${VAULT}/canvas"
echo '{"nodes":[],"edges":[]}' > "${VAULT}/canvas/project-board.canvas"

# Mock EDITOR so it doesn't open anything
export EDITOR="true"

# Run new.sh from the test repo
TASK_ID="TEST-001"
output=$(cd "${TEST_REPO}" && bash scripts/new.sh "${TASK_ID}" 2>&1)
code=$?

it "exits 0 for a fresh task"
assert_exit_ok $code

it "creates brief file in vault/00-inbox/"
assert_file_exists "${VAULT}/00-inbox/${TASK_ID}.md"

it "creates .ai/runs/<TASK-ID>/ directory"
assert_dir_exists "${TEST_REPO}/.ai/runs/${TASK_ID}"

it "brief contains task_id in frontmatter"
assert_file_contains "${VAULT}/00-inbox/${TASK_ID}.md" "${TASK_ID}"

it "brief status starts as draft"
assert_file_contains "${VAULT}/00-inbox/${TASK_ID}.md" "status: draft"

it "brief has Acceptance criteria section"
assert_file_contains "${VAULT}/00-inbox/${TASK_ID}.md" "Acceptance criteria"

it "prints success message"
assert_contains "Task created" "$output"

describe "new.sh — idempotency guard"

it "exits non-zero if brief already exists"
output2=$(cd "${TEST_REPO}" && bash scripts/new.sh "${TASK_ID}" 2>&1); code2=$?
assert_exit_fail $code2

it "prints 'already exists' message on duplicate"
assert_contains "already exists" "$output2"

teardown_workspace
print_summary
