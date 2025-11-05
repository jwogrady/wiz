#!/usr/bin/env bash
# ==============================================================================
# setup_git_hooks.sh - Setup git hooks for conventional commits
# ==============================================================================
# Installs git hooks and configures commit message template for
# conventional commits validation.
#
# Usage:
#   ./scripts/setup_git_hooks.sh
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WIZ_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly GIT_HOOKS_DIR="${WIZ_ROOT}/.git/hooks"
readonly COMMIT_MSG_HOOK="${GIT_HOOKS_DIR}/commit-msg"
readonly COMMIT_TEMPLATE="${WIZ_ROOT}/.gitmessage"

# --- Colors ---
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_NC='\033[0m'

# --- Logging Functions ---
log_info() {
  echo -e "${COLOR_GREEN}✓${COLOR_NC} $1"
}

log_warn() {
  echo -e "${COLOR_YELLOW}⚠${COLOR_NC} $1"
}

log_error() {
  echo -e "${COLOR_RED}✗${COLOR_NC} $1" >&2
}

# --- Setup Functions ---

# setup_commit_msg_hook: Install commit-msg hook
setup_commit_msg_hook() {
  log_info "Setting up commit-msg hook..."

  if [[ ! -d "$GIT_HOOKS_DIR" ]]; then
    log_error "Git hooks directory not found: ${GIT_HOOKS_DIR}"
    log_error "Are you in a git repository?"
    return 1
  fi

  # Create hook content
  local hook_content
  hook_content=$(cat << 'HOOK_EOF'
#!/usr/bin/env bash
# Git commit-msg hook to validate commit messages
# Validates against Conventional Commits specification

set -euo pipefail

# Get the commit message file
COMMIT_MSG_FILE="$1"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Run the validator
if [[ -f "${SCRIPT_DIR}/scripts/validate_commit_msg.sh" ]]; then
  "${SCRIPT_DIR}/scripts/validate_commit_msg.sh" "$COMMIT_MSG_FILE"
else
  echo "Warning: commit message validator not found" >&2
  exit 0
fi
HOOK_EOF
)

  # Write hook
  echo "$hook_content" > "$COMMIT_MSG_HOOK"
  chmod +x "$COMMIT_MSG_HOOK"

  log_info "Commit-msg hook installed: ${COMMIT_MSG_HOOK}"
  return 0
}

# setup_commit_template: Configure git commit template
setup_commit_template() {
  log_info "Configuring commit message template..."

  if [[ ! -f "$COMMIT_TEMPLATE" ]]; then
    log_warn "Commit template not found: ${COMMIT_TEMPLATE}"
    log_warn "Skipping template configuration"
    return 0
  fi

  # Set template for this repository
  git config commit.template "$COMMIT_TEMPLATE"

  log_info "Commit template configured: ${COMMIT_TEMPLATE}"
  log_info "Run 'git commit' (without -m) to use the template"
  return 0
}

# verify_setup: Verify the setup is working
verify_setup() {
  log_info "Verifying setup..."

  local errors=0

  # Check hook exists and is executable
  if [[ ! -f "$COMMIT_MSG_HOOK" ]]; then
    log_error "Commit-msg hook not found: ${COMMIT_MSG_HOOK}"
    ((errors++))
  elif [[ ! -x "$COMMIT_MSG_HOOK" ]]; then
    log_error "Commit-msg hook is not executable: ${COMMIT_MSG_HOOK}"
    ((errors++))
  else
    log_info "Commit-msg hook: OK"
  fi

  # Check validator exists
  if [[ ! -f "${WIZ_ROOT}/scripts/validate_commit_msg.sh" ]]; then
    log_error "Commit message validator not found"
    ((errors++))
  elif [[ ! -x "${WIZ_ROOT}/scripts/validate_commit_msg.sh" ]]; then
    log_error "Commit message validator is not executable"
    ((errors++))
  else
    log_info "Commit message validator: OK"
  fi

  # Check template is configured
  local template_path
  template_path=$(git config --get commit.template || echo "")
  if [[ -z "$template_path" ]]; then
    log_warn "Commit template not configured (optional)"
  else
    log_info "Commit template: ${template_path}"
  fi

  # Test validation with a valid message
  local test_msg_file
  test_msg_file=$(mktemp)
  echo "chore: test commit message validation" > "$test_msg_file"

  if "${WIZ_ROOT}/scripts/validate_commit_msg.sh" "$test_msg_file" >/dev/null 2>&1; then
    log_info "Validation test: OK"
  else
    log_error "Validation test failed"
    ((errors++))
  fi

  rm -f "$test_msg_file"

  # Test validation with an invalid message
  echo "invalid message" > "$test_msg_file"
  if ! "${WIZ_ROOT}/scripts/validate_commit_msg.sh" "$test_msg_file" >/dev/null 2>&1; then
    log_info "Invalid message rejection: OK"
  else
    log_error "Invalid message was accepted (should be rejected)"
    ((errors++))
  fi

  rm -f "$test_msg_file"

  if [[ $errors -eq 0 ]]; then
    log_info "Setup verification: PASSED"
    return 0
  else
    log_error "Setup verification: FAILED (${errors} error(s))"
    return 1
  fi
}

# --- Main ---
main() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Conventional Commits Setup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not in a git repository"
    return 1
  fi

  # Setup hook
  if ! setup_commit_msg_hook; then
    log_error "Failed to setup commit-msg hook"
    return 1
  fi

  # Setup template
  setup_commit_template

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Verification"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Verify setup
  if verify_setup; then
    echo ""
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "  Setup Complete!"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "All commit messages will now be validated automatically."
    log_info "See docs/CONVENTIONAL_COMMITS_SETUP.md for usage."
    return 0
  else
    echo ""
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "  Setup Incomplete"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 1
  fi
}

main "$@"
