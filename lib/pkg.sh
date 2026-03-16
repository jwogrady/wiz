#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: Package Manager Abstraction
# ==============================================================================
# Cross-platform package manager detection and installation helpers.
# Supports: apt (Debian/Ubuntu), dnf/yum (Fedora/RHEL), pacman (Arch), brew (macOS)
#
# Normal usage: sourced transitively by lib/common.sh — callers need only:
#   source /path/to/lib/common.sh
#
# Standalone (direct) usage:
#   source /path/to/lib/pkg.sh   # guard below bootstraps common.sh if needed
#
# Functions:
#   - detect_pkg_manager  (cached: apt | dnf | yum | pacman | brew | unknown)
#   - package_installed   <pkg>
#   - pkg_update
#   - pkg_upgrade
#   - pkg_clean
#   - install_package     <pkg>
#   - install_packages    <pkg> [<pkg> ...]
#
# ==============================================================================

set -euo pipefail

# --- Ensure common.sh is sourced ---
# Defensive guard: only fires when this file is sourced directly (outside the
# normal common.sh chain).  Do NOT use WIZ_ROOT:= here — common.sh derives
# WIZ_ROOT from its own BASH_SOURCE location (lib/../); assigning it to the
# lib/ directory here would misconfigure all WIZ_*_DIR paths.
if ! declare -f log >/dev/null 2>&1; then
    # shellcheck source=common.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

# Cache the detected package manager to avoid repeated detection
_WIZ_PKG_MANAGER=""

# detect_pkg_manager: Detect the system's package manager
# Usage: pkg_mgr=$(detect_pkg_manager)
# Returns: apt, dnf, yum, pacman, brew, or "unknown"
detect_pkg_manager() {
    if [[ -n "$_WIZ_PKG_MANAGER" ]]; then
        echo "$_WIZ_PKG_MANAGER"
        return 0
    fi

    if command_exists apt-get; then
        _WIZ_PKG_MANAGER="apt"
    elif command_exists dnf; then
        _WIZ_PKG_MANAGER="dnf"
    elif command_exists yum; then
        _WIZ_PKG_MANAGER="yum"
    elif command_exists pacman; then
        _WIZ_PKG_MANAGER="pacman"
    elif command_exists brew; then
        _WIZ_PKG_MANAGER="brew"
    else
        _WIZ_PKG_MANAGER="unknown"
    fi

    echo "$_WIZ_PKG_MANAGER"
}

# package_installed: Check if a package is installed (cross-platform)
# Usage: package_installed <package>
package_installed() {
    local pkg="$1"
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    case "$pkg_mgr" in
        apt)
            dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Qi "$pkg" >/dev/null 2>&1
            ;;
        brew)
            brew list "$pkg" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# pkg_update: Update package manager cache (cross-platform)
pkg_update() {
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    case "$pkg_mgr" in
        apt)
            run_stream env DEBIAN_FRONTEND=noninteractive sudo apt-get update -y
            ;;
        dnf)
            run_stream sudo dnf check-update -y || true
            ;;
        yum)
            run_stream sudo yum check-update -y || true
            ;;
        pacman)
            run_stream sudo pacman -Sy --noconfirm
            ;;
        brew)
            run_stream brew update
            ;;
        *)
            warn "Unknown package manager, skipping update"
            return 1
            ;;
    esac
}

# pkg_upgrade: Upgrade all installed packages (cross-platform)
pkg_upgrade() {
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    case "$pkg_mgr" in
        apt)
            run_stream env DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y \
                -o Dpkg::Options::=--force-confdef \
                -o Dpkg::Options::=--force-confold
            ;;
        dnf)
            run_stream sudo dnf upgrade -y
            ;;
        yum)
            run_stream sudo yum upgrade -y
            ;;
        pacman)
            run_stream sudo pacman -Syu --noconfirm
            ;;
        brew)
            run_stream brew upgrade
            ;;
        *)
            warn "Unknown package manager, skipping upgrade"
            return 1
            ;;
    esac
}

