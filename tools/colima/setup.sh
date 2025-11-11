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

# Ensure Docker socket symlink is correct
if [ -L /var/run/docker.sock ]; then
    CURRENT_LINK=$(readlink /var/run/docker.sock)
    EXPECTED_LINK="$HOME/.colima/default/docker.sock"

    if [ "$CURRENT_LINK" != "$EXPECTED_LINK" ]; then
        echo "Updating Docker socket symlink to point to Colima..."
        sudo rm /var/run/docker.sock
        sudo ln -s "$HOME/.colima/default/docker.sock" /var/run/docker.sock
    fi
else
    echo "Creating Docker socket symlink..."
    sudo ln -s "$HOME/.colima/default/docker.sock" /var/run/docker.sock
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
