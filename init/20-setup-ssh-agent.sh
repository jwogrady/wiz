#!/bin/bash
# Set up SSH agent auto-load and permissions
set -e
SSH_BLOCK_START="# >>> SSH agent auto-load >>>"
SSH_SNIPPET=$(
	cat <<'EOSSH'
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
EOSSH
)
if ! grep -qF "$SSH_BLOCK_START" "$HOME/.bashrc"; then
	echo "$SSH_SNIPPET" >>"$HOME/.bashrc"
	echo "Added SSH agent auto-load block to ~/.bashrc"
fi
if [ -d "$HOME/.ssh" ]; then
	chmod 700 "$HOME/.ssh"
	for key in "$HOME/.ssh/"id_*; do
		[[ "$key" == *.pub ]] && continue
		[ -f "$key" ] && chmod 600 "$key"
	done
fi
