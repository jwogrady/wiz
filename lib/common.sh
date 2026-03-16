#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: Common Utilities Library
# ==============================================================================
# Provides colorized logging, error handling, atomic file operations, and
# environment detection for all Wiz scripts.
#
# Usage:
#   source /path/to/lib/common.sh
#
# Functions:
#   - log, warn, error, success, debug, progress
#   - run (dry-run aware command execution)
#   - atomic_write (idempotent file updates)
#   - backup_file (safe backups before modifications)
#   - command_exists, package_installed
#   - detect_os, detect_shell, is_wsl
#
# Environment Variables:
#   WIZ_DRY_RUN       - Set to 1 to enable dry-run mode
#   WIZ_LOG_LEVEL     - 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR (default: 1)
#   WIZ_LOG_FILE      - Path to log file (default: logs/install_YYYY-MM-DD.log)
#   WIZ_VERBOSE       - Set to 1 for verbose output
#
# ==============================================================================

set -euo pipefail

# --- Color Codes ---
# Initialize color variables immediately to avoid unbound variable errors
# Style guide: ANSI color codes should be uppercase with COLOR_ prefix
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'
COLOR_DIM='\033[2m'
COLOR_NC='\033[0m'
readonly COLOR_GREEN COLOR_YELLOW COLOR_RED COLOR_BLUE COLOR_MAGENTA COLOR_CYAN COLOR_BOLD COLOR_DIM COLOR_NC

# Backward compatibility aliases (preserve existing style)
readonly GREEN="${COLOR_GREEN}"
readonly YELLOW="${COLOR_YELLOW}"
readonly RED="${COLOR_RED}"
readonly BLUE="${COLOR_BLUE}"
readonly MAGENTA="${COLOR_MAGENTA}"
readonly CYAN="${COLOR_CYAN}"
readonly BOLD="${COLOR_BOLD}"
readonly DIM="${COLOR_DIM}"
readonly NC="${COLOR_NC}"

# --- Configuration ---
# All configuration uses WIZ_ prefix for namespacing
# This prevents pollution of the global namespace and makes dependencies explicit

# Version information
readonly WIZ_VERSION="0.2.0"
readonly WIZ_CODENAME="Terminal Magic"

# Directory configuration (readonly after initialization)
readonly WIZ_ROOT="${WIZ_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly WIZ_LOG_DIR="${WIZ_ROOT}/logs"
readonly WIZ_CACHE_DIR="${HOME}/.wiz/cache"
readonly WIZ_STATE_DIR="${HOME}/.wiz/state"
readonly WIZ_SSH_FINGERPRINT_CACHE_DIR="${WIZ_CACHE_DIR}/ssh_fingerprints"

# Runtime configuration (can be modified via environment or flags)
WIZ_DRY_RUN="${WIZ_DRY_RUN:-0}"
WIZ_LOG_LEVEL="${WIZ_LOG_LEVEL:-1}"
WIZ_LOG_FILE="${WIZ_LOG_FILE:-${WIZ_LOG_DIR}/install_$(date +%F).log}"
WIZ_VERBOSE="${WIZ_VERBOSE:-0}"
WIZ_FORCE_REINSTALL="${WIZ_FORCE_REINSTALL:-0}"
WIZ_STOP_ON_ERROR="${WIZ_STOP_ON_ERROR:-1}"

# Tool version overrides (empty = use each module's own default/latest)
WIZ_NODE_VERSION="${WIZ_NODE_VERSION:-}"
WIZ_BUN_VERSION="${WIZ_BUN_VERSION:-}"
WIZ_STARSHIP_VERSION="${WIZ_STARSHIP_VERSION:-}"

# Backward compatibility aliases (deprecated, use WIZ_ prefix instead)
LOG_DIR="$WIZ_LOG_DIR"
CACHE_DIR="$WIZ_CACHE_DIR"
SSH_FINGERPRINT_CACHE_DIR="$WIZ_SSH_FINGERPRINT_CACHE_DIR"
DRY_RUN="$WIZ_DRY_RUN"
LOG_LEVEL="$WIZ_LOG_LEVEL"
LOG_FILE="$WIZ_LOG_FILE"
VERBOSE="$WIZ_VERBOSE"

# Export all WIZ_ variables for subprocesses
export WIZ_VERSION WIZ_CODENAME
export WIZ_ROOT WIZ_LOG_DIR WIZ_CACHE_DIR WIZ_STATE_DIR WIZ_SSH_FINGERPRINT_CACHE_DIR
export WIZ_DRY_RUN WIZ_LOG_LEVEL WIZ_LOG_FILE WIZ_VERBOSE WIZ_FORCE_REINSTALL WIZ_STOP_ON_ERROR
export WIZ_NODE_VERSION WIZ_BUN_VERSION WIZ_STARSHIP_VERSION
# Backward compat exports
export LOG_DIR LOG_FILE DRY_RUN LOG_LEVEL VERBOSE

# --- Configuration Accessor Functions ---
# These provide a clean interface for reading/modifying configuration

