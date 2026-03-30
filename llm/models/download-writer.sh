#!/usr/bin/env bash
# Download model for specs/documentation: Qwen2.5-14B-Instruct-exl2 @ 4_25
set -euo pipefail

MODEL="bartowski/Qwen2.5-14B-Instruct-exl2"
BRANCH="4_25"
DEST="${HF_MODELS_DIR:-./hf}"

echo "=== Downloading: $MODEL @ $BRANCH ==="
echo "Destination: $DEST"
echo ""
echo "Expected size: ~10–11 GB"
echo "Important: quantization 4_25 on 12 GB VRAM — keep ctx <= 8192"
echo ""

harbor hf dl \
  -m "$MODEL" \
  -s "$DEST" \
  -b "$BRANCH"

echo ""
echo "Done. Next step:"
echo "  ./profiles/tabbyapi-writer.sh"
