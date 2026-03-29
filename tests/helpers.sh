#!/usr/bin/env bash
# tests/helpers.sh — Shared test utilities (no external dependencies)

# ─── Cross-platform sed -i ─────────────────────────────────────────────────────
_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/detect-platform.sh
source "${_HELPERS_DIR}/../scripts/detect-platform.sh"
unset _HELPERS_DIR

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

# ─── Counters ─────────────────────────────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
_CURRENT_TEST=""

# ─── Test lifecycle ───────────────────────────────────────────────────────────
describe() { echo -e "\n${CYAN}${BOLD}▶ $*${RESET}"; }

it() {
    _CURRENT_TEST="$1"
}

pass() {
    TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    echo -e "  ${GREEN}✓${RESET} ${_CURRENT_TEST}"
}

fail() {
    TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    echo -e "  ${RED}✗${RESET} ${_CURRENT_TEST}"
    [[ -n "${1:-}" ]] && echo -e "      ${RED}$1${RESET}"
}

skip_test() {
    TESTS_SKIPPED=$(( TESTS_SKIPPED + 1 ))
    echo -e "  ${YELLOW}○${RESET} ${_CURRENT_TEST} (skipped: ${1:-})"
}

# ─── Assertions ───────────────────────────────────────────────────────────────
assert_equals() {
    local expected="$1" actual="$2"
    if [[ "$expected" == "$actual" ]]; then
        pass
    else
        fail "Expected: '$expected'\n      Got:      '$actual'"
    fi
}

assert_not_equals() {
    local unexpected="$1" actual="$2"
    if [[ "$unexpected" != "$actual" ]]; then
        pass
    else
        fail "Did not expect: '$unexpected'"
    fi
}

assert_contains() {
    local needle="$1" haystack="$2"
    if echo "$haystack" | grep -qF "$needle"; then
        pass
    else
        fail "Expected to contain: '$needle'\n      In: '${haystack:0:200}'"
    fi
}

assert_not_contains() {
    local needle="$1" haystack="$2"
    if ! echo "$haystack" | grep -qF "$needle"; then
        pass
    else
        fail "Did not expect to contain: '$needle'"
    fi
}

assert_file_exists() {
    if [[ -f "$1" ]]; then
        pass
    else
        fail "File not found: $1"
    fi
}

assert_dir_exists() {
    if [[ -d "$1" ]]; then
        pass
    else
        fail "Directory not found: $1"
    fi
}

assert_file_contains() {
    local file="$1" needle="$2"
    if [[ ! -f "$file" ]]; then
        fail "File not found: $file"
        return
    fi
    if grep -qF "$needle" "$file"; then
        pass
    else
        fail "File '$file' does not contain: '$needle'"
    fi
}

assert_exit_ok() {
    local actual_exit="$1"
    if [[ "$actual_exit" -eq 0 ]]; then
        pass
    else
        fail "Expected exit 0, got $actual_exit"
    fi
}

assert_exit_fail() {
    local actual_exit="$1"
    if [[ "$actual_exit" -ne 0 ]]; then
        pass
    else
        fail "Expected non-zero exit, got 0"
    fi
}

# ─── Temp workspace ───────────────────────────────────────────────────────────
setup_workspace() {
    TEST_TMPDIR="$(mktemp -d)"
    TEST_MOCK_BIN="${TEST_TMPDIR}/bin"
    mkdir -p "${TEST_MOCK_BIN}"

    # Create a minimal git repo inside workspace
    TEST_REPO="${TEST_TMPDIR}/repo"
    mkdir -p "${TEST_REPO}"
    (cd "${TEST_REPO}" && git init -q && git commit --allow-empty -q -m "init" 2>/dev/null || true)

    export TEST_TMPDIR TEST_MOCK_BIN TEST_REPO
}

teardown_workspace() {
    [[ -n "${TEST_TMPDIR:-}" && -d "${TEST_TMPDIR}" ]] && rm -rf "${TEST_TMPDIR}"
}

# ─── Mock command factory ─────────────────────────────────────────────────────
# mock_cmd <name> [exit_code] [stdout]
mock_cmd() {
    local name="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"
    local mock_file="${TEST_MOCK_BIN}/${name}"

    cat > "${mock_file}" <<MOCK
#!/usr/bin/env bash
echo ${output@Q}
exit ${exit_code}
MOCK
    chmod +x "${mock_file}"
}

# mock_cmd_script <name> <script_body>
mock_cmd_script() {
    local name="$1"
    local body="$2"
    local mock_file="${TEST_MOCK_BIN}/${name}"
    printf '#!/usr/bin/env bash\n%s\n' "$body" > "${mock_file}"
    chmod +x "${mock_file}"
}

prepend_mock_bin() {
    export PATH="${TEST_MOCK_BIN}:${PATH}"
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    local total=$(( TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED ))
    echo ""
    echo "═══════════════════════════════════════"
    if [[ "$TESTS_FAILED" -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}PASS${RESET}  ${TESTS_PASSED}/${total} tests passed${TESTS_SKIPPED:+ (${TESTS_SKIPPED} skipped)}"
    else
        echo -e "${RED}${BOLD}FAIL${RESET}  ${TESTS_PASSED} passed, ${TESTS_FAILED} failed${TESTS_SKIPPED:+, ${TESTS_SKIPPED} skipped} (total: ${total})"
    fi
    echo "═══════════════════════════════════════"
    [[ "$TESTS_FAILED" -eq 0 ]]
}
