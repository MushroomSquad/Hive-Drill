#!/usr/bin/env bash
# detect-platform.sh — platform/distro/package-manager detection
# Source this file; do not run directly.
#
# Exports after sourcing:
#   HIVE_PLATFORM   — linux | macos | windows
#   HIVE_DISTRO     — ubuntu | debian | fedora | arch | alpine | opensuse | void | macos | ...
#   HIVE_PKG        — apt | dnf | pacman | brew | apk | zypper | xbps | unknown
#   HIVE_SED_I      — cross-platform "sed -i" invocation (use: ${HIVE_SED_I} 's/a/b/' file)
#
# Functions after sourcing:
#   hive_install <pkg> [apt] [dnf] [pacman] [brew] [apk]   — install package via detected PM
#   hive_install_hint <pkg> [apt] [dnf] [pacman] [brew] [apk] — print hint only

# ─── Detect OS ────────────────────────────────────────────────────────────────

_hive_detect_os() {
    local uname
    uname="$(uname -s 2>/dev/null || echo unknown)"

    case "$uname" in
        Linux*)
            HIVE_PLATFORM="linux"
            if [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                local _id _like
                _id="$(  grep -m1 '^ID='      /etc/os-release | cut -d= -f2 | tr -d '"' )"
                _like="$(grep -m1 '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"' )"
                HIVE_DISTRO="${_id:-linux}"
                HIVE_DISTRO_LIKE="${_like:-}"
            else
                HIVE_DISTRO="linux"
                HIVE_DISTRO_LIKE=""
            fi
            ;;
        Darwin*)
            HIVE_PLATFORM="macos"
            HIVE_DISTRO="macos"
            HIVE_DISTRO_LIKE=""
            ;;
        MINGW*|MSYS*|CYGWIN*)
            HIVE_PLATFORM="windows"
            HIVE_DISTRO="windows"
            HIVE_DISTRO_LIKE=""
            ;;
        *)
            HIVE_PLATFORM="unknown"
            HIVE_DISTRO="unknown"
            HIVE_DISTRO_LIKE=""
            ;;
    esac
}

# ─── Detect package manager ───────────────────────────────────────────────────

_hive_detect_pkg() {
    if [[ "$HIVE_PLATFORM" == "macos" ]]; then
        command -v brew &>/dev/null && HIVE_PKG="brew" || HIVE_PKG="none"
        return
    fi

    if   command -v apt-get    &>/dev/null; then HIVE_PKG="apt"
    elif command -v dnf        &>/dev/null; then HIVE_PKG="dnf"
    elif command -v yum        &>/dev/null; then HIVE_PKG="yum"
    elif command -v pacman     &>/dev/null; then HIVE_PKG="pacman"
    elif command -v apk        &>/dev/null; then HIVE_PKG="apk"
    elif command -v zypper     &>/dev/null; then HIVE_PKG="zypper"
    elif command -v xbps-install &>/dev/null; then HIVE_PKG="xbps"
    else                                         HIVE_PKG="unknown"
    fi
}

# ─── sed -i compatibility ─────────────────────────────────────────────────────
# macOS sed requires:  sed -i ''
# GNU sed requires:    sed -i
# Usage: ${HIVE_SED_I} 's/pattern/replace/' file

_hive_detect_sed() {
    if sed --version 2>/dev/null | grep -q GNU; then
        HIVE_SED_I="sed -i"
    else
        HIVE_SED_I="sed -i ''"
    fi
}

# ─── Install helpers ──────────────────────────────────────────────────────────

# hive_install_hint <display_name> <apt> <dnf> <pacman> <brew> <apk>
hive_install_hint() {
    local name="${1:-pkg}"
    local apt="${2:-$name}" dnf="${3:-$name}" pac="${4:-$name}" br="${5:-$name}" apk="${6:-$name}"

    case "$HIVE_PKG" in
        apt)    echo "sudo apt-get install -y ${apt}" ;;
        dnf)    echo "sudo dnf install -y ${dnf}" ;;
        yum)    echo "sudo yum install -y ${dnf}" ;;
        pacman) echo "sudo pacman -S --noconfirm ${pac}" ;;
        brew)   echo "brew install ${br}" ;;
        apk)    echo "sudo apk add ${apk}" ;;
        zypper) echo "sudo zypper install -y ${name}" ;;
        xbps)   echo "sudo xbps-install -y ${name}" ;;
        none)
            if [[ "$HIVE_PLATFORM" == "macos" ]]; then
                echo "# Install Homebrew first: https://brew.sh  then: brew install ${br}"
            elif [[ "$HIVE_PLATFORM" == "windows" ]]; then
                echo "# Use WSL (recommended) or Scoop: scoop install ${name}"
            else
                echo "# Install ${name} manually"
            fi
            ;;
        *)  echo "# Install ${name} manually for your platform" ;;
    esac
}

# hive_install <display_name> <apt> <dnf> <pacman> <brew> <apk>
# Returns 0 on success, 1 on failure/unsupported
hive_install() {
    local name="${1:-pkg}"
    local hint
    hint="$(hive_install_hint "$@")"

    if [[ "$hint" == "#"* ]]; then
        return 1   # no auto-install possible, caller should warn
    fi

    eval "$hint"
}

# ─── Bash version check ───────────────────────────────────────────────────────
# macOS ships bash 3.2 (GPLv2). Hive Drill needs bash 4+.

hive_check_bash() {
    local major="${BASH_VERSINFO[0]:-0}"
    if [[ "$major" -lt 4 ]]; then
        echo "⚠  bash ${BASH_VERSION} detected — Hive Drill requires bash 4+."
        if [[ "$HIVE_PLATFORM" == "macos" ]]; then
            echo "   Install newer bash:  brew install bash"
            echo "   Then re-run with:    bash $(basename "$0")"
        fi
        return 1
    fi
    return 0
}

# ─── Platform summary ─────────────────────────────────────────────────────────

hive_platform_info() {
    echo "Platform : ${HIVE_PLATFORM}"
    echo "Distro   : ${HIVE_DISTRO}${HIVE_DISTRO_LIKE:+ (like: ${HIVE_DISTRO_LIKE})}"
    echo "Pkg mgr  : ${HIVE_PKG}"
    echo "sed -i   : ${HIVE_SED_I}"
    echo "bash     : ${BASH_VERSION}"
}

# ─── Run detection ────────────────────────────────────────────────────────────

_hive_detect_os
_hive_detect_pkg
_hive_detect_sed

export HIVE_PLATFORM HIVE_DISTRO HIVE_DISTRO_LIKE HIVE_PKG HIVE_SED_I
