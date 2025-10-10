#!/bin/bash

# Script to fetch SSH keys from 1Password and set up proper symlinks
# Supports multiple 1Password accounts configured in accounts.json
# Usage: ./fetch-ssh-keys.sh [config_file]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_SSH_DIR="$HOME/.ssh"
ACCOUNTS_CONFIG="${1:-$DOTFILES_DIR/tools/1password/accounts.json}"

# Fallback to old single-key behavior if called with 4 arguments
if [ $# -eq 4 ]; then
    KEY_NAME="$1"
    KEY_FILENAME="$2"
    VAULT_NAME="$3"
    ACCOUNT="$4"
    LEGACY_MODE=true
else
    LEGACY_MODE=false
fi

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
    current_account=$(op account get --format json | jq -r '.id' 2>/dev/null || echo "")
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
    # Legacy mode - old single-key behavior
    if [ "$LEGACY_MODE" = true ]; then
        echo "Setting up SSH key from 1Password (legacy mode)..."
        SSH_KEYS_DIR="$DOTFILES_DIR/tools/ssh/keys/personal"
        mkdir -p "$SSH_KEYS_DIR"
        setup_ssh_key "$KEY_NAME" "$KEY_FILENAME"
        echo "✓ SSH key setup complete"
        return 0
    fi

    # New configuration-based approach
    echo "Setting up SSH keys from 1Password..."

    # Check if accounts configuration exists
    if [ ! -f "$ACCOUNTS_CONFIG" ]; then
        echo "Error: 1Password accounts configuration not found: $ACCOUNTS_CONFIG" >&2
        echo "Please create this file from the template:" >&2
        echo "  cp $DOTFILES_DIR/tools/1password/accounts.json.template $ACCOUNTS_CONFIG" >&2
        echo "" >&2
        echo "Or use legacy mode:" >&2
        echo "  $0 \"KEY_NAME\" \"filename\" \"vault\" \"account.1password.com\"" >&2
        return 1
    fi

    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        return 1
    fi

    # Get active accounts
    local active_accounts
    active_accounts=$(jq -r '.active_accounts[]' "$ACCOUNTS_CONFIG" 2>/dev/null || echo "")

    if [ -z "$active_accounts" ]; then
        echo "Error: No active accounts found in configuration" >&2
        return 1
    fi

    local total_keys=0

    # Process each active account
    for account_key in $active_accounts; do
        echo ""
        echo "Processing account: $account_key"

        # Get account details
        local account_uuid
        account_uuid=$(jq -r ".accounts.$account_key.account_uuid" "$ACCOUNTS_CONFIG")

        # Get SSH keys for this account
        local ssh_keys_json
        ssh_keys_json=$(jq -c ".accounts.$account_key.ssh_keys[]" "$ACCOUNTS_CONFIG" 2>/dev/null || echo "")

        if [ -z "$ssh_keys_json" ]; then
            echo "  No SSH keys configured for $account_key"
            continue
        fi

        # Create directory for this account's keys
        local account_keys_dir="$DOTFILES_DIR/tools/ssh/keys/$account_key"
        mkdir -p "$account_keys_dir"
        SSH_KEYS_DIR="$account_keys_dir"

        # Process each SSH key
        echo "$ssh_keys_json" | while read -r key_config; do
            local key_name=$(echo "$key_config" | jq -r '.name')
            local key_filename=$(echo "$key_config" | jq -r '.filename')
            local key_vault=$(echo "$key_config" | jq -r '.vault')

            echo "  Setting up: $key_name → ~/.ssh/$key_filename"

            # Set global variables for setup_ssh_key function
            KEY_NAME="$key_name"
            VAULT_NAME="$key_vault"
            ACCOUNT="$account_uuid"

            if setup_ssh_key "$key_name" "$key_filename"; then
                ((total_keys++))
            fi
        done
    done

    echo ""
    echo "✅ SSH keys setup complete!"
    echo "   Total keys configured: $total_keys"
    echo "   Keys stored in: $DOTFILES_DIR/tools/ssh/keys/"
    echo "   Symlinks created in: $HOME_SSH_DIR"
    echo ""
    echo "You can now use git signing with your SSH keys."
}

# Run main function
main "$@"
