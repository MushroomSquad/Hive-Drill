#!/usr/bin/env bash
# Инициализация проекта с нуля
# Использование: ./scripts/init.sh [--mcp] [--llm] [--all]
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
info() { echo -e "${CYAN}[--]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

INIT_MCP=false
INIT_LLM=false

for arg in "$@"; do
  case "$arg" in
    --mcp) INIT_MCP=true ;;
    --llm) INIT_LLM=true ;;
    --all) INIT_MCP=true; INIT_LLM=true ;;
  esac
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║        AI Dev OS — Init              ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── .env ──────────────────────────────────────────────────────────────
info "Проверяю .env..."
if [ ! -f .env ]; then
  cp .env.example .env
  warn ".env создан из .env.example — заполни переменные перед запуском агентов"
else
  ok ".env существует"
fi

# ── .ai/runs директория ───────────────────────────────────────────────
info "Структура .ai/runs/..."
mkdir -p .ai/runs
ok ".ai/runs/ готова"

# ── Git ───────────────────────────────────────────────────────────────
info "Проверяю git..."
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  git init
  ok "Git инициализирован"
else
  ok "Git репозиторий: $(git rev-parse --show-toplevel)"
fi

# ── Node.js (для MCP серверов) ────────────────────────────────────────
info "Проверяю Node.js..."
if command -v node &>/dev/null; then
  ok "Node.js: $(node --version)"
else
  warn "Node.js не найден — MCP серверы на npx не будут работать"
fi

# ── Зависимости агентов ───────────────────────────────────────────────
echo ""
info "=== Зависимости агентов ==="

check_cmd() {
  local cmd=$1 name=$2 install=$3
  if command -v "$cmd" &>/dev/null; then
    ok "$name: $(${cmd} --version 2>/dev/null | head -1 || echo 'найден')"
  else
    warn "$name не найден. Установи: $install"
  fi
}

check_cmd "claude"  "Claude Code" "https://claude.ai/code"
check_cmd "codex"   "Codex CLI"   "npm install -g @openai/codex"
check_cmd "cursor"  "Cursor"      "https://cursor.com"
check_cmd "just"    "just"        "cargo install just  # или brew install just"

# ── MCP серверы ───────────────────────────────────────────────────────
if [ "$INIT_MCP" = true ]; then
  echo ""
  info "=== Устанавливаю MCP серверы ==="

  if ! command -v npx &>/dev/null; then
    warn "npx не найден — пропускаю MCP установку"
  else
    npm_pkgs=(
      "@modelcontextprotocol/server-github"
      "@modelcontextprotocol/server-filesystem"
      "@modelcontextprotocol/server-memory"
    )
    for pkg in "${npm_pkgs[@]}"; do
      info "Устанавливаю $pkg..."
      npm install -g "$pkg" --silent && ok "$pkg" || warn "Не удалось установить $pkg"
    done
  fi
fi

# ── Локальный LLM стек ────────────────────────────────────────────────
if [ "$INIT_LLM" = true ]; then
  echo ""
  info "=== Инициализирую локальный LLM стек ==="
  if [ -f llm/setup/install.sh ]; then
    bash llm/setup/install.sh
  else
    warn "llm/setup/install.sh не найден"
  fi
fi

# ── just / make check ─────────────────────────────────────────────────
echo ""
info "=== Финальная проверка ==="
if command -v just &>/dev/null; then
  info "Доступные команды: just --list"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  Готово. Следующие шаги:"
echo ""
echo "  1. Заполни .env"
echo "  2. Заполни .ai/base/BASE.md"
echo "  3. just bp feature TASK-001  # запустить первый pipeline"
echo ""
if [ "$INIT_LLM" = false ]; then
  echo "  Локальный LLM: ./scripts/init.sh --llm"
fi
if [ "$INIT_MCP" = false ]; then
  echo "  MCP серверы:   ./scripts/init.sh --mcp"
fi
echo "═══════════════════════════════════════"
