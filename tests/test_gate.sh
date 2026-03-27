#!/usr/bin/env bash
# tests/test_gate.sh — Tests for scripts/gate.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

GATE_SH="${PROJECT_ROOT}/scripts/gate.sh"

describe "gate.sh — argument validation"

it "exits 1 with no arguments"
output=$("${GATE_SH}" 2>&1); code=$?
assert_exit_fail $code

it "exits 1 with only one argument"
output=$("${GATE_SH}" plan 2>&1); code=$?
assert_exit_fail $code

it "exits 1 if artifact file does not exist"
output=$("${GATE_SH}" plan /tmp/nonexistent-gate-artifact-xyz.md 2>&1); code=$?
assert_exit_fail $code

it "error message mentions missing file"
assert_contains "not found" "$output"

describe "gate.sh — approval (non-interactive via stdin)"

setup_workspace

ARTIFACT="${TEST_TMPDIR}/plan.md"
cat > "${ARTIFACT}" <<'EOF'
---
task_id: TEST-001
status: draft
---
# Plan: Test
This is a test plan.
EOF

it "approves when user inputs 'y'"
echo "y" | "${GATE_SH}" plan "${ARTIFACT}" > /dev/null 2>&1; code=$?
assert_exit_ok $code

it "sets status: approved in frontmatter after 'y'"
assert_file_contains "${ARTIFACT}" "status: approved"

it "rejects when user inputs 'n'"
# Reset status
sed -i 's/status: approved/status: draft/' "${ARTIFACT}"
echo "n" | "${GATE_SH}" plan "${ARTIFACT}" > /dev/null 2>&1; code=$?
assert_exit_fail $code

describe "gate.sh — verdict field update"

FINDINGS="${TEST_TMPDIR}/findings.md"
cat > "${FINDINGS}" <<'EOF'
---
task_id: TEST-001
verdict: NEEDS_REVIEW
---
# Findings
EOF

it "updates verdict: APPROVED in findings file"
echo "y" | "${GATE_SH}" review "${FINDINGS}" > /dev/null 2>&1
assert_file_contains "${FINDINGS}" "verdict: APPROVED"

teardown_workspace
print_summary
