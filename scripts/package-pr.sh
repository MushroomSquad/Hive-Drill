#!/usr/bin/env bash
# Packages PR from run artifacts
# Usage: ./scripts/package-pr.sh <TASK-ID>
set -euo pipefail

TASK_ID="${1:?Usage: $0 <TASK-ID>}"
RUN_DIR=".ai/runs/$TASK_ID"

die() { echo "[ERR] $*"; exit 1; }
ok()  { echo "[OK]  $*"; }

[ -d "$RUN_DIR" ] || die "Run not found: $RUN_DIR"

# Check for artifacts
MISSING=()
for f in brief.md verification.md findings.md; do
  [ -f "$RUN_DIR/$f" ] || MISSING+=("$f")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "[WARN] Artifacts not found:"
  for f in "${MISSING[@]}"; do echo "  - $RUN_DIR/$f"; done
  echo "Continue? (y/N)"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

# Check verdict in findings.md
if [ -f "$RUN_DIR/findings.md" ]; then
  if grep -q "APPROVED" "$RUN_DIR/findings.md"; then
    ok "findings.md: APPROVED"
  elif grep -q "BLOCKED\|REQUEST CHANGES" "$RUN_DIR/findings.md"; then
    die "findings.md: not APPROVED — cannot create PR"
  else
    echo "[WARN] findings.md: verdict not found — continue?"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
  fi
fi

# Generate pr-body.md if not exists
if [ ! -f "$RUN_DIR/pr-body.md" ]; then
  BRIEF_GOAL=$(grep -A3 "^## Goal" "$RUN_DIR/brief.md" 2>/dev/null | tail -3 | head -1 || echo "")
  DATE=$(date +%Y-%m-%d)

  cat > "$RUN_DIR/pr-body.md" << PR
# PR: $TASK_ID

## Summary
$([ -n "$BRIEF_GOAL" ] && echo "$BRIEF_GOAL" || echo "- TODO: fill from brief.md")

## Changes
- TODO: describe what changed

## Test plan
- [ ] ai-check.sh green
- [ ] Acceptance criteria from brief.md met
- [ ] No regressions in related modules

## Artifacts
- brief: \`.ai/runs/$TASK_ID/brief.md\`
- plan: \`.ai/runs/$TASK_ID/plan.md\`
- findings: \`.ai/runs/$TASK_ID/findings.md\`

---
_Generated: $DATE
PR
  ok "Created: $RUN_DIR/pr-body.md"
else
  ok "pr-body.md already exists"
fi

# Create PR via gh if available
if command -v gh &>/dev/null; then
  echo ""
  echo "Create PR via GitHub CLI? (y/N)"
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    TITLE=$(head -1 "$RUN_DIR/brief.md" | sed 's/^# Brief: //')
    gh pr create \
      --title "$TITLE" \
      --body "$(cat "$RUN_DIR/pr-body.md")" \
      --draft
    ok "PR created (draft)"
  fi
fi

echo ""
echo "Artifacts ready: $RUN_DIR/"
ls -la "$RUN_DIR/"
