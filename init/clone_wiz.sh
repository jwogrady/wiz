#!/bin/bash
# Clone the wiz repo
envfile="$HOME/wiz/.env"
if [ -f "$envfile" ]; then
    . "$envfile"
    WIZ_REPO_URL="https://github.com/${GITHUB_USERNAME}/wiz.git"
    git clone "$WIZ_REPO_URL" "$HOME/wiz/wiz_clone" || echo "wiz_clone already exists."
else
    echo ".env file not found. Cannot clone wiz repo."
fi
