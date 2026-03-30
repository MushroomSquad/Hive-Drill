#!/usr/bin/env bash
# self.sh — Hive Drill self-improvement pipeline
# Manages a second Hive Drill instance in workspace/hive-drill-dev/ for self-directed development.
# One Hive Drill instance improves another, pushes the result, then pulls itself.
#
# Usage:
#   ./scripts/self.sh init [--repo <git-url>] [--github <owner/repo>]
#   ./scripts/self.sh update   — git pull workspace/hive-drill-dev
#   ./scripts/self.sh status   — workspace + runs status
#   ./scripts/self.sh sync     — commit+push workspace, then pull self

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SELF_CONFIG="${PROJECT_ROOT}/.ai/self/config.json"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
info() { echo -e "  ${CYAN}[self]${RESET} $*"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*" >&2; }

_config_get() {
    python3 -c "import json; print(json.load(open('${SELF_CONFIG}')).get('${1}',''))" 2>/dev/null || echo ""
}

_require_config() {
    [[ -f "${SELF_CONFIG}" ]] || { err "Self workspace not initialized. Run: just self init"; exit 1; }
}

# ─── init ─────────────────────────────────────────────────────────────────────

cmd_init() {
    local remote_url="" github_repo=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo)   remote_url="$2"; shift 2 ;;
            --github) github_repo="$2"; shift 2 ;;
            *)        shift ;;
        esac
    done

    if [[ -z "$remote_url" ]]; then
        echo -n "  Git remote URL (for cloning Hive Drill): "
        read -r remote_url
    fi
    if [[ -z "$github_repo" ]]; then
        echo -n "  GitHub repo (owner/repo, for issues): "
        read -r github_repo
    fi

    local workspace_path="${PROJECT_ROOT}/workspace/hive-drill-dev"
    local project_name="hive-drill-dev"

    # Clone or update workspace
    if [[ -d "${workspace_path}/.git" ]]; then
        warn "Workspace already exists: ${workspace_path}"
        info "Updating..."
        git -C "${workspace_path}" pull
    else
        info "Cloning ${remote_url} → ${workspace_path}..."
        mkdir -p "$(dirname "${workspace_path}")"
        git clone "${remote_url}" "${workspace_path}"
    fi
    ok "Workspace ready: ${workspace_path}"

    # Save config
    mkdir -p "$(dirname "${SELF_CONFIG}")"
    python3 - "${SELF_CONFIG}" "${remote_url}" "${github_repo}" "${workspace_path}" "${project_name}" <<'PYEOF'
import json, sys
cfg_path, remote_url, github_repo, workspace_path, project_name = sys.argv[1:]
with open(cfg_path, "w") as f:
    json.dump({
        "remote_url":     remote_url,
        "github_repo":    github_repo,
        "workspace_path": workspace_path,
        "project_name":   project_name,
    }, f, indent=2)
PYEOF
    ok "Config saved: ${SELF_CONFIG}"

    # Register as project (reuses project.sh)
    "${SCRIPT_DIR}/project.sh" add "${project_name}" "${workspace_path}" "Hive Drill self-improvement workspace"

    # Switch to it so arch/docs go to the right vault
    "${SCRIPT_DIR}/project.sh" switch "${project_name}"

    # Generate initial architecture docs for workspace
    info "Generating workspace documentation..."
    "${SCRIPT_DIR}/canvas-arch.sh"

    echo ""
    ok "Self-improve workspace initialized."
    echo -e "  Workspace:  ${workspace_path}"
    echo -e "  GitHub:     https://github.com/${github_repo}/issues"
    echo -e "  Project:    ${project_name}"
    echo ""
    echo -e "  Next step: ${CYAN}just issues${RESET}"
}

# ─── update ───────────────────────────────────────────────────────────────────

cmd_update() {
    _require_config
    local workspace_path
    workspace_path="$(_config_get workspace_path)"

    info "Updating workspace: ${workspace_path}..."
    git -C "${workspace_path}" pull
    ok "Workspace updated to $(git -C "${workspace_path}" rev-parse --short HEAD)."
}

