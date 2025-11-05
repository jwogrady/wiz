#!/usr/bin/env bash
# ==============================================================================
# check_bash_style.sh - Enforce Status26 Bash Style Guide
# ==============================================================================
# Validates Bash scripts against STATUS26_BASH_STYLE_GUIDE_v1.md
#
# Usage:
#   ./scripts/check_bash_style.sh [file...]
#
# If no files provided, checks all .sh files in the repository.
#
# Exit codes:
#   0 - All checks passed
#   1 - Style violations found
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WIZ_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly STYLE_GUIDE="${WIZ_ROOT}/docs/STATUS26_BASH_STYLE_GUIDE_v1.md"
readonly MAX_LINE_LENGTH=80

# --- Colors ---
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_NC='\033[0m'

# --- Statistics ---
VIOLATIONS=0
FILES_CHECKED=0

# --- Logging Functions ---
log_error() {
  echo -e "${COLOR_RED}ERROR:${COLOR_NC} $1" >&2
}

log_warn() {
  echo -e "${COLOR_YELLOW}WARN:${COLOR_NC} $1"
}

log_info() {
  echo "$1"
}

log_success() {
  echo -e "${COLOR_GREEN}✓${COLOR_NC} $1"
}

# --- Check Functions ---

# check_shebang: Verify script starts with correct shebang
check_shebang() {
  local file="$1"
  local line
  line=$(head -n 1 "$file" 2>/dev/null || echo "")

  if [[ "$line" != "#!/usr/bin/env bash" ]]; then
    log_error "${file}:1: Missing or incorrect shebang"
    log_error "  Expected: #!/usr/bin/env bash"
    log_error "  Found:    ${line}"
    ((VIOLATIONS++))
    return 1
  fi

  return 0
}

# check_strict_mode: Verify set -euo pipefail is present early
check_strict_mode() {
  local file="$1"
  local found=0
  local line_num=0

  while IFS= read -r line; do
    ((line_num++))
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    if [[ "$line" =~ ^[[:space:]]*set[[:space:]]+-[[:space:]]*euo[[:space:]]+pipefail ]]; then
      found=1
      break
    fi

    # Should be within first 10 non-comment lines
    if [[ $line_num -gt 10 ]]; then
      break
    fi
  done < "$file"

  if [[ $found -eq 0 ]]; then
    log_error "${file}: Missing 'set -euo pipefail' in first 10 lines"
    ((VIOLATIONS++))
    return 1
  fi

  return 0
}

