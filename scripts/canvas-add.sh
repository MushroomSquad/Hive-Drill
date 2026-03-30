#!/usr/bin/env bash
# canvas-add.sh — adds new task card to kanban board
# Usage:
#   ./scripts/canvas-add.sh <TASK-ID> [type] [priority] [title] [lane]
#
# Example:
#   ./scripts/canvas-add.sh FEAT-001 feature p1 "Add OAuth" backlog
set -euo pipefail

TASK_ID="${1:?Usage: $0 <TASK-ID> [type] [priority] [title] [lane]}"
TYPE="${2:-feature}"
PRIORITY="${3:-p1}"
TITLE="${4:-}"
LANE="${5:-backlog}"

case "$TYPE" in
    feature|bugfix|refactor|review|release|init)
        ;;
    *)
        echo "[canvas] Unknown type: $TYPE"
        exit 1
        ;;
esac

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

python3 - "$CANVAS" "$TASK_ID" "$TYPE" "$PRIORITY" "$TITLE" "$LANE" <<'PYEOF'
import json, sys, random, string

canvas_path, task_id, task_type, priority, title, lane = sys.argv[1:]

lane_x = {
    "backlog":     20,
    "planning":   300,
    "inprogress": 580,
    "review":     860,
    "done":      1140,
}

# Type icons
type_icon = {
    "feature":  "✨",
    "bugfix":   "🐛",
    "refactor": "♻️",
    "review":   "👁",
    "release":  "🚀",
    "init":     "🏗",
}

# Colors by priority
priority_color = {
    "p0": "1",  # red
    "p1": "3",  # yellow
    "p2": "4",  # blue
    "p3": "6",  # gray
}

with open(canvas_path, "r", encoding="utf-8") as f:
    data = json.load(f)

nodes = data.get("nodes", [])

# Check if card already exists
for node in nodes:
    if node.get("type") == "text" and task_id in node.get("text", ""):
        print(f"[canvas] Card {task_id} already exists, skipping.")
        sys.exit(0)

# Find occupied y positions in this column to avoid overlap
x_target = lane_x.get(lane, 20)
used_y = [
    n["y"] for n in nodes
    if n.get("type") == "text"
    and abs(n.get("x", 0) - x_target) < 50
    and n.get("y", 0) >= 440
]
next_y = max(used_y, default=420) + 100 if used_y else 440

# Generate unique id
node_id = "card-" + "".join(random.choices(string.ascii_lowercase + string.digits, k=8))

icon = type_icon.get(task_type, "📝")
color = priority_color.get(priority, "6")
title_text = f"\n{title}" if title else ""

card_text = f"**{task_id}**\n{priority} · {task_type}{title_text}"

new_node = {
    "id": node_id,
    "type": "text",
    "text": card_text,
    "x": x_target,
    "y": next_y,
    "width": 200,
    "height": 80 if not title else 100,
    "color": color,
}

nodes.append(new_node)
data["nodes"] = nodes

with open(canvas_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"[canvas] Added card {task_id} → {lane} (y={next_y})")
PYEOF
