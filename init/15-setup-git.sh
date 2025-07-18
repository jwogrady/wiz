#!/bin/bash
# filepath: /home/john/wiz/15-setup-git.sh

# Load values from .env
ENV_FILE="$HOME/wiz/.env"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Set global git config using .env values
git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_USER}"

# Create a default global .gitignore
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

echo "Global git config and .gitignore set up using values from .env."