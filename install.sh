#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# COSMIC WIZ BOOTSTRAP v1.1
# Interactive WSL/Unix environment bootstrap script by @jwogrady
#
# Features:
#   - Interactive setup for Git identity and SSH keys
#   - Safe handling of .env and SSH key files
#   - Global Git config and ignore setup
#   - Clones the wiz repo (~/wiz)
#   - Optional cleanup of install artifacts
#
# Usage:
#   ./install.sh [options]
#   Options:
#     --dry-run         Show commands without executing
#     --force           Overwrite .env and SSH keys
#     --debug           Print shell execution (set -x)
#     --name=NAME       Set Git user.name
#     --email=EMAIL     Set Git user.email
#     --github=USER     Set GitHub username
#     --win-user=USER   Set Windows username
#     --keys-path=PATH  Provide SSH key archive manually
#
# Prerequisites:
#   - git, ssh-agent, tar must be installed and available in PATH
#   - Intended for WSL or Linux environments
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'
[ -z "${BASH_VERSION:-}" ] && { echo "❌ Please run this with bash, not sh."; exit 1; }

# --- Logging and Error Handling ---
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
log()   { echo -e "${GREEN}[$(timestamp)] [INFO] $*${NC}"; }
warn()  { echo -e "${YELLOW}[$(timestamp)] [WARN] $*${NC}" >&2; }
error() { echo -e "${RED}[$(timestamp)] [ERROR] $*${NC}" >&2; }
trap 'error "Script failed at line $LINENO: $BASH_COMMAND"' ERR

# --- Default Variables ---
DRY_RUN=0
FORCE=0
DEBUG=0
KEYS_PATH=""
GIT_NAME=""
GIT_EMAIL=""
GITHUB_USERNAME=""
WIN_USER=""

# --- CLI Flags Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --debug) DEBUG=1 ;;
    --name=*) GIT_NAME="${1#*=}" ;;
    --email=*) GIT_EMAIL="${1#*=}" ;;
    --github=*) GITHUB_USERNAME="${1#*=}" ;;
    --win-user=*) WIN_USER="${1#*=}" ;;
    --keys-path=*) KEYS_PATH="${1#*=}" ;;
    --help)
      echo -e "\nUsage: $0 [options]"
      echo -e "  --dry-run         Show commands without executing"
      echo -e "  --force           Overwrite .env and SSH keys"
      echo -e "  --debug           Print shell execution (set -x)"
      echo -e "  --name=NAME       Set Git user.name"
      echo -e "  --email=EMAIL     Set Git user.email"
      echo -e "  --github=USER     Set GitHub username"
      echo -e "  --win-user=USER   Set Windows username"
      echo -e "  --keys-path=PATH  Provide SSH key archive manually"
      exit 0
      ;;
    *) warn "Unknown option: $1" ;;
  esac
  shift
done
(( DEBUG )) && set -x

# --- Safe run wrapper ---
# Executes commands, or logs them if DRY_RUN is set
run() {
  if (( DRY_RUN )); then log "[DRY-RUN] $*"; else "$@"; fi
}

# --- Banner ---
show_banner() {
  echo -e "\n\033[1;36m"
  echo "  ╭────────────────────────────────────────────╮"
  echo "  │       🌌 COSMIC WIZ BOOTSTRAP v1.1        │"
  echo "  │       by @jwogrady | status26.com         │"
  echo "  ╰────────────────────────────────────────────╯"
  echo -e "\033[0m"
}

# --- Requirements ---
# Checks for required commands and exits if missing
check_requirements() {
  local cmds=(git ssh-agent tar)
  for cmd in "${cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || { error "Missing command: $cmd"; exit 1; }
  done
}

# --- .env validation ---
# Ensures .env file has valid lines
validate_env() {
  local envfile="$HOME/.env"
  if grep -qvE '^[A-Z_]+="[^"]*"$' "$envfile"; then
    error "❌ Invalid lines in .env — fix it manually."
    exit 1
  fi
}

# --- Interactive environment setup ---
# Prompts for Git identity and writes .env, or loads if already exists
write_env() {
  local envfile="$HOME/.env"
  # Prompt for local git name
  [[ -z "$GIT_NAME" ]] && read -rp "👤 What is your local git name? " GIT_NAME

  # Prompt for local git email
  [[ -z "$GIT_EMAIL" ]] && read -rp "📧 What is your local git email? " GIT_EMAIL

  # Confirm or edit GitHub username
  local default_github="$GIT_NAME"
  if [[ -z "$GITHUB_USERNAME" ]]; then
    read -rp "🐙 Is your GitHub username '$default_github'? [Y/e]: " confirm_github
    case "${confirm_github,,}" in
      e*)
        read -rp "🐙 Enter your GitHub username: " GITHUB_USERNAME
        ;;
      *)
        GITHUB_USERNAME="$default_github"
        ;;
    esac
  fi

  # Try to find Windows username from /mnt/c/Users
  local win_user_guess=""
  if [[ -z "$WIN_USER" ]]; then
    win_user_guess=$(ls /mnt/c/Users 2>/dev/null | grep -v 'Public' | head -n1)
    read -rp "🪟 Is your Windows username '$win_user_guess'? [Y/e]: " confirm_win
    case "${confirm_win,,}" in
      e*)
        read -rp "🪟 Enter your Windows username: " WIN_USER
        ;;
      *)
        WIN_USER="$win_user_guess"
        ;;
    esac
  fi

  SSH_KEY_STATUS="setup"
  cat > "$envfile" <<EOF
