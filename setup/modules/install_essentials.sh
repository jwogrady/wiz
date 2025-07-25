#!/usr/bin/env bash
# Install essential tools and update system

# Simple log function
log() {
	echo "[INFO] $*"
}

# Simple run function
run() {
	log "Running: $*"
	eval "$@"
}

# Define all essential packages in a single array (duplicates removed)
ESSENTIAL_PKGS=(bind9-host dnsutils iperf3 mtr net-tools netcat-openbsd traceroute whois 
nmap btop glances htop lshw neofetch strace lsof build-essential cabal-install cmake jq
git curl wget unzip zip zsh docker.io docker-compose ca-certificates gnupg nano vim gh
 lsb-release sudo tree xz-utils)

log "Updating system packages..."
run "sudo apt update && sudo apt upgrade -y"

log "Installing all essential packages..."
for pkg in "${ESSENTIAL_PKGS[@]}"; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done
