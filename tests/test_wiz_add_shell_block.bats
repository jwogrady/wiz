#!/usr/bin/env bats
# ==============================================================================
# Tests for wiz_add_shell_block() — lib/module-base.sh
# ==============================================================================
# Strategy: isolate HOME to TEST_TMPDIR/home so tests never touch the real
# ~/.bashrc / ~/.zshrc.  Functions are called directly (not via 'run') so we
# can inspect file contents after the call.
# ==============================================================================

load helpers/common_setup

setup() {
    _common_setup
    _setup_isolated_home
    source "${WIZ_ROOT}/lib/module-base.sh"
}
teardown() { _common_teardown; }

# sentinel and block used across tests
_SENTINEL=">>> Test block >>>"
_BLOCK='
# >>> Test block >>>
export WIZ_TEST_VAR=1
# <<< Test block <<<'

# --- tests ---

@test "wiz_add_shell_block: appends block to both .bashrc and .zshrc" {
    wiz_add_shell_block "$_SENTINEL" "$_BLOCK"

    grep -qF "$_SENTINEL" "${HOME}/.bashrc"
    grep -qF "$_SENTINEL" "${HOME}/.zshrc"
}

@test "wiz_add_shell_block: idempotent — block not duplicated on second call" {
    wiz_add_shell_block "$_SENTINEL" "$_BLOCK"
    wiz_add_shell_block "$_SENTINEL" "$_BLOCK"

    local count
    count="$(grep -cF "$_SENTINEL" "${HOME}/.bashrc")"
    [[ "$count" -eq 1 ]]

    count="$(grep -cF "$_SENTINEL" "${HOME}/.zshrc")"
    [[ "$count" -eq 1 ]]
}

@test "wiz_add_shell_block: skips missing rc files without error" {
    rm -f "${HOME}/.bashrc" "${HOME}/.zshrc"

    wiz_add_shell_block "$_SENTINEL" "$_BLOCK"

    [[ ! -f "${HOME}/.bashrc" ]]
    [[ ! -f "${HOME}/.zshrc" ]]
}

@test "wiz_add_shell_block: dry-run does not modify rc files" {
    WIZ_DRY_RUN=1

    wiz_add_shell_block "$_SENTINEL" "$_BLOCK"

    # Files exist but should be empty (untouched by dry-run)
    [[ ! -s "${HOME}/.bashrc" ]]
    [[ ! -s "${HOME}/.zshrc" ]]
}
