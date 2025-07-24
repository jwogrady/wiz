#!/usr/bin/env bash
# Install hostmaster, DNS, and network tools

# Log the start of the network tools installation
log "Installing hostmaster, domain, DNS, and internet tools..."

# Install a suite of DNS and network troubleshooting tools
for pkg in bind9-host dnsutils whois traceroute mtr nmap iperf3 netcat-openbsd; do
	if dpkg -s "$pkg" &>/dev/null; then
		log "$pkg is already installed. Skipping."
	else
		run "sudo apt install -y $pkg"
	fi
done
