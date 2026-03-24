#!/usr/bin/env bash
# go.sh — Main pipeline automation script
# Usage: ./scripts/go.sh <TASK-ID> [--from-stage <0-6>]
#
# Stages:
#   0  Brief  (human)
#   1  Plan   (claude)  → Gate
#   2  Tasks  (claude)
#   3  Code   (codex)
#   4  Tests  (scripts)
#   5  Review (claude)  → Gate
#   6  PR     (scripts)

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────────────────
log_stage() {
    local stage_num="$1"
    local stage_name="$2"
    echo ""
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
    echo -e "${CYAN}${BOLD}  Stage ${stage_num}: ${stage_name}${RESET}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
}

log_info()    { echo -e "  ${BOLD}→${RESET} $*"; }
log_success() { echo -e "  ${GREEN}✓${RESET} $*"; }
log_warn()    { echo -e "  ${YELLOW}⚠${RESET} $*"; }
log_error()   { echo -e "  ${RED}✗${RESET} $*"; }

die() {
    log_error "$*"
    exit 1
}

check_cmd() {
    command -v "$1" &>/dev/null
}

# ─── Args ────────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <TASK-ID> [--from-stage <0-6>]"
    exit 1
fi

TASK_ID="$1"
FROM_STAGE=0

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from-stage)
            FROM_STAGE="${2:-0}"
            shift 2
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

# ─── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VAULT="${PROJECT_ROOT}/vault"
RUN_DIR="${PROJECT_ROOT}/.ai/runs/${TASK_ID}"
INBOX="${VAULT}/00-inbox"
ACTIVE="${VAULT}/01-active"
DONE="${VAULT}/02-done"
GATE_SCRIPT="${SCRIPT_DIR}/gate.sh"

mkdir -p "${RUN_DIR}" "${ACTIVE}" "${DONE}"

# ─── Find brief ──────────────────────────────────────────────────────────────
find_brief() {
    local locations=(
        "${INBOX}/${TASK_ID}.md"
        "${ACTIVE}/${TASK_ID}.md"
        "${RUN_DIR}/brief.md"
    )
    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    return 1
}

# ─── Frontmatter helpers ─────────────────────────────────────────────────────
get_frontmatter_value() {
    local file="$1"
    local key="$2"
    # Extract value between --- blocks
    awk '/^---/{found++} found==1 && /^'"$key"':/{gsub(/^'"$key"':[[:space:]]*/,""); gsub(/#.*$/,""); gsub(/[[:space:]]*$/,""); print; exit}' "$file"
}

set_frontmatter_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    # Replace the value in frontmatter
    sed -i "s|^${key}:.*|${key}: ${value}|" "$file"
}

# ─── Stage: check brief ready ────────────────────────────────────────────────
stage_check_brief() {
    log_stage 0 "Brief"

    local brief_path
    if ! brief_path="$(find_brief)"; then
        die "Brief not found for task '${TASK_ID}'.
  Expected one of:
    ${INBOX}/${TASK_ID}.md
    ${ACTIVE}/${TASK_ID}.md
    ${RUN_DIR}/brief.md
  Run: just new ${TASK_ID}"
    fi

    log_info "Found brief: ${brief_path}"

    local status
    status="$(get_frontmatter_value "${brief_path}" "status")"
    log_info "Status: ${status}"

    if [[ "$status" != "ready" ]]; then
        log_warn "Brief status is '${status}', expected 'ready'."
        echo ""
        echo -e "  ${YELLOW}Please fill the brief and change status to 'ready'.${RESET}"
        echo -e "  File: ${brief_path}"
        echo ""

        if [[ -n "${EDITOR:-}" ]]; then
            read -r -p "  Open in \$EDITOR (${EDITOR})? [Y/n] " open_ans
            if [[ "${open_ans,,}" != "n" ]]; then
                "${EDITOR}" "${brief_path}"
            fi
        else
            echo "  Set EDITOR env var to open automatically."
        fi

        # Re-check
        status="$(get_frontmatter_value "${brief_path}" "status")"
        if [[ "$status" != "ready" ]]; then
            die "Brief status is still '${status}'. Set status: ready to proceed."
        fi
    fi

    # Copy brief to run dir if not already there
    if [[ "$brief_path" != "${RUN_DIR}/brief.md" ]]; then
        cp "${brief_path}" "${RUN_DIR}/brief.md"
        log_success "Copied brief to ${RUN_DIR}/brief.md"
    fi

    # Move to active if coming from inbox
    if [[ "$brief_path" == "${INBOX}/${TASK_ID}.md" ]]; then
        mv "${brief_path}" "${ACTIVE}/${TASK_ID}.md"
        log_success "Moved brief to 01-active/"
    fi

    log_success "Brief ready."
}

