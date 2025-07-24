#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Wiz - Terminal Magic: Test for lib/common.sh utilities
# Verifies logging, atomic_write, and environment detection functions.
# ------------------------------------------------------------------------------

# Source common utilities
# shellcheck source=../lib/common.sh
. "$(dirname "$0")/../lib/common.sh"

# Test logging functions
log "Testing log function"
warn "Testing warn function"
error "Testing error function"

# Test atomic_write (should only update file if content changes)
touch /tmp/testfile
atomic_write /tmp/testfile <<<"test"
atomic_write /tmp/testfile <<<"test" # Should not rewrite
rm /tmp/testfile

# Test OS and shell detection
echo "OS detected: $(detect_os)"
echo "Shell detected: $(detect_shell)"
