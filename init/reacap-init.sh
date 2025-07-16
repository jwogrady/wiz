#!/bin/bash
# aweMe Initi Recap and Next Steps

set -e

# Recap Section
cat <<EOF

============================
  aweMe Initi Recap
============================

- Environment variables were collected and saved to .env (prompt_env.sh)
- SSH keys were extracted (extract_keys.sh)
- SSH agent auto-load was configured (setup_ssh_agent.sh)
- Dotfiles repository was cloned to .backup (clone_dotfiles.sh)
- Wiz repository was cloned to wiz_clone (clone_wiz.sh)

EOF

# Show backup location if exists (if created by init scripts)
MACHINE_NAME="$(hostname)"
LATEST_BACKUP=$(ls -td $HOME/.backup/$MACHINE_NAME/* 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    echo "Latest dotfiles backup: $LATEST_BACKUP"
fi

# Next Steps Section
cat <<EOF

============================
  Next Steps
============================

1. Review your .env file in $HOME/wiz/.env and update any values if needed.
2. Check your SSH keys in $HOME/.ssh and ensure permissions are correct.
3. Review and apply your dotfiles from .backup or your dotfiles repo.
4. Restart your shell or source your profile to apply changes.
5. Continue with any project-specific setup or run your main bootstrap script.

For more details, check the README or documentation in your wiz repo.

============================
EOF
