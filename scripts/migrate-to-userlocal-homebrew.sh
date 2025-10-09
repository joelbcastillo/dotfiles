#!/bin/bash

# Migrate from system-wide Homebrew to user-local Homebrew
# This script:
# 1. Exports your current package list
# 2. Installs user-local Homebrew
# 3. Reinstalls all packages
# 4. Optionally removes system Homebrew

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Detect current Homebrew
detect_system_brew() {
    if [ -x "/opt/homebrew/bin/brew" ]; then
        echo "/opt/homebrew/bin/brew"
    elif [ -x "/usr/local/bin/brew" ]; then
        echo "/usr/local/bin/brew"
    else
        echo ""
    fi
}

SYSTEM_BREW=$(detect_system_brew)
USER_BREW="$HOME/.homebrew/bin/brew"
BACKUP_DIR="$HOME/.homebrew-migration-$(date +%Y%m%d_%H%M%S)"

print_message "${BLUE}" "🍺 Migrating to User-Local Homebrew"
echo ""

# Check if system Homebrew exists
if [ -z "$SYSTEM_BREW" ]; then
    print_message "${RED}" "❌ No system-wide Homebrew installation found"
    print_message "${YELLOW}" "Nothing to migrate. Use setup-homebrew-userlocal.sh to install."
    exit 1
fi

print_message "${GREEN}" "Found system Homebrew: $SYSTEM_BREW"
BREW_VERSION=$("$SYSTEM_BREW" --version | head -n1)
print_message "${GREEN}" "Version: $BREW_VERSION"
echo ""

# Check if user-local already exists
if [ -d "$HOME/.homebrew" ]; then
    print_message "${YELLOW}" "⚠️  User-local Homebrew already exists at $HOME/.homebrew"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Create backup directory
print_message "${GREEN}" "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Export current package list
print_message "${GREEN}" "Exporting current package list..."
"$SYSTEM_BREW" bundle dump --file="$BACKUP_DIR/Brewfile" --force
print_message "${GREEN}" "✅ Saved to $BACKUP_DIR/Brewfile"

# List what will be installed
FORMULA_COUNT=$("$SYSTEM_BREW" list --formula | wc -l | tr -d ' ')
CASK_COUNT=$("$SYSTEM_BREW" list --cask | wc -l | tr -d ' ')
TAP_COUNT=$("$SYSTEM_BREW" tap | wc -l | tr -d ' ')

echo ""
print_message "${BLUE}" "📊 Current Installation:"
print_message "${BLUE}" "  Formulae: $FORMULA_COUNT"
print_message "${BLUE}" "  Casks: $CASK_COUNT"
print_message "${BLUE}" "  Taps: $TAP_COUNT"
echo ""

# Show Brewfile preview
print_message "${BLUE}" "Preview of Brewfile (first 20 lines):"
head -n 20 "$BACKUP_DIR/Brewfile"
echo ""

# Confirm migration
print_message "${YELLOW}" "⚠️  This will:"
print_message "${YELLOW}" "  1. Install Homebrew to ~/.homebrew"
print_message "${YELLOW}" "  2. Reinstall all packages to user-local Homebrew"
print_message "${YELLOW}" "  3. Install casks to ~/Applications (not /Applications)"
echo ""
read -p "Continue with migration? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_message "${BLUE}" "Migration cancelled. Backup saved at: $BACKUP_DIR"
    exit 0
fi

# Run user-local setup
print_message "${GREEN}" "Installing user-local Homebrew..."
if [ -f "$(dirname "$0")/setup-homebrew-userlocal.sh" ]; then
    bash "$(dirname "$0")/setup-homebrew-userlocal.sh"
else
    # Inline installation if script not found
    mkdir -p "$HOME/.homebrew"
    curl -L https://github.com/Homebrew/brew/tarball/master | \
        tar xz --strip-components 1 -C "$HOME/.homebrew"
fi

# Verify installation
if [ ! -x "$USER_BREW" ]; then
    print_message "${RED}" "❌ User-local Homebrew installation failed"
    exit 1
fi

# Source user-local Homebrew
export PATH="$HOME/.homebrew/bin:$HOME/.homebrew/sbin:$PATH"

# Install packages from Brewfile
print_message "${GREEN}" "Installing packages from Brewfile..."
print_message "${YELLOW}" "This may take a while..."
echo ""

if "$USER_BREW" bundle --file="$BACKUP_DIR/Brewfile"; then
    print_message "${GREEN}" "✅ All packages installed successfully"
else
    print_message "${YELLOW}" "⚠️  Some packages may have failed to install"
    print_message "${YELLOW}" "Check the output above for details"
fi

# Create comparison report
print_message "${GREEN}" "Creating comparison report..."
cat > "$BACKUP_DIR/MIGRATION_REPORT.txt" <<EOF
Homebrew Migration Report
=========================
Date: $(date)

System Homebrew:
  Location: $("$SYSTEM_BREW" --prefix)
  Version: $("$SYSTEM_BREW" --version | head -n1)
  Formulae: $FORMULA_COUNT
  Casks: $CASK_COUNT
  Taps: $TAP_COUNT

User-Local Homebrew:
  Location: $("$USER_BREW" --prefix)
  Version: $("$USER_BREW" --version | head -n1)
  Formulae: $("$USER_BREW" list --formula | wc -l | tr -d ' ')
  Casks: $("$USER_BREW" list --cask | wc -l | tr -d ' ')
  Taps: $("$USER_BREW" tap | wc -l | tr -d ' ')

Backup Location: $BACKUP_DIR

To verify casks are working:
  ls -la ~/Applications

To use user-local Homebrew:
  Add to ~/.zshrc or ~/.zshenv:
    [ -f "\$HOME/.homebrew/homebrew.env" ] && source "\$HOME/.homebrew/homebrew.env"

To remove system Homebrew (AFTER verifying everything works):
  sudo rm -rf $("$SYSTEM_BREW" --prefix)
  sudo rm -rf /Library/Caches/Homebrew

  WARNING: This requires sudo and is irreversible!
EOF

print_message "${GREEN}" "✅ Report saved to $BACKUP_DIR/MIGRATION_REPORT.txt"

echo ""
print_message "${GREEN}" "🎉 Migration complete!"
echo ""
print_message "${BLUE}" "📋 Next Steps:"
print_message "${BLUE}" "1. Add to your ~/.zshrc or ~/.zshenv:"
echo ""
echo "  # User-local Homebrew"
echo "  [ -f \"\$HOME/.homebrew/homebrew.env\" ] && source \"\$HOME/.homebrew/homebrew.env\""
echo ""
print_message "${BLUE}" "2. Restart your shell or run:"
echo ""
echo "  source ~/.homebrew/homebrew.env"
echo ""
print_message "${BLUE}" "3. Verify everything works:"
echo ""
echo "  brew --version"
echo "  brew doctor"
echo "  ls ~/Applications  # Check casks"
echo ""
print_message "${BLUE}" "4. Test your applications from ~/Applications"
echo ""
print_message "${YELLOW}" "⚠️  System Homebrew is still installed"
print_message "${YELLOW}" "After verifying everything works, you can remove it:"
echo ""
echo "  sudo rm -rf $("$SYSTEM_BREW" --prefix)"
echo ""
print_message "${YELLOW}" "Backup saved at: $BACKUP_DIR"
print_message "${YELLOW}" "Keep this backup until you've verified everything works!"
