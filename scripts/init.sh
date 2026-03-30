#!/usr/bin/env bash
# Initialization / bootstrap for Hive Drill
# Usage: ./scripts/init.sh [--mcp] [--llm] [--all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=detect-platform.sh
source "${SCRIPT_DIR}/detect-platform.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
info() { echo -e "${CYAN}[--]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

INIT_MCP=false
INIT_LLM=false
INIT_GSD=false

for arg in "$@"; do
  case "$arg" in
    --mcp) INIT_MCP=true ;;
    --llm) INIT_LLM=true ;;
    --gsd) INIT_GSD=true ;;
    --all) INIT_MCP=true; INIT_LLM=true; INIT_GSD=true ;;
    --gsd) INIT_GSD=true ;;
  esac
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       🐝  Hive Drill — Init          ║"
echo "╚══════════════════════════════════════╝"
echo ""
info "Platform: ${HIVE_PLATFORM} / ${HIVE_DISTRO} / pkg: ${HIVE_PKG}"

# Windows without WSL: stop early and explain
if [[ "$HIVE_PLATFORM" == "windows" ]]; then
    die "Native Windows is not supported. Please use WSL2:\n  https://learn.microsoft.com/en-us/windows/wsl/install\n  Then re-run from inside WSL."
fi

# macOS: check bash version
if [[ "$HIVE_PLATFORM" == "macos" ]]; then
    hive_check_bash || warn "Some scripts may not work with bash ${BASH_VERSION}. Install bash 4+: brew install bash"
fi

# macOS: nudge toward Homebrew if missing
if [[ "$HIVE_PLATFORM" == "macos" && "$HIVE_PKG" == "none" ]]; then
    warn "Homebrew not found. Install it first: https://brew.sh"
    warn "Then re-run this script."
    exit 1
fi
echo ""

# ── .env ──────────────────────────────────────────────────────────────
info "Checking .env..."
if [ ! -f .env ]; then
  cp .env.example .env
  warn ".env created from .env.example — fill in variables before running agents"
else
  ok ".env exists"
fi

# ── .ai/runs directory ───────────────────────────────────────────────
info "Setting up .ai/runs/..."
mkdir -p .ai/runs
ok ".ai/runs/ ready"

# ── Git ───────────────────────────────────────────────────────────────
info "Checking git..."
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  git init
  ok "Git initialized"
else
  ok "Git repository: $(git rev-parse --show-toplevel)"
fi

# ── Node.js (for MCP servers) ────────────────────────────────────────
info "Checking Node.js..."
if command -v node &>/dev/null; then
  ok "Node.js: $(node --version)"
else
  warn "Node.js not found — MCP servers via npx will not work"
fi

# ── Agent dependencies ───────────────────────────────────────────────
echo ""
info "=== Dependencies ==="

# try_install: auto-install via detected package manager; warn if unavailable
# args: cmd display apt dnf pacman brew apk
try_install() {
    local cmd="$1" name="$2" apt="${3:-$1}" dnf="${4:-$1}" pac="${5:-$1}" br="${6:-$1}" apk="${7:-$1}"
    if command -v "$cmd" &>/dev/null; then
        ok "$name: $(${cmd} --version 2>/dev/null | head -1 || echo found)"
        return
    fi
    warn "$name not found — installing..."
    if hive_install "$name" "$apt" "$dnf" "$pac" "$br" "$apk" 2>/dev/null; then
        command -v "$cmd" &>/dev/null && ok "$name installed." \
            || warn "$name install may need a shell restart."
    else
        local hint; hint="$(hive_install_hint "$name" "$apt" "$dnf" "$pac" "$br" "$apk")"
        warn "Could not auto-install. Run manually:  $hint"
    fi
}

# No-auto-install: agent CLIs require manual auth
check_cmd() {
    local cmd="$1" name="$2" hint="$3"
    command -v "$cmd" &>/dev/null \
        && ok "$name: $(${cmd} --version 2>/dev/null | head -1 || echo found)" \
        || warn "$name not found → $hint"
}

