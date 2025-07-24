#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Wiz - Terminal Magic: Idempotency Test
# Verifies that atomic_write does not rewrite files unnecessarily.
# ------------------------------------------------------------------------------

# Source common utilities
. "$(dirname "$0")/../lib/common.sh"

TESTFILE="/tmp/test_idempotent.conf"
echo "foo=bar" > "$TESTFILE"
atomic_write "$TESTFILE" <<< "foo=bar"
# Capture file modification time before and after
mtime1=$(stat -c %Y "$TESTFILE")
atomic_write "$TESTFILE" <<< "foo=bar"
mtime2=$(stat -c %Y "$TESTFILE")
if [ "$mtime1" -eq "$mtime2" ]; then
  echo "Idempotency test passed: file not rewritten unnecessarily."
else
  echo "Idempotency test failed."
fi
rm "$TESTFILE"
