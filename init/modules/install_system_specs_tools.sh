#!/usr/bin/env bash
# Install system info and monitoring tools
. "$(dirname "$0")/../../lib/common.sh"

log "Installing system info and monitoring tools..."
run "sudo apt install -y neofetch lshw htop glances btop"
log "System specs (neofetch):"
neofetch || echo "neofetch not found"
log "Hardware summary (lshw -short):"
sudo lshw -short || echo "lshw not found"
