#!/usr/bin/env bash
# Validation gate — single source of truth for all agents
# Usage:
#   ./scripts/ai-check.sh               — full check
#   ./scripts/ai-check.sh --quick       — lint only
#   ./scripts/ai-check.sh --tests-only  — tests only
#   ./scripts/ai-check.sh --full        — full + security
set -uo pipefail

MODE="${1:---full}"
FAILED=0
LOG_FILE="${AI_CHECK_LOG:-/dev/null}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}[PASS]${NC} $*" | tee -a "$LOG_FILE"; }
fail() { echo -e "${RED}[FAIL]${NC} $*" | tee -a "$LOG_FILE"; FAILED=1; }
skip() { echo -e "${YELLOW}[SKIP]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "       $*" | tee -a "$LOG_FILE"; }

run_check() {
  local name="$1" cmd="$2"
  if eval "$cmd" &>/dev/null; then
    pass "$name"
  else
    fail "$name"
    info "Command: $cmd"
    eval "$cmd" 2>&1 | tail -20 | sed 's/^/       /' | tee -a "$LOG_FILE" || true
  fi
}

echo "=== ai-check ($MODE) ===" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ── Detect project type ───────────────────────────────────────────────
detect_type() {
  [ -f package.json ]   && echo "node"   && return
  [ -f pyproject.toml ] || [ -f setup.py ] && echo "python" && return
  [ -f go.mod ]         && echo "go"     && return
  [ -f Makefile ]       && echo "make"   && return
  echo "unknown"
}

PROJECT_TYPE=$(detect_type)
info "Project type: $PROJECT_TYPE"
echo "" | tee -a "$LOG_FILE"

# ── Lint ─────────────────────────────────────────────────────────────
if [[ "$MODE" != "--tests-only" ]]; then
  echo "--- Lint ---" | tee -a "$LOG_FILE"
  case "$PROJECT_TYPE" in
    node)
      [ -f package.json ] && grep -q '"lint"' package.json \
        && run_check "ESLint / npm lint" "npm run lint" \
        || skip "npm run lint (not found in package.json)"
      ;;
    python)
      command -v ruff &>/dev/null \
        && run_check "ruff" "ruff check ." \
        || command -v flake8 &>/dev/null \
        && run_check "flake8" "flake8 ." \
        || skip "linter not found (ruff / flake8)"
      ;;
    go)
      run_check "go vet" "go vet ./..."
      command -v golangci-lint &>/dev/null \
        && run_check "golangci-lint" "golangci-lint run" \
        || skip "golangci-lint not found"
      ;;
    make)
      grep -q "^lint:" Makefile && run_check "make lint" "make lint" || skip "make lint"
      ;;
    *) skip "lint (unknown project type)" ;;
  esac
  echo "" | tee -a "$LOG_FILE"
fi

# ── Typecheck ─────────────────────────────────────────────────────────
if [[ "$MODE" != "--tests-only" && "$MODE" != "--quick" ]]; then
  echo "--- Typecheck ---" | tee -a "$LOG_FILE"
  case "$PROJECT_TYPE" in
    node)
      [ -f package.json ] && grep -q '"typecheck"' package.json \
        && run_check "TypeScript" "npm run typecheck" \
        || [ -f tsconfig.json ] \
        && run_check "tsc --noEmit" "npx tsc --noEmit" \
        || skip "typecheck (not a TypeScript project)"
      ;;
    python)
      command -v mypy &>/dev/null \
        && run_check "mypy" "mypy ." \
        || skip "mypy not found"
      ;;
    go)
      run_check "go build" "go build ./..."
      ;;
    *) skip "typecheck" ;;
  esac
  echo "" | tee -a "$LOG_FILE"
fi

# ── Tests ─────────────────────────────────────────────────────────────
echo "--- Tests ---" | tee -a "$LOG_FILE"
case "$PROJECT_TYPE" in
  node)
    [ -f package.json ] && grep -q '"test"' package.json \
      && run_check "npm test" "npm test" \
      || skip "npm test (not found in package.json)"
    ;;
  python)
    command -v pytest &>/dev/null \
      && run_check "pytest" "python -m pytest -q" \
      || skip "pytest not found"
    ;;
  go)
    run_check "go test" "go test ./..."
    ;;
  make)
    grep -q "^test:" Makefile && run_check "make test" "make test" || skip "make test"
    ;;
  *)
    # Fallback: try just test if justfile exists
    if command -v just &>/dev/null && [ -f justfile ] && just --list 2>/dev/null | grep -q "^test "; then
      run_check "just test" "just test"
    # Try the built-in bash test runner
    elif [ -f tests/run_tests.sh ]; then
      run_check "bash tests" "bash tests/run_tests.sh"
    else
      skip "tests (unknown project type)"
    fi
    ;;
esac
echo "" | tee -a "$LOG_FILE"

# ── Workspace cleanup contract ──────────────────────────────────────
if [[ -d "_ai_tmp" ]]; then
  fail "Transient workspace directory present: ./_ai_tmp (pipeline cleanup did not run)"
else
  pass "Transient workspace directory absent"
fi
echo "" | tee -a "$LOG_FILE"

# ── Security sweep (only --full) ────────────────────────────────────
if [[ "$MODE" == "--full" ]]; then
  echo "--- Security sweep ---" | tee -a "$LOG_FILE"

  # Secrets scan (basic)
  if grep -rE "(password|secret|api_key|token)\s*=\s*['\"][^'\"]{8,}" \
       --include="*.py" --include="*.ts" --include="*.js" --include="*.go" \
       --include="*.toml" --include="*.yaml" \
       . 2>/dev/null | grep -v ".env.example" | grep -v ".gitignore" | head -5; then
    fail "Possible hardcoded secrets found"
  else
    pass "Secrets scan"
  fi

  # npm audit
  if [ "$PROJECT_TYPE" = "node" ] && command -v npm &>/dev/null; then
    run_check "npm audit" "npm audit --audit-level=high"
  fi

  # Python safety
  if [ "$PROJECT_TYPE" = "python" ] && command -v pip-audit &>/dev/null; then
    run_check "pip-audit" "pip-audit -q"
  fi

  echo "" | tee -a "$LOG_FILE"
fi

# ── Summary ───────────────────────────────────────────────────────────
echo "═══════════════════════════════════" | tee -a "$LOG_FILE"
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}ai-check: PASS${NC}" | tee -a "$LOG_FILE"
  exit 0
else
  echo -e "${RED}ai-check: FAIL — fix errors above${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
