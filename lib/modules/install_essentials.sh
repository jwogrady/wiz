#!/usr/bin/env bash
# ==============================================================================
# Wiz Module: Essential System Packages
# ==============================================================================
# Installs core system tools and dependencies required by other modules.
#
# Provides:
#   - Build tools (gcc, make, cmake)
#   - Development essentials (git, curl, wget)
#   - Network utilities (nmap, netcat, mtr)
#   - Monitoring tools (htop, btop, neofetch)
#   - Security packages (ca-certificates, gnupg)
#
# Dependencies: None (foundational module)
#
# Usage:
#   ./install_essentials.sh
#   or sourced by bootstrap orchestrator
#
# ==============================================================================

set -euo pipefail

# --- Module Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source module base
# shellcheck source=../module-base.sh
source "${SCRIPT_DIR}/../module-base.sh"

# Module metadata
MODULE_NAME="essentials"
MODULE_VERSION="0.2.0"
MODULE_DESCRIPTION="Core system packages and build tools"
MODULE_DEPS=""

# --- Package Categories ---
declare -a NETWORK_UTILS=(
    "bind9-host"    "dnsutils"    "iperf3"        "mtr"           "net-tools"
    "netcat-openbsd" "traceroute" "whois"         "nmap"
)

declare -a MONITORING_TOOLS=(
    "btop"      "glances"    "htop"      "lshw"        "neofetch"
    "strace"    "lsof"
)

declare -a BUILD_TOOLS=(
    "build-essential"    "cabal-install"    "cmake"
)

declare -a DEV_ESSENTIALS=(
    "git"       "curl"      "wget"      "unzip"       "zip"
    "jq"        "tree"      "xz-utils"
)

declare -a SHELL_TOOLS=(
    "zsh"
)

declare -a DOCKER_TOOLS=(
    "docker.io"        "docker-compose"
)

declare -a SECURITY=(
    "ca-certificates"    "gnupg"
)

declare -a EDITORS=(
    "nano"    "vim"
)

declare -a GITHUB_CLI=(
    "gh"
)

declare -a SYSTEM=(
    "lsb-release"    "sudo"
)

# --- Helper Functions ---

# is_enabled: Check if a configuration option is enabled
# Usage: is_enabled "OPTION_NAME"
is_enabled() {
    local option="$1"
    local value="${!option:-}"

    # Default values for known options
    case "${option}" in
        "UPDATE_SYSTEM")
            value="${UPDATE_SYSTEM:-1}"
        ;;
        "UPGRADE_SYSTEM")
            value="${UPGRADE_SYSTEM:-0}"
        ;;
        "AUTO_CLEAN")
            value="${AUTO_CLEAN:-1}"
        ;;
        *)
            value="${value:-0}"
        ;;
    esac

    [[ "${value}" == "1" ]] || [[ "${value}" == "true" ]] || [[ "${value}" == "yes" ]]
}

# --- Module Interface Implementation ---

# describe_essentials: Describe what this module will install
describe_essentials() {
    cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 ESSENTIAL SYSTEM PACKAGES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This module installs foundational system packages:

  🔧 Build Tools:        gcc, make, cmake, cabal
  💻 Dev Essentials:     git, curl, wget, jq, tree
  🌐 Network Utilities:  nmap, mtr, netcat, dnsutils
  📊 Monitoring:         htop, btop, glances, neofetch
  🐳 Docker:             docker.io, docker-compose
  🔒 Security:           ca-certificates, gnupg
  📝 Editors:            nano, vim
  🐙 GitHub CLI:         gh

Total packages: ~50+

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# install_essentials: Main installation logic
install_essentials() {
    # Update system if configured
    # shellcheck disable=SC2310
    if is_enabled "UPDATE_SYSTEM"; then
        progress "Updating package cache..."
        run "sudo DEBIAN_FRONTEND=noninteractive apt-get update -y" || module_fail "Failed to update package cache"
    fi

    # Upgrade system if configured
    # shellcheck disable=SC2310
    if is_enabled "UPGRADE_SYSTEM"; then
        progress "Upgrading system packages..."
        run "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold" || warn "System upgrade had issues, continuing..."
    fi

    # Collect all packages for batch installation (more efficient)
    local all_packages=(
        "${NETWORK_UTILS[@]}"
        "${MONITORING_TOOLS[@]}"
        "${BUILD_TOOLS[@]}"
        "${DEV_ESSENTIALS[@]}"
        "${SHELL_TOOLS[@]}"
        "${DOCKER_TOOLS[@]}"
        "${SECURITY[@]}"
        "${EDITORS[@]}"
        "${GITHUB_CLI[@]}"
        "${SYSTEM[@]}"
    )

    # Install all packages in one batch (more efficient than multiple calls)
    log "Installing ${#all_packages[@]} packages across all categories..."
    log "  Categories: network, monitoring, build, dev, shell, docker, security, editors, github-cli, system"
    install_packages "${all_packages[@]}"

    # Clean up if configured
    # shellcheck disable=SC2310
    if is_enabled "AUTO_CLEAN"; then
        progress "Cleaning package cache..."
        run "sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y" || warn "Autoremove had issues"
        run "sudo apt-get clean" || warn "Clean had issues"
    fi

    return 0
}

# verify_essentials: Verify installation succeeded
verify_essentials() {
    local failed=0
    local critical_commands=(
        git
        curl
        wget
        make
        gcc
        docker
    )

    log "Verifying critical commands..."

    for cmd in "${critical_commands[@]}"; do
        # shellcheck disable=SC2310
        if command_exists "${cmd}"; then
            debug "  ✓ ${cmd} found"
        else
            error "  ✖ ${cmd} not found"
            failed=1
        fi
    done

    if [[ ${failed} -eq 0 ]]; then
        success "All critical commands verified"
        return 0
    else
        error "Some critical commands missing"
        return 1
    fi
}

# --- Main Execution ---

# If script is executed directly (not sourced), run the module
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    execute_module "essentials"
fi
