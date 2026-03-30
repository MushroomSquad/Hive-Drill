#!/usr/bin/env bash
# Profile: llama.cpp router mode — multiple GGUF models at once
# Purpose: fallback stack, switch via "model" field in request
# Endpoint: http://localhost:33831/v1
set -euo pipefail

echo "=== llama.cpp: Router Mode ==="
echo "Endpoint: http://localhost:33831/v1"
echo ""

# Enable router mode — remove fixed model specifier
harbor config set llamacpp.model.specifier ""

# Server arguments:
#   --models-dir  — folder with GGUF files
#   --models-max  — max models loaded simultaneously
#   --no-models-autoload — don't load everything at startup
#   -c 8192       — context size
#   -fa           — Flash Attention
#   -ngl all      — all layers on GPU
harbor llamacpp args \
  "--models-dir /app/data/models --models-max 2 --no-models-autoload -c 8192 -fa on -ngl all"

harbor up llamacpp

echo ""
echo "Load coder:"
echo "  curl -X POST http://localhost:33831/models/load \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"Qwen2.5-Coder-7B-Instruct-Q5_K_M\"}'"
echo ""
echo "Load writer:"
echo "  curl -X POST http://localhost:33831/models/load \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"Qwen2.5-14B-Instruct-Q4_K_M\"}'"
echo ""
echo "List available models:"
echo "  curl http://localhost:33831/v1/models"
