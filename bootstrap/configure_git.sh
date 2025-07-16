#!/bin/bash

# Set Git user name and email from environment variables
if [ -n "$GIT_USER" ]; then
    git config --global user.name "$GIT_USER"
    echo "Set git user.name to $GIT_USER"
fi

if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
    echo "Set git user.email to $GIT_EMAIL"
fi

# Optionally, set GitHub username if needed
if [ -n "$GITHUB_USERNAME" ]; then
    git config --global github.user "$GITHUB_USERNAME"
    echo "Set github.user to $GITHUB_USERNAME"
fi

# Set nano as the default editor for git
git config --global core.editor "nano"
echo "Set git core.editor to nano"

# Create a global gitignore if it doesn't exist
GLOBAL_GITIGNORE="$HOME/.gitignore_global"
if [ ! -f "$GLOBAL_GITIGNORE" ]; then
    cat > "$GLOBAL_GITIGNORE" <<EOF
# Compiled source #
###################
*.com
*.class
*.dll
*.exe
*.o
*.so

# Packages #
############
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.zip

# Logs and databases #
######################
*.log
*.sql
*.sqlite

# OS generated files #
######################
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Icon?
Thumbs.db
EOF
    echo "Created $GLOBAL_GITIGNORE"
fi

git config --global core.excludesfile "$GLOBAL_GITIGNORE"
echo "Set git core.excludesfile to $GLOBAL_GITIGNORE"