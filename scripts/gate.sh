#!/usr/bin/env bash
# gate.sh — Interactive approval gate
# Usage: ./scripts/gate.sh <stage-name> <artifact-file>
# Exit codes:
#   0 = approved
#   1 = rejected (stop pipeline)
#   2 = request_changes (loop back to previous execution stage)
#   3 = escalate (stop + write escalation note)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=detect-platform.sh
source "${SCRIPT_DIR}/detect-platform.sh"

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'
DIM='\033[2m'

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <stage-name> <artifact-file>"
    exit 1
fi

STAGE_NAME="$1"
ARTIFACT_FILE="$2"

if [[ ! -f "${ARTIFACT_FILE}" ]]; then
    echo -e "${RED}Error:${RESET} Artifact file not found: ${ARTIFACT_FILE}"
    exit 1
fi

# ─── Display artifact ─────────────────────────────────────────────────────────
show_artifact() {
    echo ""
    echo -e "${DIM}─────────────────────────── artifact: $(basename "${ARTIFACT_FILE}") ────────────────────────────${RESET}"
    echo ""
    if command -v bat &>/dev/null; then
        bat --style=plain --paging=never "${ARTIFACT_FILE}"
    elif command -v less &>/dev/null; then
        less -F "${ARTIFACT_FILE}" || cat "${ARTIFACT_FILE}"
    else
        cat "${ARTIFACT_FILE}"
    fi
    echo ""
    echo -e "${DIM}───────────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
}

# ─── Update frontmatter status ────────────────────────────────────────────────
mark_approved() {
    local file="$1"
    if grep -q "^status:" "${file}" 2>/dev/null; then
        ${HIVE_SED_I} "s|^status:.*|status: approved|" "${file}"
    fi
    if grep -q "^verdict:" "${file}" 2>/dev/null; then
        ${HIVE_SED_I} "s|^verdict:.*|verdict: APPROVED|" "${file}"
    fi
}

mark_needs_revision() {
    local file="$1"
    local note="$2"
    if grep -q "^status:" "${file}" 2>/dev/null; then
        ${HIVE_SED_I} "s|^status:.*|status: needs_revision|" "${file}"
    fi
    if grep -q "^verdict:" "${file}" 2>/dev/null; then
        ${HIVE_SED_I} "s|^verdict:.*|verdict: REQUEST_CHANGES|" "${file}"
    fi
    # Append revision note
    {
        echo ""
        echo "## Revision requested"
        echo "**At:** $(date '+%Y-%m-%d %H:%M')"
        echo "**Note:** ${note}"
    } >> "${file}"
}

mark_escalated() {
    local file="$1"
    local note="$2"
    if grep -q "^status:" "${file}" 2>/dev/null; then
        ${HIVE_SED_I} "s|^status:.*|status: escalated|" "${file}"
    fi
    if grep -q "^verdict:" "${file}" 2>/dev/null; then
        ${HIVE_SED_I} "s|^verdict:.*|verdict: ESCALATED|" "${file}"
    fi
    {
        echo ""
        echo "## Escalation note"
        echo "**At:** $(date '+%Y-%m-%d %H:%M')"
        echo "**Note:** ${note}"
    } >> "${file}"
}

# ─── Main gate loop ───────────────────────────────────────────────────────────
show_artifact

echo -e "${YELLOW}${BOLD}⏸  Gate: ${STAGE_NAME}${RESET}"
echo -e "   Artifact: ${ARTIFACT_FILE}"
echo ""

while true; do
    echo -e "${YELLOW}${BOLD}  y${RESET} = approve   ${YELLOW}${BOLD}r${RESET} = request changes   ${YELLOW}${BOLD}e${RESET} = edit   ${YELLOW}${BOLD}x${RESET} = escalate   ${YELLOW}${BOLD}n${RESET} = abort"
    echo -ne "$(echo -e "${YELLOW}${BOLD}Decision for '${STAGE_NAME}': ${RESET}")"
    read -r answer

    case "${answer,,}" in
        y|yes)
            mark_approved "${ARTIFACT_FILE}"
            echo ""
            echo -e "  ${GREEN}${BOLD}✓ Approved.${RESET} Continuing pipeline."
            echo ""
            exit 0
            ;;
        r|request|request_changes|revision)
            echo ""
            echo -ne "$(echo -e "${YELLOW}Revision note (what needs to change): ${RESET}")"
            read -r revision_note
            mark_needs_revision "${ARTIFACT_FILE}" "${revision_note:-no note}"
            echo ""
            echo -e "  ${YELLOW}${BOLD}↺ Request changes.${RESET} Pipeline will retry from execution stage."
            echo -e "  Note saved to: ${ARTIFACT_FILE}"
            echo ""
            exit 2
            ;;
        x|escalate)
            echo ""
            echo -ne "$(echo -e "${YELLOW}Escalation note: ${RESET}")"
            read -r escalation_note
            mark_escalated "${ARTIFACT_FILE}" "${escalation_note:-no note}"
            echo ""
            echo -e "  ${RED}${BOLD}⚠ Escalated.${RESET} Pipeline stopped. Review escalation note in:"
            echo -e "  ${ARTIFACT_FILE}"
            echo ""
            exit 3
            ;;
        n|no|abort|q|quit)
            echo ""
            echo -e "  ${RED}${BOLD}✗ Rejected.${RESET} Pipeline stopped at stage: ${STAGE_NAME}"
            echo ""
            echo -e "  To resume: ${BOLD}just go-from <TASK-ID> <stage-number>${RESET}"
            echo ""
            exit 1
            ;;
        e|edit)
            EDITOR_CMD="${EDITOR:-vi}"
            echo -e "  Opening ${ARTIFACT_FILE} in ${EDITOR_CMD}..."
            "${EDITOR_CMD}" "${ARTIFACT_FILE}"
            echo ""
            show_artifact
            ;;
        "")
            # Empty input — re-prompt
            ;;
        *)
            echo -e "  ${YELLOW}Options:${RESET} y (approve) / r (request changes) / e (edit) / x (escalate) / n (abort)"
            ;;
    esac
done
