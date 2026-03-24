#!/usr/bin/env bash
# Управление git worktrees для параллельной агентной работы
# Использование:
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
    [ -n "$TASK_ID" ] || die "TASK-ID обязателен для create"

    # Проверяем что мы в git репо
    git rev-parse --is-inside-work-tree &>/dev/null || die "Не git репозиторий"

    # Базовая ветка
    BASE_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")

    mkdir -p "$WT_BASE"

    # Создаём worktree для каждого агента
    for ag in claude codex; do
      WT_NAME="${TASK_ID}-${ag}"
      WT_PATH="$WT_BASE/$WT_NAME"
      BRANCH_NAME="agent/${TASK_ID}-${ag}"

      if [ -d "$WT_PATH" ]; then
        info "Worktree уже существует: $WT_PATH"
        continue
      fi

      # Создаём ветку и worktree
      if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        git worktree add "$WT_PATH" "$BRANCH_NAME"
      else
        git worktree add -b "$BRANCH_NAME" "$WT_PATH" "$BASE_BRANCH"
      fi

      ok "Worktree: $WT_PATH (branch: $BRANCH_NAME)"
    done

    echo ""
    echo "Агенты работают в изолированных деревьях:"
    echo "  Claude: cd $WT_BASE/${TASK_ID}-claude && claude ..."
    echo "  Codex:  cd $WT_BASE/${TASK_ID}-codex  && codex ..."
    ;;

  list)
    echo "=== Git Worktrees ==="
    git worktree list
    ;;

  clean)
    [ -n "$TASK_ID" ] || die "TASK-ID обязателен для clean"

    for ag in claude codex review; do
      WT_PATH="$WT_BASE/${TASK_ID}-${ag}"
      BRANCH="agent/${TASK_ID}-${ag}"

      if [ -d "$WT_PATH" ]; then
        info "Удаляю worktree: $WT_PATH"
        git worktree remove "$WT_PATH" --force 2>/dev/null || rm -rf "$WT_PATH"
        git branch -d "$BRANCH" 2>/dev/null || true
        ok "Удалён: $WT_PATH"
      fi
    done
    ;;

  clean-all)
    echo "Удалить ВСЕ agent/* worktrees? (y/N)"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0

    git worktree list --porcelain | grep "worktree " | awk '{print $2}' | while read -r wt; do
      if [[ "$wt" == *"/wt/"* ]]; then
        info "Удаляю: $wt"
        git worktree remove "$wt" --force 2>/dev/null || true
      fi
    done

    # Удалить agent/* ветки
    git branch | grep "agent/" | while read -r branch; do
      git branch -d "$branch" 2>/dev/null || true
    done

    ok "Все agent worktrees удалены"
    ;;

  *)
    echo "Неизвестная команда: $CMD"
    echo "Команды: create, list, clean, clean-all"
    exit 1
    ;;
esac
