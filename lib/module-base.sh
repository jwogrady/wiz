#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: Module Base Library
# ==============================================================================
# Provides standard interface for all installation modules and manages
# module dependencies with topological sorting.
#
# Every module must implement:
#   install_<name>()  - Main installation logic
#   verify_<name>()   - Verification that installation succeeded
#   describe_<name>() - Human-readable description of what will be installed
#
# Module Metadata (set in each module):
#   MODULE_NAME        - Unique module identifier (e.g., "essentials")
#   MODULE_VERSION     - Semantic version (e.g., "2.0.0")
#   MODULE_DESCRIPTION - Human-readable description
#   MODULE_DEPS        - Space-separated list of dependencies
#
# Usage:
#   source /path/to/lib/module-base.sh
#
# State Management:
#   - mark_module_complete <module>
#   - mark_module_failed <module> <error>
#   - is_module_complete <module>
#   - get_module_state <module>
#
# Dependency Management:
#   - get_dependencies <module>
#   - get_install_order <module1> <module2> ...
#   - show_dependency_graph
#
# Module Verification Helpers:
#   - check_command_installed <cmd> [display_name]
#   - add_to_path <directory>
#   - verify_command_exists <cmd> [display_name]
#   - verify_file_or_dir <path> [display_name] [is_warning]
#
# Orchestration (used by bin/install):
#   - list_modules
#   - is_disabled <module>
#   - show_installation_summary <ordered_modules>
#   - show_statistics
#   - execute_module_wrapper <module>
#   - run_module_installation
#
# ==============================================================================

set -euo pipefail

# Re-source guard: prevents double-initialization when module-base.sh is sourced
# inside a subshell that already inherited the exported functions (e.g. list_modules).
if [[ -n "${_WIZ_MODULE_BASE_LOADED:-}" ]]; then
    return 0 2>/dev/null || true
fi
_WIZ_MODULE_BASE_LOADED=1
export _WIZ_MODULE_BASE_LOADED

# --- Ensure common.sh is sourced ---
if ! declare -f log >/dev/null 2>&1; then
    # shellcheck source=common.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

# ==============================================================================
# DEPENDENCY MANAGEMENT
# ==============================================================================

# --- Module Dependencies Map ---
# Populated at startup by discover_modules() — do not edit manually.
# Use register_module <name> <deps> to add entries.
declare -gA MODULE_DEPS_MAP=()

# register_module: Add a module to the dependency map
# Usage: register_module <name> [deps]
register_module() {
    local name="$1"
    local deps="${2:-}"
    MODULE_DEPS_MAP["$name"]="$deps"
    debug "Registered module: ${name} (deps: ${deps:-none})"
}

# discover_modules: Scan a directory for install_*.sh files and register each
# Reads MODULE_NAME and MODULE_DEPS by parsing each file (no sourcing needed).
# Prints discovered module names to stdout, one per line.
# Usage: mapfile -t DEFAULT_MODULES < <(discover_modules "$MODULES_DIR")
discover_modules() {
    local modules_dir="$1"
    local module_file name deps

    for module_file in "${modules_dir}"/install_*.sh; do
        [[ -f "$module_file" ]] || continue

        # Parse metadata with grep+sed — avoids sourcing and side effects
        name="$(grep -m1 '^MODULE_NAME=' "$module_file" \
            | sed 's/^MODULE_NAME=//; s/^"//; s/"$//')"
        deps="$(grep -m1 '^MODULE_DEPS=' "$module_file" \
            | sed 's/^MODULE_DEPS=//; s/^"//; s/"$//')"

        if [[ -z "$name" ]]; then
            warn "discover_modules: no MODULE_NAME in $(basename "$module_file"), skipping"
            continue
        fi

        register_module "$name" "$deps"
        echo "$name"
    done
}

# --- Dependency Resolution Functions ---

# get_dependencies: Get dependencies for a module
# Usage: deps=$(get_dependencies <module>)
get_dependencies() {
    local module="$1"
    echo "${MODULE_DEPS_MAP[$module]:-}"
}

