#!/usr/bin/env bash
# AI Dev OS — Bootstrap installer
#
# Locally:
#   bash install.sh
#
# From repository (after publication):
#   curl -fsSL https://raw.githubusercontent.com/YOU/ai-dev-os/main/install.sh | bash
#
set -euo pipefail

# ─── Styling ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

ok()      { echo -e "  ${GREEN}✓${RESET}  $*"; }
fail()    { echo -e "  ${RED}✗${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}!${RESET}  $*"; }
info()    { echo -e "  ${DIM}→${RESET}  $*"; }
section() { echo -e "\n${CYAN}${BOLD}── $* ──────────────────────────────────────────${RESET}"; }
die()     { echo -e "\n${RED}${BOLD}Error:${RESET} $*\n"; exit 1; }

ERRORS=()
WARNINGS=()

need()  { ERRORS+=("$*"); }
nudge() { WARNINGS+=("$*"); }

# ─── Banner ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║          AI Dev OS — Installer            ║"
echo "  ║   Cursor · Codex · Claude · Local LLM    ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${RESET}"

# ─── Detect environment ─────────────────────────────────────────────────────
OS="linux"
PKG=""
IN_WSL=false

case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version && IN_WSL=true
    if command -v apt-get &>/dev/null;   then PKG="apt";
    elif command -v dnf &>/dev/null;     then PKG="dnf";
    elif command -v pacman &>/dev/null;  then PKG="pacman";
    fi
    ;;
esac

info "OS: $OS$(${IN_WSL} && echo ' (WSL2)' || true)"
info "Package manager: ${PKG:-not detected}"

# ─── Where we are running ──────────────────────────────────────────────────────
# If script runs via curl|bash, PROJECT_DIR = current folder
# If run from cloned repo — its root
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  PROJECT_DIR="$(pwd)"
fi
info "Project directory: $PROJECT_DIR"

# ─── Package installer ───────────────────────────────────────────────────────
install_pkg() {
  local pkg="$1"
  case "$OS-$PKG" in
    macos-*)        brew install "$pkg" ;;
    linux-apt)      sudo apt-get install -y "$pkg" ;;
    linux-dnf)      sudo dnf install -y "$pkg" ;;
    linux-pacman)   sudo pacman -S --noconfirm "$pkg" ;;
    *)              warn "Don't know how to install '$pkg' — do it manually"; return 1 ;;
  esac
}

# ─── 1. System dependencies ─────────────────────────────────────────────────
section "System dependencies"

# Git
if command -v git &>/dev/null; then
  ok "git $(git --version | grep -oP '[\d.]+')"
else
  info "Installing git..."
  install_pkg git && ok "git installed" || need "git — install manually"
fi

# Python 3
if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version 2>&1 | grep -oP '[\d.]+')
  ok "python3 $PY_VER"
else
  need "python3 — install from: https://python.org"
fi

# Node.js / npm
if command -v node &>/dev/null; then
  ok "node $(node --version)"
else
  warn "node not found — required for MCP servers and Codex"
  nudge "node — install from: https://nodejs.org  or  nvm install --lts"
fi

# Docker
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  ok "docker $(docker --version | grep -oP '[\d.]+')"
else
  if command -v docker &>/dev/null; then
    warn "docker found, but not running"
    nudge "start Docker Desktop or: sudo systemctl start docker"
  else
    nudge "docker — required for local LLM (Harbor). Install from: https://docs.docker.com/get-docker/"
  fi
fi

# just
if command -v just &>/dev/null; then
  ok "just $(just --version)"
else
  info "Installing just..."
  JUST_OK=false
  if [[ "$OS" == "macos" ]] && command -v brew &>/dev/null; then
    brew install just && JUST_OK=true
  elif [[ "$OS" == "linux" ]]; then
    # Try cargo
    if command -v cargo &>/dev/null; then
      cargo install just && JUST_OK=true
    else
      # Binary release
      JUST_VER=$(curl -fsSL https://api.github.com/repos/casey/just/releases/latest \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "1.36.0")
      JUST_ARCH="x86_64-unknown-linux-musl"
      curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VER}/just-${JUST_VER}-${JUST_ARCH}.tar.gz" \
        | tar xz -C /tmp just
      sudo mv /tmp/just /usr/local/bin/just && JUST_OK=true
    fi
  fi
  ${JUST_OK} && ok "just installed" || nudge "just — install with: cargo install just"
