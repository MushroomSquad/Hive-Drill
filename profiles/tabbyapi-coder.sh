#!/usr/bin/env bash
# Профиль: TabbyAPI + Qwen2.5-Coder-7B-Instruct-exl2 @ 6_5
# Назначение: основной daily-driver для написания кода
# Endpoint: http://localhost:33931/v1
set -euo pipefail

MODEL="bartowski/Qwen2.5-Coder-7B-Instruct-exl2"

echo "=== TabbyAPI: Coder 7B ==="
echo "Модель: $MODEL"
echo "Endpoint: http://localhost:33931/v1"
echo ""

harbor tabbyapi model "$MODEL"
harbor up tabbyapi

echo ""
echo "Проверка:"
echo "  curl http://localhost:33931/v1/models"
echo "  ./scripts/test-endpoint.sh tabbyapi"
