#!/bin/bash

# Script to fetch secrets from 1Password
# Usage: ./fetch-1password-secrets.sh [secret_name]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_CONFIG="$DOTFILES_DIR/tools/1password/secret-paths.json"

# Function to get secret from 1Password
get_secret() {
    local secret_name="$1"
    local item_name="$2"
    local field_name="$3"
    local vault_name="$4"
    
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
    
    # Fetch the secret
    local secret
    if [ -n "$vault_name" ]; then
        secret=$(op item get "$item_name" --vault "$vault_name" --fields "$field_name" 2>/dev/null || echo "")
    else
        secret=$(op item get "$item_name" --fields "$field_name" 2>/dev/null || echo "")
    fi
    
    if [ -z "$secret" ]; then
        echo "Error: Could not fetch secret '$secret_name' from 1Password" >&2
        return 1
    fi
    
    echo "$secret"
}

# Function to get secret configuration from JSON
get_secret_config() {
    local secret_name="$1"
    local jq_query=".$secret_name"
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        return 1
    fi
    
    # Try to find the secret in different sections
    local config
    for section in "ai_tools" "development"; do
        config=$(jq -r ".$section.$secret_name" "$SECRETS_CONFIG" 2>/dev/null)
        if [ "$config" != "null" ] && [ -n "$config" ]; then
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
        jq -r '.ai_tools | keys[]' "$SECRETS_CONFIG" 2>/dev/null | while read -r key; do
            echo "  $key" >&2
        done
        jq -r '.development | keys[]' "$SECRETS_CONFIG" 2>/dev/null | while read -r key; do
            echo "  $key" >&2
        done
        exit 1
    fi
    
    # Get secret configuration
    local config
    config=$(get_secret_config "$secret_name")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Parse configuration (simple parsing since we can't use jq in the script)
    local item_name=$(echo "$config" | grep -o '"item":"[^"]*"' | cut -d'"' -f4)
    local field_name=$(echo "$config" | grep -o '"field":"[^"]*"' | cut -d'"' -f4)
    local vault_name=$(echo "$config" | grep -o '"vault":"[^"]*"' | cut -d'"' -f4)
    
    # Get the secret
    get_secret "$secret_name" "$item_name" "$field_name" "$vault_name"
}

# Run main function with all arguments
main "$@"
