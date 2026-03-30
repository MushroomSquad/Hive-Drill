#!/usr/bin/env bash
# Check entire stack before running
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAILED=1; }
FAILED=0

echo "=== Environment Check ==="
echo ""

# Docker
if docker info &>/dev/null; then
  ok "Docker is running"
else
  fail "Docker is not running or access denied"
fi

# Docker Compose
if docker compose version &>/dev/null; then
  ok "Docker Compose $(docker compose version | grep -oP '[\d.]+' | head -1)"
else
  fail "Docker Compose is not available"
fi

# Harbor
if command -v harbor &>/dev/null; then
  ok "Harbor: $(harbor --version 2>/dev/null || echo '?')"
else
  fail "Harbor not found — run ./setup/install.sh"
fi

# GPU in Docker
echo ""
echo "=== GPU ==="
if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi -L 2>/dev/null; then
  ok "GPU available in containers"
else
  warn "GPU in Docker not detected — AI acceleration is unavailable"
fi

# Disk
echo ""
echo "=== Disk ==="
FREE_GB=$(df -BG . | awk 'NR==2{print $4}' | tr -d 'G')
if [ "$FREE_GB" -ge 20 ]; then
  ok "Free: ${FREE_GB} GB"
else
  warn "Free: ${FREE_GB} GB (>= 20 GB recommended for models)"
fi

# Ports
echo ""
echo "=== Ports ==="
for PORT in 33931 33831 8080; do
  if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    warn "Port $PORT is already in use"
  else
    ok "Port $PORT is free"
  fi
done

echo ""
if [ "$FAILED" -eq 1 ]; then
  echo -e "${RED}There are problems — fix them before running.${NC}"
  exit 1
else
  echo -e "${GREEN}Everything is ready to run.${NC}"
fi
