#!/usr/bin/env bash
# Профиль: TabbyAPI + Qwen2.5-14B-Instruct-exl2 @ 4_25
# Назначение: ТЗ, архитектурные документы, RFC, планирование
# Endpoint: http://localhost:33931/v1
set -euo pipefail

MODEL="bartowski/Qwen2.5-14B-Instruct-exl2"

echo "=== TabbyAPI: Writer 14B ==="
echo "Модель: $MODEL"
echo "Квант: 4_25 | ~10.1 GB VRAM @ 4k ctx"
echo "Endpoint: http://localhost:33931/v1"
echo ""
echo "Внимание: на 12 GB VRAM рекомендуется ctx <= 8192"
echo ""

harbor tabbyapi model "$MODEL"
harbor up tabbyapi

echo ""
echo "Проверка:"
echo "  curl http://localhost:33931/v1/models"
