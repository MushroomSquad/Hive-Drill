#!/usr/bin/env bash
# tests/test_worktree.sh — Tests for scripts/worktree.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

WORKTREE_SH="${PROJECT_ROOT}/scripts/worktree.sh"

describe "worktree.sh — argument validation"

it "exits 1 with no arguments"
output=$("${WORKTREE_SH}" 2>&1); code=$?
assert_exit_fail $code

it "exits 1 for unknown command"
output=$("${WORKTREE_SH}" unknown 2>&1); code=$?
assert_exit_fail $code

it "exits 1 for 'create' without TASK-ID"
output=$("${WORKTREE_SH}" create 2>&1); code=$?
assert_exit_fail $code

it "exits 1 for 'clean' without TASK-ID"
output=$("${WORKTREE_SH}" clean 2>&1); code=$?
assert_exit_fail $code

describe "worktree.sh — list command"

it "exits 0 for list (inside any git repo)"
# Run from the project root which is a git repo
output=$(cd "${PROJECT_ROOT}" && bash "${WORKTREE_SH}" list 2>&1); code=$?
assert_exit_ok $code

it "list output mentions 'Worktrees'"
assert_contains "Worktree" "$output"

describe "worktree.sh — create command"

setup_workspace

TASK_ID="WT-TEST-001"

# worktree.sh needs to run inside a proper git repo
# TEST_REPO is initialised with a commit by setup_workspace
cd "${TEST_REPO}"

output=$(bash "${WORKTREE_SH}" create "${TASK_ID}" 2>&1)
code=$?

it "exits 0 for create"
assert_exit_ok $code

it "creates worktree directory for claude agent"
assert_dir_exists "${TEST_REPO}/wt/${TASK_ID}-claude"

it "creates worktree directory for codex agent"
assert_dir_exists "${TEST_REPO}/wt/${TASK_ID}-codex"

it "creates agent branch for claude"
git -C "${TEST_REPO}" branch | grep -q "agent/${TASK_ID}-claude" && pass || fail "Branch agent/${TASK_ID}-claude not found"

it "creates agent branch for codex"
git -C "${TEST_REPO}" branch | grep -q "agent/${TASK_ID}-codex" && pass || fail "Branch agent/${TASK_ID}-codex not found"

describe "worktree.sh — idempotency"

it "does not fail if worktree already exists"
output2=$(bash "${WORKTREE_SH}" create "${TASK_ID}" 2>&1); code2=$?
assert_exit_ok $code2

describe "worktree.sh — clean command"

output=$(bash "${WORKTREE_SH}" clean "${TASK_ID}" 2>&1); code=$?

it "exits 0 for clean"
assert_exit_ok $code

it "removes claude worktree after clean"
[[ ! -d "${TEST_REPO}/wt/${TASK_ID}-claude" ]] && pass || fail "Worktree still exists"

it "removes codex worktree after clean"
[[ ! -d "${TEST_REPO}/wt/${TASK_ID}-codex" ]] && pass || fail "Worktree still exists"

cd "${SCRIPT_DIR}"
teardown_workspace
print_summary
