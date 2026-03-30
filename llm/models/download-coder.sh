#!/usr/bin/env bash
# Download main code model: Qwen2.5-Coder-7B-Instruct-exl2 @ 6_5
set -euo pipefail

MODEL="bartowski/Qwen2.5-Coder-7B-Instruct-exl2"
BRANCH="6_5"
DEST="${HF_MODELS_DIR:-./hf}"

echo "=== Downloading: $MODEL @ $BRANCH ==="
echo "Destination: $DEST"
echo ""
echo "Expected size: ~7–9 GB"
echo ""

harbor hf dl \
  -m "$MODEL" \
  -s "$DEST" \
  -b "$BRANCH"

echo ""
echo "Done. Next step:"
echo "  ./profiles/tabbyapi-coder.sh"
