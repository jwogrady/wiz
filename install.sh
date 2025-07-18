#!/bin/bash
# filepath: /home/john/wiz/install.sh
# WIZ Install Script: Seamless init and bootstrap

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
ENV_FILE="$SCRIPT_DIR/.env"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"

log() { printf "%s\n" "$1" | tee -a "$LOG_FILE"; }

prompt() {
    local var="$1" msg="$2" regex="$3" def="${4:-}" val=""
    while true; do
        if [[ -n "$def" ]]; then
            read -rp "$msg [default: $def]: " val
            val="${val:-$def}"
        else
            read -rp "$msg" val
        fi
        [[ "$val" =~ $regex ]] && break || printf "Invalid input. Please try again.\n"
    done
    eval "$var=\"\$val\""
}

setup_env() {
    log "\n--- Environment Setup ---"
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        log "Found existing .env file."
        log "Current values:"
        log "  Git user: $GIT_USER"
        log "  GitHub username: $GITHUB_USERNAME"
        log "  Git email: $GIT_EMAIL"
        log "  Windows username: $(basename "$KEYS_SRC" | cut -d'/' -f1)"
        [[ "${USE_DOTFILES_REPO:-n}" =~ ^[Yy]$ ]] && log "  Dotfiles repo: $GITHUB_DOTFILES_REPO_URL" || log "  Dotfiles repo: No dotfiles to load"
        read -rp $'\e[36mUse these values? [Y/Enter=accept, n=change]:\e[0m ' CONFIRM_ENV
        [[ -z "${CONFIRM_ENV:-}" || "$CONFIRM_ENV" =~ ^[Yy]$ ]] && log "Using existing .env values." && return
        log "Proceeding to update values."
    fi

    prompt GIT_USER $'\e[33mEnter your Git user name:\e[0m ' '^[a-zA-Z0-9._-]+$'
    read -rp $'\e[36mIs your GitHub username the same as your Git user name ('"$GIT_USER"$')? [Y/Enter=accept, n=change]:\e[0m ' GITHUB_SAME
    [[ -z "${GITHUB_SAME:-}" || "$GITHUB_SAME" =~ ^[Yy]$ ]] && GITHUB_USERNAME="$GIT_USER" || prompt GITHUB_USERNAME $'\e[33mEnter your GitHub username:\e[0m ' '^[a-zA-Z0-9._-]+$'
    WIN_USER=$(whoami)
    prompt WIN_USER $'\e[35mEnter your Windows username (for /mnt/c/Users/<username>):\e[0m ' '^[^/\\]+$' "$WIN_USER"
    KEYS_SRC="/mnt/c/Users/$WIN_USER/keys.tar.gz"
    KEYS_DEST="$HOME"
    prompt GIT_EMAIL $'\e[32mEnter your Git user email:\e[0m ' '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    read -rp $'\e[36mDo you have existing dotfiles to load? [y/N]:\e[0m ' USE_DOTFILES_REPO
    USE_DOTFILES_REPO="${USE_DOTFILES_REPO:-n}"
    if [[ "$USE_DOTFILES_REPO" =~ ^[Yy]$ ]]; then
        prompt GITHUB_DOTFILES_REPO_NAME $'\e[33mEnter your dotfiles repository name:\e[0m ' '^[a-zA-Z0-9._-]+$' "dotfiles"
        GITHUB_DOTFILES_REPO_URL="https://github.com/${GITHUB_USERNAME}/${GITHUB_DOTFILES_REPO_NAME}.git"
        read -rp $'\e[36mIs this correct? [Y/Enter=accept, n=change]:\e[0m ' DOTFILES_CONFIRM
        [[ ! -z "${DOTFILES_CONFIRM:-}" && ! "$DOTFILES_CONFIRM" =~ ^[Yy]$ ]] && prompt GITHUB_DOTFILES_REPO_URL $'\e[33mEnter your custom dotfiles repository URL:\e[0m ' '^https://.+'
    else
        GITHUB_DOTFILES_REPO_NAME=""
        GITHUB_DOTFILES_REPO_URL=""
    fi

    cat >"$ENV_FILE" <<EOF
GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_DOTFILES_REPO_NAME=$GITHUB_DOTFILES_REPO_NAME
GITHUB_DOTFILES_REPO_URL=$GITHUB_DOTFILES_REPO_URL
GIT_EMAIL=$GIT_EMAIL
GIT_USER=$GIT_USER
KEYS_SRC=$KEYS_SRC
KEYS_DEST=$KEYS_DEST
USE_DOTFILES_REPO=$USE_DOTFILES_REPO
EOF
    chmod 600 "$ENV_FILE"
    log ".env file created at $ENV_FILE."
}

extract_keys() {
    log "\n--- Extract SSH Keys ---"
    if [[ -f "$KEYS_SRC" ]]; then
        cp "$KEYS_SRC" "$SCRIPT_DIR/keys.tar.gz"
        if tar -xzvf "$SCRIPT_DIR/keys.tar.gz" -C "$KEYS_DEST"; then
            log "Extracted keys to $KEYS_DEST"
        else
            log "Error extracting keys."
        fi
    else
        log "Warning: $KEYS_SRC not found. Skipping key extraction."
    fi
}

setup_gitconfig() {
    log "\n--- Setup Global Git Config ---"
    git config --global user.email "${GIT_EMAIL}"
    git config --global user.name "${GIT_USER}"

    cat > "$HOME/.gitignore_global" <<EOF
# Global gitignore
*.log
*.tmp
.DS_Store
node_modules/
__pycache__/
*.swp
EOF

    git config --global core.excludesfile "$HOME/.gitignore_global"
    log "Global git config and .gitignore set up using values from .env."
}

setup_ssh_agent() {
    log "\n--- SSH Agent Setup ---"
    local SSH_BLOCK_START="# >>> SSH agent auto-load >>>"
    local SSH_SNIPPET
    SSH_SNIPPET=$(
        cat <<'EOSSH'
# >>> SSH agent auto-load >>>
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval "$(ssh-agent -s)" > /dev/null
    if [ -d "$HOME/.ssh" ]; then
        for key in "$HOME/.ssh/"id_*; do
            [[ "$key" == *.pub ]] && continue
            [ -f "$key" ] && ssh-add "$key" 2>/dev/null
        done
    fi
fi
# <<< SSH agent auto-load <<<
EOSSH
    )
    local sourced=0
    if ! grep -qF "$SSH_BLOCK_START" "$HOME/.bashrc"; then
        echo "$SSH_SNIPPET" >>"$HOME/.bashrc"
        log "Added SSH agent auto-load block to ~/.bashrc"
        sourced=1
    fi
    if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        for key in "$HOME/.ssh/"id_*; do
            [[ "$key" == *.pub ]] && continue
            [[ -f "$key" ]] && chmod 600 "$key"
        done
    fi
    [[ $sourced -eq 1 ]] && source "$HOME/.bashrc"
}

clone_dotfiles() {
    log "\n--- Clone Dotfiles Repo ---"
    if [[ ! -z "${USE_DOTFILES_REPO:-}" && "$USE_DOTFILES_REPO" =~ ^[Yy]$ && -n "$GITHUB_DOTFILES_REPO_URL" ]]; then
        local DOTFILES_DEST="$HOME/.backup"
        if [[ ! -d "$DOTFILES_DEST" ]]; then
            git clone "$GITHUB_DOTFILES_REPO_URL" "$DOTFILES_DEST" || log "$DOTFILES_DEST already exists."
        else
            log "$DOTFILES_DEST already exists, skipping clone."
        fi
    else
        log "Skipping dotfiles repo clone as requested."
    fi
}

clone_wiz() {
    log "\n--- Clone Wiz Repo ---"
    local WIZ_REPO_URL="https://github.com/${GITHUB_USERNAME}/wiz.git"
    local WIZ_DEST="$HOME/wiz_clone"
    if [[ ! -d "$WIZ_DEST" ]]; then
        git clone "$WIZ_REPO_URL" "$WIZ_DEST" || log "$WIZ_DEST already exists."
    else
        log "$WIZ_DEST already exists, skipping clone."
    fi
}

run_bootstrap() {
    log "\n===== WIZ BOOTSTRAP PHASE =====\n"
    if [[ ! -d "$BOOTSTRAP_DIR" ]]; then
        log "No bootstrap directory found at $BOOTSTRAP_DIR"
        return
    fi
    mapfile -d '' BOOTSTRAP_SCRIPTS < <(find "$BOOTSTRAP_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)
    if [ "${#BOOTSTRAP_SCRIPTS[@]}" -eq 0 ]; then
        log "No bootstrap scripts found in $BOOTSTRAP_DIR"
        return
    fi
    echo "Bootstrap scripts to run:"
    for idx in "${!BOOTSTRAP_SCRIPTS[@]}"; do
        script_name="$(basename "${BOOTSTRAP_SCRIPTS[$idx]}")"
        printf "  %2d. %s\n" "$((idx+1))" "$script_name"
    done
    echo
    for script_path in "${BOOTSTRAP_SCRIPTS[@]}"; do
        script_name="$(basename "$script_path")"
        if [ -f "$script_path" ]; then
            # Idempotency check for backup script
            if [[ "$script_name" == "40-backup-default-dots.sh" ]]; then
                MACHINE_NAME="$(hostname)"
                TODAY="$(date +'%Y-%m-%d')"
                if ls "$HOME/.backup/$MACHINE_NAME/${TODAY}_*" 1>/dev/null 2>&1; then
                    echo "Backup for today already exists, skipping $script_name."
                    continue
                fi
            fi
            echo "Running $script_name..."
            bash "$script_path"
        else
            echo "Warning: $script_name not found, skipping."
        fi
        echo
    done
    echo "===== WIZ bootstrap complete! ====="
    echo
}

recap() {
    log "\n--- Initialization Recap ---"
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        cat <<EOF
Git user:        $GIT_USER
GitHub username: $GITHUB_USERNAME
Git email:       $GIT_EMAIL
Windows user:    $(basename "$KEYS_SRC" | cut -d'/' -f1)
Keys source:     $KEYS_SRC
Keys destination:$KEYS_DEST
Dotfiles to load: $([[ "$USE_DOTFILES_REPO" =~ ^[Yy]$ ]] && echo "$GITHUB_DOTFILES_REPO_URL" || echo "No")
EOF
    else
        log "No .env file found. Initialization may not have completed."
    fi

    echo
    echo "============================"
    echo "  WIZ Install Recap"
    echo "============================"
    echo

    if [[ -f "$ENV_FILE" ]]; then
        echo -n "- .env file found: "
        [[ $(stat -c "%a" "$ENV_FILE") == "600" ]] && printf "\e[32mPermissions are correct (600)\e[0m\n" || printf "\e[31mPermissions are incorrect. Please set to 600.\e[0m\n"
    else
        echo "- [WARNING] .env file not found."
    fi

    if [[ -d "$HOME/.ssh" && "$(ls -A "$HOME/.ssh" 2>/dev/null)" ]]; then
        echo "- SSH keys found in $HOME/.ssh:"
        for key in "$HOME/.ssh/"id_*; do
            [[ "$key" == *.pub ]] && continue
            if [[ -f "$key" ]]; then
                echo -n "  - $(basename "$key"): "
                [[ $(stat -c "%a" "$key") == "600" ]] && printf "\e[32mPermissions are correct (600)\e[0m\n" || printf "\e[31mPermissions are incorrect. Please set to 600.\e[0m\n"
            fi
        done
    else
        echo "- [WARNING] SSH keys not found in $HOME/.ssh."
    fi

    if grep -q "SSH agent auto-load" "$HOME/.bashrc"; then
        echo "- SSH agent auto-load was configured."
    else
        echo "- [WARNING] SSH agent auto-load block not found in .bashrc."
    fi

    if [[ -d "$HOME/.backup" ]]; then
        echo "- Dotfiles repository was cloned to .backup."
    else
        echo "- [WARNING] Dotfiles repository not found in .backup."
    fi

    if [[ -d "$HOME/wiz_clone" ]]; then
        echo "- Wiz repository was cloned to wiz_clone."
    else
        echo "- [WARNING] Wiz repository not found in wiz_clone."
    fi

    echo
    echo "============================"
    echo "  Next Steps"
    echo "============================"
    echo
    echo "- Review your .env file in $ENV_FILE and update any values if needed."
    echo "- Verify your SSH keys in $HOME/.ssh and ensure permissions are correct."
    echo "- Apply your dotfiles from .backup or your dotfiles repo if needed."
    echo "- Restart your shell or source your profile to apply changes."
    echo

    read -rp $'\e[32mIf all checks passed (green), congratulations! You are ready to bootstrap. Press Y or Enter to continue:\e[0m ' CONFIRM_BOOTSTRAP
    if [[ -z "$CONFIRM_BOOTSTRAP" || "$CONFIRM_BOOTSTRAP" =~ ^[Yy]$ ]]; then
        printf "\e[32mCongratulations! Proceeding to bootstrap...\e[0m\n"
    else
        printf "\e[31mBootstrap aborted. Please resolve any issues and try again.\e[0m\n"
        exit 1
    fi
}

# Main install flow
setup_env
extract_keys
setup_gitconfig
setup_ssh_agent
clone_dotfiles
clone_wiz
recap
run_bootstrap

echo "===== WIZ install.sh complete! ====="
echo