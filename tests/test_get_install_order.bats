#!/usr/bin/env bats
# ==============================================================================
# Tests for get_install_order() — lib/module-base.sh
# ==============================================================================
# Covers: single module, linear chain, diamond dependency, no-dep modules,
#         duplicate requests, circular dependency detection.
# ==============================================================================

load helpers/common_setup

setup() {
    _common_setup
    source "${WIZ_ROOT}/lib/module-base.sh"
    # Reset the global dependency map for each test
    declare -gA MODULE_DEPS_MAP=()
}

teardown() { _common_teardown; }

# --- helpers ---

# _reg <name> [deps]: shorthand for register_module
_reg() { register_module "$1" "${2:-}"; }

# _order <modules...>: call get_install_order and split output into array
# Sets global ORDER_RESULT array
_order() {
    IFS=' ' read -ra ORDER_RESULT <<< "$(get_install_order "$@")"
}

# --- tests ---

@test "get_install_order: single module with no deps returns itself" {
    _reg "alpha"
    _order "alpha"
    [[ "${#ORDER_RESULT[@]}" -eq 1 ]]
    [[ "${ORDER_RESULT[0]}" == "alpha" ]]
}

@test "get_install_order: linear chain a -> b -> c returns c b a order" {
    _reg "a" "b"
    _reg "b" "c"
    _reg "c"
    _order "a"
    # c must come before b, b before a
    local pos_a pos_b pos_c i=0
    for m in "${ORDER_RESULT[@]}"; do
        case "$m" in
            a) pos_a=$i ;;
            b) pos_b=$i ;;
            c) pos_c=$i ;;
        esac
        ((i++))
    done
    [[ $pos_c -lt $pos_b ]]
    [[ $pos_b -lt $pos_a ]]
}

@test "get_install_order: diamond dep (a->b, a->c, b->d, c->d) d appears once" {
    _reg "a" "b c"
    _reg "b" "d"
    _reg "c" "d"
    _reg "d"
    _order "a"
    # Count occurrences of 'd'
    local count=0
    for m in "${ORDER_RESULT[@]}"; do
        [[ "$m" == "d" ]] && ((count++))
    done
    [[ $count -eq 1 ]]
    # d must come before b and c
    local pos_d pos_b pos_c i=0
    for m in "${ORDER_RESULT[@]}"; do
        case "$m" in
            d) pos_d=$i ;;
            b) pos_b=$i ;;
            c) pos_c=$i ;;
        esac
        ((i++))
    done
    [[ $pos_d -lt $pos_b ]]
    [[ $pos_d -lt $pos_c ]]
}

@test "get_install_order: duplicate request produces each module once" {
    _reg "x"
    _order "x" "x"
    local count=0
    for m in "${ORDER_RESULT[@]}"; do
        [[ "$m" == "x" ]] && ((count++))
    done
    [[ $count -eq 1 ]]
}

@test "get_install_order: two independent modules both appear" {
    _reg "foo"
    _reg "bar"
    _order "foo" "bar"
    [[ "${#ORDER_RESULT[@]}" -eq 2 ]]
}

@test "get_install_order: circular dependency returns non-zero exit" {
    _reg "p" "q"
    _reg "q" "p"
    run get_install_order "p"
    [[ "$status" -ne 0 ]]
}

@test "get_install_order: MODULE_DEPS 'ALL' treated as no ordering constraint" {
    _reg "summary" "ALL"
    # Should not error — ALL is a sentinel, not a real dep name
    run get_install_order "summary"
    [[ "$status" -eq 0 ]]
}
