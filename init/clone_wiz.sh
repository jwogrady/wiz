#!/bin/bash
# Clone the wiz repo
envfile="$HOME/wiz/.env"
if [ -f "$envfile" ]; then
    . "$envfile"
    WIZ_REPO_URL="https://github.com/${GITHUB_USERNAME}/wiz.git"
    cwd=$(pwd)
    # If already in the wiz directory, skip clone
    if [[ "$cwd" == "$HOME/wiz" ]]; then
        echo "Already in the wiz directory, skipping clone."
        exit 0
    fi
    # If wiz directory does not exist, clone to current directory
    if [ ! -d "$cwd/wiz" ]; then
        git clone "$WIZ_REPO_URL" "$cwd/wiz" || echo "$cwd/wiz already exists."
    else
        echo "$cwd/wiz already exists, skipping clone."
    fi
else
    echo ".env file not found. Cannot clone wiz repo."
fi
