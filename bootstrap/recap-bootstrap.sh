#!/bin/bash



echo
echo "=============================================="
echo " 🎉  Bootstrap Complete! Welcome, $USER!  🎉"
echo "=============================================="
echo
echo "Your environment is now set up and ready to use."
echo
echo "Here's what just happened (bootstrap phase):"
echo " - System packages were updated and essential tools installed (update_upgrade.sh, install_essentials.sh, install_tools.sh)"
echo " - Git was configured with your user details and a global ignore file (configure_git.sh)"
echo " - Your preferred shell environment was set up (setup_shell.sh, source_dotfiles.sh)"
echo " - Your original dotfiles were backed up for safety (backup_default_dots.sh)"
echo " - Dotfiles were restored or symlinked from your latest backup (source_dotfiles.sh)"
echo
echo "You can now start working productively!"
echo
echo "If you need to re-run any step, just execute the corresponding script in the bootstrap directory."
echo "For more details, check the README or your logs above."
echo
echo "Happy hacking, $USER! 🚀"
echo