#!/usr/bin/env bash
# project.sh — Manage projects for Hive Drill
#
# Usage (CLI):
#   ./scripts/project.sh add <name> <path> [description]
#   ./scripts/project.sh switch <name>
#   ./scripts/project.sh list
#   ./scripts/project.sh remove <name>
#   ./scripts/project.sh current
#   ./scripts/project.sh info [name]
#
# Sourced by other scripts to get roi_project_context():
#   source ./scripts/project.sh
#   roi_project_context  # sets ACTIVE_PROJECT, PROJECT_PATH

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

_roi_script_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }
_roi_root()       { cd "$(_roi_script_dir)/.." && pwd; }

# ─── State helpers ────────────────────────────────────────────────────────────

_state_dir() { echo "$(_roi_root)/.ai/state"; }
_projects_dir() { echo "$(_roi_root)/.ai/projects"; }
_current_file() { echo "$(_state_dir)/current"; }

_read_current() {
    local f
    f="$(_current_file)"
    [[ -f "$f" ]] && cat "$f" | tr -d '[:space:]' || echo ""
}

_project_cfg() {
    local name="$1"
    echo "$(_projects_dir)/${name}.json"
}

_project_exists() {
    local name="$1"
    [[ -f "$(_project_cfg "$name")" ]]
}

_list_project_names() {
    local dir
    dir="$(_projects_dir)"
    [[ -d "$dir" ]] || return 0
    find "$dir" -maxdepth 1 -name '*.json' | sed 's|.*/||; s|\.json$||' | sort
}

# ─── Public: load project context (for sourced use) ───────────────────────────
# Sets ACTIVE_PROJECT and PROJECT_PATH in the calling script's scope.
# Safe to call even when no project is active — sets both to empty string.

roi_project_context() {
    ACTIVE_PROJECT=""
    PROJECT_PATH=""
    local current
    current="$(_read_current)"
    [[ -z "$current" ]] && return 0
    local cfg
    cfg="$(_project_cfg "$current")"
    if [[ ! -f "$cfg" ]]; then
        # State file points to deleted project — ignore silently
        return 0
    fi
    ACTIVE_PROJECT="$current"
    PROJECT_PATH="$(python3 -c "
import json, sys
with open('$cfg') as f:
    d = json.load(f)
print(d.get('path', ''))
" 2>/dev/null || echo "")"
}

# ─── Canvas bootstrap for new project vault ───────────────────────────────────
_bootstrap_project_vault() {
    local name="$1"
    local roi_root
    roi_root="$(_roi_root)"
    local vault="${roi_root}/vault/projects/${name}"

    mkdir -p "${vault}/00-inbox" "${vault}/01-active" "${vault}/02-done" "${vault}/canvas" "${vault}/templates"

    local canvas="${vault}/canvas/project-board.canvas"
    if [[ ! -f "$canvas" ]]; then
        python3 - "$canvas" "$name" <<'PYEOF'
import json, sys

canvas_path, project_name = sys.argv[1], sys.argv[2]

data = {
  "nodes": [
    {"id": "lane-backlog",     "type": "text", "text": "## Backlog",      "x": 0,    "y": 320, "width": 240, "height": 60, "color": "6"},
    {"id": "lane-planning",    "type": "text", "text": "## Planning",     "x": 280,  "y": 320, "width": 240, "height": 60, "color": "4"},
    {"id": "lane-inprogress",  "type": "text", "text": "## In Progress",  "x": 560,  "y": 320, "width": 240, "height": 60, "color": "3"},
    {"id": "lane-review",      "type": "text", "text": "## Review",       "x": 840,  "y": 320, "width": 240, "height": 60, "color": "1"},
    {"id": "lane-done",        "type": "text", "text": "## Done",         "x": 1120, "y": 320, "width": 240, "height": 60, "color": "5"},
    {"id": "title",            "type": "text", "text": f"# {project_name}", "x": 0,  "y": 200, "width": 1360, "height": 60},
  ],
  "edges": []
}

with open(canvas_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"[canvas] Canvas created for project: {project_name}")
PYEOF
    fi
}

