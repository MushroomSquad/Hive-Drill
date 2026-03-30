#!/usr/bin/env bash
# Quick switch between profiles
# Usage: ./scripts/switch-model.sh [coder|writer|llamacpp|airllm]
set -euo pipefail

PROFILE="${1:-}"

usage() {
  echo "Usage: $0 <profile>"
  echo ""
  echo "Profiles:"
  echo "  coder     Qwen2.5-Coder-7B-Instruct-exl2 @ 6_5  (code, daily)"
  echo "  writer    Qwen2.5-14B-Instruct-exl2 @ 4_25      (specs, docs)"
  echo "  llamacpp  llama.cpp router (GGUF, backup)"
  echo "  airllm    AirLLM heavy mode (32B+)"
  echo ""
  echo "Current status:"
  harbor ps 2>/dev/null || echo "(harbor not running)"
}

if [ -z "$PROFILE" ]; then
  usage
  exit 0
fi

case "$PROFILE" in
  coder)
    echo "Switching to: Coder 7B (TabbyAPI)..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/tabbyapi-coder.sh"
    ;;
  writer)
    echo "Switching to: Writer 14B (TabbyAPI)..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/tabbyapi-writer.sh"
    ;;
  llamacpp)
    echo "Switching to: llama.cpp router..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/llamacpp-router.sh"
    ;;
  airllm)
    echo "Switching to: AirLLM (heavy)..."
    harbor down tabbyapi 2>/dev/null || true
    exec "$(dirname "$0")/../profiles/airllm-heavy.sh"
    ;;
  *)
    echo "Unknown profile: $PROFILE"
    usage
    exit 1
    ;;
esac