# ─── Stage 1: Plan ───────────────────────────────────────────────────────────
stage_plan() {
    log_stage 1 "Plan (Claude)"

    local plan_file="${RUN_DIR}/plan.md"
    local brief_file="${RUN_DIR}/brief.md"

    if ! check_cmd claude; then
        log_warn "claude CLI not found. Skipping automatic plan generation."
        log_warn "To generate manually: claude < ${brief_file} > ${plan_file}"

        # Create placeholder if plan doesn't exist
        if [[ ! -f "${plan_file}" ]]; then
            cat "${VAULT}/templates/plan.md" > "${plan_file}"
            set_frontmatter_value "${plan_file}" "task_id" "${TASK_ID}"
            log_info "Created plan template at ${plan_file}"
            log_warn "Fill it manually, then re-run: just go-from ${TASK_ID} 1"
        fi
        return 0
    fi

    log_info "Calling Claude to generate plan..."

    local prompt
    prompt="$(cat <<'PROMPT_EOF'
You are a senior software architect. Read the task brief below and produce a detailed implementation plan.

Output ONLY valid Markdown with YAML frontmatter. Use this exact structure:

---
task_id: TASK_ID_PLACEHOLDER
status: draft
agent: claude
created: DATE_PLACEHOLDER
---

# Plan: [title]

## Current state diagnosis
[analysis]

## Options considered
### Option A — [name]
[pros/cons/effort]

### Option B — [name]
[pros/cons/effort]

## Chosen approach
[decision and rationale]

## Implementation steps
1. [step]
2. [step]
...

## Migration risks
| Risk | Likelihood | Impact | Mitigation |

## Test strategy
- Unit tests: ...
- Integration tests: ...
- Manual verification: ...

## Rollback
1. [step]

---

BRIEF:
PROMPT_EOF
)"

    # Replace placeholders
    prompt="${prompt/TASK_ID_PLACEHOLDER/${TASK_ID}}"
    prompt="${prompt/DATE_PLACEHOLDER/$(date +%Y-%m-%d)}"

    local full_prompt="${prompt}

$(cat "${brief_file}")"

    if ! echo "${full_prompt}" | claude --no-markdown-fence > "${plan_file}" 2>/dev/null; then
        # Fallback: try without flags
        if ! echo "${full_prompt}" | claude > "${plan_file}" 2>/dev/null; then
            log_warn "Claude returned an error. Check ${plan_file} manually."
        fi
    fi

    if [[ -f "${plan_file}" && -s "${plan_file}" ]]; then
        # Fix frontmatter values
        set_frontmatter_value "${plan_file}" "task_id" "${TASK_ID}"
        log_success "Plan generated: ${plan_file}"
    else
        log_warn "Plan file is empty. Using template."
        cat "${VAULT}/templates/plan.md" > "${plan_file}"
        set_frontmatter_value "${plan_file}" "task_id" "${TASK_ID}"
    fi
}

# ─── Gate: Plan approval ─────────────────────────────────────────────────────
gate_plan() {
    local plan_file="${RUN_DIR}/plan.md"
    echo ""
    echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}  ⏸ GATE: Plan Review Required${RESET}"
    echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [[ -x "${GATE_SCRIPT}" ]]; then
        if ! "${GATE_SCRIPT}" "plan" "${plan_file}"; then
            die "Plan rejected. Pipeline stopped."
        fi
    else
        # Inline gate fallback
        echo ""
        if check_cmd bat; then
            bat --style=plain "${plan_file}"
        else
            cat "${plan_file}"
        fi
        echo ""
        while true; do
            read -r -p "$(echo -e "${YELLOW}Approve plan? [y=yes / n=abort / e=edit]${RESET} ") " ans
            case "${ans,,}" in
                y|yes)
                    log_success "Plan approved."
                    set_frontmatter_value "${plan_file}" "status" "approved"
                    break
                    ;;
                n|no|abort)
                    die "Plan rejected by user."
                    ;;
                e|edit)
                    "${EDITOR:-vi}" "${plan_file}"
                    ;;
                *)
                    echo "  Enter y, n, or e."
                    ;;
            esac
        done
    fi
}

