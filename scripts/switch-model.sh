#!/usr/bin/env bash
# Быстрое переключение между профилями
# Использование: ./scripts/switch-model.sh [coder|writer|llamacpp|airllm]
set -euo pipefail

PROFILE="${1:-}"

usage() {
  echo "Использование: $0 <профиль>"
  echo ""
  echo "Профили:"
  echo "  coder     Qwen2.5-Coder-7B-Instruct-exl2 @ 6_5  (код, daily)"
  echo "  writer    Qwen2.5-14B-Instruct-exl2 @ 4_25      (ТЗ, доки)"
  echo "  llamacpp  llama.cpp router (GGUF, резервный)"
  echo "  airllm    AirLLM тяжёлый режим (32B+)"
  echo ""
  echo "Текущий статус:"
  harbor ps 2>/dev/null || echo "(harbor не запущен)"
}

if [ -z "$PROFILE" ]; then
  usage
  exit 0
fi

case "$PROFILE" in
  coder)
    echo "Переключаюсь на: Coder 7B (TabbyAPI)..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/tabbyapi-coder.sh"
    ;;
  writer)
    echo "Переключаюсь на: Writer 14B (TabbyAPI)..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/tabbyapi-writer.sh"
    ;;
  llamacpp)
    echo "Переключаюсь на: llama.cpp router..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/llamacpp-router.sh"
    ;;
  airllm)
    echo "Переключаюсь на: AirLLM (heavy)..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/airllm-heavy.sh"
    ;;
  *)
    echo "Неизвестный профиль: $PROFILE"
    usage
    exit 1
    ;;
esac
