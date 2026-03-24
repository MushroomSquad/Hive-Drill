#!/usr/bin/env bash
# Простой бенчмарк скорости: tok/s для текущего endpoint
# Использование: ./scripts/benchmark.sh [tabbyapi|llamacpp] [short|long]
set -euo pipefail

TARGET="${1:-tabbyapi}"
MODE="${2:-short}"

case "$TARGET" in
  tabbyapi)  BASE_URL="http://localhost:33931/v1" ;;
  llamacpp)  BASE_URL="http://localhost:33831/v1" ;;
  *)         BASE_URL="$TARGET" ;;
esac

# Получаем первую доступную модель
MODEL_ID=$(curl -sf "$BASE_URL/models" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['id'] if d.get('data') else '')" 2>/dev/null || echo "")

if [ -z "$MODEL_ID" ]; then
  echo "Нет загруженных моделей или endpoint недоступен: $BASE_URL"
  exit 1
fi

case "$MODE" in
  short)
    PROMPT="Write a Python function to reverse a string. Only code, no explanation."
    MAX_TOKENS=100
    ;;
  long)
    PROMPT="Design a REST API for a task management system. Include endpoints, request/response schemas, and authentication approach. Be detailed."
    MAX_TOKENS=600
    ;;
esac

echo "=== Бенчмарк ==="
echo "Endpoint:   $BASE_URL"
echo "Модель:     $MODEL_ID"
echo "Режим:      $MODE (max_tokens=$MAX_TOKENS)"
echo ""

START=$(date +%s%3N)

RESPONSE=$(curl -sf "$BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL_ID\",
    \"messages\": [{\"role\": \"user\", \"content\": $(echo "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))")}],
    \"max_tokens\": $MAX_TOKENS,
    \"temperature\": 0.1,
    \"stream\": false
  }")

END=$(date +%s%3N)
ELAPSED_MS=$(( END - START ))

echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
usage = data.get('usage', {})
content = data['choices'][0]['message']['content']
comp_tokens = usage.get('completion_tokens', len(content.split()))
elapsed_s = $ELAPSED_MS / 1000.0
tps = comp_tokens / elapsed_s if elapsed_s > 0 else 0

print(f'Время:          {elapsed_s:.2f} s')
print(f'Токены вывода:  {comp_tokens}')
print(f'Скорость:       {tps:.1f} tok/s')
print()
print('Ответ (начало):')
print(content[:300].strip())
" 2>/dev/null || echo "Не удалось разобрать ответ"
