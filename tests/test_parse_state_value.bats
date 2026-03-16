#!/usr/bin/env bats
# ==============================================================================
# Tests for _parse_state_value() — lib/module-base.sh
# ==============================================================================
# Covers: happy-path key extraction, missing key, missing file, quoted values,
#         key-prefix collisions, and multi-line state files.
# ==============================================================================

load helpers/common_setup

setup()    { _common_setup; source "${WIZ_ROOT}/lib/module-base.sh"; }
teardown() { _common_teardown; }

# --- helpers ---

_write_state() {
    printf '%s\n' "$@" > "${TEST_TMPDIR}/state_file"
}

# --- tests ---

@test "_parse_state_value: returns value for existing key" {
    _write_state "STATUS=complete" "TIMESTAMP=1234567890"
    result=$(_parse_state_value "${TEST_TMPDIR}/state_file" "STATUS")
    [[ "$result" == "complete" ]]
}

@test "_parse_state_value: returns timestamp value" {
    _write_state "STATUS=complete" "TIMESTAMP=9999999999"
    result=$(_parse_state_value "${TEST_TMPDIR}/state_file" "TIMESTAMP")
    [[ "$result" == "9999999999" ]]
}

@test "_parse_state_value: returns empty string for missing key" {
    _write_state "STATUS=complete"
    result=$(_parse_state_value "${TEST_TMPDIR}/state_file" "MISSING")
    [[ -z "$result" ]]
}

@test "_parse_state_value: returns failure (exit 1) for missing file" {
    run _parse_state_value "${TEST_TMPDIR}/nonexistent" "STATUS"
    [[ "$status" -ne 0 ]]
}

@test "_parse_state_value: does not confuse STATUS_EXTRA with STATUS" {
    _write_state "STATUS_EXTRA=wrong" "STATUS=correct"
    result=$(_parse_state_value "${TEST_TMPDIR}/state_file" "STATUS")
    [[ "$result" == "correct" ]]
}

@test "_parse_state_value: handles quoted value (strips nothing — raw passthrough)" {
    _write_state 'ERROR="some error message"'
    result=$(_parse_state_value "${TEST_TMPDIR}/state_file" "ERROR")
    # grep+sed passthrough: quotes are preserved in raw state file
    [[ "$result" == '"some error message"' ]]
}

@test "_parse_state_value: returns first match when key appears twice" {
    _write_state "STATUS=first" "STATUS=second"
    result=$(_parse_state_value "${TEST_TMPDIR}/state_file" "STATUS")
    [[ "$result" == "first" ]]
}
