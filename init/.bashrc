# ~/.bashrc - WIZ Pretty Bash Terminal
# Add this to your ~/.bashrc or source it from ~/.profile for bash

# Color codes
RED='\[\033[0;31m\]'
GREEN='\[\033[0;32m\]'
YELLOW='\[\033[1;33m\]'
BLUE='\[\033[0;34m\]'
MAGENTA='\[\033[0;35m\]'
CYAN='\[\033[0;36m\]'
RESET='\[\033[0m\]'

# Vibrant, modern prompt: user@host:path (git branch)
parse_git_branch() {
    git branch 2>/dev/null | grep '^*' | sed 's/* //'
}
export PS1="\[\033[0;36m\]\u\[\033[0m\]@\[\033[0;35m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]\[\033[0;34m\]\$(parse_git_branch)\[\033[0m\]\$ "

# Colorized ls (if available)
if command -v ls >/dev/null 2>&1; then
    alias ls='ls --color=auto'
fi

# Colorized grep (if available)
if command -v grep >/dev/null 2>&1; then
    alias grep='grep --color=auto'
fi

# Welcome message
printf "\033[0;32mWelcome to your WIZ bash shell!\033[0m\n"

# One-liner to test color prompt interactively:
# Paste this in your shell to test:
# export PS1="\[\033[0;36m\]\u\[\033[0m\]@\[\033[0;35m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[0m\]\$ "
