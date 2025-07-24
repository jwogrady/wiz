#!/usr/bin/env bash
# Install essential tools and update system
. "$(dirname "$0")/../../lib/common.sh"

log "Updating system packages..."
run "sudo apt update && sudo apt upgrade -y"
log "Installing essential tools (editors, net, build)..."
run "sudo apt install -y git vim nano curl net-tools speedtest-cli build-essential cmake tree"
