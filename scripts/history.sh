#!/usr/bin/env bash
# history.sh — Checkpoint history viewer for a pipeline run
# Inspired by LangGraph get_state_history() + time travel
#
# Usage: ./scripts/history.sh <TASK-ID> [--project <name>]
#
# Shows all recorded checkpoints for a task in chronological order,
# with the exact `just go-from` command to resume from each point.

set -euo pipefail

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Args ─────────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <TASK-ID> [--project <name>]"
    exit 1
fi

TASK_ID="$1"
shift

PROJECT_NAME=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project) PROJECT_NAME="${2:-}"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ─── Resolve project ──────────────────────────────────────────────────────────
if [[ -z "$PROJECT_NAME" ]]; then
    STATE_FILE="${PROJECT_ROOT}/.ai/state/current"
    if [[ -f "$STATE_FILE" ]]; then
        PROJECT_NAME="$(cat "$STATE_FILE" | tr -d '[:space:]')"
    fi
fi

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: no active project. Use --project <name> or set active project first."
    exit 1
fi

RUN_DIR="${PROJECT_ROOT}/.ai/runs/${PROJECT_NAME}/${TASK_ID}"

if [[ ! -d "$RUN_DIR" ]]; then
    echo "Error: run directory not found: ${RUN_DIR}"
    exit 1
fi

# ─── Stage names map ──────────────────────────────────────────────────────────
stage_name() {
    case "$1" in
        0) echo "Brief"      ;;
        1) echo "Plan"       ;;
        2) echo "Tasks"      ;;
        3) echo "Code"       ;;
        4) echo "Tests"      ;;
        5) echo "Review"     ;;
        6) echo "PR"         ;;
        *) echo "Stage $1"   ;;
    esac
}

# ─── Header ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
echo -e "${CYAN}${BOLD}  Pipeline History: ${TASK_ID}${RESET}"
echo -e "${CYAN}${BOLD}  Project: ${PROJECT_NAME}${RESET}"
echo -e "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
echo ""

# ─── Current checkpoint ───────────────────────────────────────────────────────
CHECKPOINT_FILE="${RUN_DIR}/checkpoint.yml"

if [[ ! -f "$CHECKPOINT_FILE" ]]; then
    echo -e "  ${YELLOW}No checkpoint found.${RESET} Pipeline has not been run yet."
    echo ""
    echo -e "  Start with: ${BOLD}just go ${TASK_ID}${RESET}"
    echo ""
    exit 0
fi

# Parse checkpoint
last_stage="$(grep "^last_completed_stage:" "$CHECKPOINT_FILE" | awk '{print $2}')"
last_stage_name="$(grep "^last_completed_stage_name:" "$CHECKPOINT_FILE" | awk '{print $2}')"
timestamp="$(grep "^timestamp:" "$CHECKPOINT_FILE" | awk '{print $2}')"
resume_cmd="$(grep "^resume_with:" "$CHECKPOINT_FILE" | sed 's/^resume_with: //')"

# ─── Timeline ────────────────────────────────────────────────────────────────
echo -e "  ${DIM}Stage  Status      Artifact${RESET}"
echo -e "  ${DIM}─────────────────────────────────────────────${RESET}"

for stage_num in 0 1 2 3 4 5 6; do
    sname="$(stage_name $stage_num)"

    # Determine status relative to last completed
    if [[ $stage_num -le $last_stage ]]; then
        status_icon="${GREEN}✓${RESET}"
        status_label="completed"
    elif [[ $stage_num -eq $(( last_stage + 1 )) ]]; then
        status_icon="${YELLOW}→${RESET}"
        status_label="next    "
    else
        status_icon="${DIM}·${RESET}"
        status_label="pending "
    fi

    # Detect artifact
    artifact=""
    case $stage_num in
        0) [[ -f "${RUN_DIR}/brief.md"        ]] && artifact="brief.md" ;;
        1) [[ -f "${RUN_DIR}/plan.md"         ]] && artifact="plan.md" ;;
        2) [[ -f "${RUN_DIR}/tasks.yaml"      ]] && artifact="tasks.yaml" ;;
        3) [[ -f "${RUN_DIR}/codex.log"       ]] && artifact="codex.log" ;;
        4) [[ -f "${RUN_DIR}/test-report.md"  ]] && artifact="test-report.md" ;;
        5) [[ -f "${RUN_DIR}/findings.md"     ]] && artifact="findings.md" ;;
        6) [[ -f "${RUN_DIR}/pr-body.md"      ]] && artifact="pr-body.md" ;;
    esac
    artifact_str="${DIM}${artifact}${RESET}"
    [[ -z "$artifact" ]] && artifact_str="${DIM}—${RESET}"

    printf "  %s  Stage %-2s  %-10s  %s  %b\n" \
        "$(echo -e "$status_icon")" \
        "$stage_num" \
        "($sname)" \
        "$status_label" \
        "$artifact_str"
done

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${DIM}Last checkpoint: ${timestamp}${RESET}"
echo ""

# Resume options
next_stage=$(( last_stage + 1 ))
if [[ $next_stage -le 6 ]]; then
    echo -e "  ${BOLD}Resume from next stage (${next_stage} — $(stage_name $next_stage)):${RESET}"
    echo -e "    just go-from ${TASK_ID} ${next_stage}"
    echo ""
    echo -e "  ${BOLD}Or resume from any completed stage:${RESET}"
    for s in $(seq 0 "$last_stage"); do
        echo -e "    ${DIM}Stage ${s} ($(stage_name $s)):${RESET}  just go-from ${TASK_ID} ${s}"
    done
else
    echo -e "  ${GREEN}${BOLD}Pipeline complete.${RESET}"
fi

echo ""

# ─── Decisions log (if any) ──────────────────────────────────────────────────
if [[ -f "${RUN_DIR}/decisions.md" ]]; then
    decision_count="$(grep -c "^### DEC-" "${RUN_DIR}/decisions.md" 2>/dev/null || echo 0)"
    if [[ "$decision_count" -gt 0 ]]; then
        echo -e "  ${CYAN}${decision_count} architectural decision(s) logged:${RESET} ${RUN_DIR}/decisions.md"
        echo ""
    fi
fi
