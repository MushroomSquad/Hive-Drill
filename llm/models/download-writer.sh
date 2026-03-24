#!/usr/bin/env bash
# Скачивает модель для ТЗ/документации: Qwen2.5-14B-Instruct-exl2 @ 4_25
set -euo pipefail

MODEL="bartowski/Qwen2.5-14B-Instruct-exl2"
BRANCH="4_25"
DEST="${HF_MODELS_DIR:-./hf}"

echo "=== Скачиваю: $MODEL @ $BRANCH ==="
echo "Назначение: $DEST"
echo ""
echo "Ожидаемый размер: ~10–11 GB"
echo "Важно: квант 4_25 на 12 GB VRAM — держи ctx <= 8192"
echo ""

harbor hf dl \
  -m "$MODEL" \
  -s "$DEST" \
  -b "$BRANCH"

echo ""
echo "Готово. Следующий шаг:"
echo "  ./profiles/tabbyapi-writer.sh"
