#!/bin/bash

# Script to create a clean dotfiles-template repository
# This exports your current dotfiles without any secret history

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Dotfiles Template Repository Creator${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Configuration
CURRENT_DIR="$(pwd)"
TEMPLATE_DIR="${HOME}/dotfiles-template"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${YELLOW}This script will:${NC}"
echo "  1. Create a fresh git repository at: ${TEMPLATE_DIR}"
echo "  2. Copy all non-sensitive files from your current dotfiles"
echo "  3. Exclude all personal configuration files"
echo "  4. Create a clean commit history"
echo
echo -e "${RED}WARNING: This will NOT modify your current dotfiles.${NC}"
echo

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Clean up existing template directory if it exists
if [ -d "$TEMPLATE_DIR" ]; then
    echo -e "${YELLOW}Template directory already exists. Removing...${NC}"
    rm -rf "$TEMPLATE_DIR"
fi

# Create template directory
echo -e "${GREEN}Creating template directory...${NC}"
mkdir -p "$TEMPLATE_DIR"

# Copy files using git export (excludes .git directory)
echo -e "${GREEN}Copying files (excluding .git)...${NC}"
git archive HEAD | tar -x -C "$TEMPLATE_DIR"

# Initialize new git repository
echo -e "${GREEN}Initializing new git repository...${NC}"
cd "$TEMPLATE_DIR"
git init
git add -A

# Remove any accidentally included personal files
echo -e "${YELLOW}Removing personal files from template...${NC}"

# Remove personal config files
rm -f config.json 2>/dev/null || true
rm -f tools/claude/config.json 2>/dev/null || true
rm -f tools/cursor-agent/config.json 2>/dev/null || true
rm -f tools/raycast/config.json 2>/dev/null || true
rm -f tools/1password/secret-paths.json 2>/dev/null || true
rm -f .dotbot/configs/ssh-*.yaml 2>/dev/null || true
rm -rf .dotfiles-private 2>/dev/null || true

# Stage changes after removals
git add -A

# Create initial commit
echo -e "${GREEN}Creating initial commit...${NC}"
git commit -m "Initial commit: Clean dotfiles template

This is a template repository for macOS development environment setup.

Features:
- Modular configuration system with dotbot
- Private file management support
- Multiple installation profiles (minimal, default, full)
- 1Password integration for secrets
- AI tools configuration (Claude, Cursor)
- Shell setup (Oh My Zsh, Starship)
- Development tools and languages

See README.md and QUICKSTART.md for setup instructions.

🤖 Generated template from personal dotfiles"

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Template repository created!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}Location:${NC} $TEMPLATE_DIR"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the template directory"
echo "  2. Create a new GitHub repository called 'dotfiles-template'"
echo "  3. Push the template:"
echo
echo -e "${BLUE}     cd $TEMPLATE_DIR${NC}"
echo -e "${BLUE}     git remote add origin git@github.com:yourusername/dotfiles-template.git${NC}"
echo -e "${BLUE}     git branch -M main${NC}"
echo -e "${BLUE}     git push -u origin main${NC}"
echo
echo "  4. Mark the GitHub repository as a template in Settings"
echo
echo -e "${GREEN}Your original dotfiles remain at: $CURRENT_DIR${NC}"
