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

# show_preflight: Pre-run mission briefing
# Usage: show_preflight <ordered_modules_space_separated>
# Calls is_disabled / is_module_complete — available at call time via module-base.sh.
show_preflight() {
    local ordered_modules="$1"
    local module_array
    IFS=' ' read -ra module_array <<< "$ordered_modules"

    local mode_label
    if [[ "${WIZ_DRY_RUN:-0}" == "1" ]]; then
        mode_label="${YELLOW}DRY RUN${NC}"
    else
        mode_label="live"
    fi

    local bash_ver="${BASH_VERSION%%(*}"

    local will_install=() will_skip=()
    local m
    for m in "${module_array[@]}"; do
        if is_disabled "$m"; then
            continue
        elif is_module_complete "$m" && [[ "${WIZ_FORCE_REINSTALL:-0}" != "1" ]]; then
            will_skip+=("$m")
        else
            will_install+=("$m")
        fi
    done

    local count=${#will_install[@]}
    local plural; [[ $count -ne 1 ]] && plural="s" || plural=""
    local sep="  ─────────────────────────────────────────────────"

    echo ""
    printf "%s\n" "$sep"
    printf "  ${BOLD}%d module%s${NC}  ·  %b  ·  Bash %s\n" \
        "$count" "$plural" "$mode_label" "$bash_ver"
    printf "%s\n" "$sep"
    echo ""

    local mod_file raw_desc desc
    for m in "${will_install[@]+"${will_install[@]}"}"; do
        mod_file="${MODULES_DIR:-${WIZ_ROOT}/lib/modules}/install_${m}.sh"
        desc=""
        if [[ -f "$mod_file" ]]; then
            raw_desc=$(grep -m1 '^MODULE_DESCRIPTION=' "$mod_file" 2>/dev/null || true)
            if [[ -n "$raw_desc" ]]; then
                raw_desc="${raw_desc#MODULE_DESCRIPTION=}"
                raw_desc="${raw_desc#\"}" ; raw_desc="${raw_desc%\"}"
                raw_desc="${raw_desc#\'}" ; raw_desc="${raw_desc%\'}"
                desc="$raw_desc"
            fi
        fi
        if [[ -n "$desc" ]]; then
            printf "  ${CYAN}▶${NC}  %-14s  ${DIM}%s${NC}\n" "$m" "$desc"
        else
            printf "  ${CYAN}▶${NC}  %s\n" "$m"
        fi
    done

    if [[ ${#will_skip[@]} -gt 0 ]]; then
        echo ""
        for m in "${will_skip[@]}"; do
            printf "  ${DIM}⊘  %-14s  already installed${NC}\n" "$m"
        done
    fi

    local log_display="${WIZ_LOG_FILE:-}"
    log_display="${log_display/#$HOME/\~}"

    echo ""
    printf "  ${DIM}Log  %s${NC}\n" "$log_display"
    echo ""
}

# show_module_header: Per-module progress line printed before execution
# Usage: show_module_header <current> <total> <module>
show_module_header() {
    local current="$1" total="$2" module="$3"
    echo ""
    printf "  ${BLUE}[%d/%d]${NC}  ${BOLD}%s${NC}\n" "$current" "$total" "$module"
    echo ""
}

# show_module_result: Status line printed after each module execution
# Usage: show_module_result <module> <ok|skip|fail> <elapsed_seconds>
show_module_result() {
    local module="$1" status="$2" elapsed="${3:-0}"
    case "$status" in
        ok)   printf "  ${GREEN}✓${NC}  %-14s  ${DIM}%ss${NC}\n" "$module" "$elapsed" ;;
        skip) printf "  ${DIM}⊘  %-14s  already installed${NC}\n" "$module" ;;
        fail) printf "  ${RED}✖${NC}  %-14s  ${DIM}%ss${NC}\n" "$module" "$elapsed" ;;
    esac
}

# show_launch_summary: Final screen shown after full install
# Usage: show_launch_summary <skip_identity> <git_name> <git_email>
# Reads MODULES_COMPLETED / MODULES_FAILED / MODULES_SKIPPED from module-base.sh globals.
show_launch_summary() {
    local skip_identity="${1:-0}"
    local git_name="${2:-}"
    local git_email="${3:-}"

    local sep="  ─────────────────────────────────────────────────"
    local log_display="${WIZ_LOG_FILE:-}"
    log_display="${log_display/#$HOME/\~}"

    local total_ran
    total_ran=$(( ${MODULES_COMPLETED:-0} + ${MODULES_FAILED:-0} \
        + ${MODULES_SKIPPED:-0} ))

    echo ""
    printf "%s\n" "$sep"

    if [[ ${MODULES_FAILED:-0} -eq 0 ]]; then
        printf "  ${GREEN}${BOLD}✓  Wiz complete${NC}\n"
    else
        printf "  ${RED}${BOLD}✖  Installation incomplete${NC}\n"
    fi

    printf "%s\n" "$sep"
    echo ""

    if [[ $total_ran -gt 0 ]]; then
        local _stats=""
        [[ ${MODULES_COMPLETED:-0} -gt 0 ]] && \
            _stats="${MODULES_COMPLETED} installed"
        [[ ${MODULES_FAILED:-0} -gt 0 ]] && {
            [[ -n "$_stats" ]] && _stats+="  ·  "
            _stats+="${MODULES_FAILED} failed"
        }
        [[ ${MODULES_SKIPPED:-0} -gt 0 ]] && {
            [[ -n "$_stats" ]] && _stats+="  ·  "
            _stats+="${MODULES_SKIPPED} skipped"
        }
        [[ -n "$_stats" ]] && printf "  %s\n" "$_stats"
        echo ""
    fi

    if [[ "$skip_identity" == "0" ]] && [[ -n "$git_name" ]]; then
        printf "  ${BOLD}Git${NC}    %s <%s>\n" "$git_name" "$git_email"
        echo ""
    fi

    printf "  ${BOLD}Next${NC}   exec zsh\n"
    printf "         ${DIM}or exec bash${NC}\n"
    echo ""
    printf "  ${DIM}Log${NC}    %s\n" "$log_display"

    if [[ "$skip_identity" == "1" ]]; then
        echo ""
        printf \
            "  ${DIM}Identity:  ./bin/install --skip-modules${NC}\n"
    fi

    echo ""
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
export -f show_preflight show_module_header show_module_result show_launch_summary

debug "UI helpers library loaded"
