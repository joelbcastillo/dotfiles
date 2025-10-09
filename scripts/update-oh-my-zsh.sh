#!/usr/bin/env bash

# Update Oh-My-Zsh safely
# Handles git conflicts and preserves custom configurations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${1}${2}${NC}"
}

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [ ! -d "$OMZ_DIR" ]; then
    print_message "$RED" "❌ Oh-My-Zsh not found at $OMZ_DIR"
    exit 1
fi

print_message "$BLUE" "🔄 Updating Oh-My-Zsh..."
echo ""

cd "$OMZ_DIR"

# Check if it's a git repository
if [ ! -d ".git" ]; then
    print_message "$RED" "❌ Oh-My-Zsh directory is not a git repository"
    print_message "$YELLOW" "Reinstall with: ~/.dotfiles/scripts/install-oh-my-zsh.sh"
    exit 1
fi

# Save current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
print_message "$BLUE" "Current branch: $CURRENT_BRANCH"

# Fetch latest changes
print_message "$BLUE" "Fetching latest changes..."
if ! git fetch origin; then
    print_message "$RED" "❌ Failed to fetch updates"
    exit 1
fi

# Check for local changes
if ! git diff-index --quiet HEAD --; then
    print_message "$YELLOW" "⚠️  Local changes detected in Oh-My-Zsh"
    print_message "$YELLOW" "Stashing changes..."
    git stash push -m "oh-my-zsh-update-$(date +%Y%m%d-%H%M%S)"
    STASHED=true
else
    STASHED=false
fi

# Update to latest
print_message "$BLUE" "Pulling latest changes..."
if git pull --rebase origin master; then
    print_message "$GREEN" "✅ Oh-My-Zsh updated successfully"

    # Restore stashed changes if any
    if [ "$STASHED" = true ]; then
        print_message "$YELLOW" "Applying stashed changes..."
        if git stash pop; then
            print_message "$GREEN" "✅ Stashed changes applied"
        else
            print_message "$YELLOW" "⚠️  Conflict applying stashed changes"
            print_message "$YELLOW" "Resolve conflicts and run: git stash drop"
        fi
    fi
else
    print_message "$RED" "❌ Failed to update Oh-My-Zsh"
    if [ "$STASHED" = true ]; then
        print_message "$YELLOW" "Your changes are stashed. Restore with: git stash pop"
    fi
    exit 1
fi

# Update plugins (submodules if any)
if [ -f ".gitmodules" ]; then
    print_message "$BLUE" "Updating plugins..."
    git submodule update --init --recursive
fi

# Show current version
CURRENT_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
print_message "$GREEN" "Current version: $CURRENT_VERSION"

echo ""
print_message "$GREEN" "🎉 Oh-My-Zsh update complete!"
print_message "$YELLOW" "Restart your shell to apply changes: exec zsh"
