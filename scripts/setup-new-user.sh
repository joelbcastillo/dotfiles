#!/bin/bash

# Setup script for new dotfiles users
# This script helps new users configure their personal settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_message "${BLUE}" "🚀 Setting up dotfiles for new user..."

# Get user information
read -p "Enter your full name: " FULL_NAME
read -p "Enter your email address: " EMAIL_ADDRESS
read -p "Enter your company domain (e.g., company.com): " COMPANY_DOMAIN

# Update git configuration files
print_message "${GREEN}" "📝 Updating git configuration..."

# Update user git config
cat > tools/git/gitconfig.user << EOF
[user]
    name = $FULL_NAME
    email = $EMAIL_ADDRESS
    # SSH public key for commit signing
    # Fetch from 1Password: Run scripts/fetch-ssh-keys.sh
    # Or manually place your public key at ~/.ssh/github.pub
    signingkey = ~/.ssh/github.pub

[gpg]
    format = ssh

[commit]
    gpgsign = true

[core]
    editor = vim
    excludesfile = ~/.gitignore_global

[init]
    defaultBranch = main

[push]
    default = simple

[pull]
    rebase = false

[color]
    ui = auto
