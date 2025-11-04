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
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
# MAGENTA reserved for future use
# readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# --- Configuration ---
# shellcheck disable=SC2155
readonly WIZ_ROOT="${WIZ_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${WIZ_ROOT}/logs"
DRY_RUN="${WIZ_DRY_RUN:-0}"
LOG_LEVEL="${WIZ_LOG_LEVEL:-1}"
# shellcheck disable=SC2155
LOG_FILE="${WIZ_LOG_FILE:-${LOG_DIR}/install_$(date +%F).log}"
VERBOSE="${WIZ_VERBOSE:-0}"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# --- Logging Functions ---

# timestamp: Returns current ISO 8601 timestamp
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# _write_log: Internal function to write to log file
# In dry-run mode, truncate verbose logs to reduce file size
_write_log() {
    local level="$1"
    shift
    local message="$*"
    
    # In dry-run mode, truncate very long messages to prevent log bloat
    if [[ $DRY_RUN -eq 1 ]] && [[ ${#message} -gt 500 ]]; then
        message="${message:0:500}... [truncated in dry-run]"
    fi
    
    echo "[$(timestamp)] [$level] $message" >> "$LOG_FILE"
}

# debug: Debug-level log (dim cyan) - level 0
debug() {
    [[ $LOG_LEVEL -le 0 ]] || return 0
    echo -e "${DIM}${CYAN}[DEBUG]${NC} $*" >&2
    _write_log "DEBUG" "$@"
}

# log: Info-level log (green) - level 1
log() {
    [[ $LOG_LEVEL -le 1 ]] || return 0
    echo -e "${GREEN}→${NC} $*"
    _write_log "INFO" "$@"
}

# warn: Warning-level log (yellow) - level 2
warn() {
    [[ $LOG_LEVEL -le 2 ]] || return 0
    echo -e "${YELLOW}⚠${NC} $*" >&2
    _write_log "WARN" "$@"
}

# error: Error-level log (red) - level 3
error() {
    echo -e "${RED}✖${NC} $*" >&2
    _write_log "ERROR" "$@"
}

# success: Success message (bold green)
success() {
    echo -e "${GREEN}${BOLD}✓${NC} $*"
    _write_log "SUCCESS" "$@"
}

# progress: Show progress indicator
progress() {
    echo -e "${BLUE}⋯${NC} $*"
    _write_log "PROGRESS" "$@"
}

# --- Command Execution ---

# run: Execute command with dry-run support
# Usage: run "command to execute"
run() {
    local cmd="$*"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "${DIM}[DRY-RUN]${NC} $cmd"
        _write_log "DRY-RUN" "$cmd"
        return 0
    fi
    
    if [[ $VERBOSE -eq 1 ]]; then
        debug "Executing: $cmd"
    fi
    
    _write_log "EXEC" "$cmd"
    
    if eval "$cmd"; then
        [[ $VERBOSE -eq 1 ]] && debug "Success: $cmd"
        return 0
    else
        local exit_code=$?
        error "Command failed (exit $exit_code): $cmd"
        return $exit_code
    fi
}

# --- Error Handling ---

# Trap errors and print helpful message with line number and command
trap 'error "Script failed at line $LINENO: $BASH_COMMAND"' ERR

# --- Environment Detection ---

# detect_os: Detect operating system
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
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
    grep -qi microsoft /proc/version 2>/dev/null
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
        for user_dir in /mnt/c/Users/*; do
            [[ -d "$user_dir" ]] || continue
            local basename
            basename="$(basename "$user_dir")"
            # Skip system directories
            [[ "$basename" == "Public" ]] && continue
            [[ "$basename" == "Default" ]] && continue
            [[ "$basename" == "Default User" ]] && continue
            echo "$basename"
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
    tar -xzf "$archive" -C "$temp_extract" 2>/dev/null || {
        rm -rf "$temp_extract"
        return 1
    }
    
    # Check if archive contains .ssh directory
    if [[ -d "$temp_extract/.ssh" ]]; then
        # Archive contains .ssh directory, copy all files from it
        for keyfile in "$temp_extract/.ssh"/*; do
            [[ -f "$keyfile" ]] || continue
            local basename
            basename="$(basename "$keyfile")"
            cp "$keyfile" "$target_dir/$basename" 2>/dev/null || true
            
            # Set correct permissions
            if [[ "$basename" != *.pub ]]; then
                chmod 600 "$target_dir/$basename" 2>/dev/null || true
            else
                chmod 644 "$target_dir/$basename" 2>/dev/null || true
            fi
        done
    else
        # Archive contents are directly in root, copy all key files
        for keyfile in "$temp_extract"/*; do
            [[ -f "$keyfile" ]] || continue
            local basename
            basename="$(basename "$keyfile")"
            cp "$keyfile" "$target_dir/$basename" 2>/dev/null || true
            
            # Set correct permissions
            if [[ "$basename" != *.pub ]]; then
                chmod 600 "$target_dir/$basename" 2>/dev/null || true
            else
                chmod 644 "$target_dir/$basename" 2>/dev/null || true
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
    run "cp '$file' '$backup_file'"
    debug "Backed up: $file -> $backup_file"
}

# append_to_file_once: Add content to file if not already present
# Usage: append_to_file_once <file> <marker> <content>
append_to_file_once() {
    local file="$1"
    local marker="$2"
    local content="$3"
    
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

# package_installed: Check if a package is installed (apt)
# Usage: package_installed <package>
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# install_package: Install package if not already installed
# Usage: install_package <package>
install_package() {
    local pkg="$1"
    
    if package_installed "$pkg"; then
        debug "Package already installed: $pkg"
        return 0
    fi
    
    log "Installing package: $pkg"
    run "sudo apt-get install -y '$pkg'"
}

# install_packages: Install multiple packages
# Usage: install_packages package1 package2 package3
install_packages() {
    local packages=("$@")
    local to_install=()
    
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
    run "sudo apt-get install -y ${to_install[*]}"
}

# --- Progress Indicators ---

# progress_bar: Display a progress bar
# Usage: progress_bar <current> <total> <description>
progress_bar() {
    local current=$1
    local total=$2
    local desc="${3:-}"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${BLUE}[%-50s]${NC} %3d%% %s" \
        "$(printf '#%.0s' $(seq 1 $filled))$(printf ' %.0s' $(seq 1 $empty))" \
        "$percent" \
        "$desc"
    
    [[ $current -eq $total ]] && echo
}

# spinner: Show a spinner while a command runs
# Usage: spinner <command> [description]
spinner() {
    local cmd="$1"
    local desc="${2:-Processing...}"
    local pid
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    eval "$cmd" &
    pid=$!
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${BLUE}%s${NC} %s" "${spinstr:0:1}" "$desc"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    wait $pid
    local exit_code=$?
    printf "\r${GREEN}✓${NC} %s\n" "$desc"
    
    return $exit_code
}

# --- Banner Display ---

# show_banner: Display application banner
show_banner() {
    cat <<'EOF'

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
        run "rm -rf '$repo_dir'"
    fi
}

# --- Download and Installation Helpers ---

# curl_or_wget_download: Download using curl or wget with fallback
# Usage: curl_or_wget_download <url> [output_file] [error_message]
curl_or_wget_download() {
    local url="$1"
    local output_file="${2:-}"
    local error_msg="${3:-Failed to download}"
    
    if command_exists curl; then
        if [[ -n "$output_file" ]]; then
            run "curl -fsSL -o '$output_file' '$url'" || {
                warn "curl download failed, trying wget..."
                if command_exists wget; then
                    run "wget -q -O '$output_file' '$url'" || {
                        error "$error_msg"
                        return 1
                    }
                else
                    error "$error_msg: Neither curl nor wget available"
                    return 1
                fi
            }
        else
            run "curl -fsSL '$url'" || {
                warn "curl download failed, trying wget..."
                if command_exists wget; then
                    run "wget -qO- '$url'" || {
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
            run "wget -q -O '$output_file' '$url'" || {
                error "$error_msg"
                return 1
            }
        else
            run "wget -qO- '$url'" || {
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
curl_or_wget_pipe() {
    local url="$1"
    local additional_args="${2:-}"
    local error_msg="${3:-Failed to download and execute installer}"
    
    if command_exists curl; then
        run "curl -fsSL '$url' | bash $additional_args" || {
            warn "curl installation failed, trying wget..."
            if command_exists wget; then
                run "wget -qO- '$url' | bash $additional_args" || {
                    error "$error_msg"
                    return 1
                }
            else
                error "$error_msg: Neither curl nor wget available"
                return 1
            fi
        }
    elif command_exists wget; then
        run "wget -qO- '$url' | bash $additional_args" || {
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

# --- Export Functions ---
export -f timestamp log warn error success debug progress
export -f run atomic_write backup_file append_to_file_once
export -f command_exists package_installed install_package install_packages
export -f detect_os detect_shell is_wsl detect_windows_user extract_ssh_keys_from_archive
export -f progress_bar spinner show_banner prepare_code_repo
export -f curl_or_wget_download curl_or_wget_pipe get_command_version
export -f check_command_installed add_to_path verify_command_exists verify_file_or_dir

# Log library initialization
debug "Common library loaded from: ${BASH_SOURCE[0]}"
debug "Wiz root: $WIZ_ROOT"
debug "Log file: $LOG_FILE"
debug "Dry-run: $DRY_RUN"
