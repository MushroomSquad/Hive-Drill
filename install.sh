#!/usr/bin/env bash
# AI Dev OS — Bootstrap installer
#
# Локально:
#   bash install.sh
#
# Из репозитория (после публикации):
#   curl -fsSL https://raw.githubusercontent.com/YOU/ai-dev-os/main/install.sh | bash
#
set -euo pipefail

# ─── Оформление ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

ok()      { echo -e "  ${GREEN}✓${RESET}  $*"; }
fail()    { echo -e "  ${RED}✗${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET}  $*"; }
info()    { echo -e "  ${DIM}→${RESET}  $*"; }
section() { echo -e "\n${CYAN}${BOLD}── $* ──────────────────────────────────────────${RESET}"; }
die()     { echo -e "\n${RED}${BOLD}Ошибка:${RESET} $*\n"; exit 1; }

ERRORS=()
WARNINGS=()

need()  { ERRORS+=("$*"); }
nudge() { WARNINGS+=("$*"); }

# ─── Баннер ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║          AI Dev OS — Installer            ║"
echo "  ║   Cursor · Codex · Claude · Local LLM    ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Определяем окружение ─────────────────────────────────────────────────────
OS="linux"
PKG=""
IN_WSL=false

case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version && IN_WSL=true
    if command -v apt-get &>/dev/null;   then PKG="apt";
    elif command -v dnf &>/dev/null;     then PKG="dnf";
    elif command -v pacman &>/dev/null;  then PKG="pacman";
    fi
    ;;
esac

info "ОС: $OS$(${IN_WSL} && echo ' (WSL2)' || true)"
info "Пакетный менеджер: ${PKG:-не определён}"

# ─── Где мы запущены ──────────────────────────────────────────────────────────
# Если скрипт запущен через curl|bash, PROJECT_DIR = текущая папка
# Если запущен из клонированного репо — его корень
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  PROJECT_DIR="$(pwd)"
fi
info "Директория проекта: $PROJECT_DIR"

# ─── Установщик пакетов ───────────────────────────────────────────────────────
install_pkg() {
  local pkg="$1"
  case "$OS-$PKG" in
    macos-*)        brew install "$pkg" ;;
    linux-apt)      sudo apt-get install -y "$pkg" ;;
    linux-dnf)      sudo dnf install -y "$pkg" ;;
    linux-pacman)   sudo pacman -S --noconfirm "$pkg" ;;
    *)              warn "Не знаю как установить '$pkg' — сделай вручную"; return 1 ;;
  esac
}

# ─── 1. Системные зависимости ─────────────────────────────────────────────────
section "Системные зависимости"

# Git
if command -v git &>/dev/null; then
  ok "git $(git --version | grep -oP '[\d.]+')"
else
  info "Устанавливаю git..."
  install_pkg git && ok "git установлен" || need "git — установи вручную"
fi

# Python 3
if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version 2>&1 | grep -oP '[\d.]+')
  ok "python3 $PY_VER"
else
  need "python3 — установи: https://python.org"
fi

# Node.js / npm
if command -v node &>/dev/null; then
  ok "node $(node --version)"
else
  warn "node не найден — нужен для MCP серверов и Codex"
  nudge "node — установи: https://nodejs.org  или  nvm install --lts"
fi

# Docker
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  ok "docker $(docker --version | grep -oP '[\d.]+')"
else
  if command -v docker &>/dev/null; then
    warn "docker найден, но не запущен"
    nudge "запусти Docker Desktop или: sudo systemctl start docker"
  else
    nudge "docker — нужен для локального LLM (Harbor). Установи: https://docs.docker.com/get-docker/"
  fi
fi

# just
if command -v just &>/dev/null; then
  ok "just $(just --version)"
