#!/usr/bin/env bash
# Download GGUF models for fallback llama.cpp stack
set -euo pipefail

DEST="${LLAMACPP_MODELS_DIR:-./llamacpp/data/models}"
mkdir -p "$DEST"

echo "=== Downloading GGUF models for llama.cpp ==="
echo "Destination: $DEST"
echo ""

# Coder Q5_K_M (~5.44 GB, best quality within 6 GB)
echo "1/2 Qwen2.5-Coder-7B-Instruct Q5_K_M..."
harbor hf dl \
  -m Qwen/Qwen2.5-Coder-7B-Instruct-GGUF \
  -s "$DEST" \
  --include "Qwen2.5-Coder-7B-Instruct-Q5_K_M.gguf"

echo ""

# Writer Q4_K_M (~8.99 GB)
echo "2/2 Qwen2.5-14B-Instruct Q4_K_M..."
harbor hf dl \
  -m Qwen/Qwen2.5-14B-Instruct-GGUF \
  -s "$DEST" \
  --include "Qwen2.5-14B-Instruct-Q4_K_M.gguf"

echo ""
echo "Done. Next step:"
echo "  ./profiles/llamacpp-router.sh"