# --- Topological Sort State (module-scope globals, reset per get_install_order call) ---
_GIO_ORDERED=()
_GIO_VISITED=()
_GIO_VISITING=()

# _gio_remove: Remove element from a named global array
# Usage: _gio_remove _GIO_VISITING "module"
# Requires Bash 4.3+ for local -n nameref
_gio_remove() {
    local -n _gio_ref=$1
    local _gio_elem=$2
    local _gio_new=()
    local _gio_v
    for _gio_v in "${_gio_ref[@]+"${_gio_ref[@]}"}"; do
        [[ "$_gio_v" != "$_gio_elem" ]] && _gio_new+=("$_gio_v")
    done
    _gio_ref=("${_gio_new[@]+"${_gio_new[@]}"}")
}

# _gio_visit: DFS visit for topological sort; operates on _GIO_* globals
_gio_visit() {
    local module="$1"

    # Already visited?
    local v
    for v in "${_GIO_VISITED[@]+"${_GIO_VISITED[@]}"}"; do
        [[ "$v" == "$module" ]] && return 0
    done

    # Circular dependency check
    for v in "${_GIO_VISITING[@]+"${_GIO_VISITING[@]}"}"; do
        if [[ "$v" == "$module" ]]; then
            error "Circular dependency detected: $module"
            return 1
        fi
    done

    _GIO_VISITING+=("$module")

    local deps
    deps="$(get_dependencies "$module")"
    if [[ -n "$deps" ]] && [[ "$deps" != "ALL" ]]; then
        local dep
        for dep in $deps; do
            _gio_visit "$dep" || return 1
        done
    fi

    _gio_remove _GIO_VISITING "$module"
    _GIO_VISITED+=("$module")
    _GIO_ORDERED+=("$module")
}

# get_install_order: Calculate installation order based on dependencies
# Usage: ordered_modules=$(get_install_order module1 module2 module3)
get_install_order() {
    _GIO_ORDERED=()
    _GIO_VISITED=()
    _GIO_VISITING=()

    local module
    for module in "$@"; do
        _gio_visit "$module" || return 1
    done

    echo "${_GIO_ORDERED[@]}"
}


# verify_dependencies: Verify all module dependencies can be met
# Usage: if verify_dependencies; then ...
verify_dependencies() {
    local failed=0
    
    for module in "${!MODULE_DEPS_MAP[@]}"; do
        local deps="${MODULE_DEPS_MAP[$module]}"

        { [[ -z "$deps" ]] || [[ "$deps" == "ALL" ]]; } && continue

        for dep in $deps; do
            if [[ ! -v MODULE_DEPS_MAP[$dep] ]]; then
                error "Module $module depends on unknown module: $dep"
                failed=1
            fi
        done
    done
    
    return $failed
}

# show_dependency_graph: Display module dependencies
show_dependency_graph() {
    echo "Module Dependency Graph:"
    echo "======================="
    
    for module in "${!MODULE_DEPS_MAP[@]}"; do
        local deps="${MODULE_DEPS_MAP[$module]}"

        if [[ -z "$deps" ]]; then
            echo "  $module (no dependencies)"
        else
            echo "  $module → $deps"
        fi
    done | sort
}

# ==============================================================================
# MODULE STATE CONFIGURATION
# ==============================================================================
# WIZ_STATE_DIR is defined in common.sh, but ensure it exists if this is sourced independently
: "${WIZ_STATE_DIR:=$HOME/.wiz/state}"
mkdir -p "$WIZ_STATE_DIR"

# Module metadata defaults (override in each module)
MODULE_NAME="${MODULE_NAME:-unknown}"
MODULE_VERSION="${MODULE_VERSION:-1.0.0}"
MODULE_DESCRIPTION="${MODULE_DESCRIPTION:-No description}"
MODULE_DEPS="${MODULE_DEPS:-}"

# --- Module Lifecycle Functions ---