# wiz_config_get: Get a configuration value
# Usage: value=$(wiz_config_get "dry_run")
wiz_config_get() {
    local key="$1"
    case "$key" in
        dry_run)      echo "$WIZ_DRY_RUN" ;;
        verbose)      echo "$WIZ_VERBOSE" ;;
        log_level)    echo "$WIZ_LOG_LEVEL" ;;
        log_file)     echo "$WIZ_LOG_FILE" ;;
        force)        echo "$WIZ_FORCE_REINSTALL" ;;
        stop_on_error)    echo "$WIZ_STOP_ON_ERROR" ;;
        root)             echo "$WIZ_ROOT" ;;
        log_dir)          echo "$WIZ_LOG_DIR" ;;
        cache_dir)        echo "$WIZ_CACHE_DIR" ;;
        state_dir)        echo "$WIZ_STATE_DIR" ;;
        node_version)     echo "$WIZ_NODE_VERSION" ;;
        bun_version)      echo "$WIZ_BUN_VERSION" ;;
        starship_version) echo "$WIZ_STARSHIP_VERSION" ;;
        *)                echo "" ;;
    esac
}

# wiz_config_set: Set a configuration value
# Usage: wiz_config_set "dry_run" "1"
wiz_config_set() {
    local key="$1"
    local value="$2"
    case "$key" in
        dry_run)
            WIZ_DRY_RUN="$value"
            DRY_RUN="$value"
            export WIZ_DRY_RUN DRY_RUN
            ;;
        verbose)
            WIZ_VERBOSE="$value"
            VERBOSE="$value"
            export WIZ_VERBOSE VERBOSE
            ;;
        log_level)
            WIZ_LOG_LEVEL="$value"
            LOG_LEVEL="$value"
            export WIZ_LOG_LEVEL LOG_LEVEL
            ;;
        force)
            WIZ_FORCE_REINSTALL="$value"
            export WIZ_FORCE_REINSTALL
            ;;
        stop_on_error)
            WIZ_STOP_ON_ERROR="$value"
            export WIZ_STOP_ON_ERROR
            ;;
        node_version)
            WIZ_NODE_VERSION="$value"
            export WIZ_NODE_VERSION
            ;;
        bun_version)
            WIZ_BUN_VERSION="$value"
            export WIZ_BUN_VERSION
            ;;
        starship_version)
            WIZ_STARSHIP_VERSION="$value"
            export WIZ_STARSHIP_VERSION
            ;;
        *)
            warn "Unknown config key: $key"
            return 1
            ;;
    esac
}

# wiz_is_dry_run: Check if dry-run mode is enabled
# Usage: if wiz_is_dry_run; then ...
wiz_is_dry_run() {
    [[ "$WIZ_DRY_RUN" == "1" ]]
}

# wiz_is_verbose: Check if verbose mode is enabled
# Usage: if wiz_is_verbose; then ...
wiz_is_verbose() {
    [[ "$WIZ_VERBOSE" == "1" ]]
}

# wiz_is_force: Check if force reinstall is enabled
# Usage: if wiz_is_force; then ...
wiz_is_force() {
    [[ "$WIZ_FORCE_REINSTALL" == "1" ]]
}

# Ensure directories exist
mkdir -p "$WIZ_LOG_DIR"
mkdir -p "$WIZ_SSH_FINGERPRINT_CACHE_DIR"
mkdir -p "$WIZ_STATE_DIR"

# --- Logging Functions ---
# All logging functions write to both stdout/stderr (for user visibility) and
# the log file (for troubleshooting). Log levels control verbosity:
#   0 = DEBUG (detailed diagnostic information)
#   1 = INFO  (normal operational messages)
#   2 = WARN  (warning messages, non-fatal)
#   3 = ERROR (error messages, may be fatal)

# timestamp: Returns current ISO 8601 timestamp in UTC
# Usage: timestamp
# Output: 2025-01-15T14:30:00Z
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# _write_log: Internal function to write to log file
_write_log() {
    local level="$1"
    shift
    echo "[$(timestamp)] [$level] $*" >> "$LOG_FILE"
}

# debug: Debug-level log (dim cyan) - level 0
debug() {
    local level="${LOG_LEVEL:-1}"
    [[ $level -le 0 ]] || return 0
    # Defensive color variable initialization
    local dim="${DIM:-}"
    local cyan="${CYAN:-}"
    local nc="${NC:-}"
    [[ -z "$dim" ]] && dim='\033[2m'
    [[ -z "$cyan" ]] && cyan='\033[0;36m'
    [[ -z "$nc" ]] && nc='\033[0m'
    echo -e "${dim}${cyan}[DEBUG]${nc} $*" >&2
    # Only call _write_log if it's available (defensive for trap contexts)
    if declare -f _write_log >/dev/null 2>&1; then
        _write_log "DEBUG" "$@"
    fi
}

# log: Info-level log (green) - level 1
log() {
    local level="${LOG_LEVEL:-1}"
    [[ $level -le 1 ]] || return 0
    # Ensure color variables are available (defensive)
    local green="${GREEN:-}"
    local nc="${NC:-}"
    [[ -z "$green" ]] && green='\033[0;32m'
    [[ -z "$nc" ]] && nc='\033[0m'
    echo -e "${green}→${nc} $*"
    # Only call _write_log if it's available (defensive for trap contexts)
    if declare -f _write_log >/dev/null 2>&1; then
        _write_log "INFO" "$@"
    fi
}

# warn: Warning-level log (yellow) - level 2
warn() {
    local level="${LOG_LEVEL:-1}"
    [[ $level -le 2 ]] || return 0
    echo -e "${YELLOW}⚠${NC} $*" >&2
    # Only call _write_log if it's available (defensive for trap contexts)
    if declare -f _write_log >/dev/null 2>&1; then
        _write_log "WARN" "$@"
    fi
}

