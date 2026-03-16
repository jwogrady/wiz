#!/usr/bin/env bats
# ==============================================================================
# Tests for wiz_update_shell_block() — lib/module-base.sh
# ==============================================================================
# Strategy: isolate HOME to TEST_TMPDIR/home; operate on an explicit rc_file
# path for clarity.  Functions are called directly so we can inspect the file
# after each call.
# ==============================================================================

load helpers/common_setup

setup() {
    _common_setup
    _setup_isolated_home
    source "${WIZ_ROOT}/lib/module-base.sh"
    RC_FILE="${HOME}/.bashrc"
}
teardown() { _common_teardown; }

_START="# --- Wiz Test ---"
_END="# --- End Wiz Test ---"

# --- tests ---

@test "wiz_update_shell_block: replaces existing block" {
    printf '%s\n' "$_START" "old content" "$_END" "after" > "$RC_FILE"

    wiz_update_shell_block "$_START" "$_END" "new content" "$RC_FILE"

    ! grep -qF "old content" "$RC_FILE"
    grep -qF "new content"   "$RC_FILE"
    # Lines after the block are preserved
    grep -qF "after"         "$RC_FILE"
}

@test "wiz_update_shell_block: appends block when absent" {
    echo "existing line" > "$RC_FILE"

    wiz_update_shell_block "$_START" "$_END" "new content" "$RC_FILE"

    grep -qF "existing line" "$RC_FILE"
    grep -qF "new content"   "$RC_FILE"
}

@test "wiz_update_shell_block: missing end sentinel warns and still appends block" {
    # Start sentinel present but no end sentinel — function must not delete to EOF
    printf '%s\n' "$_START" "orphaned content" > "$RC_FILE"

    wiz_update_shell_block "$_START" "$_END" "new content" "$RC_FILE"

    # Old content must NOT have been deleted (no-sentinel safety guard)
    grep -qF "orphaned content" "$RC_FILE"
    # New block is still appended after the warning
    grep -qF "new content" "$RC_FILE"
}

@test "wiz_update_shell_block: dry-run does not modify file" {
    echo "original" > "$RC_FILE"
    WIZ_DRY_RUN=1

    wiz_update_shell_block "$_START" "$_END" "new content" "$RC_FILE"

    grep -qF "original"    "$RC_FILE"
    ! grep -qF "new content" "$RC_FILE"
}

@test "wiz_update_shell_block: nonexistent file returns 0 without error" {
    bats_run wiz_update_shell_block "$_START" "$_END" "new content" "/nonexistent/path/.zshrc"
    [[ "$status" -eq 0 ]]
}
