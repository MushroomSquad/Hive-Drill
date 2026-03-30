#!/usr/bin/env bash
# canvas-move.sh — moves task card on kanban board
# Usage:
#   ./scripts/canvas-move.sh <TASK-ID> <lane>
#   lane: backlog | planning | inprogress | review | done
set -euo pipefail

TASK_ID="${1:?Usage: $0 <TASK-ID> <lane>}"
LANE="${2:?Usage: $0 <TASK-ID> <lane>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Project context ──────────────────────────────────────────────────────────
source "${SCRIPT_DIR}/project.sh" 2>/dev/null || true
ACTIVE_PROJECT="${ACTIVE_PROJECT:-}"
roi_project_context 2>/dev/null || true

if [[ -n "${ACTIVE_PROJECT}" ]]; then
    CANVAS="${PROJECT_ROOT}/vault/projects/${ACTIVE_PROJECT}/canvas/project-board.canvas"
else
    CANVAS="${PROJECT_ROOT}/vault/canvas/project-board.canvas"
fi

[[ -f "$CANVAS" ]] || { echo "[canvas] Canvas not found: $CANVAS"; exit 0; }

# X-coordinates of cards within each column
# Columns: backlog=0, planning=280, inprogress=560, review=840, done=1120
# Cards with +20 offset from column edge
python3 - "$CANVAS" "$TASK_ID" "$LANE" <<'PYEOF'
import json, sys, re

canvas_path, task_id, lane = sys.argv[1], sys.argv[2], sys.argv[3]

lane_x = {
    "backlog":     20,
    "planning":   300,
    "inprogress": 580,
    "review":     860,
    "done":      1140,
}

if lane not in lane_x:
    print(f"[canvas] Unknown lane: {lane}. Valid: {list(lane_x.keys())}")
    sys.exit(0)

target_x = lane_x[lane]

with open(canvas_path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Find card by task_id in node text
moved = False
for node in data.get("nodes", []):
    if node.get("type") == "text" and task_id in node.get("text", ""):
        old_x = node["x"]
        node["x"] = target_x
        moved = True
        print(f"[canvas] {task_id}: x {old_x} → {target_x} ({lane})")
        break

if not moved:
    print(f"[canvas] Card {task_id} not found in canvas, skipping.")
    sys.exit(0)

with open(canvas_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

PYEOF