# error: Error-level log (red) - level 3
# Usage: error "message" ["troubleshooting_hint"]
error() {
    # Ensure color variables are available (defensive)
    local red="${RED:-}"
    local nc="${NC:-}"
    local bold="${BOLD:-}"
    [[ -z "$red" ]] && red='\033[0;31m'
    [[ -z "$nc" ]] && nc='\033[0m'
    [[ -z "$bold" ]] && bold='\033[1m'
    
    echo -e "${red}✖${nc} $1" >&2
    
    # Show troubleshooting hint if provided as second argument
    if [[ -n "${2:-}" ]]; then
        echo -e "${bold}  💡 Troubleshooting:${nc} $2" >&2
    fi
    
    # Only call _write_log if it's available (defensive for trap contexts)
    if declare -f _write_log >/dev/null 2>&1; then
        _write_log "ERROR" "$@"
    fi
}

# success: Success message (bold green)
success() {
    # Ensure color variables are available (defensive)
    local green="${GREEN:-}"
    local bold="${BOLD:-}"
    local nc="${NC:-}"
    [[ -z "$green" ]] && green='\033[0;32m'
    [[ -z "$bold" ]] && bold='\033[1m'
    [[ -z "$nc" ]] && nc='\033[0m'
    echo -e "${green}${bold}✓${nc} $*"
    # Only call _write_log if it's available (defensive for trap contexts)
    if declare -f _write_log >/dev/null 2>&1; then
        _write_log "SUCCESS" "$@"
    fi
}

# progress: Show progress indicator
progress() {
    # Defensive color variable initialization
    local blue="${BLUE:-}"
    local nc="${NC:-}"
    [[ -z "$blue" ]] && blue='\033[0;34m'
    [[ -z "$nc" ]] && nc='\033[0m'
    echo -e "${blue}⋯${nc} $*"
    # Only call _write_log if it's available (defensive for trap contexts)
    if declare -f _write_log >/dev/null 2>&1; then
        _write_log "PROGRESS" "$@"
    fi
}

# --- Command Execution ---
# Three execution modes:
#   run        - Safe execution, no shell interpretation (preferred); captures output
#   run_stream - Safe execution, no shell interpretation; streams output to terminal
#                Use for long-running commands: apt-get, nvm install, npm, etc.
#   run_shell  - Shell execution with eval; use only when pipes/redirects needed
#
# Features:
# - Dry-run mode support (shows commands without executing)
# - Automatic logging of all commands and their results
# - Verbose mode support for debugging
# - Proper error handling and exit code propagation

# _run_common_pre: Shared pre-execution logic
# Returns 0 if should skip execution (dry-run), 1 if should execute
_run_common_pre() {
    local display_cmd="$1"

    if [[ $DRY_RUN -eq 1 ]]; then
        local dim="${DIM:-\033[2m}"
        local nc="${NC:-\033[0m}"
        echo -e "${dim}[DRY-RUN]${nc} $display_cmd"
        declare -f _write_log >/dev/null 2>&1 && _write_log "DRY-RUN" "$display_cmd"
        return 0
    fi

    [[ $VERBOSE -eq 1 ]] && debug "Executing: $display_cmd"
    declare -f _write_log >/dev/null 2>&1 && _write_log "EXEC" "$display_cmd"
    return 1
}

# _run_common_post: Shared post-execution logic
_run_common_post() {
    local exit_code="$1"
    local display_cmd="$2"

    if [[ $exit_code -eq 0 ]]; then
        [[ $VERBOSE -eq 1 ]] && debug "Success: $display_cmd"
        return 0
    fi

    # Provide helpful hints for common errors
    local troubleshooting=""
    case "$display_cmd" in
        *apt-get*) troubleshooting="Check: sudo apt-get update && sudo apt-get install -f" ;;
        *git*) troubleshooting="Check: git config --global user.name and user.email are set" ;;
        *ssh*) troubleshooting="Check: SSH keys are present in ~/.ssh/ and added to GitHub" ;;
    esac

    if [[ -n "$troubleshooting" ]]; then
        error "Command failed (exit $exit_code): $display_cmd" "$troubleshooting"
    else
        error "Command failed (exit $exit_code): $display_cmd"
    fi
    return $exit_code
}

# run: Execute command safely without shell interpretation
# Usage: run command arg1 arg2 ...
# Example: run chmod 700 "$ssh_dir"
# Example: run git config --global user.name "$name"
# Returns: Exit code of the executed command (or 0 in dry-run mode)
# NOTE: Does NOT support pipes, redirects, or shell expansions. Use run_shell for those.
run() {
    # Build display string with space separator (IFS may be set to newline)
    local display_cmd="${*}"
    # If IFS is non-standard, rebuild with spaces
    if [[ "$IFS" != $' \t\n' ]]; then
        display_cmd=""
        local arg
        for arg in "$@"; do
            display_cmd="${display_cmd:+$display_cmd }$arg"
        done
    fi

    if _run_common_pre "$display_cmd"; then
        return 0
    fi

    # Execute command directly - safe, no eval
    local exit_code=0
    local output
    output=$("$@" 2>&1) || exit_code=$?

    # Filter harmless systemd warnings from apt
    echo "$output" | grep -v -E 'Failed to (stop|start).*service: Unit.*not loaded' || true

    _run_common_post "$exit_code" "$display_cmd"
}