# pkg_clean: Clean package manager cache and remove unused packages (cross-platform)
pkg_clean() {
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    case "$pkg_mgr" in
        apt)
            run_stream env DEBIAN_FRONTEND=noninteractive sudo apt-get autoremove -y || true
            run_stream sudo apt-get clean || true
            ;;
        dnf)
            run_stream sudo dnf autoremove -y || true
            run_stream sudo dnf clean all || true
            ;;
        yum)
            run_stream sudo yum autoremove -y || true
            run_stream sudo yum clean all || true
            ;;
        pacman)
            local orphans
            mapfile -t orphans < <(pacman -Qdtq 2>/dev/null)
            if [[ ${#orphans[@]} -gt 0 ]]; then
                run_stream sudo pacman -Rns --noconfirm "${orphans[@]}" || true
            fi
            run_stream sudo pacman -Sc --noconfirm || true
            ;;
        brew)
            run_stream brew cleanup || true
            ;;
        *)
            warn "Unknown package manager, skipping cleanup"
            return 1
            ;;
    esac
}

# install_package: Install a single package if not already installed (cross-platform)
# Usage: install_package <package>
install_package() {
    local pkg="$1"
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    if package_installed "$pkg"; then
        debug "Package already installed: $pkg"
        return 0
    fi

    log "Installing package: $pkg"

    case "$pkg_mgr" in
        apt)
            run_stream env DEBIAN_FRONTEND=noninteractive \
                DEBCONF_NONINTERACTIVE_SEEN=true \
                sudo -E apt-get install -y \
                -o Dpkg::Options::=--force-confdef \
                -o Dpkg::Options::=--force-confold \
                -o DPkg::Pre-Install-Pkgs::= \
                "$pkg"
            ;;
        dnf)
            run_stream sudo dnf install -y "$pkg"
            ;;
        yum)
            run_stream sudo yum install -y "$pkg"
            ;;
        pacman)
            run_stream sudo pacman -S --noconfirm "$pkg"
            ;;
        brew)
            run_stream brew install "$pkg"
            ;;
        *)
            error "Unknown package manager: $pkg_mgr"
            return 1
            ;;
    esac
}

# install_packages: Install multiple packages (cross-platform)
# Usage: install_packages package1 package2 ...
install_packages() {
    local packages=("$@")
    local to_install=()
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    # For apt: one dpkg-query invocation covers all packages instead of N
    # individual dpkg -l calls.  For other managers the per-package loop is fine.
    if [[ "$pkg_mgr" == "apt" ]] && [[ ${#packages[@]} -gt 0 ]]; then
        local -A _apt_installed=()
        local _pkg
        while IFS= read -r _pkg; do
            [[ -n "$_pkg" ]] && _apt_installed["$_pkg"]=1
        done < <(dpkg-query -W -f='${Status}\t${Package}\n' "${packages[@]}" 2>/dev/null \
            | awk -F'\t' '$1=="install ok installed" {print $2}')
        for pkg in "${packages[@]}"; do
            [[ -z "${_apt_installed[$pkg]+x}" ]] && to_install+=("$pkg")
        done
    else
        for pkg in "${packages[@]}"; do
            package_installed "$pkg" || to_install+=("$pkg")
        done
    fi

    if [[ ${#to_install[@]} -eq 0 ]]; then
        debug "All packages already installed"
        return 0
    fi

    log "Installing ${#to_install[@]} packages: ${to_install[*]}"

    case "$pkg_mgr" in
        apt)
            run_stream env DEBIAN_FRONTEND=noninteractive \
                DEBCONF_NONINTERACTIVE_SEEN=true \
                sudo -E apt-get install -y \
                -o Dpkg::Options::=--force-confdef \
                -o Dpkg::Options::=--force-confold \
                -o DPkg::Pre-Install-Pkgs::= \
                "${to_install[@]}"
            ;;
        dnf)
            run_stream sudo dnf install -y "${to_install[@]}"
            ;;
        yum)
            run_stream sudo yum install -y "${to_install[@]}"
            ;;
        pacman)
            run_stream sudo pacman -S --noconfirm "${to_install[@]}"
            ;;
        brew)
            run_stream brew install "${to_install[@]}"
            ;;
        *)
            error "Unknown package manager: $pkg_mgr"
            return 1
            ;;
    esac

    for pkg in "${to_install[@]}"; do
        if ! package_installed "$pkg"; then
            error "Package installation verification failed: $pkg"
            return 1
        fi
    done

    return 0
}

# --- Export Functions ---
export -f detect_pkg_manager package_installed
export -f pkg_update pkg_upgrade pkg_clean
export -f install_package install_packages

debug "Package manager library loaded"
