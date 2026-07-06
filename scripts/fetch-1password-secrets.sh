#!/bin/bash

# Script to fetch secrets from 1Password
# Supports multiple 1Password accounts configured in accounts.json
# Usage: ./fetch-1password-secrets.sh [secret_name]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Check for secret-paths.json in both main dotfiles and private dotfiles
SECRETS_CONFIG="$DOTFILES_DIR/tools/1password/secret-paths.json"
if [ ! -f "$SECRETS_CONFIG" ] && [ -f "$HOME/.dotfiles-private/secrets/1password/secret-paths.json" ]; then
    SECRETS_CONFIG="$HOME/.dotfiles-private/secrets/1password/secret-paths.json"
fi
# Check for accounts.json - prioritize private dotfiles, fall back to main dotfiles
if [ -f "$HOME/.dotfiles-private/tools/accounts.json" ]; then
    ACCOUNTS_CONFIG="$HOME/.dotfiles-private/tools/accounts.json"
elif [ -f "$DOTFILES_DIR/tools/1password/accounts.json" ]; then
    ACCOUNTS_CONFIG="$DOTFILES_DIR/tools/1password/accounts.json"
else
    ACCOUNTS_CONFIG=""
fi

# Function to get account UUID from accounts.json
# Checks both private and main dotfiles accounts.json
get_account_uuid() {
    local account_key="$1"
    local config_file=""

    # Try private dotfiles first
    if [ -f "$HOME/.dotfiles-private/tools/accounts.json" ]; then
        config_file="$HOME/.dotfiles-private/tools/accounts.json"
    # Fall back to main dotfiles
    elif [ -f "$DOTFILES_DIR/tools/1password/accounts.json" ]; then
        config_file="$DOTFILES_DIR/tools/1password/accounts.json"
    fi

    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Get account_uuid first (preferred for switching, especially for same-domain accounts)
    local account_uuid
    account_uuid=$(jq -r ".accounts.$account_key.account_uuid // empty" "$config_file" 2>/dev/null)

    # If account_uuid is available, use it directly (works for same-domain accounts)
    if [ -n "$account_uuid" ] && [ "$account_uuid" != "null" ]; then
        echo "$account_uuid"
        return 0
    fi

    # Fall back to domain if account_uuid not available
    local domain
    domain=$(jq -r ".accounts.$account_key.domain // empty" "$config_file" 2>/dev/null)
    if [ -n "$domain" ] && [ "$domain" != "null" ]; then
        echo "$domain"
        return 0
    fi

    return 1
}

# Function to get default account identifier
get_default_account_identifier() {
    local config_file=""

    if [ -f "$HOME/.dotfiles-private/tools/accounts.json" ]; then
        config_file="$HOME/.dotfiles-private/tools/accounts.json"
    elif [ -f "$DOTFILES_DIR/tools/1password/accounts.json" ]; then
        config_file="$DOTFILES_DIR/tools/1password/accounts.json"
    fi

    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local default_account
    default_account=$(jq -r '.default_account // empty' "$config_file" 2>/dev/null)

    if [ -z "$default_account" ] || [ "$default_account" = "null" ]; then
        default_account=$(jq -r '.active_accounts[0] // empty' "$config_file" 2>/dev/null)
    fi

    if [ -z "$default_account" ] || [ "$default_account" = "null" ]; then
        return 1
    fi

    get_account_uuid "$default_account"
}