# run_stream: Execute command safely, streaming output directly to terminal
# Usage: run_stream command arg1 arg2 ...
# Example: run_stream sudo apt-get install -y curl wget
# Example: run_stream npm config set fund false
# Use instead of run() for long-running commands where the user should see output.
# stdout/stderr are passed through; the log file receives EXEC/SUCCESS/ERROR records only.
# Returns: Exit code of the executed command (or 0 in dry-run mode)
# NOTE: Does NOT support pipes, redirects, or shell expansions. Use run_shell for those.
run_stream() {
    # Build display string (IFS may be set to newline)
    local display_cmd="${*}"
    if [[ "$IFS" != $' \t\n' ]]; then
        display_cmd=""
        local arg
        for arg in "$@"; do
            display_cmd="${display_cmd:+$display_cmd }$arg"
        done
    fi

    if _run_common_pre "$display_cmd"; then
        return 0
    fi

    # Execute directly — stdout/stderr stream to terminal unchanged
    local exit_code=0
    "$@" || exit_code=$?

    _run_common_post "$exit_code" "$display_cmd"
}

# run_shell: Execute command string with shell interpretation
# Usage: run_shell "command with pipes | and redirects > file"
# Example: run_shell "curl -fsSL '$url' | bash"
# WARNING: Only use when shell features (pipes, redirects, subshells) are required.
#          Caller is responsible for proper quoting of variables.
# Returns: Exit code of the executed command (or 0 in dry-run mode)
run_shell() {
    local cmd="$*"

    if _run_common_pre "$cmd"; then
        return 0
    fi

    # Execute with eval - required for pipes and redirects
    local exit_code=0
    local output
    output=$(eval "$cmd" 2>&1) || exit_code=$?

    # Filter harmless systemd warnings from apt
    echo "$output" | grep -v -E 'Failed to (stop|start).*service: Unit.*not loaded' || true

    _run_common_post "$exit_code" "$cmd"
}

# --- Environment Detection ---

# detect_os: Detect operating system
# Reads /etc/os-release with grep rather than sourcing it to avoid polluting
# the script's namespace with OS variables (NAME, VERSION, ID, etc.).
detect_os() {
    if [[ -f /etc/os-release ]]; then
        local os_id
        os_id="$(grep -m1 '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr -d "'")"
        echo "${os_id:-unknown}"
    else
        echo "unknown"
    fi
}

# detect_shell: Detect current shell
detect_shell() {
    basename "${SHELL:-bash}"
}

# is_wsl: Check if running in WSL
is_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

# is_macos: Check if running on macOS
is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# is_linux: Check if running on Linux
is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# sed_inplace: Portable in-place sed that works on both GNU (Linux) and BSD (macOS)
# Usage: sed_inplace 'command' file
# Example: sed_inplace 's/foo/bar/g' myfile.txt
# Example: sed_inplace '/pattern/d' myfile.txt
sed_inplace() {
    local cmd="$1"
    local file="$2"

    if [[ ! -f "$file" ]]; then
        error "sed_inplace: file not found: $file"
        return 1
    fi

    # Detect sed variant by checking for GNU sed
    if sed --version >/dev/null 2>&1; then
        # GNU sed (Linux)
        sed -i "$cmd" "$file"
    else
        # BSD sed (macOS) - requires empty string for no backup
        sed -i '' "$cmd" "$file"
    fi
}

