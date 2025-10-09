#!/bin/bash

# Install script for touchid-for-sudo
# Requires sudo privileges to modify /etc/pam.d/sudo

# Check if running as root, if not re-exec with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges to modify /etc/pam.d/sudo"
    echo "Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

echo "Installing Touch ID for sudo..."
mkdir -p "${HOME}/.touchid-for-sudo"
cp /etc/pam.d/sudo "${HOME}/.touchid-for-sudo/sudo.backup"

# Create modified sudo pam file
awk 'NR==2 {print "auth       sufficient     pam_tid.so"} 1' /etc/pam.d/sudo > /tmp/sudo.tmp

# Move to final location
mv /tmp/sudo.tmp /etc/pam.d/sudo

echo "✅ Finished installing Touch ID for sudo"
echo "To reset to the original state, run the uninstall script"
echo "Backup saved at: ~/.touchid-for-sudo/sudo.backup"
