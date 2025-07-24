#!/usr/bin/env bash
# Install ShellCheck from source
. "$(dirname "$0")/../../lib/common.sh"

log "Installing latest ShellCheck from source..."
SHELLCHECK_TMP="$HOME/shellcheck-src"
run "sudo apt-get update"
run "sudo apt-get install -y git xz-utils cabal-install"
run "rm -rf \"$SHELLCHECK_TMP\""
run "git clone --depth 1 https://github.com/koalaman/shellcheck.git \"$SHELLCHECK_TMP\""
cd "$SHELLCHECK_TMP"
run "cabal update"
run "cabal install --installdir=\"$HOME/.local/bin\" --install-method=copy"
log "ShellCheck version: $($HOME/.local/bin/shellcheck --version | head -n 1)"
cd ~
run "rm -rf \"$SHELLCHECK_TMP\""
