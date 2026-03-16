#!/usr/bin/env bats
# ==============================================================================
# Tests for wiz_download_verified() — lib/download.sh
# ==============================================================================
# Strategy: stub download_to_temp and verify_sha256 (bash functions) after
# sourcing the library so wiz_download_verified uses the stubs instead of
# making real network calls.
#
# NOTE: lib/common.sh exports its own `run` function which clobbers BATS's
# `run` helper.  _common_setup saves the BATS `run` as `bats_run` before any
# library is sourced — all `run` calls below use `bats_run`.
# ==============================================================================

load helpers/common_setup

setup()    { _common_setup; source "${WIZ_ROOT}/lib/download.sh"; }
teardown() { _common_teardown; }

# --- helpers ---

_make_installer() {
    local path="${TEST_TMPDIR}/installer.sh"
    echo "#!/bin/sh" > "$path"
    echo "$path"
}

# --- tests ---

@test "wiz_download_verified: empty sha warns and returns temp path" {
    _make_installer >/dev/null

    download_to_temp() { echo "${TEST_TMPDIR}/installer.sh"; }
    export -f download_to_temp

    bats_run wiz_download_verified "https://example.com/install.sh" "" "failed"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "${TEST_TMPDIR}/installer.sh" ]]
}

@test "wiz_download_verified: matching sha returns temp path" {
    _make_installer >/dev/null

    download_to_temp() { echo "${TEST_TMPDIR}/installer.sh"; }
    verify_sha256()    { return 0; }
    export -f download_to_temp verify_sha256

    bats_run wiz_download_verified "https://example.com/install.sh" "abc123def456" "failed"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "${TEST_TMPDIR}/installer.sh" ]]
}

@test "wiz_download_verified: sha mismatch removes temp file and returns 1" {
    _make_installer >/dev/null

    download_to_temp() { echo "${TEST_TMPDIR}/installer.sh"; }
    verify_sha256()    { return 1; }
    export -f download_to_temp verify_sha256

    bats_run wiz_download_verified "https://example.com/install.sh" "badhash" "failed"
    [[ "$status" -ne 0 ]]
    [[ ! -f "${TEST_TMPDIR}/installer.sh" ]]
}

@test "wiz_download_verified: sha tool unavailable (rc=2) proceeds and returns path" {
    _make_installer >/dev/null

    download_to_temp() { echo "${TEST_TMPDIR}/installer.sh"; }
    verify_sha256()    { return 2; }
    export -f download_to_temp verify_sha256

    bats_run wiz_download_verified "https://example.com/install.sh" "somehash" "failed"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "${TEST_TMPDIR}/installer.sh" ]]
}

@test "wiz_download_verified: download failure returns 1" {
    download_to_temp() { return 1; }
    export -f download_to_temp

    bats_run wiz_download_verified "https://example.com/install.sh" "" "failed"
    [[ "$status" -ne 0 ]]
}
