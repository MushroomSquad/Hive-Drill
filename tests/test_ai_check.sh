#!/usr/bin/env bash
# tests/test_ai_check.sh — Tests for scripts/ai-check.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

AICHECK_SH="${PROJECT_ROOT}/scripts/ai-check.sh"

describe "ai-check.sh — unknown project type"

setup_workspace

# Empty repo: no package.json, no pyproject.toml, no go.mod
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --full 2>&1); code=$?

it "exits 0 on unknown project (all SKIPs, no FAILs)"
assert_exit_ok $code

it "reports project type as 'unknown'"
assert_contains "unknown" "$output"

it "skips lint for unknown project"
assert_contains "SKIP" "$output"

teardown_workspace

describe "ai-check.sh — node project"

setup_workspace

# Create a minimal node project with lint + test scripts
cat > "${TEST_REPO}/package.json" <<'EOF'
{
  "name": "test-project",
  "scripts": {
    "lint": "echo lint-ok",
    "test": "echo test-ok && exit 0"
  }
}
EOF

it "detects node project type"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --full 2>&1)
assert_contains "node" "$output"

it "runs npm test and passes"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --tests-only 2>&1); code=$?
assert_exit_ok $code

it "shows PASS for npm test"
assert_contains "PASS" "$output"

teardown_workspace

describe "ai-check.sh — node project failing test"

setup_workspace

cat > "${TEST_REPO}/package.json" <<'EOF'
{
  "name": "test-fail",
  "scripts": {
    "test": "exit 1"
  }
}
EOF

it "exits 1 when tests fail"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --full 2>&1); code=$?
assert_exit_fail $code

it "shows FAIL label in output"
assert_contains "FAIL" "$output"

teardown_workspace

describe "ai-check.sh — secrets scan"

setup_workspace

# Plant a fake hardcoded secret
mkdir -p "${TEST_REPO}/src"
cat > "${TEST_REPO}/src/config.py" <<'EOF'
password = "supersecret123"
EOF

cat > "${TEST_REPO}/package.json" <<'EOF'
{"name":"x","scripts":{"test":"exit 0"}}
EOF

it "flags hardcoded password as potential secret"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --full 2>&1)
assert_contains "FAIL" "$output"

teardown_workspace

describe "ai-check.sh — go project"

setup_workspace

cat > "${TEST_REPO}/go.mod" <<'EOF'
module example.com/test
go 1.21
EOF

mkdir -p "${TEST_REPO}/pkg"
cat > "${TEST_REPO}/pkg/math.go" <<'EOF'
package pkg

func Add(a, b int) int { return a + b }
EOF

cat > "${TEST_REPO}/pkg/math_test.go" <<'EOF'
package pkg

import "testing"

func TestAdd(t *testing.T) {
    if Add(1,2) != 3 { t.Fatal("wrong") }
}
EOF

it "detects go project type"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --full 2>&1)
assert_contains "go" "$output"

# Only run if go is available
if command -v go &>/dev/null; then
    it "passes go test"
    output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --full 2>&1); code=$?
    assert_exit_ok $code

    it "shows PASS for go test"
    assert_contains "PASS" "$output"
else
    it "skips go tests (go not installed)"
    skip_test "go not in PATH"
fi

teardown_workspace

describe "ai-check.sh — mode flags"

setup_workspace
cat > "${TEST_REPO}/package.json" <<'EOF'
{"name":"x","scripts":{"lint":"exit 0","test":"exit 0"}}
EOF

it "--quick mode skips typecheck"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --quick 2>&1)
assert_not_contains "Typecheck" "$output"

it "--tests-only mode skips lint"
output=$(cd "${TEST_REPO}" && bash "${AICHECK_SH}" --tests-only 2>&1)
assert_not_contains "Lint" "$output"

teardown_workspace
print_summary
