#!/usr/bin/env bash
# Упаковывает PR из артефактов run'а
# Использование: ./scripts/package-pr.sh <TASK-ID>
set -euo pipefail

TASK_ID="${1:?Usage: $0 <TASK-ID>}"
RUN_DIR=".ai/runs/$TASK_ID"

die() { echo "[ERR] $*"; exit 1; }
ok()  { echo "[OK]  $*"; }

[ -d "$RUN_DIR" ] || die "Run не найден: $RUN_DIR"

# Проверяем наличие артефактов
MISSING=()
for f in brief.md verification.md findings.md; do
  [ -f "$RUN_DIR/$f" ] || MISSING+=("$f")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "[WARN] Не найдены артефакты:"
  for f in "${MISSING[@]}"; do echo "  - $RUN_DIR/$f"; done
  echo "Продолжить? (y/N)"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

# Проверяем verdict в findings.md
if [ -f "$RUN_DIR/findings.md" ]; then
  if grep -q "APPROVED" "$RUN_DIR/findings.md"; then
    ok "findings.md: APPROVED"
  elif grep -q "BLOCKED\|REQUEST CHANGES" "$RUN_DIR/findings.md"; then
    die "findings.md: не APPROVED — нельзя создавать PR"
  else
    echo "[WARN] findings.md: verdict не найден — продолжить?"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
  fi
fi

# Генерируем pr-body.md если его нет
if [ ! -f "$RUN_DIR/pr-body.md" ]; then
  BRIEF_GOAL=$(grep -A3 "^## Goal" "$RUN_DIR/brief.md" 2>/dev/null | tail -3 | head -1 || echo "")
  DATE=$(date +%Y-%m-%d)

  cat > "$RUN_DIR/pr-body.md" << PR
# PR: $TASK_ID

## Summary
$([ -n "$BRIEF_GOAL" ] && echo "$BRIEF_GOAL" || echo "- TODO: заполни из brief.md")

## Changes
- TODO: опиши что изменилось

## Test plan
- [ ] ai-check.sh зелёный
- [ ] Acceptance criteria из brief.md выполнены
- [ ] Нет регрессий в смежных модулях

## Artifacts
- brief: \`.ai/runs/$TASK_ID/brief.md\`
- plan: \`.ai/runs/$TASK_ID/plan.md\`
- findings: \`.ai/runs/$TASK_ID/findings.md\`

---
_Generated: $DATE_
PR
  ok "Создан: $RUN_DIR/pr-body.md"
else
  ok "pr-body.md уже существует"
fi

# Создать PR через gh если доступен
if command -v gh &>/dev/null; then
  echo ""
  echo "Создать PR через GitHub CLI? (y/N)"
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    TITLE=$(head -1 "$RUN_DIR/brief.md" | sed 's/^# Brief: //')
    gh pr create \
      --title "$TITLE" \
      --body "$(cat "$RUN_DIR/pr-body.md")" \
      --draft
    ok "PR создан (draft)"
  fi
fi

echo ""
echo "Артефакты готовы: $RUN_DIR/"
ls -la "$RUN_DIR/"