# check_line_length: Check for lines exceeding max length
check_line_length() {
  local file="$1"
  local line_num=0
  local violations=0

  while IFS= read -r line; do
    ((line_num++))
    local length=${#line}

    # Skip very long lines that are likely heredocs or data
    if [[ "$line" =~ ^[[:space:]]*EOF ]] || \
       [[ "$line" == *"<< "* ]] || \
       [[ "$line" == *"<<EOF"* ]] || \
       [[ "$line" == *"<<'EOF'"* ]]; then
      continue
    fi

    if [[ $length -gt $MAX_LINE_LENGTH ]]; then
      log_warn "${file}:${line_num}: Line exceeds ${MAX_LINE_LENGTH} characters (${length})"
      ((violations++))
    fi
  done < "$file"

  if [[ $violations -gt 0 ]]; then
    log_warn "${file}: ${violations} line(s) exceed ${MAX_LINE_LENGTH} characters"
    ((VIOLATIONS += violations))
  fi

  return 0
}

# check_quoting: Basic check for unquoted variables (very basic)
check_quoting() {
  local file="$1"
  local line_num=0

  while IFS= read -r line; do
    ((line_num++))

    # Skip comments and strings
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # Check for common unquoted variable patterns (basic)
    # This is a heuristic and may have false positives
    if [[ "$line" =~ \$[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*[=\(] ]] && \
       [[ ! "$line" =~ \"\$\{ ]] && \
       [[ ! "$line" =~ echo[[:space:]]+ ]] && \
       [[ ! "$line" =~ printf[[:space:]]+ ]]; then
      # This is a very basic check - ShellCheck is better
      # Only flag obvious cases
      if [[ "$line" =~ [[:space:]]\$[a-zA-Z_][a-zA-Z0-9_]*[[:space:]] ]]; then
        log_warn "${file}:${line_num}: Possible unquoted variable (verify with ShellCheck)"
      fi
    fi
  done < "$file"

  return 0
}

# check_function_docs: Check for function docstrings
check_function_docs() {
  local file="$1"
  local line_num=0
  local prev_line=""
  local in_function=0

  while IFS= read -r line; do
    ((line_num++))
    local trimmed="${line#"${line%%[![:space:]]*}"}"

    # Detect function definition
    if [[ "$trimmed" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{ ]]; then
      local func_name
      func_name=$(echo "$trimmed" | grep -oE '^[a-zA-Z_][a-zA-Z0-9_]*' || echo "")
      in_function=1

      # Check if previous line (or line before that) has a comment
      local has_doc=0
      if [[ "$prev_line" =~ ^[[:space:]]*#.*${func_name} ]]; then
        has_doc=1
      fi

      # Check line before previous (for multi-line docstrings)
      if [[ $line_num -gt 2 ]]; then
        local prev_prev_line
        prev_prev_line=$(sed -n "$((line_num - 2))p" "$file" 2>/dev/null || echo "")
        if [[ "$prev_prev_line" =~ ^[[:space:]]*#.*${func_name} ]]; then
          has_doc=1
        fi
      fi

      if [[ $has_doc -eq 0 ]] && [[ ! "$func_name" =~ ^(main|test_|check_) ]]; then
        log_warn "${file}:${line_num}: Function '${func_name}' missing docstring"
        log_warn "  Add: # ${func_name}() - Brief description"
        ((VIOLATIONS++))
      fi
    fi

    prev_line="$line"
  done < "$file"

  return 0
}

# check_trailing_whitespace: Check for trailing whitespace
check_trailing_whitespace() {
  local file="$1"
  local line_num=0
  local violations=0

  while IFS= read -r line; do
    ((line_num++))
    if [[ "$line" =~ [[:space:]]+$ ]]; then
      log_warn "${file}:${line_num}: Trailing whitespace"
      ((violations++))
    fi
  done < "$file"

  if [[ $violations -gt 0 ]]; then
    ((VIOLATIONS += violations))
  fi

  return 0
}

# check_file: Run all checks on a single file
check_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: ${file}"
    return 1
  fi

  log_info "Checking: ${file}"

  local has_errors=0

  check_shebang "$file" || has_errors=1
  check_strict_mode "$file" || has_errors=1
  check_line_length "$file" || has_errors=1
  check_function_docs "$file" || has_errors=1
  check_trailing_whitespace "$file" || has_errors=1
  check_quoting "$file" || has_errors=1

  ((FILES_CHECKED++))

  if [[ $has_errors -eq 0 ]]; then
    log_success "All style checks passed"
  fi

  return 0
}

# find_bash_files: Find all Bash scripts in the repository
find_bash_files() {
  local files=()

  while IFS= read -r -d '' file; do
    # Skip common exclusions
    [[ "$file" =~ node_modules ]] && continue
    [[ "$file" =~ \.wiz/ ]] && continue
    [[ "$file" =~ \.git/ ]] && continue

    files+=("$file")
  done < <(find "$WIZ_ROOT" -type f -name "*.sh" -print0)

  printf '%s\n' "${files[@]}"
}

# --- Main ---
main() {
  log_info "Status26 Bash Style Guide Checker"
  log_info "Style Guide: ${STYLE_GUIDE}"
  echo ""

  local files=()

  if [[ $# -eq 0 ]]; then
    log_info "No files specified, checking all .sh files..."
    mapfile -t files < <(find_bash_files)
  else
    files=("$@")
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No Bash files found to check"
    return 1
  fi

  for file in "${files[@]}"; do
    check_file "$file"
    echo ""
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Summary:"
  echo "  Files checked: ${FILES_CHECKED}"
  echo "  Violations:    ${VIOLATIONS}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ $VIOLATIONS -eq 0 ]]; then
    log_success "All style checks passed!"
    return 0
  else
    log_error "Style violations found. Please review and fix."
    log_info "See: ${STYLE_GUIDE}"
    return 1
  fi
}

main "$@"
