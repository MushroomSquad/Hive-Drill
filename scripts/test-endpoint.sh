#!/usr/bin/env bash
# Tests endpoint with real request
# Usage: ./scripts/test-endpoint.sh [tabbyapi|llamacpp|airllm]
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
    echo "Unknown target. Use: tabbyapi, llamacpp, airllm, or full URL"
    exit 1
    ;;
esac

echo "=== Test endpoint: $BASE_URL ==="
echo ""

# 1. Models list
echo "1. GET /v1/models"
MODELS=$(curl -sf "$BASE_URL/models") || { echo "FAIL: endpoint unavailable"; exit 1; }
echo "$MODELS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
models = data.get('data', [])
print(f'  Models found: {len(models)}')
for m in models:
    print(f'  - {m[\"id\"]}')
" 2>/dev/null || echo "  (response received, but failed to parse JSON)"
echo ""

# Get first model from list
MODEL_ID=$(echo "$MODELS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
models = data.get('data', [])
print(models[0]['id'] if models else '')
" 2>/dev/null || echo "")

if [ -z "$MODEL_ID" ]; then
  echo "No loaded models — skipping generation test"
  exit 0
fi

# 2. Generation test
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
print('  Response:')
print('  ' + content.strip().replace('\n', '\n  '))
" 2>/dev/null || echo "  Response received (failed to parse)"

echo ""
echo "Test complete."
