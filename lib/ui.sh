#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: UI Helpers
# ==============================================================================
# Progress bar, spinner, and banner display utilities.
#
# Normal usage: sourced transitively by lib/common.sh — callers need only:
#   source /path/to/lib/common.sh
#
# Standalone (direct) usage:
#   source /path/to/lib/ui.sh   # guard below bootstraps common.sh if needed
#
# Functions:
#   - progress_bar  <current> <total> <description> [start_time]
#   - spinner       <pid_or_cmd> [description]
#   - show_banner
#
# ==============================================================================

set -euo pipefail

# --- Ensure common.sh is sourced ---
# Defensive guard: only fires when this file is sourced directly (outside the
# normal common.sh chain).  Do NOT use WIZ_ROOT:= here — see pkg.sh for
# explanation of why that would misconfigure WIZ_ROOT.
if ! declare -f log >/dev/null 2>&1; then
    # shellcheck source=common.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

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
    [[ $percent -gt 100 ]] && percent=100
    [[ $percent -lt 0 ]]   && percent=0
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    local blue="${BLUE:-\033[0;34m}"
    local nc="${NC:-\033[0m}"

    local time_info=""
    if [[ -n "$start_time" ]] && [[ "$start_time" != "0" ]] && [[ "$start_time" =~ ^[0-9]+$ ]]; then
        local elapsed
        elapsed=$(($(date +%s) - start_time))
        local elapsed_str
        elapsed_str=$(printf "%02d:%02d" $((elapsed / 60)) $((elapsed % 60)))

        if [[ $current -gt 0 ]] && [[ $elapsed -gt 0 ]]; then
            local avg_time_per_module remaining_modules eta_seconds eta_str
            avg_time_per_module=$((elapsed / current))
            remaining_modules=$((total - current))
            eta_seconds=$((avg_time_per_module * remaining_modules))
            eta_str=$(printf "%02d:%02d" $((eta_seconds / 60)) $((eta_seconds % 60)))
            time_info=" [${elapsed_str} elapsed, ~${eta_str} remaining]"
        else
            time_info=" [${elapsed_str} elapsed]"
        fi
    fi

    local bar_filled bar_empty
    bar_filled="$(printf '%*s' "$filled" '' | tr ' ' '#')"
    bar_empty="$(printf '%*s' "$empty" '')"
    printf "\r${blue}[%s%s]${nc} %3d%% %s%s" \
        "$bar_filled" "$bar_empty" \
        "$percent" \
        "$desc" \
        "$time_info"

    [[ $current -eq $total ]] && echo
}

# spinner: Show a spinner while a command or PID runs
# Usage: spinner <pid_or_cmd> [description]
# When passed a PID (all digits), waits for that process.
# When passed a command string, executes it via bash -c.
spinner() {
    local cmd="$1"
    local desc="${2:-Processing...}"
    local pid
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    if [[ "$cmd" =~ ^[0-9]+$ ]]; then
        pid="$cmd"
    else
        bash -c "$cmd" &
        pid=$!
    fi

    local blue="${BLUE:-\033[0;34m}"
    local nc="${NC:-\033[0m}"
    local green="${GREEN:-\033[0;32m}"

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

# --- Export Functions ---
export -f progress_bar spinner show_banner

debug "UI helpers library loaded"