# ─── status ───────────────────────────────────────────────────────────────────

cmd_status() {
    if [[ ! -f "${SELF_CONFIG}" ]]; then
        warn "Self workspace not initialized. just self init"
        return 0
    fi

    local workspace_path project_name github_repo
    workspace_path="$(_config_get workspace_path)"
    project_name="$(_config_get project_name)"
    github_repo="$(_config_get github_repo)"

    echo ""
    echo -e "${BOLD}  Self-improve workspace${RESET}"
    echo -e "  Workspace : ${workspace_path}"
    echo -e "  GitHub    : https://github.com/${github_repo}"
    echo ""

    if [[ ! -d "${workspace_path}/.git" ]]; then
        err "Workspace not found: ${workspace_path}"
        return 1
    fi

    local branch
    branch="$(git -C "${workspace_path}" symbolic-ref --short HEAD 2>/dev/null || echo 'detached')"
    local changes
    changes="$(git -C "${workspace_path}" status --short | wc -l | tr -d ' ')"
    ok "Branch: ${branch}  |  Changes: ${changes}"

    # ahead/behind
    git -C "${workspace_path}" fetch --quiet 2>/dev/null || true
    local ahead behind
    ahead="$(git -C "${workspace_path}" rev-list @{u}..HEAD --count 2>/dev/null || echo 0)"
    behind="$(git -C "${workspace_path}" rev-list HEAD..@{u} --count 2>/dev/null || echo 0)"
    [[ "$ahead"  -gt 0 ]] && warn "Ahead:  ${ahead} commit(s) — not pushed"
    [[ "$behind" -gt 0 ]] && warn "Behind: ${behind} commit(s) — not pulled"

    # Active runs
    local runs_dir="${PROJECT_ROOT}/.ai/runs/${project_name}"
    if [[ -d "${runs_dir}" ]]; then
        local run_count
        run_count="$(find "${runs_dir}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
        ok "Runs: ${run_count}"
        find "${runs_dir}" -maxdepth 1 -mindepth 1 -type d | sort -r | head -3 | while IFS= read -r r; do
            echo -e "    · $(basename "$r")"
        done
    fi
    echo ""
}

# ─── sync ─────────────────────────────────────────────────────────────────────
# Commit + push workspace changes, then pull the operator (current Hive Drill).

cmd_sync() {
    _require_config
    local workspace_path
    workspace_path="$(_config_get workspace_path)"

    # Commit workspace changes
    if git -C "${workspace_path}" diff --quiet && git -C "${workspace_path}" diff --staged --quiet; then
        warn "No uncommitted changes in workspace."
    else
        echo ""
        git -C "${workspace_path}" status --short | head -20
        echo ""
        echo -n "  Commit message (Enter = default 'chore: self-improvement batch'): "
        read -r msg
        msg="${msg:-chore: self-improvement batch}"

        git -C "${workspace_path}" add -A
        git -C "${workspace_path}" commit -m "${msg}"
        ok "Committed: ${msg}"
    fi

    # Push workspace
    info "Pushing workspace → remote..."
    git -C "${workspace_path}" push
    ok "Workspace pushed."

    # Pull current Hive Drill (operator becomes the improved version)
    info "Pulling current Hive Drill (operator)..."
    git -C "${PROJECT_ROOT}" pull
    ok "Current Hive Drill updated."

    echo ""
    ok "Cycle complete. Both instances synchronized."
}

# ─── Entry point ──────────────────────────────────────────────────────────────

_main() {
    local cmd="${1:-status}"
    shift || true
    case "$cmd" in
        init)   cmd_init "$@" ;;
        update) cmd_update "$@" ;;
        status) cmd_status "$@" ;;
        sync)   cmd_sync "$@" ;;
        *)
            echo -e "Usage: self <init|update|status|sync>"
            echo -e "  init   [--repo <url>] [--github <owner/repo>]"
            echo -e "  update — pull latest into workspace"
            echo -e "  status — workspace + runs overview"
            echo -e "  sync   — commit+push workspace, pull self"
            exit 1
            ;;
    esac
}

_main "$@"