# module_start: Log module installation start (debug-level; shown only with --verbose)
module_start() {
    debug ""
    debug "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local bold="${BOLD:-}"
    local nc="${NC:-}"
    [[ -z "$bold" ]] && bold='\033[1m'
    [[ -z "$nc" ]] && nc='\033[0m'
    debug "Module: ${bold}${MODULE_NAME}${nc}"
    debug "Version: ${MODULE_VERSION}"
    debug "Description: ${MODULE_DESCRIPTION}"
    [[ -n "$MODULE_DEPS" ]] && debug "Dependencies: $MODULE_DEPS"
    debug "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    debug ""
}

# module_complete: Mark module as successfully completed
module_complete() {
    mark_module_complete "$MODULE_NAME"
    success "Module completed: $MODULE_NAME"
}

# module_skip: Log skipped installation
module_skip() {
    local reason="${1:-Already installed}"
    log "Skipping $MODULE_NAME: $reason"
}

# module_fail: Log failure and exit
module_fail() {
    local msg="${1:-Installation failed}"
    mark_module_failed "$MODULE_NAME" "$msg"
    error "Module failed: $MODULE_NAME - $msg"
    exit 1
}

# --- State Management ---

# mark_module_complete: Mark module as successfully installed
mark_module_complete() {
    local module="$1"
    local state_file="$WIZ_STATE_DIR/$module"
    
    cat > "$state_file" << EOF
STATUS=complete
TIMESTAMP=$(date +%s)
VERSION="${MODULE_VERSION}"
DESCRIPTION="${MODULE_DESCRIPTION}"
EOF
    
    debug "Marked complete: $module"
}

# mark_module_failed: Mark module as failed
mark_module_failed() {
    local module="$1"
    local error_msg="${2:-Unknown error}"
    local state_file="$WIZ_STATE_DIR/$module"
    
    cat > "$state_file" << EOF
STATUS=failed
TIMESTAMP=$(date +%s)
ERROR="${error_msg}"
EOF
    
    debug "Marked failed: $module"
}

# _parse_state_value: Safely extract a value from state file (no sourcing)
# Usage: value=$(_parse_state_value "$state_file" "KEY")
_parse_state_value() {
    local state_file="$1"
    local key="$2"
    [[ -f "$state_file" ]] || return 1
    # Extract value using grep+sed - safe, no code execution
    grep -m1 "^${key}=" "$state_file" 2>/dev/null | sed "s/^${key}=//"
}

# is_module_complete: Check if module was previously completed
is_module_complete() {
    local module="$1"
    local state_file="$WIZ_STATE_DIR/$module"

    [[ -f "$state_file" ]] || return 1

    # Safe parsing - no source/eval
    local status
    status=$(_parse_state_value "$state_file" "STATUS")
    [[ "$status" == "complete" ]]
}

# get_module_state: Get module state information
get_module_state() {
    local module="$1"
    local state_file="$WIZ_STATE_DIR/$module"

    if [[ ! -f "$state_file" ]]; then
        echo "not-started"
        return
    fi

    # Safe parsing - no source/eval
    local status
    status=$(_parse_state_value "$state_file" "STATUS")
    echo "${status:-unknown}"
}

# --- Module Interface Validation ---

