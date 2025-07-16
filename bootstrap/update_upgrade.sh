# -----------------------------------------------------------------------------
# Script Name: update_upgrade.sh
#
# Description:
#   This script updates the package lists for upgrades and installs the latest
#   versions of all packages currently installed on the system using apt.
#
# Usage:
#   Run this script with appropriate permissions:
#     ./update_upgrade.sh
#
# Notes:
#   - Requires sudo privileges to execute package management commands.
#   - The script will exit immediately if any command exits with a non-zero status.
#
# -----------------------------------------------------------------------------
#!/bin/bash
# Update and upgrade package lists
sudo apt update && sudo apt upgrade -y