# ─── Stage 2: Tasks ──────────────────────────────────────────────────────────
stage_tasks() {
    log_stage 2 "Tasks (Claude)"

    local tasks_file="${RUN_DIR}/tasks.md"
    local plan_file="${RUN_DIR}/plan.md"

    if ! check_cmd claude; then
        log_warn "claude CLI not found. Skipping automatic task breakdown."
        if [[ ! -f "${tasks_file}" ]]; then
            cat > "${tasks_file}" <<'TASKS_TMPL'
# Tasks

<!-- Generated from plan. Fill manually if claude is unavailable. -->

## Task list

- [ ] Task 1: <!-- describe -->
- [ ] Task 2: <!-- describe -->
- [ ] Task 3: <!-- describe -->
TASKS_TMPL
            log_info "Created tasks template at ${tasks_file}"
        fi
        return 0
    fi

    log_info "Calling Claude to break plan into tasks..."

    local prompt
    prompt="$(cat <<'PROMPT_EOF'
Read the implementation plan below and produce a concrete task checklist.

Output ONLY Markdown. Format:
# Tasks: [title]

## Implementation tasks
- [ ] TASK-1: [specific action, file to change, what to do]
- [ ] TASK-2: ...

## Test tasks
- [ ] TEST-1: [what to test]

## Done criteria
- [ ] All tests pass
- [ ] Linter clean
- [ ] PR description written

PLAN:
PROMPT_EOF
)"

    local full_prompt="${prompt}

$(cat "${plan_file}")"

    if ! echo "${full_prompt}" | claude > "${tasks_file}" 2>/dev/null; then
        log_warn "Claude returned an error generating tasks."
    fi

    if [[ -f "${tasks_file}" && -s "${tasks_file}" ]]; then
        log_success "Tasks generated: ${tasks_file}"
    else
        log_warn "Tasks file empty. Creating template."
        echo "# Tasks: ${TASK_ID}" > "${tasks_file}"
    fi
}

# ─── Stage 3: Code ───────────────────────────────────────────────────────────
stage_code() {
    log_stage 3 "Code (Codex)"

    local tasks_file="${RUN_DIR}/tasks.md"
    local code_log="${RUN_DIR}/codex.log"

    if ! check_cmd codex; then
        log_warn "codex CLI not found. Skipping automatic code generation."
        log_warn "Install: npm install -g @openai/codex"
        log_warn "Or implement manually using tasks from: ${tasks_file}"
        return 0
    fi

    log_info "Calling Codex to implement tasks..."
    log_info "Working in project root: ${PROJECT_ROOT}"

    local prompt
    prompt="$(cat <<'PROMPT_EOF'
Implement all unchecked tasks in the task list below. Work in the current repository.
Make minimal, focused changes. Follow existing code style.
After each logical unit of work, the changes will be staged automatically.

TASKS:
PROMPT_EOF
)"

    local full_prompt="${prompt}

$(cat "${tasks_file}")"

    # Run codex in project root
    if ! (cd "${PROJECT_ROOT}" && echo "${full_prompt}" | codex 2>&1 | tee "${code_log}"); then
        log_warn "Codex exited with error. Check ${code_log}"
    else
        log_success "Codex finished. See ${code_log}"
    fi
}

# ─── Stage 4: Tests ──────────────────────────────────────────────────────────
stage_tests() {
    log_stage 4 "Tests & Checks"

    local test_report="${RUN_DIR}/test-report.md"

    {
        echo "# Test Report: ${TASK_ID}"
        echo "Generated: $(date)"
        echo ""
    } > "${test_report}"

    local overall_pass=true

    run_check() {
        local label="$1"
        shift
        log_info "Running: ${label}"
        if (cd "${PROJECT_ROOT}" && "$@" >> "${test_report}" 2>&1); then
            echo "- [x] ${label}: PASS" >> "${test_report}"
            log_success "${label}: PASS"
        else
            echo "- [ ] ${label}: FAIL" >> "${test_report}"
            log_warn "${label}: FAIL (non-blocking, check report)"
            overall_pass=false
        fi
        echo "" >> "${test_report}"
    }

    # Detect project type and run appropriate checks
    if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
        if check_cmd npm; then
            run_check "npm test" npm test --if-present
            run_check "npm lint" npm run lint --if-present
        fi
        if check_cmd npx; then
            run_check "TypeScript check" npx tsc --noEmit 2>/dev/null || true
        fi
    fi

    if [[ -f "${PROJECT_ROOT}/Cargo.toml" ]]; then
        if check_cmd cargo; then
            run_check "cargo test" cargo test
            run_check "cargo clippy" cargo clippy -- -D warnings
        fi
    fi

    if [[ -f "${PROJECT_ROOT}/pyproject.toml" ]] || [[ -f "${PROJECT_ROOT}/setup.py" ]]; then
        if check_cmd pytest; then
            run_check "pytest" pytest
        fi
        if check_cmd ruff; then
            run_check "ruff check" ruff check .
        fi
    fi

    if [[ -f "${PROJECT_ROOT}/go.mod" ]]; then
        if check_cmd go; then
            run_check "go test" go test ./...
            run_check "go vet" go vet ./...
        fi
    fi

    # Generic: if just has a test target
    if check_cmd just; then
        if (cd "${PROJECT_ROOT}" && just --list 2>/dev/null | grep -q "^test"); then
            run_check "just test" just test
        fi
    fi

    echo "" >> "${test_report}"
    if [[ "$overall_pass" == true ]]; then
        echo "**Overall: PASS**" >> "${test_report}"
        log_success "All checks passed. Report: ${test_report}"
    else
        echo "**Overall: PARTIAL (some checks failed)**" >> "${test_report}"
        log_warn "Some checks failed. Review ${test_report} before continuing."
    fi
}