# ─── CLI commands ─────────────────────────────────────────────────────────────

cmd_add() {
    local name="${1:-}"
    local path="${2:-}"
    local description="${3:-}"

    [[ -z "$name" ]] && { echo -e "${RED}Usage:${RESET} project add <name> <path> [description]"; exit 1; }
    [[ -z "$path" ]] && { echo -e "${RED}Usage:${RESET} project add <name> <path> [description]"; exit 1; }

    # Validate name
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error:${RESET} Project name must be alphanumeric (hyphens/underscores allowed)"
        exit 1
    fi

    # Resolve absolute path
    if [[ "$path" = /* ]]; then
        abs_path="$path"
    else
        abs_path="$(cd "$path" 2>/dev/null && pwd || echo "$path")"
    fi

    if [[ ! -d "$abs_path" ]]; then
        echo -e "${YELLOW}Warning:${RESET} Path does not exist yet: $abs_path"
        echo "  You can still register it and the directory will be used when it appears."
    fi

    mkdir -p "$(_projects_dir)"

    local cfg
    cfg="$(_project_cfg "$name")"

    if [[ -f "$cfg" ]]; then
        echo -e "${YELLOW}Project '$name' already registered. Updating...${RESET}"
    fi

    python3 - "$cfg" "$name" "$abs_path" "$description" <<'PYEOF'
import json, sys
from datetime import date

cfg_path, name, path, description = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

data = {"name": name, "path": path, "description": description, "added": str(date.today())}
with open(cfg_path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    _bootstrap_project_vault "$name"

    echo -e "${GREEN}✓${RESET} Project registered: ${BOLD}$name${RESET}"
    echo -e "  Path:    $abs_path"
    [[ -n "$description" ]] && echo -e "  Desc:    $description"
    echo ""
    echo -e "  Switch to it: ${CYAN}just project switch $name${RESET}"
}

cmd_switch() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo -e "${RED}Usage:${RESET} project switch <name>"; exit 1; }

    if ! _project_exists "$name"; then
        echo -e "${RED}Error:${RESET} Project '$name' not found."
        echo ""
        echo "Registered projects:"
        cmd_list
        exit 1
    fi

    mkdir -p "$(_state_dir)"
    echo -n "$name" > "$(_current_file)"
    _bootstrap_project_vault "$name"

    local cfg
    cfg="$(_project_cfg "$name")"
    local path
    path="$(python3 -c "import json; print(json.load(open('$cfg')).get('path',''))" 2>/dev/null || echo "")"

    echo -e "${GREEN}✓${RESET} Active project: ${BOLD}$name${RESET}"
    [[ -n "$path" ]] && echo -e "  Path: $path"
    echo -e "  Vault: vault/projects/$name/"
    echo -e "  Runs:  .ai/runs/$name/"
}

cmd_list() {
    local current
    current="$(_read_current)"
    local names
    names="$(_list_project_names)"

    if [[ -z "$names" ]]; then
        echo -e "  ${YELLOW}No projects registered.${RESET}"
        echo -e "  Add one: ${CYAN}just project add <name> <path>${RESET}"
        return 0
    fi

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local cfg marker path desc
        cfg="$(_project_cfg "$name")"
        marker="  "
        [[ "$name" == "$current" ]] && marker="${GREEN}▶ ${RESET}"
        path="$(python3 -c "import json; print(json.load(open('$cfg')).get('path',''))" 2>/dev/null || echo "?")"
        desc="$(python3 -c "import json; print(json.load(open('$cfg')).get('description',''))" 2>/dev/null || echo "")"
        echo -e "${marker}${BOLD}${name}${RESET}  ${path}${desc:+  — $desc}"
    done <<< "$names"
}

cmd_current() {
    local current
    current="$(_read_current)"
    if [[ -z "$current" ]]; then
        echo -e "  ${YELLOW}No active project.${RESET} Using hive-drill/ root paths (legacy mode)."
        echo -e "  Switch: ${CYAN}just project switch <name>${RESET}"
    else
        echo -e "  Active: ${BOLD}$current${RESET}"
        local cfg
        cfg="$(_project_cfg "$current")"
        if [[ -f "$cfg" ]]; then
            python3 -c "
import json
d = json.load(open('$cfg'))
print(f\"  Path:   {d.get('path', '(not set)')}\")
print(f\"  Vault:  vault/projects/$current/\")
print(f\"  Runs:   .ai/runs/$current/\")
desc = d.get('description','')
if desc: print(f'  Desc:   {desc}')
" 2>/dev/null || true
        fi
    fi
}

cmd_remove() {
    local name="${1:-}"
    [[ -z "$name" ]] && { echo -e "${RED}Usage:${RESET} project remove <name>"; exit 1; }

    if ! _project_exists "$name"; then
        echo -e "${RED}Error:${RESET} Project '$name' not found."
        exit 1
    fi

    rm -f "$(_project_cfg "$name")"

    # If it was active, clear state
    local current
    current="$(_read_current)"
    if [[ "$current" == "$name" ]]; then
        echo -n "" > "$(_current_file)"
        echo -e "${YELLOW}⚠${RESET} Active project cleared."
    fi

    echo -e "${GREEN}✓${RESET} Project '${name}' removed from registry."
    echo -e "  ${YELLOW}Note:${RESET} vault/projects/$name/ and .ai/runs/$name/ are kept (delete manually if needed)."
}

cmd_info() {
    local name="${1:-$(_read_current)}"
    [[ -z "$name" ]] && { echo -e "${YELLOW}No active project and no name given.${RESET}"; exit 0; }

    if ! _project_exists "$name"; then
        echo -e "${RED}Error:${RESET} Project '$name' not found."
        exit 1
    fi

    local cfg
    cfg="$(_project_cfg "$name")"
    local current
    current="$(_read_current)"

    echo ""
    echo -e "${BOLD}Project: $name${RESET}$( [[ "$name" == "$current" ]] && echo -e " ${GREEN}(active)${RESET}" )"
    python3 -c "
import json
d = json.load(open('$cfg'))
print(f\"  Path:        {d.get('path', '(not set)')}\")
desc = d.get('description','')
if desc: print(f'  Description: {desc}')
print(f\"  Added:       {d.get('added','?')}\")
" 2>/dev/null || true

    local roi_root
    roi_root="$(_roi_root)"
    echo ""
    # Count briefs and runs
    local inbox="${roi_root}/vault/projects/${name}/00-inbox"
    local active="${roi_root}/vault/projects/${name}/01-active"
    local done="${roi_root}/vault/projects/${name}/02-done"
    local runs="${roi_root}/.ai/runs/${name}"
    [[ -d "$inbox" ]] && echo -e "  Inbox:  $(find "$inbox" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') briefs"
    [[ -d "$active" ]] && echo -e "  Active: $(find "$active" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') tasks"
    [[ -d "$done" ]] && echo -e "  Done:   $(find "$done" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') tasks"
    [[ -d "$runs" ]] && echo -e "  Runs:   $(find "$runs" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') runs"
    echo ""
}

# ─── Entry point (only when run as CLI, not sourced) ──────────────────────────

_main() {
    local cmd="${1:-}"
    [[ -z "$cmd" ]] && { echo -e "Usage: project <add|switch|list|remove|current|info>"; exit 1; }
    shift || true

    case "$cmd" in
        add)     cmd_add "$@" ;;
        switch)  cmd_switch "$@" ;;
        list)    cmd_list "$@" ;;
        remove)  cmd_remove "$@" ;;
        current) cmd_current "$@" ;;
        info)    cmd_info "$@" ;;
        *)
            echo -e "${RED}Unknown command:${RESET} $cmd"
            echo -e "Commands: add, switch, list, remove, current, info"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _main "$@"
fi