GIT_NAME="$GIT_NAME"
GIT_EMAIL="$GIT_EMAIL"
GITHUB_USERNAME="$GITHUB_USERNAME"
WIN_USER="$WIN_USER"
SSH_KEY_STATUS="$SSH_KEY_STATUS"
EOF
  log ".env created ✅"
}

setup_env() {
  local envfile="$HOME/.env"
  if [[ -f "$envfile" ]]; then
    log "Loading existing .env from $envfile"
    validate_env
    set -a; source "$envfile"; set +a
  else
    write_env
    validate_env
    set -a; source "$envfile"; set +a
  fi
}

# --- SSH setup ---
setup_ssh() {
  local KEYS_SRC="${KEYS_PATH:-/mnt/c/Users/$WIN_USER/keys.tar.gz}"
  local KEYS_DEST="$HOME/keys.tar.gz"
  if [[ -f "$HOME/.ssh/id_ed25519" && $FORCE -eq 0 ]]; then
    log "SSH key already exists, skipping extraction."
  elif [ -f "$KEYS_SRC" ]; then
    run cp "$KEYS_SRC" "$KEYS_DEST"
    run tar -xzf "$KEYS_DEST" -C "$HOME/"
    run chmod 700 "$HOME/.ssh"
    run find "$HOME/.ssh" -type d -exec chmod 700 {} \;
    run find "$HOME/.ssh" -type f -exec chmod 600 {} \;
    log "SSH keys unpacked 🔑"
  else
    warn "No SSH archive found at $KEYS_SRC"
  fi

  # Ensure ssh-agent is running and keys are loaded for current shell
  if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)"
    # Try to add your main key (edit as needed for your environment)
    ssh-add "$HOME/.ssh/id_jwogrady" 2>/dev/null || warn "Could not add id_jwogrady"
    # Optionally add all other keys
    for key in "$HOME/.ssh"/id_*; do
      [[ -f "$key" && "$key" != *.pub && "$key" != "$HOME/.ssh/id_jwogrady" ]] && ssh-add "$key" 2>/dev/null
    done
  fi

  # Only add keys if not already loaded (avoids duplicate agent entries)
  ssh-add -l || warn "No keys loaded into ssh-agent"
  log "ssh-agent is live 🔐"
}

# --- Ensure ssh-agent persistence in .bashrc ---
ensure_ssh_agent_bashrc() {
  local bashrc="$HOME/.bashrc"
  local marker="# COSMIC WIZ SSH AGENT"
  local agent_snippet="
$marker
if [ -z \"\${SSH_AUTH_SOCK:-}\" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval \"\$(ssh-agent -s)\"
    ssh-add \$HOME/.ssh/id_jwogrady 2>/dev/null
    ssh-add \$HOME/.ssh/id_vultr 2>/dev/null
fi
"

  if ! grep -q "$marker" "$bashrc"; then
    echo "$agent_snippet" >> "$bashrc"
    log "Appended ssh-agent startup to $bashrc"
    # Source .bashrc to reload environment
    source "$bashrc"
    log "Reloaded .bashrc for ssh-agent environment"
  else
    log "ssh-agent persistence already present in $bashrc"
  fi
}

# --- Git repo clone ---
clone_repo() {
  local REPO="git@github.com:jwogrady/wiz.git"
  local TARGET="$HOME/wiz"
  if [ ! -d "$TARGET" ]; then
    run git clone "$REPO" "$TARGET"
    log "Cloned wiz repo 📦"
  else
    log "wiz repo already exists at $TARGET"
  fi
}

# --- Git config and global ignore ---
setup_gitconfig() {
  local gitconfig="$HOME/.gitconfig"
  cat > "$gitconfig" <<EOF
[user]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
[core]
    editor = nano
[alias]
    st = status
    co = checkout
    br = branch
    cm = commit
    lg = log --oneline --graph --decorate --all
    last = log -1 HEAD
    unstage = reset HEAD --
    amend = commit --amend --no-edit
    df = diff
    dc = diff --cached
    hist = log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short
EOF
  log "Global .gitconfig created at $gitconfig ✅"

  local gitignore="$HOME/.gitignore_global"
  cat > "$gitignore" <<EOF
node_modules/
.DS_Store
*.log
__pycache__/
*.sw?
EOF
  git config --global core.excludesfile "$gitignore"
  log "Global .gitignore_global created and set ✅"
}

# --- Cleanup ---
cleanup_install_artifacts() {
  local auto="${1:-false}"
  local files=( "$HOME/install.sh" "$HOME/keys.tar.gz" )
  if [[ "$auto" == "true" || $FORCE -eq 1 ]]; then
    for file in "${files[@]}"; do
      [[ -f "$file" ]] && run rm -f "$file" && log "Removed $file"
    done
  else
    echo
    read -rp "🧼 Remove install.sh and keys.tar.gz from home dir? [y/N]: " confirm
    [[ "${confirm,,}" =~ ^y|yes$ ]] && for file in "${files[@]}"; do
      [[ -f "$file" ]] && run rm -f "$file" && log "Removed $file"
    done
  fi
}

# --- Main ---
main() {
  show_banner
  log "Starting identity and environment setup..."
  check_requirements
  setup_env
  setup_gitconfig
  setup_ssh
  ensure_ssh_agent_bashrc
  clone_repo
  cleanup_install_artifacts "${1:-false}"
  echo -e "\n✅ Identity and repo setup complete."
  echo -e "\n${GREEN}Next steps:${NC}"
  echo "1. cd ~/wiz/init"
  echo "2. ./bootstrap.sh"
  echo -e "\nThis will install all developer tools and finish your environment setup."
}

main "$@"