#!/bin/bash

# Script to fetch SSH keys from 1Password and set up proper symlinks
# Usage: ./fetch-ssh-keys.sh [key_name] [key_filename] [vault_name] [account]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_KEYS_DIR="$DOTFILES_DIR/tools/ssh/keys/personal"
HOME_SSH_DIR="$HOME/.ssh"

# Parse arguments
KEY_NAME="${1:-SSH Key - Personal}"
KEY_FILENAME="${2:-github}"
VAULT_NAME="${3:-Personal}"
ACCOUNT="${4:-my.1password.com}"

# Function to get SSH key from 1Password
get_ssh_key() {
    local key_name="$1"
    local key_type="$2"  # "private" or "public"
    
    # Check if 1Password CLI is available
    if ! command -v op >/dev/null 2>&1; then
        echo "Error: 1Password CLI (op) is not installed or not in PATH" >&2
        return 1
    fi
    
    # Check if user is signed in
    if ! op account list >/dev/null 2>&1; then
        echo "Error: Not signed in to 1Password CLI. Run 'op signin' first" >&2
        return 1
    fi
    
    # Get vault and account from arguments
    local vault_name="$3"
    local account="$4"
    
    # Switch to the correct account if needed
    local current_account
    current_account=$(op account get --format json | jq -r '.domain' 2>/dev/null || echo "")
    if [ "$current_account" != "$account" ]; then
        echo "Switching to 1Password account: $account"
        if ! op signin --account "$account" >/dev/null 2>&1; then
            echo "Error: Could not switch to account $account. Please run 'op signin --account $account' first" >&2
            return 1
        fi
    fi
    
    # Fetch the SSH key
    local key_content
    if [ "$key_type" = "private" ]; then
        key_content=$(op item get "$key_name" --vault "$vault_name" --fields "private_key" 2>/dev/null || echo "")
    else
        key_content=$(op item get "$key_name" --vault "$vault_name" --fields "public_key" 2>/dev/null || echo "")
    fi
    
    if [ -z "$key_content" ]; then
        echo "Error: Could not fetch $key_type key for '$key_name' from 1Password" >&2
        return 1
    fi
    
    echo "$key_content"
}

# Function to setup SSH key files
setup_ssh_key() {
    local key_name="$1"
    local key_filename="$2"
    
    echo "Setting up $key_name SSH key..."
    
    # Get private key
    local private_key
    private_key=$(get_ssh_key "$key_name" "private" "$VAULT_NAME" "$ACCOUNT")
    if [ $? -ne 0 ]; then
        echo "Failed to fetch private key for $key_name"
        return 1
    fi
    
    # Get public key
    local public_key
    public_key=$(get_ssh_key "$key_name" "public" "$VAULT_NAME" "$ACCOUNT")
    if [ $? -ne 0 ]; then
        echo "Failed to fetch public key for $key_name"
        return 1
    fi
    
    # Create private key file
    local private_key_file="$SSH_KEYS_DIR/$key_filename"
    echo "$private_key" > "$private_key_file"
    chmod 600 "$private_key_file"
    
    # Create public key file
    local public_key_file="$SSH_KEYS_DIR/$key_filename.pub"
    echo "$public_key" > "$public_key_file"
    chmod 644 "$public_key_file"
    
    # Create symlinks in ~/.ssh/
    local home_private_link="$HOME_SSH_DIR/$key_filename"
    local home_public_link="$HOME_SSH_DIR/$key_filename.pub"
    
    # Remove existing links if they exist
    [ -L "$home_private_link" ] && rm "$home_private_link"
    [ -L "$home_public_link" ] && rm "$home_public_link"
    
    # Create new symlinks
    ln -s "$private_key_file" "$home_private_link"
    ln -s "$public_key_file" "$home_public_link"
    
    echo "✓ $key_name SSH key setup complete"
}

# Main function
main() {
    echo "Setting up SSH keys from 1Password..."
    
    # Ensure SSH keys directory exists
    mkdir -p "$SSH_KEYS_DIR"
    
    # Setup GitHub SSH key
    setup_ssh_key "SSH Key - Personal" "github"
    
    # Setup other SSH keys if needed
    # setup_ssh_key "PCDL SSH Key" "pcdl"
    
    echo ""
    echo "SSH keys setup complete!"
    echo "Keys are stored in: $SSH_KEYS_DIR"
    echo "Symlinks created in: $HOME_SSH_DIR"
    echo ""
    echo "You can now use git signing with your SSH keys."
}

# Run main function
main "$@"
