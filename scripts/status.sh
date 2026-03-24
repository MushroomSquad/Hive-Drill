#!/usr/bin/env bash
# Статус всей системы: агенты, LLM, активные runs
set -uo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
section() { echo ""; echo -e "${CYAN}=== $* ===${NC}"; }
ok()      { echo -e "  ${GREEN}●${NC} $*"; }
warn()    { echo -e "  ${YELLOW}○${NC} $*"; }
off()     { echo -e "  ${RED}✗${NC} $*"; }

echo "╔════════════════════════════════════╗"
echo "║       AI Dev OS — Status          ║"
echo "╚════════════════════════════════════╝"

# ── Агенты ──────────────────────────────────────────────────────────
section "Agents"
command -v claude &>/dev/null && ok "Claude Code: $(claude --version 2>/dev/null | head -1)" || off "Claude Code (не найден)"
command -v codex  &>/dev/null && ok "Codex CLI: $(codex --version 2>/dev/null | head -1)"   || off "Codex CLI (не найден)"
command -v cursor &>/dev/null && ok "Cursor"                                                 || warn "Cursor (не в PATH)"
command -v just   &>/dev/null && ok "just: $(just --version 2>/dev/null)"                   || warn "just (не найден)"

# ── Локальный LLM ────────────────────────────────────────────────────
section "Local LLM"

# TabbyAPI
if curl -sf http://localhost:33931/v1/models &>/dev/null; then
  MODELS=$(curl -sf http://localhost:33931/v1/models | \
    python3 -c "import sys,json; d=json.load(sys.stdin); [print('    -', m['id']) for m in d.get('data',[])]" 2>/dev/null || echo "    (парсинг не удался)")
  ok "TabbyAPI: ONLINE (http://localhost:33931)"
  echo "$MODELS"
else
  off "TabbyAPI: OFFLINE"
fi

# llama.cpp
if curl -sf http://localhost:33831/v1/models &>/dev/null; then
  ok "llama.cpp: ONLINE (http://localhost:33831)"
else
  warn "llama.cpp: OFFLINE"
fi

# Harbor
if command -v harbor &>/dev/null; then
  ok "Harbor: $(harbor --version 2>/dev/null || echo 'найден')"
  echo ""
  harbor ps 2>/dev/null | head -10 | sed 's/^/  /' || true
fi

# ── GPU ──────────────────────────────────────────────────────────────
section "GPU"
if command -v nvidia-smi &>/dev/null; then
  nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu \
    --format=csv,noheader,nounits 2>/dev/null | \
    awk -F',' '{printf "  ● %s | VRAM: %s/%s MB | Load: %s%%\n", $1, $2, $3, $4}' || \
    ok "nvidia-smi доступен"
else
  warn "nvidia-smi не найден"
fi

# ── MCP ──────────────────────────────────────────────────────────────
section "MCP Servers"
if [ -f mcp/config.json ]; then
  python3 -c "
import json
with open('mcp/config.json') as f:
    cfg = json.load(f)
servers = cfg.get('mcpServers', {})
for name in servers:
    print(f'  ● {name}')
" 2>/dev/null || warn "mcp/config.json (не удалось прочитать)"
else
  warn "mcp/config.json не найден"
fi

# ── Активные runs ────────────────────────────────────────────────────
section "Active Runs"
if [ -d .ai/runs ]; then
  RUNS=$(find .ai/runs -maxdepth 1 -mindepth 1 -type d | sort -r | head -5)
  if [ -z "$RUNS" ]; then
    warn "Нет активных runs"
  else
    while IFS= read -r run; do
      TASK=$(basename "$run")
      FILES=$(ls "$run" 2>/dev/null | wc -l | tr -d ' ')
      # Статус из findings.md если есть
      STATUS=""
      if [ -f "$run/findings.md" ]; then
        grep -o "APPROVED\|REQUEST CHANGES\|BLOCKED\|NEEDS DISCUSSION" "$run/findings.md" 2>/dev/null | \
          head -1 | read -r STATUS 2>/dev/null || STATUS=""
      fi
      ok "$TASK ($FILES files)${STATUS:+ — $STATUS}"
    done <<< "$RUNS"
  fi
fi

# ── Git ──────────────────────────────────────────────────────────────
section "Git"
if git rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
  ok "Branch: $BRANCH"
  WT_COUNT=$(git worktree list | wc -l | tr -d ' ')
  [ "$WT_COUNT" -gt 1 ] && ok "Worktrees: $WT_COUNT" || warn "Worktrees: только main"
fi

echo ""
