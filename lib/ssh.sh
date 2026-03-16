#!/usr/bin/env bash
# ==============================================================================
# Wiz - Terminal Magic: SSH Library
# ==============================================================================
# SSH key import, agent configuration, and session key loading.
#
# Depends on globals set by bin/install:
#   $KEYS_PATH, $WIN_USER, $GIT_EMAIL, $FORCE
#
# Usage:
#   source /path/to/lib/ssh.sh
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Ensure common.sh is sourced ---
if ! declare -f log >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=common.sh
    source "${SCRIPT_DIR}/common.sh"
fi

# ==============================================================================
# SSH KEY MANAGEMENT
# ==============================================================================

# has_ssh_keys: Check if SSH keys exist in a directory
# Usage: has_ssh_keys [ssh_dir]
has_ssh_keys() {
    local ssh_dir="${1:-${HOME}/.ssh}"
    [[ -d "$ssh_dir" ]] || return 1

    local key
    for key in "$ssh_dir"/*; do
        # Guard against empty directory (nullglob not guaranteed)
        [[ -e "$key" ]] || return 1
        [[ -f "$key" ]] || continue
        [[ "$key" == *.pub ]] && continue
        [[ "$key" == *known_hosts* ]] && continue
        [[ "$key" == *config* ]] && continue
        return 0
    done

    return 1
}

# load_ssh_keys_to_agent: Load all SSH keys into the agent
# Only prompts for passphrase if keys aren't already loaded
load_ssh_keys_to_agent() {
    local ssh_dir="${HOME}/.ssh"
    [[ -d "$ssh_dir" ]] || return 0

    if ! command_exists ssh-agent || ! command_exists ssh-add; then
        return 0
    fi

    # Start agent if not running
    if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null 2>&1 || return 0
        export SSH_AUTH_SOCK SSH_AGENT_PID
    fi

    # Get list of already-loaded keys (fingerprints)
    local loaded_fingerprints
    loaded_fingerprints=$(ssh-add -l 2>/dev/null | awk '{print $2}') || loaded_fingerprints=""

    local keys_loaded=0
    local keys_skipped=0
    local key
    for key in "$ssh_dir"/*; do
        # Guard against empty directory (nullglob not guaranteed)
        [[ -e "$key" ]] || break
        [[ -f "$key" ]] || continue
        [[ "$key" == *.pub ]] && continue
        [[ "$key" == *known_hosts* ]] && continue
        [[ "$key" == *config* ]] && continue

        # Check if key is already loaded by comparing fingerprints
        local key_fingerprint
        if declare -f get_cached_ssh_fingerprint >/dev/null 2>&1; then
            key_fingerprint=$(get_cached_ssh_fingerprint "$key")
        else
            key_fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}' || echo "")
        fi

        if [[ -n "$key_fingerprint" ]] && \
           [[ "$loaded_fingerprints" == *"$key_fingerprint"* ]]; then
            debug "SSH key already loaded: $(basename "$key")"
            keys_skipped=$((keys_skipped + 1))
            continue
        fi

        if [[ -t 0 ]] && [[ -t 1 ]]; then
            if ssh-add "$key" 2>/dev/null; then
                keys_loaded=$((keys_loaded + 1))
            else
                debug "Failed to add SSH key: $(basename "$key") (may require passphrase)"
            fi
        else
            if ssh-add "$key" 2>/dev/null; then
                keys_loaded=$((keys_loaded + 1))
            else
                debug "Skipping SSH key that requires passphrase: $(basename "$key")"
            fi
        fi
    done

    [[ $keys_loaded -gt 0 ]] && debug "Loaded $keys_loaded SSH key(s) into agent"
    [[ $keys_skipped -gt 0 ]] && debug "Skipped $keys_skipped already-loaded SSH key(s)"
}

# ensure_ssh_directory: Ensure .ssh directory exists with correct permissions
# Usage: ensure_ssh_directory <ssh_dir>
ensure_ssh_directory() {
    local ssh_dir="$1"

    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
    fi
    run chmod 700 "$ssh_dir"
}

# import_keys_from_archive: Import SSH keys from a tar.gz archive
# Usage: import_keys_from_archive <archive_path> <ssh_dir>
import_keys_from_archive() {
    local archive_path="$1"
    local ssh_dir="$2"

    log "Importing SSH keys from archive: $archive_path"

    if [[ $FORCE -eq 1 ]] || [[ ! -f "$ssh_dir/id_ed25519" ]]; then
        if extract_ssh_keys_from_archive "$archive_path" "$ssh_dir"; then
            success "SSH keys imported from archive: $archive_path"
            return 0
        else
            error "Failed to extract SSH keys from archive: $archive_path"
            error "Please verify the archive format and permissions"
            return 1
        fi
    else
        debug "SSH keys already exist, skipping import (use --force to overwrite)"
        return 0
    fi
}

# import_keys_from_directory: Copy SSH keys from a source directory
# Usage: import_keys_from_directory <source_dir> <ssh_dir> <description>
import_keys_from_directory() {
    local source_dir="$1"
    local ssh_dir="$2"
    local description="$3"

    log "Importing SSH keys from $description: $source_dir"

    local keys_imported=0
    for keyfile in "$source_dir"/id_*; do
        [[ -f "$keyfile" ]] || continue

        local basename
        basename="$(basename "$keyfile")"
        local target="$ssh_dir/$basename"

        if [[ ! -f "$target" ]] || [[ $FORCE -eq 1 ]]; then
            if run cp "$keyfile" "$target"; then
                if [[ "$basename" != *.pub ]]; then
                    run chmod 600 "$target"
                    keys_imported=$((keys_imported + 1))
                else
                    run chmod 644 "$target"
                fi
            else
                warn "Failed to copy key: $basename"
            fi
        fi
    done

    if [[ $keys_imported -gt 0 ]]; then
        success "SSH keys imported from $description"
    else
        debug "SSH keys already present, skipping import"
    fi
    return 0
}

# import_keys_from_windows_home: Import keys from Windows user home directory
# Usage: import_keys_from_windows_home <win_user> <ssh_dir>
import_keys_from_windows_home() {
    local win_user="$1"
    local ssh_dir="$2"

    # By convention, keys are in C:\Users\{WIN_USER}\keys.tar.gz
    local keys_archive="/mnt/c/Users/${win_user}/keys.tar.gz"

    if [[ -f "$keys_archive" ]]; then
        import_keys_from_archive "$keys_archive" "$ssh_dir"
        return
    fi

    # Fallback: Check Windows .ssh directory
    local win_ssh_dir="/mnt/c/Users/$win_user/.ssh"
    if [[ -d "$win_ssh_dir" ]]; then
        import_keys_from_directory "$win_ssh_dir" "$ssh_dir" "Windows"
        return 0
    fi

    return 1
}

# generate_new_ssh_key: Generate a new Ed25519 SSH key if none exist
# Usage: generate_new_ssh_key <ssh_dir> <email>
generate_new_ssh_key() {
    local ssh_dir="$1"
    local email="$2"

    if ! has_ssh_keys "$ssh_dir"; then
        warn "No SSH keys found. Generating new key..."
        run ssh-keygen -t ed25519 -C "$email" -f "$ssh_dir/id_ed25519" -N ""
        success "New SSH key generated"

        echo ""
        log "Add this public key to GitHub:"
        cat "$ssh_dir/id_ed25519.pub"
        echo ""
    else
        debug "SSH keys already present"
    fi
}

# import_ssh_keys: Orchestrate SSH key import (priority order)
import_ssh_keys() {
    local ssh_dir="${HOME}/.ssh"

    ensure_ssh_directory "$ssh_dir"

    if has_ssh_keys "$ssh_dir" && [[ $FORCE -eq 0 ]]; then
        debug "SSH keys already present (from bootstrap), skipping import"
        return 0
    fi

    # Priority 1: explicit --keys-path
    if [[ -n "$KEYS_PATH" ]] && [[ -f "$KEYS_PATH" ]]; then
        import_keys_from_archive "$KEYS_PATH" "$ssh_dir"
        return $?
    fi

    # Priority 2: Windows user home directory
    local win_user="${WIN_USER:-}"
    if [[ -z "$win_user" ]]; then
        win_user="$(detect_windows_user 2>/dev/null || echo "")"
    fi

    if [[ -z "$win_user" ]]; then
        debug "Windows username not detected, skipping Windows key import"
    elif import_keys_from_windows_home "$win_user" "$ssh_dir"; then
        return 0
    fi

    # Priority 3: generate new key
    generate_new_ssh_key "$ssh_dir" "$GIT_EMAIL"
}

# ==============================================================================
# SSH AGENT CONFIGURATION
# ==============================================================================

# configure_ssh_agent: Setup ssh-agent persistence in shell RC files
configure_ssh_agent() {
    log "Configuring ssh-agent..."

    local zshrc="${HOME}/.zshrc"
    local bashrc="${HOME}/.bashrc"

    # Track all temp files created in this function so they are removed on any
    # exit path (normal return, error, or signal).
    local _ssh_agent_tmp_files=()
    _ssh_agent_cleanup() { rm -f "${_ssh_agent_tmp_files[@]}" 2>/dev/null || true; }
    trap '_ssh_agent_cleanup' RETURN ERR

    local ssh_agent_config
    ssh_agent_config=$(cat << 'SSH_CONFIG_EOF'
# --- Wiz SSH Agent Configuration ---
# Start ssh-agent if not running
if [ -z "${SSH_AUTH_SOCK:-}" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    export SSH_AUTH_SOCK SSH_AGENT_PID

    # Get list of already-loaded key fingerprints
    loaded_fingerprints=$(ssh-add -l 2>/dev/null | awk '{print $2}' || echo "")

    # Load all private keys that aren't already loaded
    for key in "${HOME}/.ssh/"*; do
        [[ -f "$key" ]] || continue
        [[ "$key" == *.pub ]] && continue
        [[ "$key" == *known_hosts* ]] && continue
        [[ "$key" == *config* ]] && continue

        if command -v ssh-keygen >/dev/null 2>&1; then
            if declare -f get_cached_ssh_fingerprint >/dev/null 2>&1; then
                key_fingerprint=$(get_cached_ssh_fingerprint "$key")
            else
                key_fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}' || echo "")
            fi
            if [[ -n "$key_fingerprint" ]] && \
               [[ "$loaded_fingerprints" == *"$key_fingerprint"* ]]; then
                continue
            fi
        fi

        ssh-add "$key" 2>/dev/null || true
    done
fi
# --- End Wiz SSH Agent Configuration ---
SSH_CONFIG_EOF
)

    # Add to .bashrc - prepend so agent loads early
    if [[ -f "$bashrc" ]]; then
        if grep -q "Wiz SSH Agent" "$bashrc" 2>/dev/null; then
            sed_inplace \
                '/# --- Wiz SSH Agent Configuration ---/,/# --- End Wiz SSH Agent Configuration ---/d' \
                "$bashrc"
        fi
        local tmp_bashrc
        tmp_bashrc=$(mktemp)
        _ssh_agent_tmp_files+=("$tmp_bashrc")
        { echo "$ssh_agent_config"; cat "$bashrc"; } > "$tmp_bashrc" && \
            mv "$tmp_bashrc" "$bashrc"
        debug "SSH agent config added to .bashrc"
    fi

    # Add to .zshrc - insert after plugins= line if present, else prepend
    if [[ -f "$zshrc" ]]; then
        if grep -q "Wiz SSH Agent" "$zshrc" 2>/dev/null; then
            sed_inplace \
                '/# --- Wiz SSH Agent Configuration ---/,/# --- End Wiz SSH Agent Configuration ---/d' \
                "$zshrc"
        fi

        local inserted=0
        if grep -q "^plugins=" "$zshrc" 2>/dev/null; then
            local plugins_line
            plugins_line=$(grep -n "^plugins=" "$zshrc" | head -1 | cut -d: -f1)
            if [[ -n "$plugins_line" ]]; then
                local tmp_insert tmp_zshrc
                if tmp_insert=$(mktemp) && tmp_zshrc=$(mktemp); then
                    _ssh_agent_tmp_files+=("$tmp_insert" "$tmp_zshrc")
                    echo "$ssh_agent_config" > "$tmp_insert"
                    awk -v line="$plugins_line" -v tmpfile="$tmp_insert" '
                        NR == line { print; while ((getline < tmpfile) > 0) print; close(tmpfile); next }
                        { print }
                    ' "$zshrc" > "$tmp_zshrc" && mv "$tmp_zshrc" "$zshrc"
                    rm -f "$tmp_insert"
                    inserted=1
                fi
            fi
        fi

        if [[ $inserted -eq 0 ]]; then
            local tmp_zshrc_fallback
            tmp_zshrc_fallback=$(mktemp)
            _ssh_agent_tmp_files+=("$tmp_zshrc_fallback")
            { echo "$ssh_agent_config"; cat "$zshrc"; } > "$tmp_zshrc_fallback" && \
                mv "$tmp_zshrc_fallback" "$zshrc"
        fi
        debug "SSH agent config added to .zshrc"
    fi

    # Load SSH keys into current session
    load_ssh_keys_to_agent

    success "SSH agent configured"
}
