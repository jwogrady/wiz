#!/bin/bash
# Seamless interactive .env generator for wiz setup

set -euo pipefail

LOG_FILE="$HOME/wiz/init.log"
ENV_FILE="$HOME/wiz/.env"

log() {
	echo "$1" | tee -a "$LOG_FILE"
}

prompt() {
	local var="$1"
	local msg="$2"
	local regex="$3"
	local def="${4:-}"
	local val=""
	while true; do
		if [[ -n "$def" ]]; then
			read -rp "$(echo -e "$msg [default: $def]: ")" val
			val="${val:-$def}"
		else
			read -rp "$(echo -e "$msg")" val
		fi
		if [[ "$val" =~ $regex ]]; then
			printf -v "$var" '%s' "$val"
			break
		else
			echo "Invalid input. Please try again."
		fi
	done
	eval "$var=\"\$val\""
}

# Load existing .env if present
if [[ -f "$ENV_FILE" ]]; then
	# shellcheck disable=SC1090
	source "$ENV_FILE"
	log "Found existing .env file."
	log "Current values:"
	log "  Git user: $GIT_USER"
	log "  GitHub username: $GITHUB_USERNAME"
	log "  Git email: $GIT_EMAIL"
	log "  Windows username: $(basename "$KEYS_SRC" | cut -d'/' -f1)"
	if [[ "${USE_DOTFILES_REPO:-n}" =~ ^[Yy]$ ]]; then
		log "  Dotfiles repo: $GITHUB_DOTFILES_REPO_URL"
	else
		log "  Dotfiles repo: No dotfiles to load"
	fi
	read -rp $'\e[36mUse these values? [Y/Enter=accept, n=change]:\e[0m ' CONFIRM_ENV
	if [[ -z "${CONFIRM_ENV:-}" || "$CONFIRM_ENV" =~ ^[Yy]$ ]]; then
		log "Using existing .env values."
		exit 0
	fi
	log "Proceeding to update values."
fi

# Git user name
prompt GIT_USER $'\e[33mEnter your Git user name:\e[0m ' '^[a-zA-Z0-9._-]+$' "${GIT_USER:-}"

# GitHub username (optionally same as Git user)
read -rp $'\e[36mIs your GitHub username the same as your Git user name ('"$GIT_USER"$')? [Y/Enter=accept, n=change]:\e[0m ' GITHUB_SAME
if [[ -z "${GITHUB_SAME:-}" || "$GITHUB_SAME" =~ ^[Yy]$ ]]; then
	GITHUB_USERNAME="$GIT_USER"
else
	prompt GITHUB_USERNAME $'\e[33mEnter your GitHub username:\e[0m ' '^[a-zA-Z0-9._-]+$' "${GITHUB_USERNAME:-}"
fi

# Windows username (auto-detect or prompt)
WIN_USER=$(powershell.exe '$env:USERNAME' | tr -d '\r')
if [[ -z "$WIN_USER" ]]; then
	prompt WIN_USER $'\e[35mEnter your Windows username (for /mnt/c/Users/<username>):\e[0m ' '^[^/\\]+$' "${WIN_USER:-}"
else
	echo "Detected Windows username: $WIN_USER"
	read -rp $'\e[36mIs this correct? [Y/Enter=accept, n=change]:\e[0m ' CONFIRM_WIN
	if [[ "$CONFIRM_WIN" =~ ^[Nn]$ ]]; then
		prompt WIN_USER $'\e[35mPlease enter your correct Windows username:\e[0m ' '^[^/\\]+$' "$WIN_USER"
	fi
fi
KEYS_SRC="/mnt/c/Users/$WIN_USER/keys.tar.gz"
KEYS_DEST="$HOME"

# Git email
prompt GIT_EMAIL $'\e[32mEnter your Git user email:\e[0m ' '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' "${GIT_EMAIL:-}"

# Dotfiles repo
read -rp $'\e[36mDo you have existing dotfiles to load? [y/N]:\e[0m ' USE_DOTFILES_REPO
USE_DOTFILES_REPO="${USE_DOTFILES_REPO:-n}"
if [[ "$USE_DOTFILES_REPO" =~ ^[Yy]$ ]]; then
	prompt GITHUB_DOTFILES_REPO_NAME $'\e[33mEnter your dotfiles repository name:\e[0m ' '^[a-zA-Z0-9._-]+$' "${GITHUB_DOTFILES_REPO_NAME:-dotfiles}"
	GITHUB_DOTFILES_REPO_URL="https://github.com/${GITHUB_USERNAME}/${GITHUB_DOTFILES_REPO_NAME}.git"
	echo "Assuming dotfiles repo: $GITHUB_DOTFILES_REPO_URL"
	read -rp $'\e[36mIs this correct? [Y/Enter=accept, n=change]:\e[0m ' DOTFILES_CONFIRM
	if [[ ! -z "${DOTFILES_CONFIRM:-}" && ! "$DOTFILES_CONFIRM" =~ ^[Yy]$ ]]; then
		prompt GITHUB_DOTFILES_REPO_URL $'\e[33mEnter your custom dotfiles repository URL:\e[0m ' '^https://.+'
	fi
else
	echo "Skipping dotfiles repo setup."
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

log ".env file created at $ENV_FILE."
cat >"$HOME/wiz/.env" <<EOF
GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_DOTFILES_REPO_NAME=$GITHUB_DOTFILES_REPO_NAME
GITHUB_DOTFILES_REPO_URL=$GITHUB_DOTFILES_REPO_URL
GIT_EMAIL=$GIT_EMAIL
GIT_USER=$GIT_USER
KEYS_SRC=$KEYS_SRC
KEYS_DEST=$KEYS_DEST
USE_DOTFILES_REPO=$USE_DOTFILES_REPO
EOF
log ".env file created at $HOME/wiz/.env."
