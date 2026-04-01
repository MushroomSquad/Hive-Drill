#!/usr/bin/env bash
# tests/test_cleanup.sh — Tests for scripts/cleanup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

CLEANUP_SH="${PROJECT_ROOT}/scripts/cleanup.sh"

describe "cleanup.sh — removes legacy workspace artifacts"

setup_workspace

touch "${TEST_REPO}/PR_DESCRIPTION.md"
touch "${TEST_REPO}/scaffold.py"
mkdir -p "${TEST_REPO}/_ai_tmp"
touch "${TEST_REPO}/_ai_tmp/PR_DESCRIPTION.md"

it "exits 0 and removes both files on first run"
output=$(cd "${TEST_REPO}" && bash "${CLEANUP_SH}" 2>&1); code=$?
assert_exit_ok $code

it "removes PR_DESCRIPTION.md"
assert_not_contains "PR_DESCRIPTION.md" "$(find "${TEST_REPO}" -maxdepth 1 -type f -printf '%f\n')"

it "removes scaffold.py"
assert_not_contains "scaffold.py" "$(find "${TEST_REPO}" -maxdepth 1 -type f -printf '%f\n')"

it "removes _ai_tmp"
assert_not_contains "_ai_tmp" "$(find "${TEST_REPO}" -maxdepth 1 -mindepth 1 -printf '%f\n')"

it "prints what it removed"
assert_contains "Removed:" "$output"

it "exits 0 and stays idempotent on an empty workspace"
output2=$(cd "${TEST_REPO}" && bash "${CLEANUP_SH}" 2>&1); code2=$?
assert_exit_ok $code2

it "prints not-present messages on the second run"
assert_contains "Not present:" "$output2"

teardown_workspace
print_summary
