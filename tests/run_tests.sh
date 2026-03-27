#!/usr/bin/env bash
# tests/run_tests.sh — Master test runner
# Usage:
#   ./tests/run_tests.sh            # run all tests
#   ./tests/run_tests.sh gate       # run only test_gate.sh
#   ./tests/run_tests.sh new canvas # run test_new.sh and test_canvas.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; RESET='\033[0m'

# ─── Discover test files ───────────────────────────────────────────────────────
ALL_TESTS=(
    test_new
    test_gate
    test_ai_check
    test_canvas
    test_plan_init
    test_worktree
    test_package_pr
    test_go_pipeline
    test_canvas_arch
    test_status
)

if [[ $# -gt 0 ]]; then
    SELECTED=("$@")
else
    SELECTED=("${ALL_TESTS[@]}")
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       AI Dev OS — Test Suite                 ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0
SUITE_FAILURES=()

for name in "${SELECTED[@]}"; do
    # Allow "gate" shorthand for "test_gate"
    [[ "$name" != test_* ]] && name="test_${name}"
    test_file="${SCRIPT_DIR}/${name}.sh"

    if [[ ! -f "$test_file" ]]; then
        echo -e "${RED}[NOT FOUND]${RESET} $test_file"
        continue
    fi

    echo -e "${CYAN}─── Running: ${name}.sh ───────────────────────${RESET}"

    # Run test in subshell, capture output and exit code
    output=$(bash "$test_file" 2>&1)
    exit_code=$?

    echo "$output"

    # Count individual test results from output (strip ANSI then count markers)
    plain=$(printf '%s' "$output" | sed 's/\x1b\[[0-9;]*m//g')
    passed=$(printf '%s' "$plain" | grep -c '^  ✓' 2>/dev/null); passed=${passed//[^0-9]/}; passed=${passed:-0}
    failed=$(printf '%s' "$plain" | grep -c '^  ✗' 2>/dev/null); failed=${failed//[^0-9]/}; failed=${failed:-0}
    skipped=$(printf '%s' "$plain" | grep -c '^  ○' 2>/dev/null); skipped=${skipped//[^0-9]/}; skipped=${skipped:-0}

    TOTAL_PASSED=$(( TOTAL_PASSED + passed ))
    TOTAL_FAILED=$(( TOTAL_FAILED + failed ))
    TOTAL_SKIPPED=$(( TOTAL_SKIPPED + skipped ))

    [[ "$exit_code" -ne 0 ]] && SUITE_FAILURES+=("$name")
done

TOTAL=$(( TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED ))

echo ""
echo "═══════════════════════════════════════════════"
echo -e "${BOLD}Overall results: ${TOTAL} tests${RESET}"
echo -e "  ${GREEN}Passed:${RESET}  ${TOTAL_PASSED}"
echo -e "  ${RED}Failed:${RESET}  ${TOTAL_FAILED}"
[[ "$TOTAL_SKIPPED" -gt 0 ]] && echo -e "  Skipped: ${TOTAL_SKIPPED}"

if [[ "${#SUITE_FAILURES[@]}" -gt 0 ]]; then
    echo ""
    echo -e "${RED}${BOLD}Failed suites:${RESET}"
    for s in "${SUITE_FAILURES[@]}"; do
        echo -e "  ${RED}✗${RESET} $s"
    done
    echo "═══════════════════════════════════════════════"
    exit 1
else
    echo ""
    echo -e "${GREEN}${BOLD}All suites passed!${RESET}"
    echo "═══════════════════════════════════════════════"
    exit 0
fi
