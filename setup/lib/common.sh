#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source=/etc/os-release
# ------------------------------------------------------------------------------
# Wiz - Terminal Magic: Common Utilities Library
# Provides colorized logging, error handling, atomic file writes, and environment detection.
# Sourced by all major scripts for consistency and maintainability.
# ------------------------------------------------------------------------------

set -euo pipefail

# --- Color Codes ---
# Used for colorized terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Logging Functions ---
# timestamp: Returns current date/time for log entries
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
# log: Info-level log (green)
log() { echo -e "${GREEN}[$(timestamp)] [INFO] $*${NC}"; }
# warn: Warning-level log (yellow)
warn() { echo -e "${YELLOW}[$(timestamp)] [WARN] $*${NC}" >&2; }
# error: Error-level log (red)
error() { echo -e "${RED}[$(timestamp)] [ERROR] $*${NC}" >&2; }

# --- Error Handling ---
# Trap errors and print a helpful message with line number and command
trap 'error "Script failed at line $LINENO: $BASH_COMMAND"' ERR

# --- Code Directory and Repo Management ---
# prepare_code_repo <repo_dir>
# Ensures ~/code exists and deletes the repo_dir if it exists (for a fresh clone)
prepare_code_repo() {
	local repo_dir="$1"
	mkdir -p "$(dirname "$repo_dir")"
	if [ -d "$repo_dir" ]; then
		log "Removing existing source at $repo_dir..."
		run "rm -rf '$repo_dir'"
	fi
}

# --- Atomic Write ---
# atomic_write <file> <content>
# Writes content to a file only if it differs from the current content (idempotent)
atomic_write() {
	local file="$1"
	local tmpfile="${file}.tmp.$$"
	cat >"$tmpfile"
	if ! cmp -s "$tmpfile" "$file" 2>/dev/null; then
		mv "$tmpfile" "$file"
		log "Updated $file"
	else
		rm "$tmpfile"
		log "$file unchanged"
	fi
}

# --- OS Detection ---
# detect_os: Returns the OS ID (e.g., ubuntu, debian, arch)
detect_os() {
	if [ -f /etc/os-release ]; then
		# shellcheck source=/etc/os-release
		. /etc/os-release
		echo "$ID"
	else
		uname -s | tr '[:upper:]' '[:lower:]'
	fi
}

# --- Shell Detection ---
# detect_shell: Returns the current shell name (e.g., bash, zsh)
detect_shell() {
	basename "$SHELL"
}

# --- Dry-Run Support ---
# run: Executes a command, or logs it if DRY_RUN=1
run() {
	if [[ "${DRY_RUN:-0}" -eq 1 ]]; then log "[DRY-RUN] $*"; else eval "$*"; fi
}

# Export all utility functions for use in subshells
export -f log warn error atomic_write detect_os detect_shell run prepare_code_repo