fi

# ─── 2. AI tools ────────────────────────────────────────────────────────
section "AI tools"

# Claude Code
if command -v claude &>/dev/null; then
  ok "Claude Code $(claude --version 2>/dev/null | head -1)"
else
  if command -v npm &>/dev/null; then
    info "Installing Claude Code..."
    npm install -g @anthropic/claude-code 2>/dev/null \
      && ok "Claude Code installed" \
      || nudge "Claude Code — install manually: npm install -g @anthropic/claude-code"
  else
    nudge "Claude Code — requires npm: npm install -g @anthropic/claude-code"
  fi
fi

# Codex
if command -v codex &>/dev/null; then
  ok "Codex $(codex --version 2>/dev/null | head -1)"
else
  if command -v npm &>/dev/null; then
    info "Installing Codex..."
    npm install -g @openai/codex 2>/dev/null \
      && ok "Codex installed" \
      || nudge "Codex — install manually: npm install -g @openai/codex"
  else
    nudge "Codex — requires npm: npm install -g @openai/codex"
  fi
fi

# Cursor (check presence, don't install)
if command -v cursor &>/dev/null; then
  ok "Cursor"
else
  nudge "Cursor — download from: https://cursor.com"
fi

# ─── 3. MCP servers ───────────────────────────────────────────────────────────
section "MCP servers"

if command -v npm &>/dev/null; then
  MCP_PKGS=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-github"
  )
  for pkg in "${MCP_PKGS[@]}"; do
    name="${pkg##*/}"
    if npm list -g "$pkg" &>/dev/null 2>&1; then
      ok "$name (already installed)"
    else
      info "Installing $name..."
      npm install -g "$pkg" --silent 2>/dev/null \
        && ok "$name" \
        || warn "$name — installation failed"
    fi
  done
else
  nudge "MCP servers — requires npm"
fi

# ─── 4. Project ────────────────────────────────────────────────────────────────
section "Project setup"

cd "$PROJECT_DIR"

# .env
if [[ -f .env ]]; then
  ok ".env already exists"
else
  if [[ -f .env.example ]]; then
    cp .env.example .env
    ok ".env created from .env.example"
    warn "Add GITHUB_TOKEN to .env (required for MCP)"
  fi
fi

# Script permissions
if [[ -d scripts ]]; then
  chmod +x scripts/*.sh 2>/dev/null && ok "scripts/*.sh — executable"
fi
if [[ -d llm ]]; then
  find llm -name "*.sh" -exec chmod +x {} \; 2>/dev/null && ok "llm/**/*.sh — executable"
fi

# Vault structure
mkdir -p vault/00-inbox vault/01-active vault/02-done
[[ -f vault/01-active/.gitkeep ]] || touch vault/01-active/.gitkeep
[[ -f vault/02-done/.gitkeep  ]] || touch vault/02-done/.gitkeep
ok "vault/ structure ready"

# .ai/runs
mkdir -p .ai/runs
ok ".ai/runs/ ready"

# Git
if git rev-parse --is-inside-work-tree &>/dev/null; then
  ok "git repository: $(git rev-parse --show-toplevel)"
else
  git init && git add -A && git commit -m "init: AI Dev OS" --quiet
  ok "git initialized"
fi

# ─── 5. NVIDIA / GPU (optional) ───────────────────────────────────────────
section "GPU (optional)"

if command -v nvidia-smi &>/dev/null; then
  GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
  ok "GPU: $GPU"

  if [[ "$OS" == "linux" ]] || ${IN_WSL}; then
    if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 \
         nvidia-smi -L &>/dev/null 2>&1; then
      ok "GPU available in Docker"
    else
      nudge "NVIDIA Container Toolkit — run: ./llm/setup/install-nvidia.sh"
    fi
  fi
