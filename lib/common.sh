#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: Common Utilities Library
# ==============================================================================
# Core utilities: colorized logging, error handling, run/run_stream, OS/shell
# detection, file helpers, and hook runner. Sources pkg.sh, download.sh, and
# ui.sh so callers only need a single source statement.
#
# Usage:
#   source /path/to/lib/common.sh
#
# Functions (direct):
#   - log, warn, error, success, debug, progress
#   - run, run_stream, run_shell
#
# Module-specific helpers (defined in lib/module-base.sh):
#   - check_command_installed, add_to_path, verify_command_exists, verify_file_or_dir
#   - backup_file, append_to_file_once
#   - command_exists, detect_os, detect_shell, is_wsl
#   - run_hooks
#
# Functions (via sourced sub-libraries):
#   - pkg.sh:      detect_pkg_manager, install_package, install_packages, ...
#   - download.sh: verify_sha256, download_to_temp, curl_or_wget_download, ...
#   - ui.sh:       progress_bar, spinner, show_banner
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

# Backward compatibility aliases — DEPRECATED.
# Use the WIZ_ prefixed variables instead. These aliases will be removed in a
# future release. Any code still referencing LOG_DIR, CACHE_DIR, DRY_RUN,
# LOG_LEVEL, LOG_FILE, or VERBOSE should be updated to use WIZ_LOG_DIR,
# WIZ_CACHE_DIR, WIZ_DRY_RUN, WIZ_LOG_LEVEL, WIZ_LOG_FILE, or WIZ_VERBOSE.
LOG_DIR="$WIZ_LOG_DIR"           # deprecated: use WIZ_LOG_DIR
CACHE_DIR="$WIZ_CACHE_DIR"       # deprecated: use WIZ_CACHE_DIR
SSH_FINGERPRINT_CACHE_DIR="$WIZ_SSH_FINGERPRINT_CACHE_DIR"  # deprecated: use WIZ_SSH_FINGERPRINT_CACHE_DIR
DRY_RUN="$WIZ_DRY_RUN"           # deprecated: use WIZ_DRY_RUN
LOG_LEVEL="$WIZ_LOG_LEVEL"       # deprecated: use WIZ_LOG_LEVEL
LOG_FILE="$WIZ_LOG_FILE"         # deprecated: use WIZ_LOG_FILE
VERBOSE="$WIZ_VERBOSE"           # deprecated: use WIZ_VERBOSE

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

# Open a persistent append-mode file descriptor for the log file.
# Uses {varname}>> (Bash 4.1+) so the shell selects an unused FD.
# All _write_log calls write to this FD instead of re-opening the file on
# every message.  The guard prevents duplicate opens when common.sh is
# re-sourced in a subshell that already inherited the FD.
if [[ -z "${_WIZ_LOG_FD:-}" ]]; then
    exec {_WIZ_LOG_FD}>>"$WIZ_LOG_FILE"
    export _WIZ_LOG_FD
    trap 'exec {_WIZ_LOG_FD}>&-' EXIT
fi

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
    if [[ -n "${_WIZ_LOG_FD:-}" ]]; then
        echo "[$(timestamp)] [$level] $*" >&"$_WIZ_LOG_FD"
    else
        echo "[$(timestamp)] [$level] $*" >> "$WIZ_LOG_FILE"
    fi
}

