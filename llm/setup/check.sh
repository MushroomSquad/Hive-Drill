#!/usr/bin/env bash
# Проверка всего стека перед запуском
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAILED=1; }
FAILED=0

echo "=== Проверка окружения ==="
echo ""

# Docker
if docker info &>/dev/null; then
  ok "Docker запущен"
else
  fail "Docker не запущен или нет доступа"
fi

# Docker Compose
if docker compose version &>/dev/null; then
  ok "Docker Compose $(docker compose version | grep -oP '[\d.]+' | head -1)"
else
  fail "Docker Compose недоступен"
fi

# Harbor
if command -v harbor &>/dev/null; then
  ok "Harbor: $(harbor --version 2>/dev/null || echo '?')"
else
  fail "Harbor не найден — запусти ./setup/install.sh"
fi

# GPU в Docker
echo ""
echo "=== GPU ==="
if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi -L 2>/dev/null; then
  ok "GPU доступна в контейнерах"
else
  warn "GPU в Docker не обнаружена — AI-ускорение недоступно"
fi

# Диск
echo ""
echo "=== Диск ==="
FREE_GB=$(df -BG . | awk 'NR==2{print $4}' | tr -d 'G')
if [ "$FREE_GB" -ge 20 ]; then
  ok "Свободно: ${FREE_GB} GB"
else
  warn "Свободно: ${FREE_GB} GB (рекомендуется >= 20 GB для моделей)"
fi

# Порты
echo ""
echo "=== Порты ==="
for PORT in 33931 33831 8080; do
  if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    warn "Порт $PORT уже занят"
  else
    ok "Порт $PORT свободен"
  fi
done

echo ""
if [ "$FAILED" -eq 1 ]; then
  echo -e "${RED}Есть проблемы — исправь их перед запуском.${NC}"
  exit 1
else
  echo -e "${GREEN}Всё готово к запуску.${NC}"
fi
