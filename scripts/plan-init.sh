#!/usr/bin/env bash
# Инициализирует директорию артефактов для нового прогона pipeline
# Использование: ./scripts/plan-init.sh <TASK-ID> [blueprint]
set -euo pipefail

TASK_ID="${1:?Usage: $0 <TASK-ID> [blueprint]}"
BLUEPRINT="${2:-feature}"
RUN_DIR=".ai/runs/$TASK_ID"
DATE=$(date +%Y-%m-%d)

if [ -d "$RUN_DIR" ]; then
  echo "Run уже существует: $RUN_DIR"
  echo "Продолжить? (y/N)"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

mkdir -p "$RUN_DIR"

echo "Создаю: $RUN_DIR"

# brief.md — шаблон для заполнения
cat > "$RUN_DIR/brief.md" << BRIEF
# Brief: $TASK_ID

_Создан: $DATE | Blueprint: $BLUEPRINT

## Goal
<!-- Что нужно сделать и зачем -->

## Scope
### In scope
-

### Out of scope
-

## Constraints
<!-- Что нельзя трогать, дедлайн, зависимости -->

## Affected modules
-

## Risks
-

## Acceptance criteria
- [ ]
BRIEF

# tasks.yaml — шаблон
cat > "$RUN_DIR/tasks.yaml" << TASKS
run_id: $TASK_ID
blueprint: ${BLUEPRINT}-v1
created: $DATE
status: draft

tasks: []
# Заполняется на Stage 2 (task slicing)
# Шаблон:
#   - id: T1
#     title: <описание>
#     owner: codex        # codex | claude | cursor | human
#     priority: p1        # p0 | p1 | p2 | p3
#     model_lane: cloud   # cloud | local
#     inputs: []
#     outputs: []
#     depends_on: []
TASKS

echo "✓ $RUN_DIR/brief.md"
echo "✓ $RUN_DIR/tasks.yaml"
echo ""
echo "Следующие шаги:"
echo "1. Заполни $RUN_DIR/brief.md"
echo "2. Запусти blueprint: just bp $BLUEPRINT $TASK_ID"
echo "   или вручную: claude 'Read .ai/blueprints/${BLUEPRINT}-v1.md and .ai/runs/$TASK_ID/brief.md'"
