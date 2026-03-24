#!/usr/bin/env bash
# Тестирует endpoint с реальным запросом
# Использование: ./scripts/test-endpoint.sh [tabbyapi|llamacpp|airllm]
set -euo pipefail

TARGET="${1:-tabbyapi}"

case "$TARGET" in
  tabbyapi)
    BASE_URL="http://localhost:33931/v1"
    ;;
  llamacpp)
    BASE_URL="http://localhost:33831/v1"
    ;;
  airllm)
    BASE_URL="${AIRLLM_URL:-$(harbor url airllm 2>/dev/null)/v1}"
    ;;
  http*)
    BASE_URL="$TARGET"
    ;;
  *)
    echo "Неизвестный target. Используй: tabbyapi, llamacpp, airllm, или полный URL"
    exit 1
    ;;
esac

echo "=== Тест endpoint: $BASE_URL ==="
echo ""

# 1. Список моделей
echo "1. GET /v1/models"
MODELS=$(curl -sf "$BASE_URL/models") || { echo "FAIL: endpoint недоступен"; exit 1; }
echo "$MODELS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
models = data.get('data', [])
print(f'  Найдено моделей: {len(models)}')
for m in models:
    print(f'  - {m[\"id\"]}')
" 2>/dev/null || echo "  (ответ получен, но не удалось разобрать JSON)"
echo ""

# Берём первую модель из списка
MODEL_ID=$(echo "$MODELS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
models = data.get('data', [])
print(models[0]['id'] if models else '')
" 2>/dev/null || echo "")

if [ -z "$MODEL_ID" ]; then
  echo "Нет загруженных моделей — пропускаю тест генерации"
  exit 0
fi

# 2. Тест генерации
echo "2. POST /v1/chat/completions (model: $MODEL_ID)"
RESPONSE=$(curl -sf "$BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL_ID\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Write a Python one-liner that returns the factorial of n.\"}
    ],
    \"max_tokens\": 80,
    \"temperature\": 0.1,
    \"stream\": false
  }")

echo "$RESPONSE" | python3 -c "
import sys,json
data = json.load(sys.stdin)
content = data['choices'][0]['message']['content']
print('  Ответ:')
print('  ' + content.strip().replace('\n', '\n  '))
" 2>/dev/null || echo "  Ответ получен (не удалось разобрать)"

echo ""
echo "Тест завершён."
