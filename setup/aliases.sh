#!/bin/bash

# Custom Aliases File

# Basic
alias cls='clear'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'

# Directory & Navigation
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias md='mkdir -p'
alias rd='rmdir'

# File Operations
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gd='git diff'
alias gcm='git commit -m'
alias gb='git branch'
alias gcl='git clone'

# System & Updates
alias update='sudo apt update && sudo apt upgrade -y' # Debian/Ubuntu
alias updsys='sudo dnf upgrade -y'                    # Fedora
alias sysinfo='uname -a'
alias distro='cat /etc/os-release'
alias ports='ss -tuln'
alias topcpu='ps aux --sort=-%cpu | head -10'
alias topmem='ps aux --sort=-%mem | head -10'

# Docker
alias dps='docker ps'
alias dpa='docker ps -a'
alias dim='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dc='docker-compose'
alias dexec='docker exec -it'

# Editors
alias v='vim'
alias vi='vim'
alias e='nano'

# Network
alias myip='curl ifconfig.me'
alias pingg='ping google.com'

# SSH
alias sshk='ssh-keygen -t ed25519 -C "your_email@example.com"'
alias ssh-copy='ssh-copy-id -i ~/.ssh/id_ed25519.pub'

# Miscellaneous
alias weather='curl wttr.in'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
