#!/usr/bin/env bash
# tests/test_plan_init.sh — Tests for scripts/plan-init.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

PLAN_INIT_SH="${PROJECT_ROOT}/scripts/plan-init.sh"

describe "plan-init.sh — argument validation"

it "exits 1 with no arguments"
output=$("${PLAN_INIT_SH}" 2>&1); code=$?
assert_exit_fail $code

describe "plan-init.sh — run directory creation"

setup_workspace

TASK_ID="FEAT-999"
output=$(cd "${TEST_REPO}" && bash "${PLAN_INIT_SH}" "${TASK_ID}" feature 2>&1)
code=$?

it "exits 0"
assert_exit_ok $code

it "creates .ai/runs/<TASK-ID>/ directory"
assert_dir_exists "${TEST_REPO}/.ai/runs/${TASK_ID}"

it "creates brief.md in run dir"
assert_file_exists "${TEST_REPO}/.ai/runs/${TASK_ID}/brief.md"

it "creates tasks.yaml in run dir"
assert_file_exists "${TEST_REPO}/.ai/runs/${TASK_ID}/tasks.yaml"

it "brief.md contains the task id"
assert_file_contains "${TEST_REPO}/.ai/runs/${TASK_ID}/brief.md" "${TASK_ID}"

it "brief.md has Goal section"
assert_file_contains "${TEST_REPO}/.ai/runs/${TASK_ID}/brief.md" "## Goal"

it "tasks.yaml contains run_id"
assert_file_contains "${TEST_REPO}/.ai/runs/${TASK_ID}/tasks.yaml" "run_id: ${TASK_ID}"

it "tasks.yaml contains blueprint reference"
assert_file_contains "${TEST_REPO}/.ai/runs/${TASK_ID}/tasks.yaml" "blueprint: feature"

describe "plan-init.sh — existing run guard"

it "asks confirmation if run already exists (non-interactive returns early)"
# Pipe 'n' to simulate user saying no
echo "n" | (cd "${TEST_REPO}" && bash "${PLAN_INIT_SH}" "${TASK_ID}" 2>&1) > /dev/null
# files should still exist from before
assert_file_exists "${TEST_REPO}/.ai/runs/${TASK_ID}/brief.md"

teardown_workspace
print_summary
