#!/bin/bash

# Define SSH agent auto-load block
SSH_BLOCK_START="# >>> SSH agent auto-load >>>"
SSH_SNIPPET=$(cat <<'EOF'
# >>> SSH agent auto-load >>>
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval "$(ssh-agent -s)" > /dev/null
    if [ -d "$HOME/.ssh" ]; then
        for key in "$HOME/.ssh/"id_*; do
            [[ "$key" == *.pub ]] && continue
            [ -f "$key" ] && ssh-add "$key" 2>/dev/null
        done
    fi
fi
# <<< SSH agent auto-load <<<
EOF
)

# Add SSH agent block to ~/.bashrc if not already present
if ! grep -qF "$SSH_BLOCK_START" "$HOME/.bashrc"; then
    echo "$SSH_SNIPPET" >> "$HOME/.bashrc"
    echo "Added SSH agent auto-load block to ~/.bashrc"
fi

# Ensure correct permissions for .ssh directory and private keys
if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh"
    for key in "$HOME/.ssh/"id_*; do
        [[ "$key" == *.pub ]] && continue
        [ -f "$key" ] && chmod 600 "$key"
    done
fi

# Load SSH keys for this session and collect loaded key names
LOADED_KEYS=()
if [ -d "$HOME/.ssh" ]; then
    for key in "$HOME/.ssh/"id_*; do
        [[ "$key" == *.pub ]] && continue
        [ -f "$key" ] || continue
        # Only try to add valid private keys
        if ssh-keygen -y -f "$key" >/dev/null 2>&1; then
            if ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')"; then
                LOADED_KEYS+=("$(basename "$key")")
            else
                ssh-add "$key" 2>/dev/null && LOADED_KEYS+=("$(basename "$key")")
            fi
        fi
    done
fi

echo
echo "=============================================="
echo " 🎉  Bootstrap Complete! Welcome, $USER!  🎉"
echo "=============================================="
echo
echo "Your environment is now set up and ready to use."
echo
echo "Here's what just happened:"
echo " - System packages were updated and essential tools installed."
if [ ${#LOADED_KEYS[@]} -gt 0 ]; then
    echo " - SSH keys loaded into agent: ${LOADED_KEYS[*]}"
else
    echo " - No SSH keys loaded into agent."
fi
echo " - Git was configured with your user details and a global ignore file."
echo " - Your preferred shell environment was set up."
echo " - Your original dotfiles were backed up for safety."
echo " - Dotfiles were restored or symlinked from your latest backup."
echo
echo "You can now start working productively!"
echo
echo "If you need to re-run any step, just execute the corresponding script in the bootstrap directory."
echo "For more details, check the README or your logs above."
echo
echo "Happy hacking, $USER! 🚀"
echo