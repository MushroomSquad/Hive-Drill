#!/usr/bin/env bash
# Скачивает основную кодовую модель: Qwen2.5-Coder-7B-Instruct-exl2 @ 6_5
set -euo pipefail

MODEL="bartowski/Qwen2.5-Coder-7B-Instruct-exl2"
BRANCH="6_5"
DEST="${HF_MODELS_DIR:-./hf}"

echo "=== Скачиваю: $MODEL @ $BRANCH ==="
echo "Назначение: $DEST"
echo ""
echo "Ожидаемый размер: ~7–9 GB"
echo ""

harbor hf dl \
  -m "$MODEL" \
  -s "$DEST" \
  -b "$BRANCH"

echo ""
echo "Готово. Следующий шаг:"
echo "  ./profiles/tabbyapi-coder.sh"
