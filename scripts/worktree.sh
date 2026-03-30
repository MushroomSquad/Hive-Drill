#!/usr/bin/env bash
# Manages git worktrees for parallel agent work
# Usage:
#   ./scripts/worktree.sh create <TASK-ID> [agent]
#   ./scripts/worktree.sh list
#   ./scripts/worktree.sh clean <TASK-ID>
#   ./scripts/worktree.sh clean-all
set -euo pipefail

CMD="${1:?Usage: $0 <create|list|clean|clean-all> [TASK-ID] [agent]}"
TASK_ID="${2:-}"
AGENT="${3:-codex}"
WT_BASE="wt"

die() { echo "[ERR] $*"; exit 1; }
ok()  { echo "[OK]  $*"; }
info(){ echo "[--]  $*"; }

case "$CMD" in
  create)
    [ -n "$TASK_ID" ] || die "TASK-ID required for create"

    # Check we're in git repo
    git rev-parse --is-inside-work-tree &>/dev/null || die "Not a git repository"

    # Base branch
    BASE_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")

    mkdir -p "$WT_BASE"

    # Create worktree for each agent
    for ag in claude codex; do
      WT_NAME="${TASK_ID}-${ag}"
      WT_PATH="$WT_BASE/$WT_NAME"
      BRANCH_NAME="agent/${TASK_ID}-${ag}"

      if [ -d "$WT_PATH" ]; then
        info "Worktree already exists: $WT_PATH"
        continue
      fi

      # Create branch and worktree
      if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        git worktree add "$WT_PATH" "$BRANCH_NAME"
      else
        git worktree add -b "$BRANCH_NAME" "$WT_PATH" "$BASE_BRANCH"
      fi

      ok "Worktree: $WT_PATH (branch: $BRANCH_NAME)"
    done

    echo ""
    echo "Agents work in isolated trees:"
    echo "  Claude: cd $WT_BASE/${TASK_ID}-claude && claude ..."
    echo "  Codex:  cd $WT_BASE/${TASK_ID}-codex  && codex ..."
    ;;

  list)
    echo "=== Git Worktrees ==="
    git worktree list
    ;;

  clean)
    [ -n "$TASK_ID" ] || die "TASK-ID required for clean"

    for ag in claude codex review; do
      WT_PATH="$WT_BASE/${TASK_ID}-${ag}"
      BRANCH="agent/${TASK_ID}-${ag}"

      if [ -d "$WT_PATH" ]; then
        info "Removing worktree: $WT_PATH"
        git worktree remove "$WT_PATH" --force 2>/dev/null || rm -rf "$WT_PATH"
        git branch -d "$BRANCH" 2>/dev/null || true
        ok "Removed: $WT_PATH"
      fi
    done
    ;;

  clean-all)
    echo "Delete ALL agent/* worktrees? (y/N)"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0

    git worktree list --porcelain | grep "worktree " | awk '{print $2}' | while read -r wt; do
      if [[ "$wt" == *"/wt/"* ]]; then
        info "Removing: $wt"
        git worktree remove "$wt" --force 2>/dev/null || true
      fi
    done

    # Delete agent/* branches
    git branch | grep "agent/" | while read -r branch; do
      git branch -d "$branch" 2>/dev/null || true
    done

    ok "All agent worktrees removed"
    ;;

  *)
    echo "Unknown command: $CMD"
    echo "Commands: create, list, clean, clean-all"
    exit 1
    ;;
esac
