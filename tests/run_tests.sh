#!/usr/bin/env bash
# ==============================================================================
# Wiz test runner
# ==============================================================================
# Usage: ./tests/run_tests.sh [bats-options] [test-file ...]
#
# Requires BATS (Bash Automated Testing System).
# Install: https://github.com/bats-core/bats-core#installation
#   apt:  sudo apt-get install bats
#   brew: brew install bats-core
#   npm:  npm install -g bats
#
# Examples:
#   ./tests/run_tests.sh                     # run all tests
#   ./tests/run_tests.sh --tap               # TAP output
#   ./tests/run_tests.sh tests/test_has_ssh_keys.bats
# ==============================================================================
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v bats >/dev/null 2>&1; then
    echo "ERROR: bats is not installed." >&2
    echo "  apt:  sudo apt-get install bats" >&2
    echo "  brew: brew install bats-core" >&2
    echo "  npm:  npm install -g bats" >&2
    exit 1
fi

# Separate bats options (args starting with -) from test file arguments
bats_opts=()
bats_files=()
for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
        bats_opts+=("$arg")
    else
        bats_files+=("$arg")
    fi
done

if [[ ${#bats_files[@]} -eq 0 ]]; then
    exec bats "${bats_opts[@]+"${bats_opts[@]}"}" "${TESTS_DIR}"/*.bats
else
    exec bats "${bats_opts[@]+"${bats_opts[@]}"}" "${bats_files[@]}"
fi
