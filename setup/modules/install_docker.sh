#!/usr/bin/env bash
# Install Docker and Docker Compose

# Log the start of the Docker installation process
log "Installing Docker & Compose..."

# Install Docker and Docker Compose using apt
for pkg in docker.io docker-compose; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

# Add the current user to the docker group for non-root usage
run "sudo usermod -aG docker $USER"

# Inform the user that installation is complete and provide next steps
log "Docker installed. Restart WSL or run 'newgrp docker'."
