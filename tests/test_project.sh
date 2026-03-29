#!/usr/bin/env bash
# tests/test_project.sh — Tests for scripts/project.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

PROJECT_SH="${PROJECT_ROOT}/scripts/project.sh"

# ─── Setup: isolated temp roi root ────────────────────────────────────────────
setup_workspace
ROI="${TEST_REPO}"
mkdir -p "${ROI}/scripts" "${ROI}/vault/canvas" "${ROI}/vault/templates"
cp "${PROJECT_SH}" "${ROI}/scripts/project.sh"
echo '{"nodes":[],"edges":[]}' > "${ROI}/vault/canvas/project-board.canvas"

describe "project.sh — argument validation"

it "exits non-zero with no command"
output=$(cd "${ROI}" && bash scripts/project.sh 2>&1); code=$?
assert_exit_fail $code

it "prints usage on no command"
assert_contains "Usage" "$output"

it "exits non-zero on unknown command"
output=$(cd "${ROI}" && bash scripts/project.sh bogus 2>&1); code=$?
assert_exit_fail $code

describe "project.sh — add"

TARGET_PATH="${TEST_TMPDIR}/myapp"
mkdir -p "${TARGET_PATH}"

it "exits 0 when adding a valid project"
output=$(cd "${ROI}" && bash scripts/project.sh add myapp "${TARGET_PATH}" "test app" 2>&1); code=$?
assert_exit_ok $code

it "creates .ai/projects/myapp.json"
assert_file_exists "${ROI}/.ai/projects/myapp.json"

it "registry contains path"
assert_file_contains "${ROI}/.ai/projects/myapp.json" "${TARGET_PATH}"

it "registry contains description"
assert_file_contains "${ROI}/.ai/projects/myapp.json" "test app"

it "bootstraps vault/projects/myapp/ structure"
assert_dir_exists "${ROI}/vault/projects/myapp/00-inbox"
assert_dir_exists "${ROI}/vault/projects/myapp/01-active"
assert_dir_exists "${ROI}/vault/projects/myapp/02-done"

it "bootstraps canvas for project"
assert_file_exists "${ROI}/vault/projects/myapp/canvas/project-board.canvas"

it "exits non-zero without required args"
output=$(cd "${ROI}" && bash scripts/project.sh add 2>&1); code=$?
assert_exit_fail $code

it "rejects names with spaces"
output=$(cd "${ROI}" && bash scripts/project.sh add "bad name" "${TARGET_PATH}" 2>&1); code=$?
assert_exit_fail $code

describe "project.sh — list"

it "list shows registered project"
output=$(cd "${ROI}" && bash scripts/project.sh list 2>&1)
assert_contains "myapp" "$output"

describe "project.sh — switch"

it "exits 0 when switching to existing project"
output=$(cd "${ROI}" && bash scripts/project.sh switch myapp 2>&1); code=$?
assert_exit_ok $code

it "creates .ai/state/current"
assert_file_exists "${ROI}/.ai/state/current"

it "state file contains project name"
assert_file_contains "${ROI}/.ai/state/current" "myapp"

it "list marks active project"
output=$(cd "${ROI}" && bash scripts/project.sh list 2>&1)
assert_contains "▶" "$output"

it "exits non-zero for unknown project"
output=$(cd "${ROI}" && bash scripts/project.sh switch nonexistent 2>&1); code=$?
assert_exit_fail $code

describe "project.sh — current"

it "current shows active project name"
output=$(cd "${ROI}" && bash scripts/project.sh current 2>&1)
assert_contains "myapp" "$output"

describe "project.sh — roi_project_context() sourced function"

it "sets ACTIVE_PROJECT when sourced"
output=$(cd "${ROI}" && bash -c '
    source scripts/project.sh
    roi_project_context
    echo "ACTIVE=${ACTIVE_PROJECT}"
    echo "PATH_VAL=${PROJECT_PATH}"
' 2>&1)
assert_contains "ACTIVE=myapp" "$output"

it "sets PROJECT_PATH correctly when sourced"
assert_contains "${TARGET_PATH}" "$output"

describe "project.sh — info"

it "info shows project details"
output=$(cd "${ROI}" && bash scripts/project.sh info myapp 2>&1)
assert_contains "myapp" "$output"
assert_contains "${TARGET_PATH}" "$output"

describe "project.sh — remove"

it "exits 0 when removing existing project"
output=$(cd "${ROI}" && bash scripts/project.sh remove myapp 2>&1); code=$?
assert_exit_ok $code

it "removes .ai/projects/myapp.json"
[[ ! -f "${ROI}/.ai/projects/myapp.json" ]] && pass || fail "File still exists"

it "clears .ai/state/current when removed project was active"
current="$(cat "${ROI}/.ai/state/current" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$current" ]] && pass || fail "State not cleared: '$current'"

it "vault/projects/myapp/ preserved after remove"
assert_dir_exists "${ROI}/vault/projects/myapp"

it "exits non-zero when removing nonexistent project"
output=$(cd "${ROI}" && bash scripts/project.sh remove nonexistent 2>&1); code=$?
assert_exit_fail $code

describe "project.sh — no active project (legacy mode)"

it "roi_project_context sets empty vars when no state file"
rm -f "${ROI}/.ai/state/current"
output=$(cd "${ROI}" && bash -c '
    source scripts/project.sh
    roi_project_context
    echo "ACTIVE=${ACTIVE_PROJECT:-}"
' 2>&1)
assert_contains "ACTIVE=" "$output"
assert_not_contains "ACTIVE=myapp" "$output"

teardown_workspace
print_summary
