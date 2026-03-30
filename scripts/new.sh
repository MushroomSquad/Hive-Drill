#!/usr/bin/env bash
# new.sh — Create a new task brief from template
# Usage: ./scripts/new.sh [--type <type>] <TASK-ID>

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

usage() {
    echo "Usage: $0 [--type <type>] <TASK-ID>"
    echo "Example: $0 FEAT-001"
    echo "Example: $0 --type init INIT-001"
}

TYPE="feature"
TASK_ID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type)
            TYPE="${2:-}"
            if [[ -z "${TYPE}" ]]; then
                echo "Missing value for --type"
                usage
                exit 1
            fi
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -n "${TASK_ID}" ]]; then
                echo "Only one TASK-ID is allowed"
                usage
                exit 1
            fi
            TASK_ID="$1"
            shift
            ;;
    esac
done

if [[ -z "${TASK_ID}" ]]; then
    usage
    exit 1
fi

case "${TYPE}" in
    feature|bugfix|refactor|review|release|init)
        ;;
    *)
        echo "Unknown type: ${TYPE}"
        echo "Allowed types: feature, bugfix, refactor, review, release, init"
        exit 1
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Project context ──────────────────────────────────────────────────────────
source "${SCRIPT_DIR}/project.sh" 2>/dev/null || true
ACTIVE_PROJECT="${ACTIVE_PROJECT:-}"
roi_project_context 2>/dev/null || true

if [[ -z "${ACTIVE_PROJECT}" ]]; then
    echo -e "${RED}Error:${RESET} No active project."
    echo -e "  Set one first: ${CYAN}just project switch <name>${RESET}"
    echo -e "  Or register:   ${CYAN}just project add <name> <path>${RESET}"
    exit 1
fi

VAULT="${PROJECT_ROOT}/vault/projects/${ACTIVE_PROJECT}"
RUN_DIR="${PROJECT_ROOT}/.ai/runs/${ACTIVE_PROJECT}/${TASK_ID}"

case "${TYPE}" in
    init)
        TEMPLATE="${PROJECT_ROOT}/vault/templates/init-brief.md"
        ;;
    *)
        TEMPLATE="${PROJECT_ROOT}/vault/templates/brief.md"
        ;;
esac
INBOX="${VAULT}/00-inbox"

# ─── Validate ─────────────────────────────────────────────────────────────────
if [[ ! -f "${TEMPLATE}" ]]; then
    echo -e "${YELLOW}Warning:${RESET} Template not found at ${TEMPLATE}"
    echo "Creating minimal brief instead."
    TEMPLATE=""
fi

TARGET="${INBOX}/${TASK_ID}.md"

if [[ -f "${TARGET}" ]]; then
    echo -e "${YELLOW}Brief already exists:${RESET} ${TARGET}"
    echo "Delete it first if you want to start over."
    exit 1
fi

# ─── Create directories ───────────────────────────────────────────────────────
mkdir -p "${INBOX}"
mkdir -p "${RUN_DIR}"

# ─── Create brief from template ───────────────────────────────────────────────
TODAY="$(date +%Y-%m-%d)"

if [[ -n "${TEMPLATE}" ]]; then
    # Copy template and substitute placeholders
    sed \
        -e "s|<!-- FILL: e.g. FEAT-001 -->|${TASK_ID}|g" \
        -e "s|^type: .*|type: ${TYPE}|" \
        -e "s|<!-- FILL: YYYY-MM-DD -->|${TODAY}|g" \
        -e "s|just go <!-- FILL: task_id here -->|just go ${TASK_ID}|" \
        "${TEMPLATE}" > "${TARGET}"
else
    # Minimal brief
    cat > "${TARGET}" <<MINIMAL_EOF
---
task_id: ${TASK_ID}
type: ${TYPE}
priority: p1
status: draft
created: ${TODAY}
owner: <!-- FILL: your name -->
---

# Brief: <!-- FILL: title -->

## Goal

<!-- FILL: what needs to be done and why -->

## Acceptance criteria

- [ ] <!-- criterion 1 -->

---

> Change \`status: draft\` → \`status: ready\`, then run: \`just go ${TASK_ID}\`
MINIMAL_EOF
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Task created:${RESET} ${TARGET}"
echo -e "  Run dir:  ${RUN_DIR}"
echo ""

# ─── Add card to canvas ───────────────────────────────────────────────────────
"${SCRIPT_DIR}/canvas-add.sh" "${TASK_ID}" "${TYPE}" "p1" "" "backlog" 2>/dev/null || true

# ─── Open in editor ───────────────────────────────────────────────────────────
if [[ -n "${EDITOR:-}" ]]; then
    echo -e "${CYAN}Opening in \$EDITOR (${EDITOR})...${RESET}"
    "${EDITOR}" "${TARGET}"
else
    echo -e "${YELLOW}Tip:${RESET} Set \$EDITOR to open files automatically."
    echo ""
    local_path="${VAULT#${PROJECT_ROOT}/}"
    echo -e "  Open in Obsidian: ${BOLD}${local_path}/00-inbox/${TASK_ID}.md${RESET}"
fi

# ─── Next step prompt ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo -e "  1. Fill in brief in file: ${VAULT#${PROJECT_ROOT}/}/00-inbox/${TASK_ID}.md"
echo -e "  2. Change \`status: draft\` → \`status: ready\`"
echo -e "  3. Run pipeline: ${CYAN}${BOLD}just go ${TASK_ID}${RESET}"
echo ""