# ─── Stage 5: Review ─────────────────────────────────────────────────────────
stage_review() {
    log_stage 5 "Review (Claude)"

    local findings_file="${RUN_DIR}/findings.md"
    local brief_file="${RUN_DIR}/brief.md"
    local plan_file="${RUN_DIR}/plan.md"

    if ! check_cmd claude; then
        log_warn "claude CLI not found. Skipping automatic review."
        if [[ ! -f "${findings_file}" ]]; then
            cat "${VAULT}/templates/findings.md" > "${findings_file}"
            set_frontmatter_value "${findings_file}" "task_id" "${TASK_ID}"
            log_info "Created findings template at ${findings_file}"
            log_warn "Fill it manually, then re-run: just go-from ${TASK_ID} 5"
        fi
        return 0
    fi

    log_info "Getting git diff for review..."

    local diff_output=""
    if check_cmd git; then
        diff_output="$(cd "${PROJECT_ROOT}" && git diff HEAD 2>/dev/null || true)"
        if [[ -z "$diff_output" ]]; then
            diff_output="$(cd "${PROJECT_ROOT}" && git diff 2>/dev/null || true)"
        fi
    fi

    log_info "Calling Claude to review changes..."

    local prompt
    prompt="$(cat <<'PROMPT_EOF'
You are a senior software engineer doing a code review. Analyze the diff below against the original brief and plan.

Output ONLY valid Markdown with YAML frontmatter:

---
task_id: TASK_ID_PLACEHOLDER
verdict: APPROVED
agent: claude
reviewed_at: DATE_PLACEHOLDER
---

# Review Findings: [title]

## Architecture assessment
[assessment]

## Technical debt introduced
| Item | Debt level | Ticket / follow-up |
|---|---|---|

## Security notes
- [area]: [OK / WARNING / BLOCKER and notes]

## Performance notes
- [note]

## Follow-up tasks
- [ ] [follow-up]

## Verdict
> **[APPROVED / REQUEST_CHANGES / BLOCKED]**
[required changes if not approved]

---

BRIEF:
PROMPT_EOF
)"
    prompt="${prompt/TASK_ID_PLACEHOLDER/${TASK_ID}}"
    prompt="${prompt/DATE_PLACEHOLDER/$(date +%Y-%m-%d)}"

    local full_prompt="${prompt}

$(cat "${brief_file}")

PLAN:
$(cat "${plan_file}" 2>/dev/null || echo "(no plan)")

DIFF:
${diff_output:-(no diff — no changes detected)}"

    if ! echo "${full_prompt}" | claude > "${findings_file}" 2>/dev/null; then
        log_warn "Claude review returned an error."
    fi

    if [[ -f "${findings_file}" && -s "${findings_file}" ]]; then
        set_frontmatter_value "${findings_file}" "task_id" "${TASK_ID}"
        log_success "Findings generated: ${findings_file}"
    else
        log_warn "Findings empty. Using template."
        cat "${VAULT}/templates/findings.md" > "${findings_file}"
        set_frontmatter_value "${findings_file}" "task_id" "${TASK_ID}"
    fi
}

# ─── Gate: Review approval ────────────────────────────────────────────────────
gate_review() {
    local findings_file="${RUN_DIR}/findings.md"
    echo ""
    echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${YELLOW}${BOLD}  ⏸ GATE: Review Findings Approval Required${RESET}"
    echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [[ -x "${GATE_SCRIPT}" ]]; then
        if ! "${GATE_SCRIPT}" "review" "${findings_file}"; then
            die "Review rejected. Pipeline stopped."
        fi
    else
        echo ""
        if check_cmd bat; then
            bat --style=plain "${findings_file}"
        else
            cat "${findings_file}"
        fi
        echo ""
        while true; do
            read -r -p "$(echo -e "${YELLOW}Approve review findings? [y=yes / n=abort / e=edit]${RESET} ") " ans
            case "${ans,,}" in
                y|yes)
                    log_success "Review approved."
                    set_frontmatter_value "${findings_file}" "verdict" "APPROVED"
                    break
                    ;;
                n|no|abort)
                    die "Review rejected by user."
                    ;;
                e|edit)
                    "${EDITOR:-vi}" "${findings_file}"
                    ;;
                *)
                    echo "  Enter y, n, or e."
                    ;;
            esac
        done
    fi
}

