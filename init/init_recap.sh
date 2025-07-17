#!/bin/bash
# Recap of environment initialization using .env variables

ENV_FILE="$HOME/wiz/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    echo "No .env file found. Initialization may not have completed."
    exit 1
fi
# shellcheck disable=SC1090
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
