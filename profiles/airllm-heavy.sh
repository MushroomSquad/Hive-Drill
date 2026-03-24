#!/usr/bin/env bash
# Профиль: AirLLM — тяжёлые модели, которые не влезают в VRAM
# Назначение: запуск Qwen2.5-Coder-32B через layer-wise inference
# Endpoint: задаётся Harbor-ом
set -euo pipefail

MODEL="${AIRLLM_MODEL:-Qwen/Qwen2.5-Coder-32B-Instruct}"
CTX="${AIRLLM_CTX:-8192}"
COMPRESSION="${AIRLLM_COMPRESSION:-4bit}"

echo "=== AirLLM: Heavy Mode ==="
echo "Модель:      $MODEL"
echo "Контекст:    $CTX"
echo "Компрессия:  $COMPRESSION"
echo ""
echo "Внимание: первый запуск долгий — модель раскладывается по слоям на диск."
echo "Убедись, что есть 60–100 GB свободного места."
echo ""

harbor airllm model "$MODEL"
harbor airllm ctx "$CTX"
harbor airllm compression "$COMPRESSION"
harbor up airllm

echo ""
AIRLLM_URL=$(harbor url airllm 2>/dev/null || echo "смотри harbor url airllm")
echo "Endpoint: $AIRLLM_URL/v1"
echo ""
echo "Проверка:"
echo "  curl $AIRLLM_URL/v1/models"
