#!/usr/bin/env bash
# Download fast fallback coder: Meta-Llama-3.1-8B-Instruct-exl2 @ 6_5
set -euo pipefail

MODEL="bartowski/Meta-Llama-3.1-8B-Instruct-exl2"
BRANCH="6_5"
DEST="${HF_MODELS_DIR:-./hf}"

echo "=== Downloading: $MODEL @ $BRANCH ==="
echo "Destination: $DEST"
echo ""
echo "Expected size: ~8 GB"
echo "Purpose: fast fallback / drafts / explanations"
echo ""

harbor hf dl \
  -m "$MODEL" \
  -s "$DEST" \
  -b "$BRANCH"

echo ""
echo "Done."
