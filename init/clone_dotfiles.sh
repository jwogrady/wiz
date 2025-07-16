#!/bin/bash
# Clone dotfiles repo to .backup
envfile="$HOME/wiz/.env"
if [ -f "$envfile" ]; then
    . "$envfile"
    git clone "$GITHUB_DOTFILES_REPO_URL" "$HOME/wiz/.backup" || echo ".backup already exists."
else
    echo ".env file not found. Cannot clone dotfiles."
fi
