#!/usr/bin/env bash
# ==============================================================================
# validate_commit_msg.sh - Validate commit messages against Conventional Commits
# ==============================================================================
# Validates commit messages to ensure they follow the Conventional Commits
# specification as defined in commitlint.config.js
#
# Usage:
#   ./scripts/validate_commit_msg.sh <commit-msg-file>
#
# Exit codes:
#   0 - Commit message is valid
#   1 - Commit message is invalid
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WIZ_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly MAX_HEADER_LENGTH=100

# Valid commit types (from commitlint.config.js)
readonly VALID_TYPES=(
  feat fix docs style refactor perf test build ci chore revert
)

# --- Colors ---
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m'

# --- Logging Functions ---
log_error() {
  echo -e "${COLOR_RED}✗ Commit message validation failed:${COLOR_NC}" >&2
  echo -e "${COLOR_RED}  $1${COLOR_NC}" >&2
}

log_warn() {
  echo -e "${COLOR_YELLOW}⚠ $1${COLOR_NC}" >&2
}

log_info() {
  echo "$1" >&2
}

# --- Validation Functions ---

# validate_type: Check if commit type is valid
validate_type() {
  local type="$1"
  local valid=0

  for valid_type in "${VALID_TYPES[@]}"; do
    if [[ "$type" == "$valid_type" ]]; then
      valid=1
      break
    fi
  done

  if [[ $valid -eq 0 ]]; then
    log_error "Invalid type '${type}'"
    log_info "Valid types: ${VALID_TYPES[*]}"
    return 1
  fi

  return 0
}

# validate_header_format: Check header format
validate_header_format() {
  local header="$1"

  # Check format: type(scope): subject or type: subject
  # Use string matching instead of complex regex for better compatibility
  local pattern1="^[a-z]+\(.*\):"
  local pattern2="^[a-z]+:"

  if [[ "$header" =~ $pattern1 ]] || [[ "$header" =~ $pattern2 ]]; then
    # Verify there's content after the colon
    if [[ "$header" =~ :[[:space:]].+$ ]]; then
      return 0
    fi
  fi

  log_error "Invalid header format"
  log_info "Expected: <type>(<scope>): <subject> or <type>: <subject>"
  log_info "Example: feat(module): add new feature"
  log_info "Example: feat: add new feature"
  return 1
}

# validate_header_length: Check header length
validate_header_length() {
  local header="$1"
  local length=${#header}

  if [[ $length -gt $MAX_HEADER_LENGTH ]]; then
    log_error "Header exceeds ${MAX_HEADER_LENGTH} characters (${length})"
    log_info "Header: ${header:0:80}..."
    return 1
  fi

  return 0
}

# validate_subject: Check subject is not empty
validate_subject() {
  local subject="$1"

  if [[ -z "${subject// }" ]]; then
    log_error "Subject cannot be empty"
    return 1
  fi

  # Subject should not end with period
  if [[ "$subject" =~ \.$ ]]; then
    log_warn "Subject should not end with a period"
  fi

  return 0
}

# --- Main Validation ---
validate_commit_message() {
  local commit_msg_file="${1:-}"
  local errors=0

  if [[ -z "$commit_msg_file" ]] || [[ ! -f "$commit_msg_file" ]]; then
    log_error "Commit message file not provided or not found"
    return 1
  fi

  # Read commit message
  local commit_msg
  commit_msg=$(cat "$commit_msg_file")

  if [[ -z "${commit_msg// }" ]]; then
    log_error "Commit message is empty"
    return 1
  fi

  # Extract header (first line)
  local header
  header=$(echo "$commit_msg" | head -n 1)

  # Validate header format
  if ! validate_header_format "$header"; then
    ((errors++))
  fi

  # Extract type, scope, and subject using string manipulation
  local type=""
  local subject=""

  # Find the colon position
  local colon_pos
  colon_pos=$(echo "$header" | grep -b -o ":" | head -1 | cut -d: -f1 || echo "")

  if [[ -n "$colon_pos" ]]; then
    # Extract everything before colon (type and optional scope)
    local before_colon="${header:0:$colon_pos}"
    # Extract everything after colon (subject)
    subject="${header:$((colon_pos + 1))}"
    # Trim leading whitespace from subject
    subject="${subject#"${subject%%[![:space:]]*}"}"

    # Check if there's a scope in parentheses
    if [[ "$before_colon" =~ \( ]]; then
      # Extract type before opening parenthesis
      type=$(echo "$before_colon" | cut -d'(' -f1)
    else
      # No scope, entire before_colon is the type
      type="$before_colon"
    fi
  fi

  # Validate type if extracted
  if [[ -n "$type" ]]; then
    if ! validate_type "$type"; then
      ((errors++))
    fi
  fi

  # Validate subject if extracted
  if [[ -n "$subject" ]]; then
    if ! validate_subject "$subject"; then
      ((errors++))
    fi
  fi

  # Validate header length
  if ! validate_header_length "$header"; then
    ((errors++))
  fi

  # Check for merge commits (allow them)
  if [[ "$header" =~ ^Merge ]]; then
    return 0
  fi

  # Check for revert commits (allow them)
  if [[ "$header" =~ ^Revert ]]; then
    return 0
  fi

  if [[ $errors -gt 0 ]]; then
    echo ""
    log_info "Commit message:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$commit_msg" | head -n 5
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "See docs/STATUS26_BASH_STYLE_GUIDE_v1.md for commit format"
    log_info "See docs/RELEASE.md for examples"
    return 1
  fi

  return 0
}

# --- Main ---
main() {
  local commit_msg_file="${1:-}"

  if [[ -z "$commit_msg_file" ]]; then
    # Try to get commit message from git
    if command -v git >/dev/null 2>&1; then
      commit_msg_file=$(git rev-parse --git-dir)/COMMIT_EDITMSG
      if [[ ! -f "$commit_msg_file" ]]; then
        log_error "No commit message file provided"
        log_info "Usage: $0 <commit-msg-file>"
        return 1
      fi
    else
      log_error "No commit message file provided"
      log_info "Usage: $0 <commit-msg-file>"
      return 1
    fi
  fi

  if ! validate_commit_message "$commit_msg_file"; then
    return 1
  fi

  return 0
}

main "$@"
