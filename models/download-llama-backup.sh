#!/usr/bin/env bash
# Скачивает быстрый резервный кодер: Meta-Llama-3.1-8B-Instruct-exl2 @ 6_5
set -euo pipefail

MODEL="bartowski/Meta-Llama-3.1-8B-Instruct-exl2"
BRANCH="6_5"
DEST="${HF_MODELS_DIR:-./hf}"

echo "=== Скачиваю: $MODEL @ $BRANCH ==="
echo "Назначение: $DEST"
echo ""
echo "Ожидаемый размер: ~8 GB"
echo "Назначение: быстрый резерв / черновики / объяснения"
echo ""

harbor hf dl \
  -m "$MODEL" \
  -s "$DEST" \
  -b "$BRANCH"

echo ""
echo "Готово."
