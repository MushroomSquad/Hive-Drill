#!/usr/bin/env bash
# tests/test_status.sh — Tests for scripts/status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

STATUS_SH="${PROJECT_ROOT}/scripts/status.sh"

describe "status.sh — output structure"

setup_workspace

# Run from a known git repo (project root)
output=$(cd "${PROJECT_ROOT}" && bash "${STATUS_SH}" 2>&1)
code=$?

it "exits 0"
assert_exit_ok $code

it "prints Hive Drill header"
assert_contains "Hive Drill" "$output"

it "prints Agents section"
assert_contains "Agents" "$output"

it "prints Local LLM section"
assert_contains "Local LLM" "$output"

it "prints Git section"
assert_contains "Git" "$output"

it "prints Active Runs section"
assert_contains "Active Runs" "$output"

it "prints MCP Servers section"
assert_contains "MCP" "$output"

describe "status.sh — active runs detection"

# Determine the correct runs dir based on the current active project
TASK_ID="STATUS-TEST-001"
ACTIVE_PROJECT=""
[[ -f "${PROJECT_ROOT}/.ai/state/current" ]] && ACTIVE_PROJECT="$(cat "${PROJECT_ROOT}/.ai/state/current" | tr -d '[:space:]')"

if [[ -n "${ACTIVE_PROJECT}" ]]; then
    RUNS_TEST_DIR="${PROJECT_ROOT}/.ai/runs/${ACTIVE_PROJECT}/${TASK_ID}"
else
    RUNS_TEST_DIR="${PROJECT_ROOT}/.ai/runs/${TASK_ID}"
fi

mkdir -p "${RUNS_TEST_DIR}"
touch "${RUNS_TEST_DIR}/plan.md"
touch "${RUNS_TEST_DIR}/brief.md"

output=$(cd "${PROJECT_ROOT}" && bash "${STATUS_SH}" 2>&1)

it "lists newly created run"
assert_contains "${TASK_ID}" "$output"

# Cleanup
rm -rf "${RUNS_TEST_DIR}"

teardown_workspace
print_summary
