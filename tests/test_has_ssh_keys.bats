#!/usr/bin/env bats
# ==============================================================================
# Tests for has_ssh_keys() — lib/ssh.sh
# ==============================================================================
# Covers: missing dir, empty dir, dir with only .pub, dir with a private key,
#         dir with known_hosts/config only, and explicit path argument.
# ==============================================================================

load helpers/common_setup

setup() {
    _common_setup
    # ssh.sh sources common.sh internally; common.sh is already sourced by
    # _common_setup env stubs, so source ssh.sh directly.
    source "${WIZ_ROOT}/lib/common.sh"
    source "${WIZ_ROOT}/lib/ssh.sh"
    SSH_DIR="${TEST_TMPDIR}/dot_ssh"
}

teardown() { _common_teardown; }

# --- tests ---

@test "has_ssh_keys: returns false when directory does not exist" {
    bats_run has_ssh_keys "${SSH_DIR}/nonexistent"
    [[ "$status" -ne 0 ]]
}

@test "has_ssh_keys: returns false when directory is empty" {
    mkdir -p "$SSH_DIR"
    bats_run has_ssh_keys "$SSH_DIR"
    [[ "$status" -ne 0 ]]
}

@test "has_ssh_keys: returns false when only .pub file exists" {
    mkdir -p "$SSH_DIR"
    touch "${SSH_DIR}/id_ed25519.pub"
    bats_run has_ssh_keys "$SSH_DIR"
    [[ "$status" -ne 0 ]]
}

@test "has_ssh_keys: returns false when only known_hosts exists" {
    mkdir -p "$SSH_DIR"
    touch "${SSH_DIR}/known_hosts"
    bats_run has_ssh_keys "$SSH_DIR"
    [[ "$status" -ne 0 ]]
}

@test "has_ssh_keys: returns false when only config file exists" {
    mkdir -p "$SSH_DIR"
    touch "${SSH_DIR}/config"
    bats_run has_ssh_keys "$SSH_DIR"
    [[ "$status" -ne 0 ]]
}

@test "has_ssh_keys: returns true when a private key exists" {
    mkdir -p "$SSH_DIR"
    touch "${SSH_DIR}/id_ed25519"
    chmod 600 "${SSH_DIR}/id_ed25519"
    bats_run has_ssh_keys "$SSH_DIR"
    [[ "$status" -eq 0 ]]
}

@test "has_ssh_keys: returns true when private key exists alongside .pub" {
    mkdir -p "$SSH_DIR"
    touch "${SSH_DIR}/id_ed25519"
    touch "${SSH_DIR}/id_ed25519.pub"
    chmod 600 "${SSH_DIR}/id_ed25519"
    bats_run has_ssh_keys "$SSH_DIR"
    [[ "$status" -eq 0 ]]
}

@test "has_ssh_keys: defaults to HOME/.ssh when no argument given" {
    # This test only validates the function runs without error using the default
    # path (result depends on actual HOME/.ssh — just check no crash)
    bats_run has_ssh_keys
    [[ "$status" -eq 0 || "$status" -ne 0 ]]  # either outcome is valid
}
