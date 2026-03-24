#!/usr/bin/env bash
# Скачивает GGUF-модели для резервного стека llama.cpp
set -euo pipefail

DEST="${LLAMACPP_MODELS_DIR:-./llamacpp/data/models}"
mkdir -p "$DEST"

echo "=== Скачиваю GGUF-модели для llama.cpp ==="
echo "Назначение: $DEST"
echo ""

# Кодер Q5_K_M (~5.44 GB, лучшее качество в рамках 6 GB)
echo "1/2 Qwen2.5-Coder-7B-Instruct Q5_K_M..."
harbor hf dl \
  -m Qwen/Qwen2.5-Coder-7B-Instruct-GGUF \
  -s "$DEST" \
  --include "Qwen2.5-Coder-7B-Instruct-Q5_K_M.gguf"

echo ""

# Писатель Q4_K_M (~8.99 GB)
echo "2/2 Qwen2.5-14B-Instruct Q4_K_M..."
harbor hf dl \
  -m Qwen/Qwen2.5-14B-Instruct-GGUF \
  -s "$DEST" \
  --include "Qwen2.5-14B-Instruct-Q4_K_M.gguf"

echo ""
echo "Готово. Следующий шаг:"
echo "  ./profiles/llamacpp-router.sh"
