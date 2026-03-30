#!/usr/bin/env bash
# issues.sh — GitHub issues manager with Claude analysis
# Fetches open issues, analyzes them via Claude, lets user pick with fzf,
# auto-generates briefs, and kicks off the roi pipeline for each selection.
#
# Usage:
#   ./scripts/issues.sh              — full flow: list → fzf select → pipeline
#   ./scripts/issues.sh list         — fetch + analyze, print table
#   ./scripts/issues.sh run <N...>   — run pipeline for specific issue numbers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SELF_CONFIG="${PROJECT_ROOT}/.ai/self/config.json"
VAULT="${PROJECT_ROOT}/vault"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
info() { echo -e "  ${CYAN}[issues]${RESET} $*"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*" >&2; }

# ─── Guards ───────────────────────────────────────────────────────────────────

_check_deps() {
    local missing=0
    command -v gh     &>/dev/null || { err "gh CLI not found.  brew install gh / apt install gh"; missing=1; }
    command -v fzf    &>/dev/null || { err "fzf not found.     brew install fzf / apt install fzf"; missing=1; }
    command -v claude &>/dev/null || { err "claude CLI not found. https://claude.ai/code"; missing=1; }
    [[ $missing -eq 0 ]] || exit 1
    gh auth status &>/dev/null || { err "gh not authorized. Run: gh auth login"; exit 1; }
}

_load_config() {
    [[ -f "${SELF_CONFIG}" ]] || { err "Self config not found. Run: just self init"; exit 1; }
    GITHUB_REPO="$(python3 -c "import json; print(json.load(open('${SELF_CONFIG}')).get('github_repo',''))")"
    PROJECT_NAME="$(python3 -c "import json; print(json.load(open('${SELF_CONFIG}')).get('project_name',''))")"
    WORKSPACE_PATH="$(python3 -c "import json; print(json.load(open('${SELF_CONFIG}')).get('workspace_path',''))")"
    [[ -n "${GITHUB_REPO}" ]] || { err "github_repo not set in config. Reinit: just self init"; exit 1; }
}

# ─── Fetch ────────────────────────────────────────────────────────────────────

_fetch_issues() {
    info "Fetching issues from ${GITHUB_REPO}..."
    gh issue list \
        --repo "${GITHUB_REPO}" \
        --state open \
        --limit 60 \
        --json number,title,body,labels,comments,createdAt,assignees,milestone
}

# ─── Analyze ──────────────────────────────────────────────────────────────────
# Returns one line per issue: NUMBER|TYPE|PRIORITY|COMPLEXITY|SUMMARY

_analyze_issues() {
    local issues_json="$1"
    info "Analyzing via Claude..."

    local count
    count=$(echo "${issues_json}" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
    info "${count} issues — running analysis..."

    claude --print --no-markdown \
"Analyze these GitHub issues for the roi project (AI Dev OS — shell-based AI development pipeline toolkit).

For EACH issue output EXACTLY one line in this format, nothing else:
{number}|{type}|{priority}|{complexity}|{summary}

Allowed values:
- type:       bug | feature | refactor | docs | chore
- priority:   p0 | p1 | p2 | p3     (p0=critical, p1=important, p2=normal, p3=minor)
- complexity: xs | s | m | l | xl   (xs≈1h, s≈half-day, m≈1day, l≈2-3days, xl≈week+)
- summary:    max 60 chars, action-oriented (e.g. 'Fix canvas race condition on parallel runs')

No headers, no explanations, no blank lines. One line per issue.

Issues JSON:
${issues_json}"
}

# ─── Format for fzf ───────────────────────────────────────────────────────────
# Output: DISPLAY_LINE TAB NUMBER  (fzf uses TAB as delimiter)

_format_for_fzf() {
    local issues_json="$1"
    local analysis="$2"

    python3 - <<PYEOF
import json, sys

issues = $(echo "${issues_json}" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))")
analysis_raw = """${analysis}"""

# Parse analysis lines
analysis = {}
for line in analysis_raw.strip().splitlines():
    line = line.strip()
    if not line or "|" not in line:
        continue
    parts = line.split("|", 4)
    if len(parts) == 5:
        try:
            analysis[int(parts[0])] = {
                "type":       parts[1].strip(),
                "priority":   parts[2].strip(),
                "complexity": parts[3].strip(),
                "summary":    parts[4].strip(),
            }
        except ValueError:
            pass

TYPE_ICON  = {"bug":"🐛","feature":"✨","refactor":"♻️ ","docs":"📝","chore":"🔧"}
PRIO_ICON  = {"p0":"🔴","p1":"🟠","p2":"🟡","p3":"⚪"}
PRIO_ORDER = {"p0":0,"p1":1,"p2":2,"p3":3,"":4}

def sort_key(issue):
    a = analysis.get(issue["number"], {})
    return (PRIO_ORDER.get(a.get("priority",""),4), issue["number"])

for issue in sorted(issues, key=sort_key):
    num  = issue["number"]
    a    = analysis.get(num, {})
    t    = a.get("type","?")
    p    = a.get("priority","?")
    cx   = a.get("complexity","?")
    summ = a.get("summary", issue["title"])[:58]
    ti   = TYPE_ICON.get(t, "❓")
    pi   = PRIO_ICON.get(p, "⚪")
    print(f"#{num:4d}  {pi} {ti}  [{cx:<2}]  {summ:<58}\t{num}")
PYEOF
}

# ─── fzf picker ───────────────────────────────────────────────────────────────

_pick_issues() {
    local issues_json="$1"
    local fzf_lines="$2"

    # Write issues to temp file for the preview script
    local tmp_json
    tmp_json="$(mktemp /tmp/roi-issues-XXXX.json)"
    echo "${issues_json}" > "${tmp_json}"

    local preview_cmd
    preview_cmd="python3 -c \"
import json, sys
num = int('{}')
num = int('{}'.split()[-1].split('\t')[-1]) if '\t' in '{}' else num
issues = json.load(open('${tmp_json}'))
for i in issues:
    if i['number'] == num:
        labels = ', '.join(l['name'] for l in i.get('labels',[]))
        print(f'#{i[\"number\"]} — {i[\"title\"]}')
        print(f'Labels:   {labels or \"—\"}')
        print(f'Comments: {i.get(\"comments\",0)}')
        print()
        body = (i.get('body') or '(no description)')[:1000]
        print(body)
        break
\""

    local selected
    selected=$(echo "${fzf_lines}" | \
        fzf --multi \
            --ansi \
            --header "TAB = select/deselect  ·  ENTER = confirm  ·  ESC = cancel" \
            --prompt "Issues → " \
            --delimiter $'\t' \
            --with-nth 1 \
            --preview "num=\$(echo {} | awk -F'\t' '{print \$NF}'); python3 -c \"
import json
issues = json.load(open('${tmp_json}'))
for i in issues:
    if i['number'] == int('\$num'):
        labels = ', '.join(l['name'] for l in i.get('labels',[]))
        print(f'Issue #\$num — {i[\\\"title\\\"]}')
        print(f'Labels:   {labels or \\\"—\\\"}')
        print(f'Comments: {i.get(\\\"comments\\\",0)}')
        print()
        body = (i.get('body') or '(no description)')[:1200]
        print(body)
        break
\"" \
            --preview-window "right:50%:wrap" \
        | awk -F'\t' '{print $NF}') || true

    rm -f "${tmp_json}"
    echo "${selected}"
}

# ─── Brief generation ─────────────────────────────────────────────────────────

_generate_brief() {
    local issue_num="$1"
    local issue_json="$2"
    local task_id="ISSUE-${issue_num}"
    local inbox="${VAULT}/projects/${PROJECT_NAME}/00-inbox"
    local run_dir="${PROJECT_ROOT}/.ai/runs/${PROJECT_NAME}/${task_id}"

    mkdir -p "${inbox}" "${run_dir}"

    local brief_path="${inbox}/${task_id}.md"

    if [[ -f "${brief_path}" ]]; then
        warn "Brief already exists: ${brief_path} — skipping generation"
        echo "${brief_path}"
        return
    fi

    info "Generating brief for #${issue_num}..."

    local today
    today="$(date +%Y-%m-%d)"

    local brief_content
    brief_content=$(claude --print --no-markdown \
"Generate a brief.md for this GitHub issue. It will be processed by the roi AI Dev OS pipeline — a shell-based AI development toolkit. The work happens in the roi project itself (self-improvement).

Output ONLY the markdown, no explanations, no code fences around the whole file.

Required format exactly:
---
task_id: ${task_id}
type: <feature|bugfix|refactor|docs|chore>
priority: <p0|p1|p2|p3>
status: ready
created: ${today}
---

# <concise action-oriented title>

## Goal
<2-4 sentences: what needs to be done and what the outcome should be>

## Context
<why this matters, what triggers it, relevant existing code or behavior>

## Acceptance criteria
- [ ] <specific, testable criterion>
- [ ] <specific, testable criterion>
- [ ] tests pass (bash tests/run_tests.sh)

## GitHub
Issue: https://github.com/${GITHUB_REPO}/issues/${issue_num}

---

Issue data:
${issue_json}")

    echo "${brief_content}" > "${brief_path}"
    ok "Brief created: ${brief_path}"
    echo "${brief_path}"
}

# ─── Commands ─────────────────────────────────────────────────────────────────

cmd_list() {
    _check_deps
    _load_config

    local issues_json
    issues_json="$(_fetch_issues)"

    local analysis
    analysis="$(_analyze_issues "${issues_json}")"

    echo ""
    echo -e "  ${BOLD}#      Pri  Type   Size  Summary${RESET}"
    echo -e "  ──────────────────────────────────────────────────────────────────"
    _format_for_fzf "${issues_json}" "${analysis}" | awk -F'\t' '{print "  " $1}'
    echo ""
}

cmd_run() {
    _check_deps
    _load_config

    local issue_numbers=("$@")
    [[ ${#issue_numbers[@]} -gt 0 ]] || { err "Provide numbers: just issues run 42 15 7"; exit 1; }

    # Make roi-dev the active project so pipeline routes correctly
    echo -n "${PROJECT_NAME}" > "${PROJECT_ROOT}/.ai/state/current"

    local issues_json
    issues_json="$(_fetch_issues)"

    for num in "${issue_numbers[@]}"; do
        local issue_json
        issue_json=$(echo "${issues_json}" | python3 -c "
import json, sys
for i in json.load(sys.stdin):
    if i['number'] == int('${num}'):
        print(json.dumps(i, ensure_ascii=False))
        break
")
        if [[ -z "${issue_json}" ]]; then
            warn "Issue #${num} not found in open issues — skipping"
            continue
        fi

        local task_id="ISSUE-${num}"
        _generate_brief "${num}" "${issue_json}" > /dev/null

        info "Running pipeline: ${task_id}..."
        bash "${SCRIPT_DIR}/go.sh" "${task_id}"
        ok "Pipeline completed: ${task_id}"
        echo ""
    done

    ok "All issues processed."
    echo -e "  Commit and update: ${CYAN}just self sync${RESET}"
}

cmd_default() {
    _check_deps
    _load_config

    local issues_json
    issues_json="$(_fetch_issues)"

    local count
    count=$(echo "${issues_json}" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
    ok "${count} open issues in ${GITHUB_REPO}"

    local analysis
    analysis="$(_analyze_issues "${issues_json}")"

    local fzf_lines
    fzf_lines="$(_format_for_fzf "${issues_json}" "${analysis}")"

    echo ""
    info "Select issues to work on (TAB = multi-select, ENTER = confirm)..."
    echo ""

    local selected
    selected="$(_pick_issues "${issues_json}" "${fzf_lines}")"

    if [[ -z "${selected}" ]]; then
        warn "Nothing selected. Exiting."
        exit 0
    fi

    local nums=()
    while IFS= read -r n; do
        [[ -n "$n" ]] && nums+=("$n")
    done <<< "${selected}"

    echo ""
    ok "Selected: ${#nums[@]} issue(s) — ${nums[*]}"
    echo ""
    echo -n "  Run pipeline? [y/N] "
    read -r confirm
    [[ "${confirm}" == "y" || "${confirm}" == "Y" ]] || { warn "Cancelled."; exit 0; }

    cmd_run "${nums[@]}"
}

# ─── Entry point ──────────────────────────────────────────────────────────────

_main() {
    local cmd="${1:-}"
    [[ -n "$cmd" ]] && shift || true

    case "$cmd" in
        list)  cmd_list ;;
        run)   cmd_run "$@" ;;
        "")    cmd_default ;;
        *)
            err "Unknown command: $cmd"
            echo -e "Usage: issues [list | run <N...>]"
            exit 1
            ;;
    esac
}

_main "$@"
