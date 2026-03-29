#!/usr/bin/env bash
# help.sh — command reference for Hive Drill
set -euo pipefail

BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

h()  { echo -e "${BOLD}$*${RESET}"; }
g()  { echo -e "  ${GREEN}$*${RESET}"; }
c()  { echo -e "  ${CYAN}$*${RESET}"; }
ln() { echo -e "  ${YELLOW}──────────────────────────────────────────────────────${RESET}"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           🐝  Hive Drill — command reference        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"

echo ""
h "  MAIN WORKFLOW"
ln
g "  just new <TASK-ID>              " "Create task (brief in Obsidian)"
g "  just go  <TASK-ID>              " "Full pipeline: Brief→Plan→Tasks→Code→Tests→Review→PR"
g "  just go-from <ID> <stage>       " "Resume from a specific stage (0–6)"
g "  just history <TASK-ID>          " "Checkpoint history + time travel"

echo ""
h "  PROJECTS"
ln
g "  just project add <name> <path>  " "Register a project"
g "  just project switch <name>      " "Switch active project"
g "  just project list               " "List all projects"
g "  just project current            " "Show active project"
g "  just project info [name]        " "Project details"
g "  just project remove <name>      " "Remove from registry"

echo ""
h "  SELF-IMPROVE  (roi works on itself)"
ln
g "  just self init                  " "Clone roi → workspace/roi-dev/"
c "    --repo <git-url>              " "Git remote to clone from"
c "    --github owner/repo           " "GitHub repo for issues"
g "  just self update                " "git pull workspace"
g "  just self status                " "Workspace status + active runs"
g "  just self sync                  " "Commit+push workspace, pull self"

echo ""
h "  ISSUES"
ln
g "  just issues                     " "Full flow: analyse → fzf select → pipeline"
g "  just issues list                " "Show list with Claude analysis"
g "  just issues run 42 15 7         " "Run pipeline for specific issues"

echo ""
h "  DOCS & CANVAS"
ln
g "  just arch                       " "Architecture diagram of active project"
g "  just arch-of <path>             " "Diagram for an arbitrary project"
g "  just docs                       " "Update docs in vault (no canvas)"

echo ""
h "  STATUS & CHECKS"
ln
g "  just status                     " "Agents, LLM, MCP, active runs"
g "  just check [--quick]            " "lint + tests + secrets"
g "  just test [suite...]            " "Run tests (built-in runner)"

echo ""
h "  WORKTREES"
ln
g "  just wt-create <TASK-ID>        " "Create git worktree"
g "  just wt-list                    " "List worktrees"
g "  just wt-clean  <TASK-ID>        " "Remove worktree"

echo ""
h "  LOCAL LLM"
ln
g "  just llm-up                     " "TabbyAPI + coder 7B"
g "  just llm-writer                 " "TabbyAPI + writer 14B"
g "  just llm-test                   " "Test endpoint"
g "  just llm-tunnel                 " "Cloudflare tunnel"

echo ""
h "  SETUP"
ln
g "  just setup                      " "Full system initialisation"
g "  just setup-mcp                  " "MCP servers only"
g "  just setup-gsd                  " "GSD hooks only"
g "  just completions                " "Install shell completions (bash/zsh/fish)"
g "  just man                        " "just man page"

echo ""
c "  More: just --list  |  just man  |  https://just.systems/man/en/"
echo ""