# Function to switch to the correct 1Password account
# Intelligently handles account switching, including accounts with same domain
switch_account() {
    local account_identifier="$1"

    if [ -z "$account_identifier" ]; then
        return 0  # No account specified, use default
    fi

    # Check if 1Password CLI is available
    if ! command -v op >/dev/null 2>&1; then
        return 1
    fi

    # Check if user is signed in
    if ! op account list >/dev/null 2>&1; then
        return 1
    fi

    # Account identifier can be: account_uuid, domain, or domain shorthand
    local target_identifier="$account_identifier"

    # Get current account info
    local current_account_info
    current_account_info=$(op account get --format json 2>/dev/null || echo "{}")
    local current_account_id
    current_account_id=$(echo "$current_account_info" | jq -r '.id // empty' || echo "")
    local current_account_domain
    current_account_domain=$(echo "$current_account_info" | jq -r '.domain // empty' || echo "")

    # Check if we're already on the correct account
    # Match by account UUID (most reliable, especially for same-domain accounts)
    if [ -n "$current_account_id" ] && [ "$current_account_id" = "$target_identifier" ]; then
        return 0  # Already on the correct account (matched by account UUID)
    fi

    # Match by domain (if identifier is a domain)
    if [ -n "$current_account_domain" ] && [ "$current_account_domain" = "$target_identifier" ]; then
        return 0  # Already on the correct account (matched by domain)
    fi

    # Match by domain shorthand (without .1password.com)
    local domain_part="${target_identifier%.1password.com}"
    if [ "$domain_part" != "$target_identifier" ] && [ "$current_account_domain" = "$domain_part" ]; then
        return 0  # Already on the correct account
    fi

    # We need to switch accounts
    # op signin --account accepts: account_uuid, domain, or domain shorthand
    local switch_output
    switch_output=$(op signin --account "$target_identifier" 2>&1)
    local switch_exit_code=$?

    # If that fails and identifier looks like a domain, try domain shorthand
    if [ $switch_exit_code -ne 0 ] && echo "$target_identifier" | grep -q "\.1password\.com"; then
        local domain_part="${target_identifier%.1password.com}"
        switch_output=$(op signin --account "$domain_part" 2>&1)
        switch_exit_code=$?
    fi

    if [ $switch_exit_code -eq 0 ]; then
        # Verify we actually switched to the right account
        local new_account_info
        new_account_info=$(op account get --format json 2>/dev/null || echo "{}")
        local new_account_id
        new_account_id=$(echo "$new_account_info" | jq -r '.id // empty' || echo "")
        local new_account_domain
        new_account_domain=$(echo "$new_account_info" | jq -r '.domain // empty' || echo "")

        # Verify account UUID matches (if identifier was a UUID)
        if [ -n "$new_account_id" ] && [ "$new_account_id" = "$target_identifier" ]; then
            return 0  # Successfully switched to correct account (matched by UUID)
        fi

        # Verify domain matches (if identifier was a domain)
        if [ -n "$new_account_domain" ] && [ "$new_account_domain" = "$target_identifier" ]; then
            return 0  # Successfully switched to correct account (matched by domain)
        fi

        # Domain shorthand match
        local domain_part="${target_identifier%.1password.com}"
        if [ "$domain_part" != "$target_identifier" ] && [ -n "$new_account_domain" ] && [ "$new_account_domain" = "$domain_part" ]; then
            return 0  # Successfully switched
        fi

        # If we got here, switch succeeded but verification is unclear - continue anyway
        return 0
    fi

    # If all switching attempts failed, return error with helpful message
    echo "Error: Could not switch to account '$target_identifier'" >&2
    if echo "$switch_output" | grep -q "multiple accounts"; then
        echo "Multiple accounts found. 1Password CLI requires manual selection." >&2
        echo "To switch to the correct account, run:" >&2
        echo "  op signin --account $target_identifier" >&2
    else
        echo "Details: $switch_output" >&2
        echo "Hint: Make sure you're signed in. Run 'op signin' first." >&2
    fi
    return 1
}

