#!/usr/bin/env bash
# Colima setup script
# Sets up Colima as a lightweight alternative to Docker Desktop

set -e

echo "Setting up Colima..."

# Check if Colima is installed
if ! command -v colima &> /dev/null; then
    echo "Error: Colima is not installed. Please run 'brew bundle' in tools/homebrew first."
    exit 1
fi

# Check if Colima is already running
if colima status &> /dev/null; then
    echo "Colima is already running"
    colima status
else
    echo "Starting Colima with optimized settings..."
    # Start Colima with settings optimized for devcontainers and docker-compose
    # - 4 CPUs and 8GB RAM (adjust based on your needs)
    # - 60GB disk space
    # - vz VM type (Apple Virtualization Framework - faster on Apple Silicon)
    # - virtiofs for better file sharing performance
    colima start --cpu 4 --memory 8 --disk 60 --vm-type=vz --mount-type=virtiofs
fi

# Ensure Docker socket symlink is correct.
# This is best-effort on purpose: /var/run is cleared on every boot, so the
# symlink never survives a reboot, and recreating it needs sudo — which an
# unattended run (dotbot over SSH, no TTY) doesn't have. Docker itself works
# through the `colima` context without it, so a missing symlink must not fail
# the install. It only matters for tools that hardcode /var/run/docker.sock.
COLIMA_SOCK="$HOME/.colima/default/docker.sock"

if [ "$(readlink /var/run/docker.sock 2>/dev/null)" = "$COLIMA_SOCK" ]; then
    echo "✓ Docker socket symlink already correct"
elif sudo -n ln -sfn "$COLIMA_SOCK" /var/run/docker.sock 2>/dev/null; then
    echo "✓ Linked /var/run/docker.sock -> $COLIMA_SOCK"
else
    echo "⚠️  Skipping /var/run/docker.sock symlink — sudo unavailable or the link failed."
    echo "   Docker works via the 'colima' context regardless. To create it:"
    echo "     sudo ln -sfn \"$COLIMA_SOCK\" /var/run/docker.sock"
fi

# Set Docker context to Colima
docker context use colima 2>/dev/null || echo "Docker context already set to colima"

echo "✓ Colima setup complete!"
echo ""
echo "Usage:"
echo "  colima start    - Start Colima"
echo "  colima stop     - Stop Colima"
echo "  colima status   - Check Colima status"
echo "  colima restart  - Restart Colima"
echo ""
echo "To adjust resources, edit this script and run: colima delete && ./setup.sh"
