#!/usr/bin/env bash
# Initializes artifacts directory for new pipeline run
# Usage: ./scripts/plan-init.sh <TASK-ID> [blueprint]
set -euo pipefail

PROJECT_ROOT="$(pwd)"
AI_RUNS_DIR="${PROJECT_ROOT}/.ai/runs"
TASK_ID="${1:?Usage: $0 <TASK-ID> [blueprint]}"
BLUEPRINT="${2:-feature}"
RUN_DIR="${AI_RUNS_DIR}/${TASK_ID}"
DATE=$(date +%Y-%m-%d)

if [ -d "$RUN_DIR" ]; then
  echo "Run already exists: $RUN_DIR"
  echo "Continue? (y/N)"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

mkdir -p "$RUN_DIR"

echo "Creating: $RUN_DIR"

# brief.md — template to fill in
cat > "$RUN_DIR/brief.md" << BRIEF
# Brief: $TASK_ID

_Created: $DATE | Blueprint: $BLUEPRINT

## Goal
<!-- What needs to be done and why -->

## Scope
### In scope
-

### Out of scope
-

## Constraints
<!-- What can't be changed, deadline, dependencies -->

## Affected modules
-

## Risks
-

## Acceptance criteria
- [ ]
BRIEF

# tasks.yaml — template
cat > "$RUN_DIR/tasks.yaml" << TASKS
run_id: $TASK_ID
blueprint: ${BLUEPRINT}-v1
created: $DATE
status: draft

tasks: []
# Filled at Stage 2 (task slicing)
# Template:
#   - id: T1
#     title: <description>
#     owner: codex        # codex | claude | cursor | human
#     priority: p1        # p0 | p1 | p2 | p3
#     model_lane: cloud   # cloud | local
#     inputs: []
#     outputs: []
#     depends_on: []
TASKS

# decisions.md — architecture decisions log
cat > "$RUN_DIR/decisions.md" << DECISIONS
---
task_id: $TASK_ID
created: $DATE
---

# Decisions: $TASK_ID

<!-- Add entry each time a non-trivial decision is made. -->

## Decision log

### DEC-1: [Decision name]

**Date:** $DATE
**Status:** accepted

**Context**
Why was this decision needed?

**Options considered**
- Option A —
- Option B —

**Decision**
Chose [Option X], because...

**Consequences**
- Positive:
- Negative / trade-offs:
- Follow-up tasks:
DECISIONS

echo "✓ $RUN_DIR/brief.md"
echo "✓ $RUN_DIR/tasks.yaml"
echo "✓ $RUN_DIR/decisions.md"
echo ""
echo "Next steps:"
echo "1. Fill in $RUN_DIR/brief.md"
echo "2. Run blueprint: just bp $BLUEPRINT $TASK_ID"
echo "   or manually: claude 'Read .ai/blueprints/${BLUEPRINT}-v1.md and .ai/runs/$TASK_ID/brief.md'"