# Function to get secret from 1Password
get_secret() {
    local secret_name="$1"
    local item_name="$2"
    local field_name="$3"
    local vault_name="$4"
    local account_identifier="$5"

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

    # Switch to the correct account if specified
    if [ -n "$account_identifier" ]; then
        if ! switch_account "$account_identifier"; then
            echo "Error: Could not switch to account '$account_identifier'. Cannot fetch secret." >&2
            return 1
        fi
    fi

    # Fetch the secret
    local secret
    local op_error
    if [ -n "$vault_name" ]; then
        op_error=$(op item get "$item_name" --vault "$vault_name" --fields "$field_name" 2>&1)
        secret=$(echo "$op_error" | grep -v "^\[use" | grep -v "^Error:" || echo "")
    else
        op_error=$(op item get "$item_name" --fields "$field_name" 2>&1)
        secret=$(echo "$op_error" | grep -v "^\[use" | grep -v "^Error:" || echo "")
    fi

    # Check if the output is a reference that needs --reveal
    if echo "$op_error" | grep -q "^\[use 'op item get"; then
        # Try with --reveal flag
        if [ -n "$vault_name" ]; then
            secret=$(op item get "$item_name" --vault "$vault_name" --fields "$field_name" --reveal 2>/dev/null || echo "")
        else
            secret=$(op item get "$item_name" --fields "$field_name" --reveal 2>/dev/null || echo "")
        fi
    fi

    if [ -z "$secret" ]; then
        echo "Error: Could not fetch secret '$secret_name' from 1Password" >&2
        if [ -n "$account_identifier" ]; then
            echo "Hint: Make sure you're signed in to account '$account_identifier'. Run 'op signin --account $account_identifier'" >&2
        fi
        echo "Details: $op_error" >&2
        return 1
    fi

    echo "$secret"
}

# Function to get secret configuration from JSON
get_secret_config() {
    local secret_name="$1"

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        return 1
    fi

    # Dynamically find the secret in all sections
    local sections
    sections=$(jq -r 'keys[]' "$SECRETS_CONFIG" 2>/dev/null || echo "")

    if [ -z "$sections" ]; then
        echo "Error: Could not read secret-paths.json" >&2
        return 1
    fi

    # Try to find the secret in each section
    local config
    for section in $sections; do
        config=$(jq -r ".$section.$secret_name // empty" "$SECRETS_CONFIG" 2>/dev/null)
        if [ -n "$config" ] && [ "$config" != "null" ]; then
            echo "$config"
            return 0
        fi
    done

    echo "Error: Secret '$secret_name' not found in configuration" >&2
    return 1
}

# Main function
main() {
    local secret_name="$1"

    if [ -z "$secret_name" ]; then
        echo "Usage: $0 <secret_name>" >&2
        echo "Available secrets:" >&2

        if ! command -v jq >/dev/null 2>&1; then
            echo "  (jq required to list secrets)" >&2
            exit 1
        fi

        # Dynamically list all secrets from all sections
        local sections
        sections=$(jq -r 'keys[]' "$SECRETS_CONFIG" 2>/dev/null || echo "")
        for section in $sections; do
            jq -r ".$section | keys[]" "$SECRETS_CONFIG" 2>/dev/null | while read -r key; do
                echo "  $key" >&2
            done
        done
        exit 1
    fi

    # Get secret configuration
    local config
    config=$(get_secret_config "$secret_name")
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Parse configuration using jq for proper JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        exit 1
    fi

    local item_name
    # Support both item (name) and item_id (ID) - prefer item_id if available
    item_name=$(echo "$config" | jq -r 'if .item_id then .item_id else .item end // empty')
    local field_name
    field_name=$(echo "$config" | jq -r '.field // empty')
    local vault_name
    vault_name=$(echo "$config" | jq -r '.vault // empty')
    local account_key
    account_key=$(echo "$config" | jq -r '.account // empty')

    # Resolve account key to account identifier (UUID or domain)
    local account_identifier=""
    if [ -n "$account_key" ] && [ "$account_key" != "null" ]; then
        account_identifier=$(get_account_uuid "$account_key")
        if [ $? -ne 0 ] || [ -z "$account_identifier" ]; then
            echo "Warning: Could not resolve account '$account_key' from accounts.json. Using current account." >&2
            # Try using the account_key directly as identifier (might be a domain or UUID)
            account_identifier="$account_key"
        fi
    else
        account_identifier=$(get_default_account_identifier 2>/dev/null || true)
        if [ -z "$account_identifier" ]; then
            account_identifier=""
        else
            echo "Using default 1Password account for secret '$secret_name'" >&2
        fi
    fi

    # Get the secret
    get_secret "$secret_name" "$item_name" "$field_name" "$vault_name" "$account_identifier"
}

# Run main function with all arguments
main "$@"
