#!/usr/bin/env bash
# ==============================================================================
# BATS test helpers: shared setup / teardown for all wiz test suites
# ==============================================================================
# Sourced by each .bats file via 'load helpers/common_setup'.
#
# Provides:
#   - _common_setup   : create a per-test temp dir, stub required env vars,
#                       source the library under test
#   - _common_teardown: clean up temp dir
#
# Usage inside a .bats file:
#   setup()    { _common_setup;    }
#   teardown() { _common_teardown; }
# ==============================================================================

# Resolve wiz root regardless of where bats is invoked from
WIZ_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIZ_ROOT="$(cd "${WIZ_TEST_DIR}/.." && pwd)"

_common_setup() {
    # Unique temp directory for each test — avoids cross-test pollution
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR

    # Capture BATS's `run` before any wiz library is sourced.
    # lib/common.sh exports its own `run` (a command wrapper with logging) which
    # clobbers BATS's `run` (the test helper that captures output/status).
    # Tests that source wiz libs must call `bats_run` instead of `run`.
    eval "bats_run() { $(declare -f run | tail -n +2) }"

    # --- Stub required WIZ_ variables so sourcing libs doesn't fail ---
    export WIZ_ROOT
    export WIZ_LOG_DIR="${TEST_TMPDIR}/logs"
    export WIZ_CACHE_DIR="${TEST_TMPDIR}/cache"
    export WIZ_STATE_DIR="${TEST_TMPDIR}/state"
    export WIZ_SSH_FINGERPRINT_CACHE_DIR="${TEST_TMPDIR}/cache/ssh_fingerprints"
    export WIZ_DRY_RUN=0
    export WIZ_LOG_LEVEL=3   # suppress all output during tests
    export WIZ_LOG_FILE="${TEST_TMPDIR}/logs/wiz.log"
    export WIZ_VERBOSE=0
    export WIZ_FORCE_REINSTALL=0
    export WIZ_STOP_ON_ERROR=1

    # Compat aliases — still referenced by run/_run_common_pre and ssh.sh/identity.sh
    # until WIZ_FORCE_REINSTALL fully replaces FORCE everywhere.
    export LOG_DIR="$WIZ_LOG_DIR"
    export LOG_FILE="$WIZ_LOG_FILE"
    export DRY_RUN=0
    export LOG_LEVEL=3
    export VERBOSE=0
    export FORCE=0

    mkdir -p "$WIZ_LOG_DIR" "$WIZ_CACHE_DIR" "$WIZ_STATE_DIR" \
             "$WIZ_SSH_FINGERPRINT_CACHE_DIR"
}

_setup_isolated_home() {
    # Redirects HOME to a temp directory so tests don't touch the real ~/.bashrc / ~/.zshrc.
    # Call after _common_setup (requires TEST_TMPDIR to exist).
    # Optional arg: pass 0 to skip creating empty rc files (test creates them itself).
    export HOME="${TEST_TMPDIR}/home"
    mkdir -p "$HOME"
    local create_rc="${1:-1}"
    if [[ "$create_rc" -eq 1 ]]; then
        touch "${HOME}/.bashrc" "${HOME}/.zshrc"
    fi
}

_common_teardown() {
    # Close the log FD opened by common.sh if present
    if [[ -n "${_WIZ_LOG_FD:-}" ]]; then
        exec {_WIZ_LOG_FD}>&- 2>/dev/null || true
        unset _WIZ_LOG_FD
    fi
    [[ -d "${TEST_TMPDIR:-}" ]] && rm -rf "$TEST_TMPDIR"
}
