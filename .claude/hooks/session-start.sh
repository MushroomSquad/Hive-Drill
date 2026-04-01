#!/usr/bin/env bash
# session-start.sh — prints project context at the start of every Claude Code session.
# Runs via SessionStart hook in .claude/settings.json.
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="${REPO_ROOT}/.ai/state/current"
RUNS_DIR="${REPO_ROOT}/.ai/runs"
ROUTING="${REPO_ROOT}/.ai/routing/policy.yaml"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║           HIVE DRILL — SESSION START      ║"
echo "╚══════════════════════════════════════════╝"

# Active project
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_PROJECT="$(cat "$STATE_FILE")"
    echo "  Project : $CURRENT_PROJECT"
else
    echo "  Project : (none set — run: ./scripts/project.sh switch <name>)"
fi

# Current branch
BRANCH="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo "unknown")"
echo "  Branch  : $BRANCH"

# Recent runs
echo ""
echo "  Recent runs:"
if [[ -d "$RUNS_DIR" ]]; then
    # List top-5 runs sorted by modification time
    RECENT=$(find "$RUNS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %f\n" 2>/dev/null \
        | sort -rn | head -5 | awk '{print $2}')
    if [[ -n "$RECENT" ]]; then
        while IFS= read -r run; do
            # Show status if checkpoint exists
            CHECKPOINT="${RUNS_DIR}/${run}/checkpoint.yml"
            if [[ -f "$CHECKPOINT" ]]; then
                STATUS=$(grep -m1 "^status:" "$CHECKPOINT" 2>/dev/null | awk '{print $2}' || echo "?")
            else
                STATUS="no-checkpoint"
            fi
            echo "    • $run  [$STATUS]"
        done <<< "$RECENT"
    else
        echo "    (no runs yet)"
    fi
else
    echo "    (runs directory not found)"
fi

# Routing reminder
echo ""
echo "  Model routing (policy.yaml):"
echo "    P0 → claude-opus  (planner) + codex cloud-high (executor)"
echo "    P1 → claude-sonnet (planner) + codex cloud-medium (executor)"
echo "    P2 → codex local-fast"
echo "    P3 → codex local-cheap"

# Pending worktrees
echo ""
echo "  Active worktrees:"
WT=$(git -C "$REPO_ROOT" worktree list 2>/dev/null | tail -n +2 | awk '{print $1}' || true)
if [[ -n "$WT" ]]; then
    while IFS= read -r path; do
        NAME=$(basename "$path")
        echo "    • $NAME"
    done <<< "$WT"
else
    echo "    (none)"
fi

echo ""
echo "  Reminders:"
echo "    • Read .ai/base/BASE.md before any non-trivial task"
echo "    • Run ./scripts/ai-check.sh before marking task done"
echo "    • All artifacts → .ai/runs/<TASK-ID>/"
echo ""
