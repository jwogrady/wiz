#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: Identity Library
# ==============================================================================
# Git identity configuration: validation, .env management, and git setup.
#
# Depends on globals set by bin/install:
#   $WIZ_ROOT, $GIT_NAME, $GIT_EMAIL, $GITHUB_USERNAME, $WIN_USER, $FORCE
#
# Usage:
#   source /path/to/lib/identity.sh
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Ensure common.sh is sourced ---
if ! declare -f log >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=common.sh
    source "${SCRIPT_DIR}/common.sh"
fi

# ==============================================================================
# ENVIRONMENT FILE MANAGEMENT
# ==============================================================================

# validate_env: Ensure .env file has valid lines
validate_env() {
    local envfile="$1"

    if ! grep -q '^GIT_NAME=' "$envfile" 2>/dev/null; then
        return 1
    fi

    return 0
}

# validate_git_name: Validate Git name format
# Usage: validate_git_name <name>
# Security: Rejects shell metacharacters to prevent injection when written to .env
validate_git_name() {
    local name="$1"

    # Name must not be empty or only whitespace
    [[ -n "${name// }" ]] || return 1

    # Name should be at least 2 characters
    [[ ${#name} -ge 2 ]] || return 1

    # Name should not contain only special characters
    [[ "$name" =~ [[:alnum:]] ]] || return 1

    # Security: Reject shell metacharacters that could cause injection
    # Allowed: letters, numbers, spaces, hyphens, apostrophes, periods
    # Rejected: backticks, $, ", \, newlines, etc.
    [[ "$name" =~ ^[a-zA-Z0-9\ \'\.\-]+$ ]] || return 1

    return 0
}

# validate_email: Validate email format
# Usage: validate_email <email>
validate_email() {
    local email="$1"

    # Basic email format validation
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || return 1

    return 0
}

# validate_github_username: Validate GitHub username format
# Usage: validate_github_username <username>
validate_github_username() {
    local username="$1"

    # GitHub usernames: alphanumeric + hyphens, 1-39 chars,
    # cannot start/end with hyphen, no consecutive hyphens
    [[ ${#username} -ge 1 ]] && [[ ${#username} -le 39 ]] || return 1

    if [[ ${#username} -eq 1 ]]; then
        [[ "$username" =~ ^[a-zA-Z0-9]$ ]] || return 1
    else
        [[ "$username" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]] || return 1
        [[ ! "$username" =~ -- ]] || return 1
    fi

    return 0
}

# write_env: Interactive environment setup
write_env() {
    local envfile="${WIZ_ROOT}/.env"

    # Load existing .env if present and not forcing
    if [[ -f "$envfile" ]] && [[ $FORCE -eq 0 ]]; then
        if validate_env "$envfile"; then
            log "Loading existing configuration from .env"
            # shellcheck source=/dev/null
            source "$envfile"
            return 0
        else
            warn "Existing .env appears invalid, recreating..."
        fi
    fi

    # Interactive prompts if values not provided via CLI
    if [[ -z "$GIT_NAME" ]]; then
        read -rp "Enter your full name (for Git commits): " GIT_NAME
    fi

    if [[ -z "$GIT_EMAIL" ]]; then
        read -rp "Enter your email (for Git commits): " GIT_EMAIL
    fi

    if [[ -z "$GITHUB_USERNAME" ]]; then
        read -rp "Enter your GitHub username: " GITHUB_USERNAME
    fi

    # Auto-detect Windows username if not provided (no prompt needed)
    if [[ -z "$WIN_USER" ]]; then
        WIN_USER="$(detect_windows_user 2>/dev/null || echo "")"
        if [[ -n "$WIN_USER" ]]; then
            debug "Auto-detected Windows username: $WIN_USER"
        fi
    fi

    # Validate inputs
    if [[ -z "$GIT_NAME" ]] || [[ -z "$GIT_EMAIL" ]] || [[ -z "$GITHUB_USERNAME" ]]; then
        error "Name, email, and GitHub username are required"
        exit 1
    fi

    if ! validate_git_name "$GIT_NAME"; then
        error "Invalid name format. Please enter your full name."
        exit 1
    fi

    if ! validate_email "$GIT_EMAIL"; then
        error "Invalid email format. Please enter a valid email address."
        exit 1
    fi

    if ! validate_github_username "$GITHUB_USERNAME"; then
        error "Invalid GitHub username format. Username must contain only alphanumeric characters and hyphens."
        exit 1
    fi

    # Write .env file with restricted permissions (contains user info)
    log "Writing configuration to .env..."

    # Create with mode 0600 (owner read/write only) using umask
    ( umask 077 && cat > "$envfile" << EOF
# Wiz Configuration
# Generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")

GIT_NAME="$GIT_NAME"
GIT_EMAIL="$GIT_EMAIL"
GITHUB_USERNAME="$GITHUB_USERNAME"
WIN_USER="$WIN_USER"
EOF
    )

    success "Configuration saved to .env (mode 0600)"

    # Source the file we just created
    # shellcheck source=/dev/null
    source "$envfile"
}

# ==============================================================================
# GIT CONFIGURATION
# ==============================================================================

# configure_git: Set global Git identity and defaults
configure_git() {
    log "Configuring Git..."

    # Set global Git identity
    run git config --global user.name "$GIT_NAME"
    run git config --global user.email "$GIT_EMAIL"

    # Set useful Git defaults
    run git config --global init.defaultBranch main
    run git config --global pull.rebase false
    run git config --global core.autocrlf input

    # Create global .gitignore
    local gitignore="${HOME}/.gitignore_global"

    if [[ ! -f "$gitignore" ]] || [[ $FORCE -eq 1 ]]; then
        log "Creating global .gitignore..."

        cat > "$gitignore" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/

# Environment
.env
.env.local

# Node
node_modules/
npm-debug.log*

# Python
__pycache__/
*.py[cod]
venv/
.python-version
EOF

        run git config --global core.excludesfile "$gitignore"
        success "Global .gitignore created"
    else
        debug "Global .gitignore already exists"
    fi

    success "Git configured for: $GIT_NAME <$GIT_EMAIL>"
}
