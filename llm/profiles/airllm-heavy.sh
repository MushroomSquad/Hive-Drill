#!/usr/bin/env bash
# Profile: AirLLM — heavy models that don't fit in VRAM
# Purpose: run Qwen2.5-Coder-32B via layer-wise inference
# Endpoint: provided by Harbor
set -euo pipefail

MODEL="${AIRLLM_MODEL:-Qwen/Qwen2.5-Coder-32B-Instruct}"
CTX="${AIRLLM_CTX:-8192}"
COMPRESSION="${AIRLLM_COMPRESSION:-4bit}"

echo "=== AirLLM: Heavy Mode ==="
echo "Model:         $MODEL"
echo "Context:       $CTX"
echo "Compression:   $COMPRESSION"
echo ""
echo "Warning: first run is slow — model is decomposed into layers on disk."
echo "Make sure you have 60–100 GB of free space."
echo ""

harbor airllm model "$MODEL"
harbor airllm ctx "$CTX"
harbor airllm compression "$COMPRESSION"
harbor up airllm

echo ""
AIRLLM_URL=$(harbor url airllm 2>/dev/null || echo "see harbor url airllm")
echo "Endpoint: $AIRLLM_URL/v1"
echo ""
echo "Verification:"
echo "  curl $AIRLLM_URL/v1/models"
