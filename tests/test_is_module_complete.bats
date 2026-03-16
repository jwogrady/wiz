#!/usr/bin/env bats
# ==============================================================================
# Tests for is_module_complete() and get_module_state() — lib/module-base.sh
# ==============================================================================

load helpers/common_setup

setup()    { _common_setup; source "${WIZ_ROOT}/lib/module-base.sh"; }
teardown() { _common_teardown; }

# --- tests ---

@test "is_module_complete: returns false when no state file exists" {
    bats_run is_module_complete "no_such_module"
    [[ "$status" -ne 0 ]]
}

@test "is_module_complete: returns true after mark_module_complete" {
    mark_module_complete "mymodule"
    bats_run is_module_complete "mymodule"
    [[ "$status" -eq 0 ]]
}

@test "is_module_complete: returns false after mark_module_failed" {
    mark_module_failed "mymodule" "something went wrong"
    bats_run is_module_complete "mymodule"
    [[ "$status" -ne 0 ]]
}

@test "get_module_state: returns 'not-started' when no state file" {
    result=$(get_module_state "no_such_module")
    [[ "$result" == "not-started" ]]
}

@test "get_module_state: returns 'complete' after mark_module_complete" {
    mark_module_complete "mymodule"
    result=$(get_module_state "mymodule")
    [[ "$result" == "complete" ]]
}

@test "get_module_state: returns 'failed' after mark_module_failed" {
    mark_module_failed "mymodule" "oops"
    result=$(get_module_state "mymodule")
    [[ "$result" == "failed" ]]
}

@test "is_module_complete: separate modules have independent state" {
    mark_module_complete "alpha"
    mark_module_failed  "beta" "broken"
    bats_run is_module_complete "alpha"
    [[ "$status" -eq 0 ]]
    bats_run is_module_complete "beta"
    [[ "$status" -ne 0 ]]
}
