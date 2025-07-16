#!/bin/bash
# Prompt user for environment variables and write .env
set -e
read -rp "Enter your GitHub username: " GITHUB_USERNAME
read -rp "Enter your dotfiles repository name: " GITHUB_DOTFILES_REPO_NAME
GITHUB_DOTFILES_REPO_URL="https://github.com/${GITHUB_USERNAME}/${GITHUB_DOTFILES_REPO_NAME}.git"
read -rp "Enter your Git user email: " GIT_EMAIL
read -rp "Enter your Git user name: " GIT_USER
read -rp "Enter the path to your keys.tar.gz file: " KEYS_SRC
KEYS_DEST="$HOME"
cat > "$HOME/wiz/.env" <<EOF
GITHUB_USERNAME=$GITHUB_USERNAME
GITHUB_DOTFILES_REPO_NAME=$GITHUB_DOTFILES_REPO_NAME
GITHUB_DOTFILES_REPO_URL=$GITHUB_DOTFILES_REPO_URL
GIT_EMAIL=$GIT_EMAIL
GIT_USER=$GIT_USER
KEYS_SRC=$KEYS_SRC
KEYS_DEST=$KEYS_DEST
EOF
echo ".env file created at $HOME/wiz/.env."
