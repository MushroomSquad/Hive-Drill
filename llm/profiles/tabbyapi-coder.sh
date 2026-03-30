#!/usr/bin/env bash
# Profile: TabbyAPI + Qwen2.5-Coder-7B-Instruct-exl2 @ 6_5
# Purpose: main daily driver for code writing
# Endpoint: http://localhost:33931/v1
set -euo pipefail

MODEL="bartowski/Qwen2.5-Coder-7B-Instruct-exl2"

echo "=== TabbyAPI: Coder 7B ==="
echo "Model: $MODEL"
echo "Endpoint: http://localhost:33931/v1"
echo ""

harbor tabbyapi model "$MODEL"
harbor up tabbyapi

echo ""
echo "Verification:"
echo "  curl http://localhost:33931/v1/models"
echo "  ./scripts/test-endpoint.sh tabbyapi"