#                   cmd        display       apt           dnf            pacman        brew    apk
try_install "git"   "git"      "git"         "git"         "git"          "git"         "git"
try_install "python3" "Python 3" "python3"   "python3"     "python"       "python3"     "python3"
try_install "just"  "just"     "just"        "just"        "just"         "just"        "just"
try_install "gh"    "GitHub CLI" "gh"         "gh"         "github-cli"   "gh"          "github-cli"
try_install "fzf"   "fzf"      "fzf"         "fzf"         "fzf"          "fzf"         "fzf"

check_cmd "claude" "Claude Code" "https://claude.ai/code"
check_cmd "codex"  "Codex CLI"   "npm install -g @openai/codex"
check_cmd "cursor" "Cursor"      "https://cursor.com (optional)"

# ── MCP servers ───────────────────────────────────────────────────────
if [ "$INIT_MCP" = true ]; then
  echo ""
  info "=== Installing MCP servers ==="

  if ! command -v npx &>/dev/null; then
    warn "npx not found — skipping MCP installation"
  else
    npm_pkgs=(
      "@modelcontextprotocol/server-github"
      "@modelcontextprotocol/server-filesystem"
      "@modelcontextprotocol/server-memory"
    )
    for pkg in "${npm_pkgs[@]}"; do
      info "Installing $pkg..."
      npm install -g "$pkg" --silent && ok "$pkg" || warn "Failed to install $pkg"
    done
  fi
fi

# ── Local LLM stack ────────────────────────────────────────────────
if [ "$INIT_LLM" = true ]; then
  echo ""
  info "=== Initializing local LLM stack ==="
  if [ -f llm/setup/install.sh ]; then
    bash llm/setup/install.sh
  else
    warn "llm/setup/install.sh not found"
  fi
fi

# ── GSD (get-shit-done) ──────────────────────────────────────────────
if [ "$INIT_GSD" = true ]; then
  echo ""
  info "=== Installing GSD (get-shit-done) ==="

  GSD_HOOKS_DIR="${HOME}/.claude/hooks"
  GSD_DIR="${HOME}/.claude/get-shit-done"

  if [ -f "${GSD_HOOKS_DIR}/gsd-statusline.js" ]; then
    ok "GSD already installed ($(cat "${GSD_DIR}/VERSION" 2>/dev/null || echo 'version unknown'))"
  else
    if ! command -v git &>/dev/null; then
      warn "git not found — skipping GSD installation"
    elif ! command -v node &>/dev/null; then
      warn "node not found — skipping GSD installation"
    else
      GSD_TMP=$(mktemp -d)
      info "Cloning GSD..."
      if git clone --depth=1 --quiet https://github.com/gsd-build/get-shit-done.git "${GSD_TMP}" 2>/dev/null; then
        if [ -f "${GSD_TMP}/install.sh" ]; then
          bash "${GSD_TMP}/install.sh" --yes 2>/dev/null && ok "GSD installed" || warn "GSD install.sh returned error"
        else
          # Manual installation: copy hooks and get-shit-done/
          mkdir -p "${GSD_HOOKS_DIR}" "${GSD_DIR}"
          [ -d "${GSD_TMP}/hooks" ]           && cp -r "${GSD_TMP}/hooks/." "${GSD_HOOKS_DIR}/"
          [ -d "${GSD_TMP}/get-shit-done" ]   && cp -r "${GSD_TMP}/get-shit-done/." "${GSD_DIR}/"
          ok "GSD files copied"
          warn "Add hooks manually: ~/.claude/settings.json → hooks"
        fi
      else
        warn "Failed to clone GSD. Install manually: https://github.com/gsd-build/get-shit-done"
      fi
      rm -rf "${GSD_TMP}"
    fi
  fi
fi

# ── just / make check ─────────────────────────────────────────────────
echo ""
info "=== Final check ==="
if command -v just &>/dev/null; then
  info "Available commands: just --list"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  Done. Next steps:"
echo ""
echo "  1. Fill in .env"
echo "  2. Fill in .ai/base/BASE.md"
echo "  3. just bp feature TASK-001  # run first pipeline"
echo ""
if [ "$INIT_LLM" = false ]; then
  echo "  Local LLM: ./scripts/init.sh --llm"
fi
if [ "$INIT_MCP" = false ]; then
  echo "  MCP servers:   ./scripts/init.sh --mcp"
fi
echo "═══════════════════════════════════════"
