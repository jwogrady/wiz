#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: Download Helpers
# ==============================================================================
# SHA-256 verification, curl/wget download with fallback, and version detection.
#
# Normal usage: sourced transitively by lib/common.sh — callers need only:
#   source /path/to/lib/common.sh
#
# Standalone (direct) usage:
#   source /path/to/lib/download.sh   # guard below bootstraps common.sh if needed
#
# Functions:
#   - verify_sha256          <file> <expected_hex>
#   - download_to_temp       <url> [error_message]
#   - curl_or_wget_download  <url> [output_file] [error_message]
#   - get_command_version    <cmd> [pattern]
#
# ==============================================================================

set -euo pipefail

# --- Ensure common.sh is sourced ---
# Defensive guard: only fires when this file is sourced directly (outside the
# normal common.sh chain).  Do NOT use WIZ_ROOT:= here — see pkg.sh for
# explanation of why that would misconfigure WIZ_ROOT.
if ! declare -f log >/dev/null 2>&1; then
    # shellcheck source=common.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

# verify_sha256: Compare a file's SHA-256 digest against an expected value
# Usage: verify_sha256 <file> <expected_hex_digest>
# Returns 0 on match, 1 on mismatch, 2 if sha256sum/shasum unavailable (warns, not fatal)
verify_sha256() {
    local file="$1"
    local expected="$2"

    local sha_cmd=""
    if command_exists sha256sum; then
        sha_cmd="sha256sum"
    elif command_exists shasum; then
        sha_cmd="shasum -a 256"
    else
        warn "sha256sum/shasum not available — skipping checksum verification for $(basename "$file")"
        return 2
    fi

    local actual
    actual="$($sha_cmd "$file" | awk '{print $1}')"

    if [[ "$actual" != "$expected" ]]; then
        error "SHA-256 mismatch for $(basename "$file")"
        error "  expected: $expected"
        error "  actual:   $actual"
        return 1
    fi

    debug "SHA-256 verified: $(basename "$file")"
    return 0
}

# download_to_temp: Download a URL to a mktemp file; print the temp path to stdout.
# Usage: tmp=$(download_to_temp <url> [error_message])
# Caller is responsible for deleting the file when done.
download_to_temp() {
    local url="$1"
    local error_msg="${2:-Failed to download installer}"

    local tmp_file
    tmp_file="$(mktemp)"
    chmod 600 "$tmp_file"

    curl_or_wget_download "$url" "$tmp_file" "$error_msg" || {
        rm -f "$tmp_file"
        return 1
    }

    echo "$tmp_file"
}

# curl_or_wget_download: Download using curl or wget with fallback
# Usage: curl_or_wget_download <url> [output_file] [error_message]
curl_or_wget_download() {
    local url="$1"
    local output_file="${2:-}"
    local error_msg="${3:-Failed to download}"

    if command_exists curl; then
        if [[ -n "$output_file" ]]; then
            run curl -fsSL -o "$output_file" "$url" || {
                warn "curl download failed, trying wget..."
                if command_exists wget; then
                    run wget -q -O "$output_file" "$url" || {
                        error "$error_msg"
                        return 1
                    }
                else
                    error "$error_msg: Neither curl nor wget available"
                    return 1
                fi
            }
        else
            run curl -fsSL "$url" || {
                warn "curl download failed, trying wget..."
                if command_exists wget; then
                    run wget -qO- "$url" || {
                        error "$error_msg"
                        return 1
                    }
                else
                    error "$error_msg: Neither curl nor wget available"
                    return 1
                fi
            }
        fi
    elif command_exists wget; then
        if [[ -n "$output_file" ]]; then
            run wget -q -O "$output_file" "$url" || {
                error "$error_msg"
                return 1
            }
        else
            run wget -qO- "$url" || {
                error "$error_msg"
                return 1
            }
        fi
    else
        error "$error_msg: Neither curl nor wget available"
        return 1
    fi

    return 0
}

# get_command_version: Extract version string from a command's output
# Usage: version=$(get_command_version <command> [version_pattern])
get_command_version() {
    local cmd="$1"
    local pattern="${2:-version}"

    if ! command_exists "$cmd"; then
        echo "unknown"
        return 1
    fi

    local version=""

    if version=$(timeout 2 "$cmd" --version </dev/null 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/^v//' 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi

    if version=$(timeout 2 "$cmd" -v </dev/null 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/^v//' 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi

    if version=$(timeout 2 "$cmd" -version </dev/null 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/^v//' 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi

    if version=$(timeout 2 "$cmd" --version </dev/null 2>/dev/null | head -n1 2>/dev/null); then
        [[ -n "$version" ]] && echo "$version" && return 0
    fi

    echo "unknown"
    return 1
}

# --- Export Functions ---
export -f verify_sha256 download_to_temp curl_or_wget_download get_command_version

debug "Download helpers library loaded"
