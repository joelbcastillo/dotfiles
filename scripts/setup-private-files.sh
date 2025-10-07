#!/bin/bash

# Simple script to pull in private files from dotfiles-private repository
# Usage: PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./scripts/setup-private-files.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIVATE_REPO_URL="${PRIVATE_REPO_URL:-}"
PRIVATE_DIR="${HOME}/.dotfiles-private"
SSH_CONFIGS="${SSH_CONFIGS:-both}"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to setup private repository
setup_private_files() {
    if [ -z "$PRIVATE_REPO_URL" ]; then
        print_message "${YELLOW}" "No private repository URL provided."
        print_message "${BLUE}" "Usage: PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./scripts/setup-private-files.sh"
        return 1
    fi
    
    print_message "${BLUE}" "🔒 Setting up private files from: $PRIVATE_REPO_URL"
    
    # Clone or update private repository
    if [ -d "$PRIVATE_DIR" ]; then
        print_message "${GREEN}" "Private repository exists, updating..."
        cd "$PRIVATE_DIR"
        git pull origin main
    else
        print_message "${GREEN}" "Cloning private repository..."
        git clone "$PRIVATE_REPO_URL" "$PRIVATE_DIR"
    fi
    
    # Link private git configs
    print_message "${GREEN}" "🔗 Linking private git configurations..."
    
    # Link all git configs from private repository
    if [ -d "$PRIVATE_DIR/git" ]; then
        for gitconfig in "$PRIVATE_DIR/git"/gitconfig.*; do
            if [ -f "$gitconfig" ]; then
                local config_name=$(basename "$gitconfig")
                ln -sf "$gitconfig" "$DOTFILES_DIR/tools/git/$config_name"
                print_message "${GREEN}" "✅ Linked $config_name"
            fi
        done
    else
        print_message "${YELLOW}" "⚠️  No git configs found in private repository"
    fi
    
    # Link private aliases
    if [ -f "$PRIVATE_DIR/aliases/company-aliases.zsh" ]; then
        ln -sf "$PRIVATE_DIR/aliases/company-aliases.zsh" "$DOTFILES_DIR/shells/zsh/zsh.before/company-aliases.zsh"
        print_message "${GREEN}" "✅ Linked company aliases"
    else
        print_message "${YELLOW}" "⚠️  Company aliases not found in private repository"
    fi
    
    # Link private VS Code settings
    if [ -f "$PRIVATE_DIR/vscode/settings.json" ]; then
        ln -sf "$PRIVATE_DIR/vscode/settings.json" "$DOTFILES_DIR/apps/vscode/settings.json"
        print_message "${GREEN}" "✅ Linked private VS Code settings"
    else
        print_message "${YELLOW}" "⚠️  Private VS Code settings not found in private repository"
    fi
    
    # Link private Cursor settings
    if [ -f "$PRIVATE_DIR/cursor/settings.json" ]; then
        ln -sf "$PRIVATE_DIR/cursor/settings.json" "$DOTFILES_DIR/apps/cursor/settings.json"
        print_message "${GREEN}" "✅ Linked private Cursor settings"
    else
        print_message "${YELLOW}" "⚠️  Private Cursor settings not found in private repository"
    fi
    
    # Setup SSH configs based on SSH_CONFIGS parameter
    print_message "${BLUE}" "🔐 Setting up SSH configurations..."
    
    # Find all available SSH configs in private repo
    local available_configs=()
    for config_file in "$PRIVATE_DIR/dotbot"/ssh-*.yaml; do
        if [ -f "$config_file" ]; then
            local config_name=$(basename "$config_file" .yaml | sed 's/ssh-//')
            available_configs+=("$config_name")
        fi
    done
    
    # Show available configs
    if [ ${#available_configs[@]} -gt 0 ]; then
        print_message "${BLUE}" "Available SSH configs: ${available_configs[*]}"
    else
        print_message "${YELLOW}" "⚠️  No SSH configs found in private repository"
        return
    fi
    
    case "$SSH_CONFIGS" in
        "all")
            # Link all available SSH configs
            for config_name in "${available_configs[@]}"; do
                local config_file="$PRIVATE_DIR/dotbot/ssh-$config_name.yaml"
                if [ -f "$config_file" ]; then
                    ln -sf "$config_file" "$DOTFILES_DIR/.dotbot/configs/ssh-$config_name.yaml"
                    print_message "${GREEN}" "✅ Linked ssh-$config_name.yaml"
                fi
            done
            ;;
        *)
            # Check if the specified config exists
            local config_file="$PRIVATE_DIR/dotbot/ssh-$SSH_CONFIGS.yaml"
            if [ -f "$config_file" ]; then
                ln -sf "$config_file" "$DOTFILES_DIR/.dotbot/configs/ssh-$SSH_CONFIGS.yaml"
                print_message "${GREEN}" "✅ Linked ssh-$SSH_CONFIGS.yaml"
            else
                print_message "${YELLOW}" "⚠️  SSH config '$SSH_CONFIGS' not found"
                print_message "${YELLOW}" "Available configs: ${available_configs[*]}, or use 'all' for all configs"
            fi
            ;;
    esac

    print_message "${GREEN}" "🎉 Private files setup complete!"
    print_message "${YELLOW}" "📋 Next steps:"
    print_message "${YELLOW}" "1. Review the linked files"
    print_message "${YELLOW}" "2. Run: ./install"
    print_message "${YELLOW}" "3. Source your shell: source ~/.zshrc"
}

# Main function
main() {
    print_message "${BLUE}" "🚀 Setting up private files..."
    setup_private_files
}

# Run main function
main "$@"
