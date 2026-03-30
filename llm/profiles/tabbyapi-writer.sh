#!/usr/bin/env bash
# Profile: TabbyAPI + Qwen2.5-14B-Instruct-exl2 @ 4_25
# Purpose: specs, architecture docs, RFC, planning
# Endpoint: http://localhost:33931/v1
set -euo pipefail

MODEL="bartowski/Qwen2.5-14B-Instruct-exl2"

echo "=== TabbyAPI: Writer 14B ==="
echo "Model: $MODEL"
echo "Quantization: 4_25 | ~10.1 GB VRAM @ 4k ctx"
echo "Endpoint: http://localhost:33931/v1"
echo ""
echo "Warning: on 12 GB VRAM it is recommended to keep ctx <= 8192"
echo ""

harbor tabbyapi model "$MODEL"
harbor up tabbyapi

echo ""
echo "Verification:"
echo "  curl http://localhost:33931/v1/models"
