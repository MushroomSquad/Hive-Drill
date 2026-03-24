#!/usr/bin/env bash
# Профиль: llama.cpp router mode — несколько GGUF-моделей одновременно
# Назначение: резервный стек, переключение по полю "model" в запросе
# Endpoint: http://localhost:33831/v1
set -euo pipefail

echo "=== llama.cpp: Router Mode ==="
echo "Endpoint: http://localhost:33831/v1"
echo ""

# Включить router mode — убрать фиксированный specifier модели
harbor config set llamacpp.model.specifier ""

# Аргументы сервера:
#   --models-dir  — папка с GGUF файлами
#   --models-max  — максимум одновременно загруженных моделей
#   --no-models-autoload — не грузить всё при старте
#   -c 8192       — размер контекста
#   -fa           — Flash Attention
#   -ngl all      — все слои на GPU
harbor llamacpp args \
  "--models-dir /app/data/models --models-max 2 --no-models-autoload -c 8192 -fa on -ngl all"

harbor up llamacpp

echo ""
echo "Загрузить кодер:"
echo "  curl -X POST http://localhost:33831/models/load \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"Qwen2.5-Coder-7B-Instruct-Q5_K_M\"}'"
echo ""
echo "Загрузить писателя:"
echo "  curl -X POST http://localhost:33831/models/load \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\": \"Qwen2.5-14B-Instruct-Q4_K_M\"}'"
echo ""
echo "Список доступных моделей:"
echo "  curl http://localhost:33831/v1/models"
