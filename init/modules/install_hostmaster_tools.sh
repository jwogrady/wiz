#!/usr/bin/env bash
# Install hostmaster, DNS, and network tools
. "$(dirname "$0")/../../lib/common.sh"

log "Installing hostmaster, domain, DNS, and internet tools..."
run "sudo apt install -y bind9-host dnsutils whois traceroute mtr nmap iperf3 netcat-openbsd"
