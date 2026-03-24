#!/usr/bin/env bash
# Установка Harbor и зависимостей
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

echo "=== Local LLM Stack — Install ==="

# --- Docker ---
if ! command -v docker &>/dev/null; then
  die "Docker не найден. Установи: https://docs.docker.com/engine/install/"
fi
ok "Docker: $(docker --version)"

# --- Docker Compose ---
DC_VER=$(docker compose version 2>/dev/null | grep -oP '[\d.]+' | head -1 || echo "0")
REQUIRED="2.23.1"
if [ "$(printf '%s\n' "$REQUIRED" "$DC_VER" | sort -V | head -1)" != "$REQUIRED" ]; then
  die "Docker Compose >= $REQUIRED нужен. Текущий: $DC_VER"
fi
ok "Docker Compose: $DC_VER"

# --- Git ---
if ! command -v git &>/dev/null; then
  die "Git не найден."
fi
ok "Git: $(git --version)"

# --- NVIDIA ---
if command -v nvidia-smi &>/dev/null; then
  ok "NVIDIA driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)"
else
  warn "nvidia-smi не найден — GPU-ускорение недоступно. Установи NVIDIA Container Toolkit."
fi

# --- Harbor ---
if command -v harbor &>/dev/null; then
  ok "Harbor уже установлен: $(harbor --version 2>/dev/null || echo 'версия неизвестна')"
else
  echo "Устанавливаю Harbor..."
  if command -v pipx &>/dev/null; then
    pipx install llm-harbor
  elif command -v npm &>/dev/null; then
    npm install -g @avcodes/harbor
  else
    curl -fsSL https://av.codes/get-harbor.sh | bash
  fi
  ok "Harbor установлен"
fi

echo ""
echo "Запусти для проверки:"
echo "  harbor doctor"
echo "  ./setup/check.sh"
