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

            # TODO: dead path — needs google_drive_username + google_drive_credential keys in secret-paths.json.template (only google_drive_credentials exists today)
            # Special handling for google_drive_credentials - combine username and credential
            if [ "$secret_name" = "google_drive_credentials" ]; then
                local username_value
                local credential_value

                # `|| x=""` is required: under `set -e` a failing command
                # substitution aborts the script, so the warn-and-continue
                # branches below would never run.
                username_value=$("$FETCH_SCRIPT" "google_drive_username" 2>/dev/null) || username_value=""
                credential_value=$("$FETCH_SCRIPT" "google_drive_credential" 2>/dev/null) || credential_value=""

                if [ -n "$username_value" ] && [ -n "$credential_value" ]; then
                    # Construct JSON object with username and credential
                    # Use jq for proper JSON construction if available, otherwise use sed
                    if command -v jq >/dev/null 2>&1; then
                        secret_value=$(jq -n --arg user "$username_value" --arg cred "$credential_value" '{username: $user, credential: $cred}' | jq -c .)
                    else
                        # Fallback: manual JSON construction with proper escaping
                        username_escaped=$(echo "$username_value" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n')
                        credential_escaped=$(echo "$credential_value" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n')
                        secret_value="{\"username\":\"$username_escaped\",\"credential\":\"$credential_escaped\"}"
                    fi
                    # Replace the reference with the JSON object (already a JSON string, so escape it for the outer JSON)
                    secret_escaped=$(echo "$secret_value" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
                    echo "$line" | sed "s|1password://$secret_name|\"$secret_escaped\"|g"
                else
                    echo "Warning: Could not fetch Google Drive credentials (username and/or credential) from 1Password" >&2
                    echo "$line"
                fi
            else
                # Fetch the secret from 1Password
                # See note above: `|| secret_value=""` keeps `set -e` from
                # aborting here so the warning branch can run.
                secret_value=$("$FETCH_SCRIPT" "$secret_name" 2>/dev/null) || secret_value=""

                if [ -n "$secret_value" ]; then
                    # Escape the value for JSON
                    secret_escaped=$(echo "$secret_value" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
                    # Replace the reference with the actual value
                    echo "$line" | sed "s|1password://$secret_name|\"$secret_escaped\"|g"
                else
                    echo "Warning: Could not fetch secret '$secret_name' from 1Password" >&2
                    echo "$line"
                fi
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
