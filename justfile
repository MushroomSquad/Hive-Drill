# 🐝 Hive Drill — AI development pipeline
# Install: cargo install just  # or: brew install just / apt install just
# Run:     just <command>
# Help:    just help

set dotenv-load := true
set positional-arguments := true

# ─── Help ───────────────────────────────────────────────────────────

# Show help for all commands
help:
    @./scripts/help.sh

# ─── Man & completions ──────────────────────────────────────────────

# Open just man page
man:
    @just --man | man -l -

# Install shell completions (bash / zsh / fish)
completions:
    #!/usr/bin/env bash
    shell="$(basename "${SHELL:-bash}")"
    case "$shell" in
      fish)
        dir="${HOME}/.config/fish/completions"
        mkdir -p "$dir"
        just --completions fish > "$dir/just.fish"
        echo "✓ Fish completions → $dir/just.fish"
        echo "  Restart fish or: source $dir/just.fish"
        ;;
      zsh)
        dir="${HOME}/.zsh/completions"
        mkdir -p "$dir"
        just --completions zsh > "$dir/_just"
        echo "✓ Zsh completions → $dir/_just"
        echo "  Add to ~/.zshrc if not already there:"
        echo "    fpath=(~/.zsh/completions \$fpath)"
        echo "    autoload -Uz compinit && compinit"
        ;;
      bash)
        dir="${HOME}/.local/share/bash-completion/completions"
        mkdir -p "$dir"
        just --completions bash > "$dir/just"
        echo "✓ Bash completions → $dir/just"
        echo "  Restart bash or: source $dir/just"
        ;;
      *)
        echo "Shell '${shell}' is not supported automatically."
        echo "Available options:"
        echo "  just --completions bash > ~/.local/share/bash-completion/completions/just"
        echo "  just --completions zsh  > ~/.zsh/completions/_just"
        echo "  just --completions fish > ~/.config/fish/completions/just.fish"
        ;;
    esac

# ─── Main workflow ───────────────────────────────────────────────────

# Create a new task (brief in Obsidian, card on kanban)
new task_id:
    @./scripts/new.sh "{{task_id}}"

# Run full pipeline: Brief→Plan→Tasks→Code→Tests→Review→PR
go task_id:
    @./scripts/go.sh "{{task_id}}"

# Resume pipeline from a specific stage (0=Brief, 1=Plan, 2=Tasks, 3=Code, 4=Tests, 5=Review, 6=PR)
go-from task_id stage:
    @./scripts/go.sh "{{task_id}}" --from-stage "{{stage}}"

# Task checkpoint history + time travel commands
history task_id:
    @./scripts/history.sh "{{task_id}}"

# ─── Tests ──────────────────────────────────────────────────────────

# Run tests (built-in runner, no dependencies)
test *suites:
    @bash tests/run_tests.sh {{suites}}

# ─── Status ─────────────────────────────────────────────────────────

# Status of agents, LLM, MCP, active runs
status:
    @./scripts/status.sh

# lint + typecheck + tests + secrets (full done-criteria check)
check *args:
    @./scripts/ai-check.sh {{args}}

# ─── Worktrees ──────────────────────────────────────────────────────

# Create a git worktree for a task
wt-create task_id:
    @./scripts/worktree.sh create "{{task_id}}"

# List active worktrees
wt-list:
    @./scripts/worktree.sh list

# Remove a task worktree
wt-clean task_id:
    @./scripts/worktree.sh clean "{{task_id}}"

# ─── Local LLM ──────────────────────────────────────────────────────

# Start TabbyAPI with coder profile (Qwen2.5-Coder 7B)
llm-up:
    @./llm/profiles/tabbyapi-coder.sh

# Start TabbyAPI with writer profile (Qwen2.5 14B)
llm-writer:
    @./llm/profiles/tabbyapi-writer.sh

# Test LLM endpoint
llm-test:
    @./llm/scripts/test-endpoint.sh tabbyapi

# Cloudflare tunnel for remote access to TabbyAPI
llm-tunnel:
    @./llm/cursor/tunnel.sh tabbyapi cloudflared

# ─── Docs & Canvas ──────────────────────────────────────────────────

# Generate architecture canvas for the active project
arch:
    @./scripts/canvas-arch.sh

# Generate architecture canvas for an arbitrary external project
arch-of project:
    @./scripts/canvas-arch.sh "{{project}}"

# Update docs/ in vault without regenerating canvas
docs:
    @./scripts/canvas-arch.sh --docs

# ─── Workspace (target project) ─────────────────────────────────────

# Clone an external project into workspace/ and set WORKSPACE in .env
clone url name="project":
    #!/usr/bin/env bash
    mkdir -p workspace
    git clone "{{url}}" "workspace/{{name}}"
    source "$(dirname "$0")/scripts/detect-platform.sh"
    if [ -f .env ]; then
        if grep -q "^WORKSPACE=" .env; then
            ${HIVE_SED_I} "s|^WORKSPACE=.*|WORKSPACE=workspace/{{name}}|" .env
        else
            echo "WORKSPACE=workspace/{{name}}" >> .env
        fi
    else
        echo "WORKSPACE=workspace/{{name}}" > .env
    fi
    echo "✓ Cloned: workspace/{{name}}"
    echo "  WORKSPACE=workspace/{{name}} written to .env"

# Show current workspace and its status
workspace:
    #!/usr/bin/env bash
    source .env 2>/dev/null || true
    if [ -z "${WORKSPACE:-}" ]; then
        echo "WORKSPACE not set — agents run in the hive-drill/ root"
        echo "Clone a project: just clone <url> <name>"
    elif [ -d "${WORKSPACE}" ]; then
        echo "Workspace: ${WORKSPACE}"
        echo "Recent commits:"
        git -C "${WORKSPACE}" log --oneline -5 2>/dev/null || true
    else
        echo "WORKSPACE=${WORKSPACE} (directory not found)"
        echo "Clone: just clone <url> $(basename ${WORKSPACE})"
    fi

# Open workspace in editor ($EDITOR or code)
open:
    #!/usr/bin/env bash
    source .env 2>/dev/null || true
    TARGET="${WORKSPACE:-$(pwd)}"
    [ "${TARGET}" = "$(pwd)" ] && echo "Opening hive-drill/ root" || echo "Opening: ${TARGET}"
    ${EDITOR:-code} "${TARGET}"

# ─── Projects ────────────────────────────────────────────────────────

# Manage projects: add / switch / list / remove / current / info
project *args:
    @./scripts/project.sh {{args}}

# ─── Self-improve ────────────────────────────────────────────────────

# Self-improve workspace: init / update / status / sync
self *args:
    @./scripts/self.sh {{args}}

# GitHub issues: Claude analysis + fzf select + pipeline
issues *args:
    @./scripts/issues.sh {{args}}

# ─── Setup ──────────────────────────────────────────────────────────

# Full system initialisation
setup:
    @./scripts/init.sh --all

# Install MCP servers only
setup-mcp:
    @./scripts/init.sh --mcp

# Install GSD hooks only
setup-gsd:
    @./scripts/init.sh --gsd
