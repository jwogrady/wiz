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
#   - resolve_dependencies <module>
#   - get_install_order <module1> <module2> ...
#   - show_dependency_graph
#
# ==============================================================================

set -euo pipefail

# --- Ensure common.sh is sourced ---
if ! declare -f log >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=common.sh
    source "${SCRIPT_DIR}/common.sh"
fi

# ==============================================================================
# DEPENDENCY MANAGEMENT
# ==============================================================================

# --- Module Dependencies Map ---
# This is populated dynamically by scanning modules or can be predefined
declare -gA MODULE_DEPS=(
    # Core dependencies
    [essentials]=""
    [zsh]=""
    
    # Shell enhancements depend on zsh
    [starship]="zsh"
    
    # Development tools depend on essentials
    [node]="essentials"
    [bun]="essentials"
    [neovim]="essentials"
    [docker]="essentials"
    
    # Summary runs last
    [summary]="ALL"
)

# --- Dependency Resolution Functions ---

# get_dependencies: Get dependencies for a module
# Usage: deps=$(get_dependencies <module>)
get_dependencies() {
    local module="$1"
    echo "${MODULE_DEPS[$module]:-}"
}

# has_dependencies: Check if module has dependencies
# Usage: if has_dependencies <module>; then ...
has_dependencies() {
    local module="$1"
    local deps
    deps="$(get_dependencies "$module")"
    [[ -n "$deps" ]]
}

# check_dependency: Check if a dependency is met
# Usage: if check_dependency <dep>; then ...
check_dependency() {
    local dep="$1"
    
    # Special case: "ALL" means all previous modules must complete
    [[ "$dep" == "ALL" ]] && return 0
    
    # Check if dependency module was completed successfully
    if is_module_complete "$dep"; then
        return 0
    fi
    
    return 1
}

# resolve_dependencies: Ensure all dependencies are met
# Usage: resolve_dependencies <module>
resolve_dependencies() {
    local module="$1"
    local deps
    deps="$(get_dependencies "$module")"
    
    [[ -z "$deps" ]] && return 0
    
    # Special case for "ALL"
    if [[ "$deps" == "ALL" ]]; then
        debug "Module $module requires all previous modules to complete"
        return 0
    fi
    
    # Check each dependency
    local missing_deps=()
    for dep in $deps; do
        if ! check_dependency "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Module $module has unmet dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# get_install_order: Calculate installation order based on dependencies
# Usage: ordered_modules=$(get_install_order module1 module2 module3)
get_install_order() {
    local modules=("$@")
    local ordered=()
    local visited=()
    local visiting=()
    
    # Topological sort using depth-first search
    _visit() {
        local module="$1"
        
        # Check if already visited
        for v in "${visited[@]+"${visited[@]}"}"; do
            [[ "$v" == "$module" ]] && return 0
        done
        
        # Check for circular dependency
        for v in "${visiting[@]+"${visiting[@]}"}"; do
            if [[ "$v" == "$module" ]]; then
                error "Circular dependency detected: $module"
                return 1
            fi
        done
        
        # Mark as visiting
        visiting+=("$module")
        
        # Visit dependencies first
        local deps
        deps="$(get_dependencies "$module")"
        if [[ -n "$deps" ]] && [[ "$deps" != "ALL" ]]; then
            for dep in $deps; do
                _visit "$dep" || return 1
            done
        fi
        
        # Remove from visiting, add to visited
        visiting=("${visiting[@]/$module}")
        visited+=("$module")
        ordered+=("$module")
    }
    
    # Visit each requested module
    for module in "${modules[@]}"; do
        _visit "$module" || return 1
    done
    
    # Return ordered list
    echo "${ordered[@]}"
}

# verify_dependencies: Verify all module dependencies can be met
# Usage: if verify_dependencies; then ...
verify_dependencies() {
    local failed=0
    
    for module in "${!MODULE_DEPS[@]}"; do
        local deps="${MODULE_DEPS[$module]}"
        
        [[ -z "$deps" ]] || [[ "$deps" == "ALL" ]] && continue
        
        for dep in $deps; do
            if [[ ! -v MODULE_DEPS[$dep] ]]; then
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
    
    for module in "${!MODULE_DEPS[@]}"; do
        local deps="${MODULE_DEPS[$module]}"
        
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
export WIZ_STATE_DIR="${WIZ_STATE_DIR:-$HOME/.wiz/state}"
mkdir -p "$WIZ_STATE_DIR"

# Module metadata defaults (override in each module)
MODULE_NAME="${MODULE_NAME:-unknown}"
MODULE_VERSION="${MODULE_VERSION:-1.0.0}"
MODULE_DESCRIPTION="${MODULE_DESCRIPTION:-No description}"
MODULE_DEPS="${MODULE_DEPS:-}"

# --- Module Lifecycle Functions ---

# module_start: Log module installation start
module_start() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Defensive color variable initialization
    local bold="${BOLD:-}"
    local nc="${NC:-}"
    [[ -z "$bold" ]] && bold='\033[1m'
    [[ -z "$nc" ]] && nc='\033[0m'
    log "Module: ${bold}${MODULE_NAME}${nc}"
    log "Version: ${MODULE_VERSION}"
    log "Description: ${MODULE_DESCRIPTION}"
    [[ -n "$MODULE_DEPS" ]] && log "Dependencies: $MODULE_DEPS"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
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

# is_module_complete: Check if module was previously completed
is_module_complete() {
    local module="$1"
    local state_file="$WIZ_STATE_DIR/$module"
    
    [[ -f "$state_file" ]] || return 1
    
    # shellcheck source=/dev/null
    source "$state_file"
    
    [[ "${STATUS:-}" == "complete" ]]
}

# get_module_state: Get module state information
get_module_state() {
    local module="$1"
    local state_file="$WIZ_STATE_DIR/$module"
    
    if [[ ! -f "$state_file" ]]; then
        echo "not-started"
        return
    fi
    
    # shellcheck source=/dev/null
    source "$state_file"
    echo "${STATUS:-unknown}"
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
    
    # Show description
    "describe_${module_name}"
    
    # Start module
    module_start
    
    # Check if already complete
    if is_module_complete "$module_name" && [[ "${WIZ_FORCE_REINSTALL:-0}" != "1" ]]; then
        module_skip "Already completed (use WIZ_FORCE_REINSTALL=1 to override)"
        return 0
    fi
    
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

# --- Export Functions ---
export -f module_start module_complete module_skip module_fail
export -f mark_module_complete mark_module_failed is_module_complete get_module_state
export -f validate_module_interface execute_module
export -f get_dependencies has_dependencies check_dependency
export -f resolve_dependencies get_install_order verify_dependencies
export -f show_dependency_graph

debug "Module base library loaded (with dependency management)"
