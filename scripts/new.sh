#!/usr/bin/env bash
# new.sh — Create a new task brief from template
# Usage: ./scripts/new.sh <TASK-ID>

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <TASK-ID>"
    echo "Example: $0 FEAT-001"
    exit 1
fi

TASK_ID="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VAULT="${PROJECT_ROOT}/vault"
TEMPLATE="${VAULT}/templates/brief.md"
INBOX="${VAULT}/00-inbox"
RUN_DIR="${PROJECT_ROOT}/.ai/runs/${TASK_ID}"

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
        -e "s|<!-- FILL: YYYY-MM-DD -->|${TODAY}|g" \
        "${TEMPLATE}" > "${TARGET}"
else
    # Minimal brief
    cat > "${TARGET}" <<MINIMAL_EOF
---
task_id: ${TASK_ID}
type: feature
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

# ─── Open in editor ───────────────────────────────────────────────────────────
if [[ -n "${EDITOR:-}" ]]; then
    echo -e "${CYAN}Opening in \$EDITOR (${EDITOR})...${RESET}"
    "${EDITOR}" "${TARGET}"
else
    echo -e "${YELLOW}Tip:${RESET} Set \$EDITOR to open files automatically."
    echo ""
    echo -e "  Open in Obsidian: ${BOLD}vault/00-inbox/${TASK_ID}.md${RESET}"
fi

# ─── Next step prompt ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo -e "  1. Заполни brief в файле: vault/00-inbox/${TASK_ID}.md"
echo -e "  2. Смени \`status: draft\` → \`status: ready\`"
echo -e "  3. Запусти pipeline: ${CYAN}${BOLD}just go ${TASK_ID}${RESET}"
echo ""