else
  info "Устанавливаю just..."
  JUST_OK=false
  if [[ "$OS" == "macos" ]] && command -v brew &>/dev/null; then
    brew install just && JUST_OK=true
  elif [[ "$OS" == "linux" ]]; then
    # Пробуем cargo
    if command -v cargo &>/dev/null; then
      cargo install just && JUST_OK=true
    else
      # Бинарный релиз
      JUST_VER=$(curl -fsSL https://api.github.com/repos/casey/just/releases/latest \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "1.36.0")
      JUST_ARCH="x86_64-unknown-linux-musl"
      curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VER}/just-${JUST_VER}-${JUST_ARCH}.tar.gz" \
        | tar xz -C /tmp just
      sudo mv /tmp/just /usr/local/bin/just && JUST_OK=true
    fi
  fi
  ${JUST_OK} && ok "just установлен" || nudge "just — установи: cargo install just"
fi

# ─── 2. AI-инструменты ────────────────────────────────────────────────────────
section "AI-инструменты"

# Claude Code
if command -v claude &>/dev/null; then
  ok "Claude Code $(claude --version 2>/dev/null | head -1)"
else
  if command -v npm &>/dev/null; then
    info "Устанавливаю Claude Code..."
    npm install -g @anthropic/claude-code 2>/dev/null \
      && ok "Claude Code установлен" \
      || nudge "Claude Code — установи вручную: npm install -g @anthropic/claude-code"
  else
    nudge "Claude Code — нужен npm: npm install -g @anthropic/claude-code"
  fi
fi

# Codex
if command -v codex &>/dev/null; then
  ok "Codex $(codex --version 2>/dev/null | head -1)"
else
  if command -v npm &>/dev/null; then
    info "Устанавливаю Codex..."
    npm install -g @openai/codex 2>/dev/null \
      && ok "Codex установлен" \
      || nudge "Codex — установи вручную: npm install -g @openai/codex"
  else
    nudge "Codex — нужен npm: npm install -g @openai/codex"
  fi
fi

# Cursor (проверяем наличие, не устанавливаем)
if command -v cursor &>/dev/null; then
  ok "Cursor"
else
  nudge "Cursor — скачай: https://cursor.com"
fi

# ─── 3. MCP серверы ───────────────────────────────────────────────────────────
section "MCP серверы"

if command -v npm &>/dev/null; then
  MCP_PKGS=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-github"
  )
  for pkg in "${MCP_PKGS[@]}"; do
    name="${pkg##*/}"
    if npm list -g "$pkg" &>/dev/null 2>&1; then
      ok "$name (уже установлен)"
    else
      info "Устанавливаю $name..."
      npm install -g "$pkg" --silent 2>/dev/null \
        && ok "$name" \
        || warn "$name — не удалось установить"
    fi
  done
else
  nudge "MCP серверы — нужен npm"
fi

# ─── 4. Проект ────────────────────────────────────────────────────────────────
section "Настройка проекта"

cd "$PROJECT_DIR"

# .env
if [[ -f .env ]]; then
  ok ".env уже существует"
else
  if [[ -f .env.example ]]; then
    cp .env.example .env
    ok ".env создан из .env.example"
    warn "Заполни API ключи в .env !"
  fi
fi

# Права на скрипты
if [[ -d scripts ]]; then
  chmod +x scripts/*.sh 2>/dev/null && ok "scripts/*.sh — исполняемые"
fi
if [[ -d llm ]]; then
  find llm -name "*.sh" -exec chmod +x {} \; 2>/dev/null && ok "llm/**/*.sh — исполняемые"
fi

# Структура vault
mkdir -p vault/00-inbox vault/01-active vault/02-done
[[ -f vault/01-active/.gitkeep ]] || touch vault/01-active/.gitkeep
[[ -f vault/02-done/.gitkeep  ]] || touch vault/02-done/.gitkeep
ok "vault/ структура готова"

# .ai/runs
mkdir -p .ai/runs
ok ".ai/runs/ готова"

# Git
if git rev-parse --is-inside-work-tree &>/dev/null; then
  ok "git репозиторий: $(git rev-parse --show-toplevel)"
else
  git init && git add -A && git commit -m "init: AI Dev OS" --quiet
  ok "git инициализирован"
fi

# ─── 5. NVIDIA / GPU (опционально) ───────────────────────────────────────────
section "GPU (опционально)"