# validate_module_interface: Ensure module implements required functions
validate_module_interface() {
    local module_name="$1"
    local missing=()
    
    # Check for required functions
    if ! declare -f "install_${module_name}" >/dev/null 2>&1; then
        missing+=("install_${module_name}")
    fi
    
    if ! declare -f "verify_${module_name}" >/dev/null 2>&1; then
        missing+=("verify_${module_name}")
    fi
    
    if ! declare -f "describe_${module_name}" >/dev/null 2>&1; then
        missing+=("describe_${module_name}")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Module $module_name missing required functions: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# --- Module Execution Wrapper ---

# execute_module: Run module with standard lifecycle
execute_module() {
    local module_name="$1"
    
    # Validate interface
    if ! validate_module_interface "$module_name"; then
        module_fail "Invalid module interface"
    fi
    
    # Start module (shows module header)
    module_start
    
    # Check if already complete (before showing description)
    if is_module_complete "$module_name" && [[ "${WIZ_FORCE_REINSTALL:-0}" != "1" ]]; then
        module_skip "Already completed (use WIZ_FORCE_REINSTALL=1 to override)"
        return 0
    fi
    
    # Show description only if module will actually be installed
    # This reduces clutter for already-installed modules
    "describe_${module_name}"
    
    # Run installation
    if "install_${module_name}"; then
        # Verify installation
        if "verify_${module_name}"; then
            module_complete
            return 0
        else
            module_fail "Verification failed"
        fi
    else
        module_fail "Installation failed"
    fi
}

# _module_banner: Print a section separator with a title
# Usage: _module_banner "TITLE STRING"
# All describe_* functions use this to avoid duplicating the separator literal.
_module_banner() {
    local title="$1"
    local sep="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf '\n%s\n%s\n%s\n' "$sep" "$title" "$sep"
}

# ==============================================================================
# MODULE VERIFICATION HELPERS
# ==============================================================================
# These functions are module-specific concerns moved here from common.sh.
# They depend on get_command_version (from download.sh via common.sh).

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

# wiz_add_shell_block: Idempotently append a block to ~/.bashrc and ~/.zshrc.
# Skips rc files that do not exist. Dry-run delegated to append_to_file_once.
# Usage: wiz_add_shell_block <sentinel> <block>
# sentinel: unique string present inside block (e.g. ">>> NVM init >>>")
# block:    full text to append (must contain the sentinel string)
wiz_add_shell_block() {
    local sentinel="$1"
    local block="$2"

    local rc_file
    for rc_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        [[ -f "$rc_file" ]] || continue
        append_to_file_once "$rc_file" "$sentinel" "$block"
    done
}

# wiz_update_shell_block: Remove an existing wiz-managed block then append updated version.
# Operates on a single rc file. Call once per shell (bash/zsh) with the appropriate block.
# Usage: wiz_update_shell_block <start_sentinel> <end_sentinel> <block> <rc_file>
# Constraints: start_sentinel and end_sentinel must not contain '/' (sed delimiter).
# Safety: if start_sentinel is present but end_sentinel is absent, warns and skips
#         deletion to avoid deleting content from the sentinel to EOF.
wiz_update_shell_block() {
    local start_sentinel="$1"
    local end_sentinel="$2"
    local block="$3"
    local rc_file="$4"

    [[ -f "$rc_file" ]] || return 0

    if [[ ${WIZ_DRY_RUN:-0} -eq 1 ]]; then
        log "[DRY-RUN] Would update shell block '${start_sentinel}' in ${rc_file}"
        return 0
    fi

    if grep -qF "$start_sentinel" "$rc_file" 2>/dev/null; then
        if ! grep -qF "$end_sentinel" "$rc_file" 2>/dev/null; then
            warn "Block '${start_sentinel}' has no closing sentinel in ${rc_file} — skipping removal to avoid data loss"
        else
            sed_inplace "/${start_sentinel}/,/${end_sentinel}/d" "$rc_file"
        fi
    fi

    printf '%s\n' "$block" >> "$rc_file"
    debug "Shell block '${start_sentinel}' updated in ${rc_file}"
}

# ==============================================================================
# MODULE ORCHESTRATION
# ==============================================================================
# Globals and functions for running modules in order. Declared here so that
# bin/install can populate REQUESTED_MODULES/DISABLED_MODULES from CLI args and
# call run_module_installation() without redefining the execution engine.

MODULES_DIR="${WIZ_ROOT}/lib/modules"
DISABLED_MODULES=()
REQUESTED_MODULES=()
# DEFAULT_MODULES is populated at startup by:
#   mapfile -t DEFAULT_MODULES < <(discover_modules "$MODULES_DIR")
DEFAULT_MODULES=()

# Counters (reset at the start of each run_module_installation call)
MODULES_COMPLETED=0
MODULES_FAILED=0
MODULES_SKIPPED=0

# list_modules: Print all available modules with version and description
list_modules() {
    echo "Available Modules:"
    echo "=================="
    echo ""

    for module_file in "${MODULES_DIR}"/install_*.sh; do
        [[ -f "$module_file" ]] || continue

        local module_name
        module_name="$(basename "$module_file" .sh)"
        module_name="${module_name#install_}"

        (
            # shellcheck source=/dev/null
            if ! source "$module_file" 2>/dev/null; then
                printf "  %-15s v%-8s %s\n" \
                    "$module_name" \
                    "ERROR" \
                    "Failed to load module"
                exit 1
            fi

            # Show CLI override version if set for this module
            local override_var="WIZ_${module_name^^}_VERSION"
            local override_val="${!override_var:-}"
            local version_display="${MODULE_VERSION:-unknown}"
            if [[ -n "$override_val" ]]; then
                version_display="${MODULE_VERSION:-unknown} (target: ${override_val})"
            fi
            printf "  %-15s %-18s %s\n" \
                "$module_name" \
                "$version_display" \
                "${MODULE_DESCRIPTION:-No description}"
        ) || warn "Could not read module: $module_name"
    done

    echo ""
}

# is_disabled: Check if a module is in the DISABLED_MODULES list
is_disabled() {
    local module="$1"

    for disabled in "${DISABLED_MODULES[@]+"${DISABLED_MODULES[@]}"}"; do
        [[ "$module" == "$disabled" ]] && return 0
    done

    return 1
}

# execute_module_wrapper: Load and run a single module file, update counters
execute_module_wrapper() {
    local module="$1"
    local module_file="${MODULES_DIR}/install_${module}.sh"

    if [[ ! -f "$module_file" ]]; then
        local available
        available="$(printf '%s\n' "${MODULES_DIR}"/install_*.sh \
            | sed 's|.*/install_||;s|\.sh$||' \
            | tr '\n' ' ')"
        error "Module not found: $module" "Available modules: ${available}"
        return 1
    fi

    if is_disabled "$module"; then
        log "Module disabled: $module"
        MODULES_SKIPPED=$((MODULES_SKIPPED + 1))
        return 0
    fi

    if is_module_complete "$module" && [[ "${WIZ_FORCE_REINSTALL:-0}" != "1" ]]; then
        log "Module already completed: $module (use --force to reinstall)"
        MODULES_SKIPPED=$((MODULES_SKIPPED + 1))
        return 0
    fi

    # Run pre-module hooks
    run_hooks "pre-module" "$module"

    log "Executing module: $module"

    if (
        # shellcheck source=/dev/null
        source "$module_file"
        execute_module "$module"
    ); then
        MODULES_COMPLETED=$((MODULES_COMPLETED + 1))
        # Run post-module hooks on success
        run_hooks "post-module" "$module"
        return 0
    else
        MODULES_FAILED=$((MODULES_FAILED + 1))
        error "Module failed: $module"

        if [[ "${WIZ_STOP_ON_ERROR:-1}" == "1" ]]; then
            error "Stopping due to error (set WIZ_STOP_ON_ERROR=0 to continue)"
            return 1
        fi

        return 0
    fi
}

# show_installation_summary: Display what will be installed before starting
show_installation_summary() {
    local ordered_modules="$1"
    local modules_to_install=()
    local modules_to_skip=()

    # Convert space-separated string to array
    local module_array
    IFS=' ' read -ra module_array <<< "$ordered_modules"

    # Categorize modules
    for module in "${module_array[@]}"; do
        if is_disabled "$module"; then
            continue  # Skip disabled modules
        elif is_module_complete "$module" && [[ "${WIZ_FORCE_REINSTALL:-0}" != "1" ]]; then
            modules_to_skip+=("$module")
        else
            modules_to_install+=("$module")
        fi
    done

    # Display summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  INSTALLATION PLAN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ ${#modules_to_install[@]} -gt 0 ]]; then
        local install_display
        install_display="$(IFS=' '; echo "${modules_to_install[*]}")"
        printf "  📦 Will install:   %s\n" "$install_display"
        printf "  Total modules:    %d\n" "${#modules_to_install[@]}"
    else
        printf "  📦 Will install:   (none - all modules completed)\n"
    fi

    if [[ ${#modules_to_skip[@]} -gt 0 ]]; then
        local skip_display
        skip_display="$(IFS=' '; echo "${modules_to_skip[*]}")"
        printf "  ⊘ Will skip:       %s\n" "$skip_display"
        printf "  Skipped count:    %d\n" "${#modules_to_skip[@]}"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# show_statistics: Print post-run module counters
show_statistics() {
    local total=$((MODULES_COMPLETED + MODULES_FAILED + MODULES_SKIPPED))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  INSTALLATION STATISTICS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    printf "  Total modules:    %d\n" "$total"
    printf "  ✓ Completed:      %d\n" "$MODULES_COMPLETED"
    printf "  ⊘ Skipped:        %d\n" "$MODULES_SKIPPED"
    printf "  ✖ Failed:         %d\n" "$MODULES_FAILED"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# run_module_installation: Top-level orchestrator — sort, plan, execute all modules
# Requires init_config() to be defined by the caller (bin/install).
run_module_installation() {
    debug "Wiz Module Installation v${WIZ_VERSION}"

    # Reset counters for this run
    MODULES_COMPLETED=0
    MODULES_FAILED=0
    MODULES_SKIPPED=0

    init_config

    if [[ ${#DEFAULT_MODULES[@]} -eq 0 ]]; then
        error "No modules found in ${MODULES_DIR}"
        return 1
    fi

    if [[ ${#REQUESTED_MODULES[@]} -eq 0 ]]; then
        REQUESTED_MODULES=("${DEFAULT_MODULES[@]}")
    fi

    debug "Modules requested: $(IFS=' '; echo "${REQUESTED_MODULES[*]}")"
    [[ ${#DISABLED_MODULES[@]} -gt 0 ]] && \
        debug "Modules disabled: $(IFS=' '; echo "${DISABLED_MODULES[*]}")"

    if ! verify_dependencies; then
        error "Dependency verification failed"
        return 1
    fi

    debug "Resolving dependencies..."

    local ordered_modules
    if ordered_modules=$(get_install_order "${REQUESTED_MODULES[@]}"); then
        debug "Installation order: $ordered_modules"
    else
        error "Failed to resolve dependencies"
        return 1
    fi

    # Preflight mission briefing
    show_preflight "$ordered_modules"

    # Run pre-install hooks
    run_hooks "pre-install"

    # Convert space-separated string to array
    local module_array
    IFS=' ' read -ra module_array <<< "$ordered_modules"

    local total=${#module_array[@]}
    local current=0
    local _prev_skipped _mod_start _elapsed

    for module in "${module_array[@]}"; do
        current=$((current + 1))
        _prev_skipped=$MODULES_SKIPPED
        _mod_start=$(date +%s)

        show_module_header "$current" "$total" "$module"

        if ! execute_module_wrapper "$module"; then
            _elapsed=$(( $(date +%s) - _mod_start ))
            show_module_result "$module" "fail" "$_elapsed"
            error "Module failed: $module — try: ./bin/install --module=$module --verbose --debug"

            if [[ "${WIZ_STOP_ON_ERROR:-1}" == "1" ]]; then
                error "Stopping on error  (WIZ_STOP_ON_ERROR=0 to continue)"
                return 1
            fi
        elif [[ $MODULES_SKIPPED -gt $_prev_skipped ]]; then
            show_module_result "$module" "skip" "0"
        else
            _elapsed=$(( $(date +%s) - _mod_start ))
            show_module_result "$module" "ok" "$_elapsed"
        fi
    done

    # Run post-install hooks
    run_hooks "post-install"

    echo ""
    [[ $MODULES_FAILED -eq 0 ]] && return 0 || return 1
}

# --- Export Functions ---
export -f module_start module_complete module_skip module_fail
export -f mark_module_complete mark_module_failed is_module_complete get_module_state _parse_state_value
export -f validate_module_interface execute_module
export -f get_dependencies get_install_order verify_dependencies _gio_remove _gio_visit
export -f show_dependency_graph _module_banner
export -f register_module discover_modules
export -f check_command_installed add_to_path verify_command_exists verify_file_or_dir
export -f wiz_add_shell_block wiz_update_shell_block
export -f list_modules is_disabled show_installation_summary show_statistics
export -f execute_module_wrapper run_module_installation

debug "Module base library loaded"
