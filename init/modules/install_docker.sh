#!/usr/bin/env bash
# Install Docker and Docker Compose
. "$(dirname "$0")/../../lib/common.sh"

log "Installing Docker & Compose..."
run "sudo apt install -y docker.io docker-compose"
run "sudo usermod -aG docker $USER"
log "Docker installed. Restart WSL or run 'newgrp docker'."