# debug: Debug-level log (dim cyan) - level 0
debug() {
    local level="${WIZ_LOG_LEVEL:-1}"
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
    local level="${WIZ_LOG_LEVEL:-1}"
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
    local level="${WIZ_LOG_LEVEL:-1}"
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

# _wiz_run_pre: Shared pre-execution logic
# Returns 0 if should skip execution (dry-run), 1 if should execute
_wiz_run_pre() {
    local display_cmd="$1"

    if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
        local dim="${DIM:-\033[2m}"
        local nc="${NC:-\033[0m}"
        echo -e "${dim}[DRY-RUN]${nc} $display_cmd"
        declare -f _write_log >/dev/null 2>&1 && _write_log "DRY-RUN" "$display_cmd"
        return 0
    fi

    [[ ${WIZ_VERBOSE:-0} -eq 1 ]] && debug "Executing: $display_cmd"
    declare -f _write_log >/dev/null 2>&1 && _write_log "EXEC" "$display_cmd"
    return 1
}

# _wiz_run_post: Shared post-execution logic
_wiz_run_post() {
    local exit_code="$1"
    local display_cmd="$2"

    if [[ $exit_code -eq 0 ]]; then
        [[ ${WIZ_VERBOSE:-0} -eq 1 ]] && debug "Success: $display_cmd"
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

    if _wiz_run_pre "$display_cmd"; then
        return 0
    fi

    # Execute command directly - safe, no eval
    local exit_code=0
    local output
    output=$("$@" 2>&1) || exit_code=$?

    # Filter harmless systemd warnings from apt
    echo "$output" | grep -v -E 'Failed to (stop|start).*service: Unit.*not loaded' || true

    _wiz_run_post "$exit_code" "$display_cmd"
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

    if _wiz_run_pre "$display_cmd"; then
        return 0
    fi

    # Execute directly — stdout/stderr stream to terminal unchanged
    local exit_code=0
    "$@" || exit_code=$?

    _wiz_run_post "$exit_code" "$display_cmd"
}

# run_shell: Execute command string with shell interpretation
# Usage: run_shell "command with pipes | and redirects > file"
# Example: run_shell "curl -fsSL '$url' | bash"
# WARNING: Only use when shell features (pipes, redirects, subshells) are required.
#          Caller is responsible for proper quoting of variables.
# Returns: Exit code of the executed command (or 0 in dry-run mode)
run_shell() {
    local cmd="$*"

    if _wiz_run_pre "$cmd"; then
        return 0
    fi

    # Execute with eval - required for pipes and redirects
    local exit_code=0
    local output
    output=$(eval "$cmd" 2>&1) || exit_code=$?

    # Filter harmless systemd warnings from apt
    echo "$output" | grep -v -E 'Failed to (stop|start).*service: Unit.*not loaded' || true

    _wiz_run_post "$exit_code" "$cmd"
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

# --- File Operations ---

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

    if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
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

# --- Sub-libraries ---
# These three files are sourced here rather than at the top of the file because
# they call log(), command_exists(), run(), and run_stream() — all of which must
# be defined before the source statements execute.
# DO NOT move these source calls above the logging or run-execution sections.
# shellcheck source=pkg.sh
source "${WIZ_ROOT}/lib/pkg.sh"
# shellcheck source=download.sh
source "${WIZ_ROOT}/lib/download.sh"
# shellcheck source=ui.sh
source "${WIZ_ROOT}/lib/ui.sh"

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

# --- Export Functions ---
# Note: pkg.sh, download.sh, and ui.sh export their own functions when sourced above.
export -f wiz_config_get wiz_config_set wiz_is_dry_run wiz_is_verbose wiz_is_force
export -f run_hooks
export -f timestamp log warn error success debug progress _write_log
export -f run run_stream run_shell _wiz_run_pre _wiz_run_post
export -f backup_file append_to_file_once
export -f command_exists
export -f detect_os detect_shell is_wsl is_macos is_linux sed_inplace
export -f detect_windows_user
# --- Error Handling ---
# Trap errors and print helpful message with line number and command
# Set trap AFTER all functions are defined and logging is initialized
# Use defensive checks to ensure both error and _write_log functions exist
trap 'if declare -f error >/dev/null 2>&1 && declare -f _write_log >/dev/null 2>&1; then error "Script failed at line $LINENO: $BASH_COMMAND"; else echo "ERROR: Script failed at line $LINENO: $BASH_COMMAND" >&2; fi' ERR

# Log library initialization
debug "Common library loaded from: ${BASH_SOURCE[0]}"
debug "Wiz root: $WIZ_ROOT"

debug "Log file: $LOG_FILE"
debug "Dry-run: $WIZ_DRY_RUN"
