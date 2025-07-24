#!/usr/bin/env bash
# Install essential tools and update system

# Update system package lists and upgrade installed packages
log "Updating system packages..."
run "sudo apt update && sudo apt upgrade -y"

# Install a set of essential tools for development and networking
log "Installing DNS / Network tools..."
for pkg in bind9-host dnsutils iperf3 mtr net-tools netcat-openbsd traceroute whois nmap; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing system monitoring & info tools..."
for pkg in btop glances htop lshw neofetch strace lsof; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing build / dev toolchain..."
for pkg in build-essential cabal-install cmake jq git; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing package management & shells..."
for pkg in curl wget unzip zip zsh; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing Docker stack..."
for pkg in docker.io docker-compose; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing security / SSL tools..."
for pkg in ca-certificates gnupg; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing user tools / editors..."
for pkg in nano vim; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing GitHub CLI..."
for pkg in gh; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done

log "Installing OS metadata & core utils..."
for pkg in lsb-release sudo tree xz-utils; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done
