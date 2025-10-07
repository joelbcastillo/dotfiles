#!/bin/bash

# Script to resolve 1password:// references in config files
# Usage: ./resolve-1password-secrets.sh <config_file>

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FETCH_SCRIPT="$DOTFILES_DIR/scripts/fetch-1password-secrets.sh"

# Function to resolve 1password:// references
resolve_secrets() {
    local config_file="$1"
    local temp_file
    
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file '$config_file' not found" >&2
        return 1
    fi
    
    # Create temporary file
    temp_file=$(mktemp)
    
    # Process the file line by line
    while IFS= read -r line; do
        # Check if line contains 1password:// reference
        if [[ "$line" =~ 1password://([^\"\s]+) ]]; then
            local secret_name="${BASH_REMATCH[1]}"
            local secret_value
            
            # Fetch the secret from 1Password
            secret_value=$("$FETCH_SCRIPT" "$secret_name" 2>/dev/null)
            
            if [ $? -eq 0 ] && [ -n "$secret_value" ]; then
                # Replace the reference with the actual value
                echo "$line" | sed "s|1password://$secret_name|\"$secret_value\"|g"
            else
                echo "Warning: Could not fetch secret '$secret_name' from 1Password" >&2
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done < "$config_file" > "$temp_file"
    
    # Replace original file with resolved version
    mv "$temp_file" "$config_file"
    
    echo "Resolved 1password:// references in '$config_file'"
}

# Function to resolve secrets in a directory
resolve_secrets_in_dir() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo "Error: Directory '$dir' not found" >&2
        return 1
    fi
    
    # Find all JSON files in the directory
    find "$dir" -name "*.json" -type f | while read -r file; do
        echo "Processing: $file"
        resolve_secrets "$file"
    done
}

# Main function
main() {
    local target="$1"
    
    if [ -z "$target" ]; then
        echo "Usage: $0 <config_file_or_directory>" >&2
        exit 1
    fi
    
    if [ -f "$target" ]; then
        resolve_secrets "$target"
    elif [ -d "$target" ]; then
        resolve_secrets_in_dir "$target"
    else
        echo "Error: '$target' is not a file or directory" >&2
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