# ─── Stage 6: PR ─────────────────────────────────────────────────────────────
stage_pr() {
    log_stage 6 "PR"

    if check_cmd just && [[ -f "${PROJECT_ROOT}/justfile" ]]; then
        if (cd "${PROJECT_ROOT}" && just --list 2>/dev/null | grep -q "^pr "); then
            log_info "Running: just pr ${TASK_ID}"
            (cd "${PROJECT_ROOT}" && just pr "${TASK_ID}") || log_warn "just pr failed."
            return 0
        fi
    fi

    if [[ -f "${PROJECT_ROOT}/scripts/package-pr.sh" ]]; then
        log_info "Running: scripts/package-pr.sh ${TASK_ID}"
        "${PROJECT_ROOT}/scripts/package-pr.sh" "${TASK_ID}" || log_warn "package-pr.sh failed."
        return 0
    fi

    log_warn "No PR script found. Manual steps:"
    echo ""
    echo "  1. git add -A"
    echo "  2. git commit -m 'feat(${TASK_ID}): implement task'"
    echo "  3. git push origin HEAD"
    echo "  4. gh pr create --title '${TASK_ID}' --body 'See .ai/runs/${TASK_ID}/'"
    echo ""
}

# ─── Copy artifacts to vault ─────────────────────────────────────────────────
copy_artifacts_to_vault() {
    local active_dir="${ACTIVE}/${TASK_ID}"
    mkdir -p "${active_dir}"

    local artifacts=("plan.md" "tasks.md" "test-report.md" "findings.md")
    for artifact in "${artifacts[@]}"; do
        if [[ -f "${RUN_DIR}/${artifact}" ]]; then
            cp "${RUN_DIR}/${artifact}" "${active_dir}/${artifact}"
            log_success "Copied ${artifact} → vault/01-active/${TASK_ID}/${artifact}"
        fi
    done
}

# ─── Finalize ─────────────────────────────────────────────────────────────────
finalize() {
    log_stage "✓" "Complete"

    # Move active note and artifacts to done
    local active_note="${ACTIVE}/${TASK_ID}.md"
    local active_dir="${ACTIVE}/${TASK_ID}"
    local done_dir="${DONE}/${TASK_ID}"

    mkdir -p "${DONE}"

    if [[ -f "${active_note}" ]]; then
        set_frontmatter_value "${active_note}" "status" "done"
        mv "${active_note}" "${DONE}/${TASK_ID}.md"
        log_success "Moved brief to 02-done/"
    fi

    if [[ -d "${active_dir}" ]]; then
        mv "${active_dir}" "${done_dir}" 2>/dev/null || true
        log_success "Moved artifacts to 02-done/${TASK_ID}/"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}${BOLD}  Pipeline complete for ${TASK_ID}${RESET}"
    echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "  Run artifacts: ${BOLD}${RUN_DIR}/${RESET}"
    echo -e "  Vault note:    ${BOLD}${DONE}/${TASK_ID}.md${RESET}"
    echo ""
}

# ─── Main pipeline ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}AI Dev OS Pipeline${RESET} — Task: ${CYAN}${BOLD}${TASK_ID}${RESET}"
if [[ $FROM_STAGE -gt 0 ]]; then
    echo -e "  Starting from stage: ${FROM_STAGE}"
fi
echo ""

run_stage() {
    local stage_num="$1"
    local fn="$2"
    if [[ $stage_num -ge $FROM_STAGE ]]; then
        "$fn"
    else
        log_info "Skipping stage ${stage_num} (--from-stage ${FROM_STAGE})"
    fi
}

run_stage 0 stage_check_brief
run_stage 1 stage_plan
[[ $FROM_STAGE -le 1 ]] && gate_plan
copy_artifacts_to_vault
run_stage 2 stage_tasks
copy_artifacts_to_vault
run_stage 3 stage_code
run_stage 4 stage_tests
copy_artifacts_to_vault
run_stage 5 stage_review
[[ $FROM_STAGE -le 5 ]] && gate_review
copy_artifacts_to_vault
run_stage 6 stage_pr

finalize
