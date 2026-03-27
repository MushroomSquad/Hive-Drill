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

it "prints AI Dev OS header"
assert_contains "AI Dev OS" "$output"

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

TASK_ID="STATUS-TEST-001"
mkdir -p "${PROJECT_ROOT}/.ai/runs/${TASK_ID}"
touch "${PROJECT_ROOT}/.ai/runs/${TASK_ID}/plan.md"
touch "${PROJECT_ROOT}/.ai/runs/${TASK_ID}/brief.md"

output=$(cd "${PROJECT_ROOT}" && bash "${STATUS_SH}" 2>&1)

it "lists newly created run"
assert_contains "${TASK_ID}" "$output"

# Cleanup
rm -rf "${PROJECT_ROOT}/.ai/runs/${TASK_ID}"

teardown_workspace
print_summary