else
  info "NVIDIA GPU not detected — local LLM will run on CPU (slow)"
fi

# ─── 6. Local LLM (Harbor) — optional ─────────────────────────────────────
section "Local LLM (Harbor)"

if command -v harbor &>/dev/null; then
  ok "Harbor $(harbor --version 2>/dev/null || echo 'found')"
else
  echo ""
  echo -e "  Harbor is required for local LLM (TabbyAPI / llama.cpp)."
  echo -e "  ${DIM}Without it, Codex will only work through cloud.${RESET}"
  echo ""
  read -r -p "  Install Harbor now? [y/N] " install_harbor
  if [[ "${install_harbor,,}" == "y" ]]; then
    if command -v pipx &>/dev/null; then
      pipx install llm-harbor && ok "Harbor installed via pipx"
    elif command -v npm &>/dev/null; then
      npm install -g @avcodes/harbor && ok "Harbor installed via npm"
    else
      curl -fsSL https://av.codes/get-harbor.sh | bash && ok "Harbor installed"
    fi
  else
    nudge "Harbor — install later: curl -fsSL https://av.codes/get-harbor.sh | bash"
  fi
fi

# ─── 7. Agent authorization ───────────────────────────────────────────────────
section "Agent authorization"

# Claude Code — uses its own auth, not .env
if command -v claude &>/dev/null; then
  if claude auth status &>/dev/null 2>&1; then
    ok "Claude Code: authorized"
  else
    info "Authorize Claude Code:"
    echo ""
    echo -e "     ${CYAN}claude auth login${RESET}"
    echo ""
    nudge "claude auth login — required for agent to work"
  fi
fi

# Codex — uses its own auth, not .env
if command -v codex &>/dev/null; then
  if codex auth status &>/dev/null 2>&1; then
    ok "Codex: authorized"
  else
    info "Authorize Codex:"
    echo ""
    echo -e "     ${CYAN}codex auth login${RESET}"
    echo ""
    nudge "codex auth login — required for agent to work"
  fi
fi

# GitHub token — only needed for MCP server
check_github_token() {
  local val=""
  val=$(grep -E "^GITHUB_TOKEN=.+" .env 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'" || true)
  val="${val:-${GITHUB_TOKEN:-}}"
  if [[ -n "$val" && "$val" != "ghp_..." ]]; then
    ok "GITHUB_TOKEN: set (for MCP)"
  else
    nudge "GITHUB_TOKEN — add to .env for GitHub MCP server: https://github.com/settings/tokens (scope: repo)"
  fi
}
check_github_token

# ─── Summary ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── Summary ─────────────────────────────────────────────────────────${RESET}"
echo ""

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo -e "  ${RED}${BOLD}Critical issues (must fix):${RESET}"
  for e in "${ERRORS[@]}"; do
    fail "$e"
  done
  echo ""
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo -e "  ${YELLOW}${BOLD}Recommended:${RESET}"
  for w in "${WARNINGS[@]}"; do
    warn "$w"
  done
  echo ""
fi

if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}Installation complete!${RESET}"
else
  echo -e "  ${YELLOW}Installation complete with warnings — some features unavailable.${RESET}"
fi

# ─── Next steps ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}── How to get started ────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${BOLD}1. Open vault in Obsidian:${RESET}"
echo -e "     ${DIM}File → Open Vault → $(pwd)/vault${RESET}"
echo ""
echo -e "  ${BOLD}2. Authorize agents (once):${RESET}"
echo -e "     ${CYAN}claude auth login${RESET}"
echo -e "     ${CYAN}codex auth login${RESET}"
echo ""
echo -e "  ${BOLD}3. Create first task:${RESET}"
echo -e "     ${CYAN}just new FEAT-001${RESET}"
echo ""
echo -e "  ${BOLD}4. Fill brief in Obsidian → change status: ready${RESET}"
echo ""
echo -e "  ${BOLD}5. Run pipeline:${RESET}"
echo -e "     ${CYAN}just go FEAT-001${RESET}"
echo ""
echo -e "  ${DIM}Full list of commands: just --list${RESET}"
echo ""