# detect_windows_user: Auto-detect Windows username for WSL environments
detect_windows_user() {
    # Try to get Windows username from whoami.exe if available
    if command -v whoami.exe >/dev/null 2>&1; then
        local win_user
        win_user=$(whoami.exe 2>/dev/null | tr -d '\r\n' | sed 's/.*\\//')
        [[ -n "$win_user" ]] && echo "$win_user" && return 0
    fi
    
    # Try to get from USERNAME environment variable (common in WSL)
    if [[ -n "${USERNAME:-}" ]]; then
        echo "$USERNAME"
        return 0
    fi
    
    # Fallback: scan /mnt/c/Users/ for first non-system directory
    if [[ -d /mnt/c/Users ]]; then
        local user_dir dir_basename
        for user_dir in /mnt/c/Users/*; do
            [[ -d "$user_dir" ]] || continue
            dir_basename="$(basename "$user_dir")"
            # Skip system directories
            [[ "$dir_basename" == "Public" ]]       && continue
            [[ "$dir_basename" == "Default" ]]      && continue
            [[ "$dir_basename" == "Default User" ]] && continue
            echo "$dir_basename"
            return 0
        done
    fi
    
    return 1
}

# extract_ssh_keys_from_archive: Extract SSH keys from tar.gz archive
# Usage: extract_ssh_keys_from_archive <archive_path> <target_dir>
extract_ssh_keys_from_archive() {
    local archive="$1"
    local target_dir="$2"
    
    [[ -f "$archive" ]] || return 1
    
    # Extract archive to temp directory
    local temp_extract
    temp_extract="$(mktemp -d)"
    tar --no-absolute-names -xzf "$archive" -C "$temp_extract" 2>/dev/null || {
        rm -rf "$temp_extract"
        return 1
    }
    
    # Check if archive contains .ssh directory
    if [[ -d "$temp_extract/.ssh" ]]; then
        # Archive contains .ssh directory, copy all files from it
        local keyfile key_basename
        for keyfile in "$temp_extract/.ssh"/*; do
            [[ -e "$keyfile" ]] || break
            [[ -f "$keyfile" ]] || continue
            key_basename="$(basename "$keyfile")"
            cp "$keyfile" "$target_dir/$key_basename" 2>/dev/null || true

            # Set correct permissions
            if [[ "$key_basename" != *.pub ]]; then
                chmod 600 "$target_dir/$key_basename" 2>/dev/null || true
            else
                chmod 644 "$target_dir/$key_basename" 2>/dev/null || true
            fi
        done
    else
        # Archive contents are directly in root, copy all key files
        local keyfile key_basename
        for keyfile in "$temp_extract"/*; do
            [[ -e "$keyfile" ]] || break
            [[ -f "$keyfile" ]] || continue
            key_basename="$(basename "$keyfile")"
            cp "$keyfile" "$target_dir/$key_basename" 2>/dev/null || true

            # Set correct permissions
            if [[ "$key_basename" != *.pub ]]; then
                chmod 600 "$target_dir/$key_basename" 2>/dev/null || true
            else
                chmod 644 "$target_dir/$key_basename" 2>/dev/null || true
            fi
        done
    fi
    
    # Clean up temp directory
    rm -rf "$temp_extract"
    return 0
}

# --- File Operations ---

# atomic_write: Write content to file only if it differs (idempotent)
# Usage: atomic_write <file> <content>
atomic_write() {
    local file="$1"
    local content="$2"
    
    if [[ -f "$file" ]] && echo "$content" | diff -q "$file" - >/dev/null 2>&1; then
        debug "File unchanged, skipping write: $file"
        return 0
    fi
    
    debug "Writing file: $file"
    echo "$content" > "$file"
}

# backup_file: Create timestamped backup before modifying
# Usage: backup_file <file>
backup_file() {
    local file="$1"
    
    [[ -f "$file" ]] || return 0
    
    local backup_dir="${HOME}/.wiz/backups"
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_file="${backup_dir}/$(basename "$file").${timestamp}.bak"
    
    mkdir -p "$backup_dir"
    run cp "$file" "$backup_file"
    debug "Backed up: $file -> $backup_file"
}

# append_to_file_once: Add content to file if not already present
# Usage: append_to_file_once <file> <marker> <content>
append_to_file_once() {
    local file="$1"
    local marker="$2"
    local content="$3"

    if [[ $DRY_RUN -eq 1 ]]; then
        log "[DRY-RUN] Would append to $file (marker: $marker)"
        return 0
    fi

    [[ -f "$file" ]] || touch "$file"

    if grep -Fq "$marker" "$file" 2>/dev/null; then
        debug "Content already present in $file (marker: $marker)"
        return 0
    fi

    debug "Appending to $file"
    echo "$content" >> "$file"
}

# --- Command and Package Utilities ---

# command_exists: Check if a command is available
# Usage: command_exists <command>
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Package Manager Abstraction ---
# Supports: apt (Debian/Ubuntu), dnf/yum (Fedora/RHEL), pacman (Arch), brew (macOS)

# Cache the detected package manager to avoid repeated detection
_WIZ_PKG_MANAGER=""

# detect_pkg_manager: Detect the system's package manager
# Usage: pkg_mgr=$(detect_pkg_manager)
# Returns: apt, dnf, yum, pacman, brew, or "unknown"
detect_pkg_manager() {
    # Return cached value if available
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
            # Unknown package manager - assume not installed
            return 1
            ;;
    esac
}

# pkg_update: Update package manager cache (cross-platform)
# Usage: pkg_update
pkg_update() {
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    case "$pkg_mgr" in
        apt)
            run_stream env DEBIAN_FRONTEND=noninteractive sudo apt-get update -y
            ;;
        dnf)
            run_stream sudo dnf check-update -y || true  # dnf returns 100 if updates available
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
# Usage: pkg_upgrade
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
# Usage: pkg_clean
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
            # Remove orphaned packages only when there are some to remove.
            # pacman -Qdtq returns empty output (not an error) when no orphans exist;
            # passing an empty string to pacman -Rns is an error, so we must guard.
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

# install_package: Install package if not already installed (cross-platform)
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
# Usage: install_packages package1 package2 package3
install_packages() {
    local packages=("$@")
    local to_install=()
    local pkg_mgr
    pkg_mgr=$(detect_pkg_manager)

    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

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

    # Verify all packages were installed
    for pkg in "${to_install[@]}"; do
        if ! package_installed "$pkg"; then
            error "Package installation verification failed: $pkg"
            return 1
        fi
    done

    return 0
}

# --- Progress Indicators ---

# progress_bar: Display a progress bar with elapsed time and ETA
# Usage: progress_bar <current> <total> <description> [start_time]
progress_bar() {
    local current=$1
    local total=$2
    local desc="${3:-}"
    local start_time="${4:-}"

    # Guard: zero total would cause division-by-zero under set -e
    if [[ $total -eq 0 ]]; then
        return 0
    fi

    local percent=$((current * 100 / total))
    # Clamp percent to [0,100] in case current > total
    [[ $percent -gt 100 ]] && percent=100
    [[ $percent -lt 0 ]]   && percent=0
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    # Defensive color variable initialization
    local blue="${BLUE:-}"
    local nc="${NC:-}"
    [[ -z "$blue" ]] && blue='\033[0;34m'
    [[ -z "$nc" ]] && nc='\033[0m'
    
    # Calculate elapsed time and ETA if start_time provided
    local time_info=""
    if [[ -n "$start_time" ]] && [[ "$start_time" != "0" ]] && [[ "$start_time" =~ ^[0-9]+$ ]]; then
        local elapsed
        elapsed=$(($(date +%s) - start_time))
        local elapsed_str
        elapsed_str=$(printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60)))
        
        # Estimate remaining time (simple linear estimation)
        if [[ $current -gt 0 ]] && [[ $elapsed -gt 0 ]]; then
            local avg_time_per_module
            avg_time_per_module=$((elapsed / current))
            local remaining_modules
            remaining_modules=$((total - current))
            local eta_seconds
            eta_seconds=$((avg_time_per_module * remaining_modules))
            local eta_str
            eta_str=$(printf "%02d:%02d" $((eta_seconds / 60)) $((eta_seconds % 60)))
            time_info=" [${elapsed_str} elapsed, ~${eta_str} remaining]"
        else
            time_info=" [${elapsed_str} elapsed]"
        fi
    fi
    
    # Build bar using printf width trick — avoids spawning seq subprocesses
    local bar_filled bar_empty
    bar_filled="$(printf '%*s' "$filled" '' | tr ' ' '#')"
    bar_empty="$(printf '%*s' "$empty" '')"
    printf "\r${blue}[%s%s]${nc} %3d%% %s%s" \
        "$bar_filled" "$bar_empty" \
        "$percent" \
        "$desc" \
        "$time_info"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# spinner: Show a spinner while a command runs
# Usage: spinner <pid_or_cmd> [description]
# When passed a PID, waits for that process. When passed a command string,
# executes it via bash -c (caller controls shell interpretation).
spinner() {
    local cmd="$1"
    local desc="${2:-Processing...}"
    local pid
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    # If $cmd looks like a PID (all digits), wait for it; else run via bash -c
    if [[ "$cmd" =~ ^[0-9]+$ ]]; then
        pid="$cmd"
    else
        bash -c "$cmd" &
        pid=$!
    fi
    
    # Defensive color variable initialization
    local blue="${BLUE:-}"
    local nc="${NC:-}"
    local green="${GREEN:-}"
    [[ -z "$blue" ]] && blue='\033[0;34m'
    [[ -z "$nc" ]] && nc='\033[0m'
    [[ -z "$green" ]] && green='\033[0;32m'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${blue}%s${nc} %s" "${spinstr:0:1}" "$desc"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    wait $pid
    local exit_code=$?
    printf "\r${green}✓${nc} %s\n" "$desc"
    
    return $exit_code
}

# --- Banner Display ---

# show_banner: Display application banner
show_banner() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🌌  WIZ - TERMINAL MAGIC  ✨                            ║
║                                                            ║
║   Modular Developer Environment Bootstrapper              ║
║   https://github.com/jwogrady/wiz                          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

EOF
}

# --- Repository Management ---

# prepare_code_repo: Ensures ~/code exists and cleans repo_dir for fresh clone
# Usage: prepare_code_repo <repo_dir>
prepare_code_repo() {
    local repo_dir="$1"
    
    mkdir -p "$HOME/code"
    
    if [[ -d "$repo_dir" ]]; then
        warn "Removing existing directory: $repo_dir"
        run rm -rf "$repo_dir"
    fi
}

# --- Download and Installation Helpers ---

# verify_sha256: Compare a file's SHA-256 digest against an expected value
# Usage: verify_sha256 <file> <expected_hex_digest>
# Returns 0 on match, 1 on mismatch, 2 if sha256sum/shasum unavailable (warns, not fatal)
verify_sha256() {
    local file="$1"
    local expected="$2"

    local sha_cmd=""
    if command_exists sha256sum; then
        sha_cmd="sha256sum"
    elif command_exists shasum; then
        sha_cmd="shasum -a 256"
    else
        warn "sha256sum/shasum not available — skipping checksum verification for $(basename "$file")"
        return 2
    fi

    local actual
    actual="$($sha_cmd "$file" | awk '{print $1}')"

    if [[ "$actual" != "$expected" ]]; then
        error "SHA-256 mismatch for $(basename "$file")"
        error "  expected: $expected"
        error "  actual:   $actual"
        return 1
    fi

    debug "SHA-256 verified: $(basename "$file")"
    return 0
}

# download_to_temp: Download a URL to a mktemp file; print the temp path to stdout
# Usage: tmp=$(download_to_temp <url> <error_message>)
# Caller is responsible for deleting the file when done.
download_to_temp() {
    local url="$1"
    local error_msg="${2:-Failed to download installer}"

    local tmp_file
    tmp_file="$(mktemp)"
    chmod 600 "$tmp_file"

    curl_or_wget_download "$url" "$tmp_file" "$error_msg" || {
        rm -f "$tmp_file"
        return 1
    }

    echo "$tmp_file"
}

# curl_or_wget_download: Download using curl or wget with fallback
# Usage: curl_or_wget_download <url> [output_file] [error_message]
curl_or_wget_download() {
    local url="$1"
    local output_file="${2:-}"
    local error_msg="${3:-Failed to download}"

    if command_exists curl; then
        if [[ -n "$output_file" ]]; then
            run curl -fsSL -o "$output_file" "$url" || {
                warn "curl download failed, trying wget..."
                if command_exists wget; then
                    run wget -q -O "$output_file" "$url" || {
                        error "$error_msg"
                        return 1
                    }
                else
                    error "$error_msg: Neither curl nor wget available"
                    return 1
                fi
            }
        else
            run curl -fsSL "$url" || {
                warn "curl download failed, trying wget..."
                if command_exists wget; then
                    run wget -qO- "$url" || {
                        error "$error_msg"
                        return 1
                    }
                else
                    error "$error_msg: Neither curl nor wget available"
                    return 1
                fi
            }
        fi
    elif command_exists wget; then
        if [[ -n "$output_file" ]]; then
            run wget -q -O "$output_file" "$url" || {
                error "$error_msg"
                return 1
            }
        else
            run wget -qO- "$url" || {
                error "$error_msg"
                return 1
            }
        fi
    else
        error "$error_msg: Neither curl nor wget available"
        return 1
    fi

    return 0
}

# curl_or_wget_pipe: Pipe download directly to bash
# Usage: curl_or_wget_pipe <url> [additional_args] [error_message]
# NOTE: Uses run_shell because pipes require shell interpretation
curl_or_wget_pipe() {
    local url="$1"
    local additional_args="${2:-}"
    local error_msg="${3:-Failed to download and execute installer}"

    # Quote URL for shell safety
    local quoted_url
    quoted_url=$(printf '%q' "$url")

    if command_exists curl; then
        run_shell "curl -fsSL $quoted_url | bash $additional_args" || {
            warn "curl installation failed, trying wget..."
            if command_exists wget; then
                run_shell "wget -qO- $quoted_url | bash $additional_args" || {
                    error "$error_msg"
                    return 1
                }
            else
                error "$error_msg: Neither curl nor wget available"
                return 1
            fi
        }
    elif command_exists wget; then
        run_shell "wget -qO- $quoted_url | bash $additional_args" || {
            error "$error_msg"
            return 1
        }
    else
        error "$error_msg: Neither curl nor wget available"
        return 1
    fi

    return 0
}

# get_command_version: Extract version from command output consistently
# Usage: version=$(get_command_version <command> [version_pattern])
get_command_version() {
    local cmd="$1"
    local pattern="${2:-version}"
    
    if ! command_exists "$cmd"; then
        echo "unknown"
        return 1
    fi
    
    # Try different version extraction methods with timeout and stdin redirect
    local version=""
    
    # Try --version first (most common)
    if version=$(timeout 2 "$cmd" --version </dev/null 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/^v//' 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi
    
    # Try -v
    if version=$(timeout 2 "$cmd" -v </dev/null 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/^v//' 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi
    
    # Try -version
    if version=$(timeout 2 "$cmd" -version </dev/null 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/^v//' 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi
    
    # Fallback: try to extract version from first line
    if version=$(timeout 2 "$cmd" --version </dev/null 2>/dev/null | head -n1 2>/dev/null); then
        # Extract first version-like string
        version=$(echo "$version" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
        [[ -n "$version" ]] && echo "$version" && return 0
    fi
    
    echo "unknown"
    return 1
}

# check_command_installed: Check if command is installed
# Usage: if check_command_installed <command> [command_name]; then return; fi
# Returns 0 if already installed and should skip, 1 if should install
# Note: Caller should handle module_skip if returning 0
check_command_installed() {
    local cmd="$1"
    local cmd_name="${2:-$cmd}"
    
    if command_exists "$cmd"; then
        local current_version
        current_version="$(get_command_version "$cmd")"
        
        if [[ "${WIZ_FORCE_REINSTALL:-0}" != "1" ]]; then
            log "${cmd_name} already installed: v${current_version}"
            return 0  # Skip installation
        else
            log "${cmd_name} already installed: v${current_version} (forcing reinstall)"
        fi
    fi
    
    return 1  # Should install
}

# add_to_path: Add directory to PATH if not already present
# Usage: add_to_path <directory>
add_to_path() {
    local dir="$1"
    
    [[ -d "$dir" ]] || return 1
    
    if [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
        debug "Added $dir to PATH"
    fi
    
    return 0
}

# verify_command_exists: Verify command exists and optionally get version
# Usage: verify_command_exists <command> [display_name]
# Returns 0 on success, 1 on failure (caller handles failed counter)
verify_command_exists() {
    local cmd="$1"
    local display_name="${2:-$cmd}"
    
    if ! command_exists "$cmd"; then
        error "${display_name} command not found"
        return 1
    else
        local version
        version="$(get_command_version "$cmd")"
        success "✓ ${display_name} v${version}"
        return 0
    fi
}

# verify_file_or_dir: Verify file or directory exists
# Usage: verify_file_or_dir <path> [display_name] [is_warning]
# Returns 0 if exists, 1 if not (caller handles failed counter)
verify_file_or_dir() {
    local path="$1"
    local display_name="${2:-$path}"
    local is_warning="${3:-0}"
    
    if [[ -e "$path" ]]; then
        success "✓ ${display_name}"
        return 0
    else
        if [[ $is_warning -eq 1 ]]; then
            warn "${display_name} not found: $path"
        else
            error "${display_name} not found: $path"
        fi
        return 1
    fi
}

# --- Hooks System ---
# Allows extensibility through user-defined scripts in hooks directories
# Hooks are executed in alphabetical order and can be placed in:
#   - hooks/pre-install.d/   - Run before module installation begins
#   - hooks/post-install.d/  - Run after module installation completes
#   - hooks/pre-module.d/    - Run before each module (receives module name as $1)
#   - hooks/post-module.d/   - Run after each module (receives module name as $1)

readonly WIZ_HOOKS_DIR="${WIZ_ROOT}/hooks"

# run_hooks: Execute all hooks in a directory
# Usage: run_hooks "pre-install" [args...]
# Returns: 0 if all hooks succeed, 1 if any hook fails (continues on failure)
run_hooks() {
    local stage="$1"
    shift
    local hook_dir="${WIZ_HOOKS_DIR}/${stage}.d"

    # Skip if hooks directory doesn't exist
    [[ -d "$hook_dir" ]] || return 0

    local hook
    local failed=0

    # Run hooks in sorted order
    for hook in "$hook_dir"/*.sh; do
        # Skip if no hooks found (glob didn't match)
        [[ -e "$hook" ]] || continue

        # Skip non-executable hooks
        if [[ ! -x "$hook" ]]; then
            debug "Skipping non-executable hook: $(basename "$hook")"
            continue
        fi

        local hook_name
        hook_name=$(basename "$hook")
        debug "Running hook: $hook_name"

        if wiz_is_dry_run; then
            log "[DRY-RUN] Would run hook: $hook_name"
        else
            if "$hook" "$@"; then
                debug "Hook completed: $hook_name"
            else
                warn "Hook failed: $hook_name (continuing)"
                failed=1
            fi
        fi
    done

    return $failed
}

# run_hook_if_exists: Run a single named hook file if it exists
# Usage: run_hook_if_exists "pre-install/setup.sh" [args...]
run_hook_if_exists() {
    local hook_path="$1"
    shift
    local full_path="${WIZ_HOOKS_DIR}/${hook_path}"

    [[ -x "$full_path" ]] || return 0

    debug "Running hook: $hook_path"
    if wiz_is_dry_run; then
        log "[DRY-RUN] Would run hook: $hook_path"
        return 0
    fi

    "$full_path" "$@"
}

# --- Export Functions ---
export -f wiz_config_get wiz_config_set wiz_is_dry_run wiz_is_verbose wiz_is_force
export -f run_hooks run_hook_if_exists
export -f timestamp log warn error success debug progress
export -f run run_stream run_shell _run_common_pre _run_common_post
export -f atomic_write backup_file append_to_file_once
export -f command_exists detect_pkg_manager package_installed
export -f pkg_update pkg_upgrade pkg_clean
export -f install_package install_packages
export -f detect_os detect_shell is_wsl is_macos is_linux sed_inplace
export -f detect_windows_user extract_ssh_keys_from_archive
export -f progress_bar spinner show_banner prepare_code_repo
export -f curl_or_wget_download curl_or_wget_pipe get_command_version
export -f check_command_installed add_to_path verify_command_exists verify_file_or_dir

# --- Error Handling ---
# Trap errors and print helpful message with line number and command
# Set trap AFTER all functions are defined and logging is initialized
# Use defensive checks to ensure both error and _write_log functions exist
trap 'if declare -f error >/dev/null 2>&1 && declare -f _write_log >/dev/null 2>&1; then error "Script failed at line $LINENO: $BASH_COMMAND"; else echo "ERROR: Script failed at line $LINENO: $BASH_COMMAND" >&2; fi' ERR

# Log library initialization
debug "Common library loaded from: ${BASH_SOURCE[0]}"
debug "Wiz root: $WIZ_ROOT"

# ==============================================================================
# SSH FINGERPRINT CACHING
# ==============================================================================

# get_cached_ssh_fingerprint: Get SSH key fingerprint with caching
# Usage: fingerprint=$(get_cached_ssh_fingerprint <key_file>)
# Returns: Fingerprint (MD5 or SHA256 format) or empty string on error
get_cached_ssh_fingerprint() {
    local key_file="$1"
    [[ -f "$key_file" ]] || return 1
    
    local key_basename
    key_basename="$(basename "$key_file")"
    local cache_file="${SSH_FINGERPRINT_CACHE_DIR}/${key_basename}.fingerprint"
    local cache_mtime_file="${SSH_FINGERPRINT_CACHE_DIR}/${key_basename}.mtime"
    
    # Get key file modification time
    local key_mtime
    key_mtime="$(stat -c %Y "$key_file" 2>/dev/null || stat -f %m "$key_file" 2>/dev/null || echo "0")"
    
    # Check if cache exists and is fresh
    if [[ -f "$cache_file" ]] && [[ -f "$cache_mtime_file" ]]; then
        local cached_mtime
        cached_mtime="$(cat "$cache_mtime_file" 2>/dev/null || echo "0")"
        
        # If mtime matches, use cached fingerprint
        if [[ "$key_mtime" == "$cached_mtime" ]]; then
            local cached_fingerprint
            cached_fingerprint="$(cat "$cache_file" 2>/dev/null || echo "")"
            if [[ -n "$cached_fingerprint" ]]; then
                debug "Using cached fingerprint for: $key_basename"
                echo "$cached_fingerprint"
                return 0
            fi
        fi
    fi
    
    # Generate fingerprint (extract MD5 or SHA256 format)
    if ! command_exists ssh-keygen; then
        return 1
    fi
    
    local fingerprint
    fingerprint=$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}' || echo "")
    
    if [[ -n "$fingerprint" ]]; then
        # Save to cache
        echo "$fingerprint" > "$cache_file"
        echo "$key_mtime" > "$cache_mtime_file"
        debug "Cached fingerprint for: $key_basename"
    fi
    
    echo "$fingerprint"
}
debug "Log file: $LOG_FILE"
debug "Dry-run: $DRY_RUN"
