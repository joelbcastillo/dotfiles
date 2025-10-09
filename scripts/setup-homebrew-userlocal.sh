#!/bin/bash

# Install Homebrew in user's home directory (~/.homebrew)
# This allows each user to have their own Homebrew installation
# without requiring sudo or conflicting with other users

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

# Configuration
HOMEBREW_PREFIX="$HOME/.homebrew"
APPLICATIONS_DIR="$HOME/Applications"

print_message "${BLUE}" "🍺 Setting up user-local Homebrew"
print_message "${BLUE}" "Installation directory: $HOMEBREW_PREFIX"
print_message "${BLUE}" "Applications directory: $APPLICATIONS_DIR"
echo ""

# Check if already installed
if [ -d "$HOMEBREW_PREFIX" ]; then
    print_message "${YELLOW}" "⚠️  Homebrew already exists at $HOMEBREW_PREFIX"
    read -p "Reinstall? This will delete the existing installation. [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "${BLUE}" "Skipping installation"
        exit 0
    fi
    print_message "${YELLOW}" "Removing existing installation..."
    rm -rf "$HOMEBREW_PREFIX"
fi

# Create directories
print_message "${GREEN}" "Creating directories..."
mkdir -p "$HOMEBREW_PREFIX"
mkdir -p "$APPLICATIONS_DIR"

# Download and install Homebrew
print_message "${GREEN}" "Downloading Homebrew..."
curl -L https://github.com/Homebrew/brew/tarball/master | \
    tar xz --strip-components 1 -C "$HOMEBREW_PREFIX"

# Create configuration file
print_message "${GREEN}" "Creating Homebrew configuration..."
cat > "$HOMEBREW_PREFIX/homebrew.env" <<EOF
# User-Local Homebrew Configuration
# This file configures Homebrew for user-local installation

# Homebrew directories
export HOMEBREW_PREFIX="$HOMEBREW_PREFIX"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"

# User-local applications directory for casks
export HOMEBREW_CASK_OPTS="--appdir=$APPLICATIONS_DIR"

# Prevent Homebrew from automatically updating (users can update manually)
export HOMEBREW_NO_AUTO_UPDATE=0

# Disable analytics (privacy)
export HOMEBREW_NO_ANALYTICS=1

# Disable environment hints
export HOMEBREW_NO_ENV_HINTS=1

# Add Homebrew to PATH
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:\$PATH"

# Set MANPATH
export MANPATH="$HOMEBREW_PREFIX/share/man:\$MANPATH"

# Set INFOPATH
export INFOPATH="$HOMEBREW_PREFIX/share/info:\$INFOPATH"
EOF

# Source the configuration
source "$HOMEBREW_PREFIX/homebrew.env"

# Verify installation
print_message "${GREEN}" "Verifying installation..."
if ! "$HOMEBREW_PREFIX/bin/brew" --version &>/dev/null; then
    print_message "${RED}" "❌ Homebrew installation failed"
    exit 1
fi

BREW_VERSION=$("$HOMEBREW_PREFIX/bin/brew" --version | head -n1)
print_message "${GREEN}" "✅ Homebrew installed: $BREW_VERSION"

# Update Homebrew
print_message "${GREEN}" "Updating Homebrew..."
"$HOMEBREW_PREFIX/bin/brew" update

# Install recommended packages for development
print_message "${BLUE}" "Installing recommended development tools? [Y/n] "
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_message "${GREEN}" "Installing development tools..."
    "$HOMEBREW_PREFIX/bin/brew" install git curl wget
fi

# Create shell configuration snippet
SHELL_CONFIG="$HOME/.homebrew-userlocal.zsh"
cat > "$SHELL_CONFIG" <<'EOF'
# User-Local Homebrew Configuration
# Source this file from your ~/.zshrc or ~/.zshenv

# Source Homebrew environment
if [ -f "$HOME/.homebrew/homebrew.env" ]; then
    source "$HOME/.homebrew/homebrew.env"
fi
EOF

print_message "${GREEN}" "✅ Created shell configuration at $SHELL_CONFIG"

# Create README
README_FILE="$HOMEBREW_PREFIX/README.txt"
cat > "$README_FILE" <<EOF
User-Local Homebrew Installation
=================================

Installed: $(date)
Location: $HOMEBREW_PREFIX
Applications: $APPLICATIONS_DIR

This is a user-local Homebrew installation. You do NOT need sudo to install packages.

Usage:
  brew install <package>      # Install formula
  brew install --cask <app>   # Install application to ~/Applications
  brew uninstall <package>    # Uninstall package
  brew update                 # Update Homebrew
  brew upgrade                # Upgrade all packages
  brew doctor                 # Check for problems

Shell Configuration:
  Add this to your ~/.zshrc or ~/.zshenv:

    # User-local Homebrew
    [ -f "\$HOME/.homebrew/homebrew.env" ] && source "\$HOME/.homebrew/homebrew.env"

  Or source the pre-made configuration:

    source ~/.homebrew-userlocal.zsh

Cask Applications:
  Applications install to: $APPLICATIONS_DIR
  To run them, you can:
    1. Open from Finder (navigate to ~/Applications)
    2. Add to Dock
    3. Use Spotlight (may require: mdimport ~/Applications)
    4. Launch from terminal: open ~/Applications/AppName.app

Common Commands:
  brew list                   # List installed packages
  brew search <term>          # Search for packages
  brew info <package>         # Show package info
  brew cleanup                # Remove old versions

Updating:
  brew update                 # Update Homebrew itself
  brew outdated               # Check for outdated packages
  brew upgrade                # Upgrade all packages
  brew upgrade <package>      # Upgrade specific package

Troubleshooting:
  brew doctor                 # Diagnose problems
  brew config                 # Show configuration

Uninstalling:
  To remove this Homebrew installation:
    rm -rf $HOMEBREW_PREFIX
    rm -f $SHELL_CONFIG

Documentation:
  https://docs.brew.sh/
EOF

chmod 644 "$README_FILE"

echo ""
print_message "${GREEN}" "🎉 User-local Homebrew installation complete!"
echo ""
print_message "${BLUE}" "📋 Next Steps:"
print_message "${BLUE}" "1. Add to your shell configuration (~/.zshrc or ~/.zshenv):"
echo ""
echo "  # User-local Homebrew"
echo "  [ -f \"\$HOME/.homebrew/homebrew.env\" ] && source \"\$HOME/.homebrew/homebrew.env\""
echo ""
print_message "${BLUE}" "2. Restart your shell or run:"
echo ""
echo "  source $HOMEBREW_PREFIX/homebrew.env"
echo ""
print_message "${BLUE}" "3. Test with:"
echo ""
echo "  brew install hello"
echo "  brew install --cask alfred  # Installs to ~/Applications"
echo ""
print_message "${BLUE}" "4. Read the README:"
echo ""
echo "  cat $README_FILE"
echo ""
print_message "${YELLOW}" "⚠️  Important Notes:"
print_message "${YELLOW}" "  • Casks install to ~/Applications (not /Applications)"
print_message "${YELLOW}" "  • Some casks may not work if they require system-level installation"
print_message "${YELLOW}" "  • You may need to allow apps in System Settings > Privacy & Security"
print_message "${YELLOW}" "  • Spotlight indexing: mdimport ~/Applications"