if command -v nvidia-smi &>/dev/null; then
  GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
  ok "GPU: $GPU"

  if [[ "$OS" == "linux" ]] || ${IN_WSL}; then
    if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 \
         nvidia-smi -L &>/dev/null 2>&1; then
      ok "GPU доступна в Docker"
    else
      nudge "NVIDIA Container Toolkit — запусти: ./llm/setup/install-nvidia.sh"
    fi
  fi
else
  info "NVIDIA GPU не обнаружена — локальный LLM будет на CPU (медленно)"
fi

# ─── 6. Локальный LLM (Harbor) — опционально ─────────────────────────────────
section "Локальный LLM (Harbor)"

if command -v harbor &>/dev/null; then
  ok "Harbor $(harbor --version 2>/dev/null || echo 'найден')"
else
  echo ""
  echo -e "  Harbor нужен для локального LLM (TabbyAPI / llama.cpp)."
  echo -e "  ${DIM}Без него Codex будет работать только через облако.${RESET}"
  echo ""
  read -r -p "  Установить Harbor сейчас? [y/N] " install_harbor
  if [[ "${install_harbor,,}" == "y" ]]; then
    if command -v pipx &>/dev/null; then
      pipx install llm-harbor && ok "Harbor установлен через pipx"
    elif command -v npm &>/dev/null; then
      npm install -g @avcodes/harbor && ok "Harbor установлен через npm"
    else
      curl -fsSL https://av.codes/get-harbor.sh | bash && ok "Harbor установлен"
    fi
  else
    nudge "Harbor — установи позже: curl -fsSL https://av.codes/get-harbor.sh | bash"
  fi
fi

# ─── 7. Ключи ─────────────────────────────────────────────────────────────────
section "API ключи"

check_key() {
  local var="$1" label="$2" url="$3"
  local val=""
  val=$(grep -E "^${var}=.+" .env 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'" || true)
  val="${val:-${!var:-}}"
  if [[ -n "$val" && "$val" != "sk-ant-..." && "$val" != "sk-..." && "$val" != "ghp_..." ]]; then
    ok "${label}: задан"
  else
    nudge "${label} — добавь в .env: ${var}=...  (${url})"
  fi
}

check_key "ANTHROPIC_API_KEY" "Anthropic (Claude)" "https://console.anthropic.com/keys"
check_key "OPENAI_API_KEY"    "OpenAI (Codex)"     "https://platform.openai.com/api-keys"
check_key "GITHUB_TOKEN"      "GitHub (MCP)"       "https://github.com/settings/tokens"

# ─── Итог ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Итог ─────────────────────────────────────────────────────────${RESET}"
echo ""

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo -e "  ${RED}${BOLD}Критические проблемы (нужно исправить):${RESET}"
  for e in "${ERRORS[@]}"; do
    fail "$e"
  done
  echo ""
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo -e "  ${YELLOW}${BOLD}Рекомендуется:${RESET}"
  for w in "${WARNINGS[@]}"; do
    warn "$w"
  done
  echo ""
fi

if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}Установка завершена!${RESET}"
else
  echo -e "  ${YELLOW}Установка завершена с предупреждениями — часть функций недоступна.${RESET}"
fi

# ─── Следующие шаги ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Как начать работу ────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${BOLD}1. Открой vault в Obsidian:${RESET}"
echo -e "     ${DIM}File → Open Vault → $(pwd)/vault${RESET}"
echo ""
echo -e "  ${BOLD}2. Заполни API ключи:${RESET}"
echo -e "     ${DIM}\$EDITOR .env${RESET}"
echo ""
echo -e "  ${BOLD}3. Создай первую задачу:${RESET}"
echo -e "     ${CYAN}just new FEAT-001${RESET}"
echo ""
echo -e "  ${BOLD}4. Заполни бриф в Obsidian → смени status: ready${RESET}"
echo ""
echo -e "  ${BOLD}5. Запусти пайплайн:${RESET}"
echo -e "     ${CYAN}just go FEAT-001${RESET}"
echo ""
echo -e "  ${DIM}Полный список команд: just --list${RESET}"
echo ""
