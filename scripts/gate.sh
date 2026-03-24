#!/usr/bin/env bash
# gate.sh — Interactive approval gate
# Usage: ./scripts/gate.sh <stage-name> <artifact-file>
# Exit code: 0 = approved, 1 = rejected

set -euo pipefail

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
    # Update status in frontmatter if present
    if grep -q "^status:" "${file}" 2>/dev/null; then
        sed -i "s|^status:.*|status: approved|" "${file}"
    fi
    if grep -q "^verdict:" "${file}" 2>/dev/null; then
        sed -i "s|^verdict:.*|verdict: APPROVED|" "${file}"
    fi
}

# ─── Main gate loop ───────────────────────────────────────────────────────────
show_artifact

echo -e "${YELLOW}${BOLD}⏸  Gate: ${STAGE_NAME}${RESET}"
echo -e "   Artifact: ${ARTIFACT_FILE}"
echo ""

while true; do
    echo -ne "$(echo -e "${YELLOW}${BOLD}Approve '${STAGE_NAME}'? [y = yes  /  n = abort  /  e = edit then re-ask]: ${RESET}")"
    read -r answer

    case "${answer,,}" in
        y|yes)
            mark_approved "${ARTIFACT_FILE}"
            echo ""
            echo -e "  ${GREEN}${BOLD}✓ Approved.${RESET} Continuing pipeline."
            echo ""
            exit 0
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
            echo -e "  ${YELLOW}Please enter:${RESET} y (approve) / n (abort) / e (edit)"
            ;;
    esac
done
