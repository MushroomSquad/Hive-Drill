#!/usr/bin/env bash
# Показывает статус всех сервисов и доступных endpoint'ов
set -uo pipefail

echo "=== Local LLM Stack — Status ==="
echo ""

# Harbor сервисы
echo "--- Harbor сервисы ---"
harbor ps 2>/dev/null || echo "(Harbor не запущен)"
echo ""

# TabbyAPI
echo "--- TabbyAPI (http://localhost:33931) ---"
if curl -sf http://localhost:33931/v1/models &>/dev/null; then
  echo "Статус: ONLINE"
  echo "Модели:"
  curl -sf http://localhost:33931/v1/models | \
    python3 -c "import sys,json; [print('  -', m['id']) for m in json.load(sys.stdin).get('data',[])]" 2>/dev/null || \
    echo "  (не удалось разобрать ответ)"
else
  echo "Статус: OFFLINE"
fi
echo ""

# llama.cpp
echo "--- llama.cpp (http://localhost:33831) ---"
if curl -sf http://localhost:33831/v1/models &>/dev/null; then
  echo "Статус: ONLINE"
  echo "Модели:"
  curl -sf http://localhost:33831/v1/models | \
    python3 -c "import sys,json; [print('  -', m['id']) for m in json.load(sys.stdin).get('data',[])]" 2>/dev/null || \
    echo "  (не удалось разобрать ответ)"
else
  echo "Статус: OFFLINE"
fi
echo ""

# GPU
echo "--- GPU ---"
if command -v nvidia-smi &>/dev/null; then
  nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu \
    --format=csv,noheader,nounits 2>/dev/null | \
    awk -F',' '{printf "  %s | VRAM: %s/%s MB | Load: %s%%\n", $1, $2, $3, $4}'
else
  echo "nvidia-smi не доступен"
fi
