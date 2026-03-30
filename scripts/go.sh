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
    echo "Usage: $0 <TASK-ID> [--from-stage <0-6>] [--workspace <path|self>]"
    exit 1
fi

TASK_ID="$1"
FROM_STAGE=0
WORKSPACE_OVERRIDE=""   # set via --workspace flag

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --from-stage)
            FROM_STAGE="${2:-0}"
            shift 2
            ;;
        --workspace)
            WORKSPACE_OVERRIDE="${2:-}"
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

# Load .env (justfile loads it too, but direct calls need this)
[[ -f "${PROJECT_ROOT}/.env" ]] && set -a && source "${PROJECT_ROOT}/.env" 2>/dev/null && set +a || true

# TARGET_ROOT — codebase where agents read/write code.
# Priority: --workspace flag > brief frontmatter > WORKSPACE in .env > PROJECT_ROOT
resolve_target_root() {
    local ws="${1:-}"
    if [[ -z "$ws" ]] || [[ "$ws" == "self" ]]; then
        echo "${PROJECT_ROOT}"
        return
    fi
    if [[ "$ws" = /* ]]; then
        echo "$ws"
    else
        echo "${PROJECT_ROOT}/${ws}"
    fi
}

# ─── Project context ─────────────────────────────────────────────────────────
# shellcheck source=project.sh
source "${SCRIPT_DIR}/project.sh" 2>/dev/null || true
# shellcheck source=detect-platform.sh
source "${SCRIPT_DIR}/detect-platform.sh"
ACTIVE_PROJECT="${ACTIVE_PROJECT:-}"
PROJECT_PATH="${PROJECT_PATH:-}"
roi_project_context 2>/dev/null || true

[[ -z "${ACTIVE_PROJECT}" ]] && die "No active project.\n  Set one first: just project switch <name>\n  Or register:   just project add <name> <path>"

# ─── Workspace / TARGET_ROOT ──────────────────────────────────────────────────
# Priority: --workspace flag > project path > WORKSPACE in .env > PROJECT_ROOT
if [[ -n "${WORKSPACE_OVERRIDE}" ]]; then
    TARGET_ROOT="$(resolve_target_root "${WORKSPACE_OVERRIDE}")"
elif [[ -n "${PROJECT_PATH:-}" ]]; then
    TARGET_ROOT="${PROJECT_PATH}"
elif [[ -n "${WORKSPACE:-}" ]]; then
    TARGET_ROOT="$(resolve_target_root "${WORKSPACE}")"
else
    TARGET_ROOT="${PROJECT_ROOT}"
fi

if [[ "${TARGET_ROOT}" != "${PROJECT_ROOT}" ]] && [[ ! -d "${TARGET_ROOT}" ]]; then
    die "WORKSPACE not found: ${TARGET_ROOT}\n  Run: just clone <url> <name>"
fi

# ─── Namespaced paths ─────────────────────────────────────────────────────────
VAULT="${PROJECT_ROOT}/vault/projects/${ACTIVE_PROJECT}"
RUN_DIR="${PROJECT_ROOT}/.ai/runs/${ACTIVE_PROJECT}/${TASK_ID}"
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
    ${HIVE_SED_I} "s|^${key}:.*|${key}: ${value}|" "$file"
}

# ─── Stage retry (LangGraph retry_policy pattern) ────────────────────────────
# Usage: run_stage_with_retry <stage_num> <function_name> [max_retries]
# Applies to non-deterministic stages (codex, external tools).
run_stage_with_retry() {
    local stage_num="$1"
    local fn="$2"
    local max_retries="${3:-${STAGE_MAX_RETRIES:-2}}"

    if [[ $stage_num -lt $FROM_STAGE ]]; then
        log_info "Skipping stage ${stage_num} (--from-stage ${FROM_STAGE})"
        return 0
    fi

    local attempt=1
    local delay=5
    while true; do
        if "$fn"; then
            return 0
        fi
        if [[ $attempt -ge $max_retries ]]; then
            log_error "Stage ${stage_num} (${fn}) failed after ${max_retries} attempts."
            return 1
        fi
        log_warn "Stage ${stage_num} failed (attempt ${attempt}/${max_retries}). Retrying in ${delay}s..."
        sleep "${delay}"
        delay=$(( delay * 2 ))
        attempt=$(( attempt + 1 ))
    done
}

# ─── Checkpoint ──────────────────────────────────────────────────────────────
write_checkpoint() {
    local stage_num="$1"
    local stage_name="$2"
    local checkpoint_file="${RUN_DIR}/checkpoint.yml"
    cat > "${checkpoint_file}" <<YAML
task_id: ${TASK_ID}
project: ${ACTIVE_PROJECT}
last_completed_stage: ${stage_num}
last_completed_stage_name: ${stage_name}
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
resume_with: --from-stage $((stage_num + 1))
YAML
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

    # Read workspace override from brief frontmatter (only if not set via --workspace flag)
    if [[ -z "${WORKSPACE_OVERRIDE}" ]]; then
        local brief_ws
        brief_ws="$(get_frontmatter_value "${RUN_DIR}/brief.md" "workspace")"
        if [[ -n "${brief_ws}" ]]; then
            TARGET_ROOT="$(resolve_target_root "${brief_ws}")"
            if [[ "${TARGET_ROOT}" != "${PROJECT_ROOT}" ]] && [[ ! -d "${TARGET_ROOT}" ]]; then
                die "Brief 'workspace: ${brief_ws}' not found: ${TARGET_ROOT}"
            fi
            log_info "Workspace override from brief: ${TARGET_ROOT}"
        fi
    fi

    "${SCRIPT_DIR}/canvas-move.sh" "${TASK_ID}" "planning" 2>/dev/null || true
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

    # Gather project snapshot so claude -p has context without needing filesystem tools
    local project_snapshot
    project_snapshot="$(
        echo "=== Project: ${TARGET_ROOT} ==="
        echo ""
        echo "--- File tree (depth 4, excluding .git/node_modules/__pycache__) ---"
        find "${TARGET_ROOT}" \
            -not \( -name '.git' -prune \) \
            -not \( -name '__pycache__' -prune \) \
            -not \( -name 'node_modules' -prune \) \
            -not \( -name '.venv' -prune \) \
            -not -name '*.pyc' \
            -maxdepth 4 -print 2>/dev/null | sort | sed "s|${TARGET_ROOT}/||" | head -200
        echo ""
        # Key files
        for kf in package.json pyproject.toml setup.py Cargo.toml go.mod requirements.txt README.md; do
            if [[ -f "${TARGET_ROOT}/${kf}" ]]; then
                echo "--- ${kf} ---"
                head -60 "${TARGET_ROOT}/${kf}"
                echo ""
            fi
        done
    )"

    # Workspace directive for the prompt
    local workspace_directive
    if [[ "${TARGET_ROOT}" != "${PROJECT_ROOT}" ]]; then
        workspace_directive="You are planning changes to the TARGET PROJECT at: ${TARGET_ROOT}
Do NOT suggest changes to the AI Dev OS tool itself (at ${PROJECT_ROOT}).
All implementation steps must modify files inside ${TARGET_ROOT}."
    else
        workspace_directive="You are planning a meta-task on the AI Dev OS repo itself at: ${PROJECT_ROOT}"
    fi

    local prompt
    prompt="$(cat <<'PROMPT_EOF'
You are a senior software architect. Read the task brief and project snapshot below, then produce a detailed implementation plan.

WORKSPACE_DIRECTIVE_PLACEHOLDER

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
    prompt="${prompt/WORKSPACE_DIRECTIVE_PLACEHOLDER/${workspace_directive}}"

    local full_prompt="${prompt}

$(cat "${brief_file}")

PROJECT SNAPSHOT:
${project_snapshot}"

    # claude -p = non-interactive print mode (doesn't wait for terminal)
    local tmp_prompt
    tmp_prompt=$(mktemp)
    echo "${full_prompt}" > "${tmp_prompt}"
    if ! claude -p "$(cat "${tmp_prompt}")" > "${plan_file}" 2>/dev/null; then
        log_warn "Claude returned an error. Check ${plan_file} manually."
    fi
    rm -f "${tmp_prompt}"

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

# ─── Plan validators ─────────────────────────────────────────────────────────
# Runs two fast claude agents in parallel before gate:
#   - reality-check: is the plan realistic?
#   - completeness:  are there missing risks or steps?
# Output is informational (does not block pipeline).
validate_plan() {
    local plan_file="${RUN_DIR}/plan.md"

    if ! check_cmd claude || [[ ! -f "${plan_file}" ]]; then
        return 0
    fi

    echo ""
    echo -e "  ${CYAN}Running plan validators...${RESET}"

    local reality_out="${RUN_DIR}/validate-reality.md"
    local completeness_out="${RUN_DIR}/validate-completeness.md"

    local reality_prompt
    reality_prompt="You are a reality-check reviewer. Read this implementation plan and answer in 5-10 lines:
1. Is the chosen approach realistic given the stated constraints?
2. Are the implementation steps achievable in the described scope?
3. Any hidden complexity or wrong assumptions?
Reply concisely. Start with PASS or WARN.

PLAN:
$(cat "${plan_file}")"

    local completeness_prompt
    completeness_prompt="You are a completeness reviewer. Read this implementation plan and answer in 5-10 lines:
1. Are there missing steps that will be obviously needed?
2. Are all stated risks covered with mitigations?
3. Is the test strategy sufficient for the described changes?
Reply concisely. Start with PASS or WARN.

PLAN:
$(cat "${plan_file}")"

    # Run both validators in parallel
    local tmp_r tmp_c
    tmp_r=$(mktemp)
    tmp_c=$(mktemp)

    claude -p "${reality_prompt}" > "${reality_out}" 2>/dev/null &
    local pid_r=$!
    claude -p "${completeness_prompt}" > "${completeness_out}" 2>/dev/null &
    local pid_c=$!

    wait "${pid_r}" 2>/dev/null || true
    wait "${pid_c}" 2>/dev/null || true
    rm -f "${tmp_r}" "${tmp_c}"

    # Display results
    local any_warn=false
    for f in "${reality_out}" "${completeness_out}"; do
        local label
        [[ "$f" == "${reality_out}" ]] && label="Reality" || label="Completeness"
        if [[ -f "$f" && -s "$f" ]]; then
            local first_line
            first_line="$(head -1 "$f")"
            if echo "${first_line}" | grep -qi "^warn"; then
                log_warn "[${label}] ${first_line}"
                any_warn=true
            else
                log_success "[${label}] ${first_line}"
            fi
        fi
    done

    if [[ "$any_warn" == true ]]; then
        echo ""
        echo -e "  ${YELLOW}Validator warnings found. Review before approving:${RESET}"
        echo -e "  ${YELLOW}  ${reality_out}${RESET}"
        echo -e "  ${YELLOW}  ${completeness_out}${RESET}"
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

    local tmp_prompt
    tmp_prompt=$(mktemp)
    echo "${full_prompt}" > "${tmp_prompt}"
    if ! claude -p "$(cat "${tmp_prompt}")" > "${tasks_file}" 2>/dev/null; then
        log_warn "Claude returned an error generating tasks."
    fi
    rm -f "${tmp_prompt}"

    if [[ -f "${tasks_file}" && -s "${tasks_file}" ]]; then
        log_success "Tasks generated: ${tasks_file}"
    else
        log_warn "Tasks file empty. Creating template."
        echo "# Tasks: ${TASK_ID}" > "${tasks_file}"
    fi
}

# ─── Safety: guard against self-modification ─────────────────────────────────
guard_workspace() {
    if [[ "${TARGET_ROOT}" == "${PROJECT_ROOT}" ]]; then
        echo ""
        echo -e "${RED}${BOLD}┌─────────────────────────────────────────────────┐${RESET}"
        echo -e "${RED}${BOLD}│  ⚠  WARNING: No WORKSPACE set                   │${RESET}"
        echo -e "${RED}${BOLD}│                                                  │${RESET}"
        echo -e "${RED}${BOLD}│  Codex will write code into THIS roi/ directory. │${RESET}"
        echo -e "${RED}${BOLD}│  That means the AI Dev OS itself may be changed. │${RESET}"
        echo -e "${RED}${BOLD}│                                                  │${RESET}"
        echo -e "${RED}${BOLD}│  To target a real project:                       │${RESET}"
        echo -e "${RED}${BOLD}│    just clone <url> <name>                       │${RESET}"
        echo -e "${RED}${BOLD}│    # or: echo WORKSPACE=workspace/myapp >> .env  │${RESET}"
        echo -e "${RED}${BOLD}└─────────────────────────────────────────────────┘${RESET}"
        echo ""
        if [[ ! -t 0 ]]; then
            die "WORKSPACE not set and stdin is not a terminal. Aborting to prevent self-modification."
        fi
        read -r -p "$(echo -e "${RED}Continue anyway and modify roi/ itself? [yes/N]${RESET} ") " ans
        if [[ "${ans}" != "yes" ]]; then
            die "Aborted. Set WORKSPACE in .env and re-run."
        fi
        log_warn "Proceeding with TARGET_ROOT=PROJECT_ROOT (self-modification mode)."
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
    log_info "Working in workspace: ${TARGET_ROOT}"

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

    # codex exec = non-interactive mode
    local tmp_prompt
    tmp_prompt=$(mktemp)
    echo "${full_prompt}" > "${tmp_prompt}"
    if ! (cd "${TARGET_ROOT}" && codex exec --skip-git-repo-check --sandbox workspace-write "$(cat "${tmp_prompt}")" 2>&1 | tee "${code_log}"); then
        log_warn "Codex exited with error. Check ${code_log}"
    else
        log_success "Codex finished. See ${code_log}"
    fi
    rm -f "${tmp_prompt}"
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
        if (cd "${TARGET_ROOT}" && "$@" >> "${test_report}" 2>&1); then
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
    if [[ -f "${TARGET_ROOT}/package.json" ]]; then
        if check_cmd npm; then
            run_check "npm test" npm test --if-present
            run_check "npm lint" npm run lint --if-present
        fi
        if check_cmd npx; then
            run_check "TypeScript check" npx tsc --noEmit 2>/dev/null || true
        fi
    fi

    if [[ -f "${TARGET_ROOT}/Cargo.toml" ]]; then
        if check_cmd cargo; then
            run_check "cargo test" cargo test
            run_check "cargo clippy" cargo clippy -- -D warnings
        fi
    fi

    if [[ -f "${TARGET_ROOT}/pyproject.toml" ]] || [[ -f "${TARGET_ROOT}/setup.py" ]]; then
        if check_cmd pytest; then
            run_check "pytest" pytest
        fi
        if check_cmd ruff; then
            run_check "ruff check" ruff check .
        fi
    fi

    if [[ -f "${TARGET_ROOT}/go.mod" ]]; then
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
        diff_output="$(cd "${TARGET_ROOT}" && git diff HEAD 2>/dev/null || true)"
        if [[ -z "$diff_output" ]]; then
            diff_output="$(cd "${TARGET_ROOT}" && git diff 2>/dev/null || true)"
        fi
    fi

    log_info "Calling Claude to review changes in ${TARGET_ROOT}..."

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

    local tmp_prompt
    tmp_prompt=$(mktemp)
    echo "${full_prompt}" > "${tmp_prompt}"
    if ! claude -p "$(cat "${tmp_prompt}")" > "${findings_file}" 2>/dev/null; then
        log_warn "Claude review returned an error."
    fi
    rm -f "${tmp_prompt}"

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

    local artifacts=("plan.md" "tasks.md" "test-report.md" "findings.md" "decisions.md")
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
if [[ "${TARGET_ROOT}" != "${PROJECT_ROOT}" ]]; then
    echo -e "  Workspace: ${CYAN}${TARGET_ROOT}${RESET}"
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
[[ $FROM_STAGE -le 0 ]] && write_checkpoint 0 "brief"
# Brief found → card already in planning (moved to stage_check_brief)

run_stage 1 stage_plan
[[ $FROM_STAGE -le 1 ]] && validate_plan
[[ $FROM_STAGE -le 1 ]] && gate_plan
[[ $FROM_STAGE -le 1 ]] && write_checkpoint 1 "plan"
copy_artifacts_to_vault

run_stage 2 stage_tasks
[[ $FROM_STAGE -le 2 ]] && write_checkpoint 2 "tasks"
copy_artifacts_to_vault
"${SCRIPT_DIR}/canvas-move.sh" "${TASK_ID}" "inprogress" 2>/dev/null || true

# Safety check before any agent writes code (only when codex is available)
[[ $FROM_STAGE -le 3 ]] && check_cmd codex && guard_workspace

# ─── Execution + Review loop (crewAI @router pattern) ────────────────────────
# If gate_review returns exit 2 (request_changes), loop back to stage 3.
# Mirrors LangGraph: nodes can be re-entered after human interrupt + state update.
MAX_REVIEW_LOOPS="${MAX_REVIEW_LOOPS:-2}"
REVIEW_LOOP=0

while true; do
    REVIEW_LOOP=$(( REVIEW_LOOP + 1 ))
    if [[ $REVIEW_LOOP -gt 1 ]]; then
        log_stage "↺" "Revision loop ${REVIEW_LOOP}/${MAX_REVIEW_LOOPS}"
    fi

    run_stage_with_retry 3 stage_code
    [[ $FROM_STAGE -le 3 ]] && write_checkpoint 3 "code"
    run_stage_with_retry 4 stage_tests
    [[ $FROM_STAGE -le 4 ]] && write_checkpoint 4 "tests"
    copy_artifacts_to_vault
    "${SCRIPT_DIR}/canvas-move.sh" "${TASK_ID}" "review" 2>/dev/null || true

    run_stage 5 stage_review

    # Capture gate exit code (gate.sh: 0=approved 1=rejected 2=request_changes 3=escalate)
    gate_exit=0
    if [[ $FROM_STAGE -le 5 ]]; then
        if [[ -x "${GATE_SCRIPT}" ]]; then
            "${GATE_SCRIPT}" "review" "${RUN_DIR}/findings.md" || gate_exit=$?
        else
            # Inline fallback when gate.sh is unavailable
            echo -e "${YELLOW}${BOLD}  y${RESET} = approve   ${YELLOW}${BOLD}r${RESET} = request changes   ${YELLOW}${BOLD}n${RESET} = abort"
            while true; do
                read -r -p "$(echo -e "${YELLOW}Decision for review: ${RESET}")" _ans
                case "${_ans,,}" in
                    y|yes)   gate_exit=0; break ;;
                    r|request) gate_exit=2; break ;;
                    n|no|abort) gate_exit=1; break ;;
                    *) echo "  Enter y, r, or n." ;;
                esac
            done
        fi
    fi

    if [[ $gate_exit -eq 0 ]]; then
        write_checkpoint 5 "review"
        copy_artifacts_to_vault
        "${SCRIPT_DIR}/canvas-move.sh" "${TASK_ID}" "done" 2>/dev/null || true
        break
    elif [[ $gate_exit -eq 2 ]]; then
        if [[ $REVIEW_LOOP -ge $MAX_REVIEW_LOOPS ]]; then
            die "Max revision loops (${MAX_REVIEW_LOOPS}) reached. Stopping pipeline."
        fi
        log_warn "Revision requested. Looping back to Stage 3 (attempt ${REVIEW_LOOP}/${MAX_REVIEW_LOOPS})."
        # Reset FROM_STAGE so stages 3-5 run again
        FROM_STAGE=3
        continue
    else
        die "Gate rejected or escalated (exit ${gate_exit}). Pipeline stopped."
    fi
done

run_stage 6 stage_pr

finalize
