#!/bin/bash

# Safe Brew Bundle installer
# Attempts to install casks to ~/Applications if user-local Homebrew
# Warns instead of failing for casks that require global installation

set -e

BREWFILE="${1:-$HOME/Brewfile}"
BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || echo "")}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${1}${2}${NC}"
}

if [ ! -f "$BREWFILE" ]; then
    print_message "$RED" "❌ Brewfile not found: $BREWFILE"
    exit 1
fi

# Detect if user-local Homebrew
IS_USER_LOCAL=false
if [[ "$BREW_PREFIX" == "$HOME/.homebrew" ]]; then
    IS_USER_LOCAL=true
    print_message "$BLUE" "🍺 Detected user-local Homebrew"
    print_message "$BLUE" "   Casks will install to ~/Applications"
fi

# Parse Brewfile and categorize
FORMULAE=()
CASKS=()
TAPS=()
FAILED_CASKS=()
WARNINGS=()

while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    if [[ "$line" =~ ^tap[[:space:]]+ ]]; then
        TAPS+=("$line")
    elif [[ "$line" =~ ^brew[[:space:]]+ ]]; then
        FORMULAE+=("$line")
    elif [[ "$line" =~ ^cask[[:space:]]+ ]]; then
        CASKS+=("$line")
    fi
done < "$BREWFILE"

print_message "$BLUE" "📦 Installing packages from Brewfile..."
print_message "$BLUE" "   Taps: ${#TAPS[@]}"
print_message "$BLUE" "   Formulae: ${#FORMULAE[@]}"
print_message "$BLUE" "   Casks: ${#CASKS[@]}"
echo ""

# Install taps
if [ ${#TAPS[@]} -gt 0 ]; then
    print_message "$GREEN" "🔧 Installing taps..."
    for tap in "${TAPS[@]}"; do
        print_message "$BLUE" "  Installing: $tap"
        eval "brew $tap" || print_message "$YELLOW" "  ⚠️  Failed: $tap"
    done
fi

# Install formulae
if [ ${#FORMULAE[@]} -gt 0 ]; then
    print_message "$GREEN" "🍺 Installing formulae..."
    for formula in "${FORMULAE[@]}"; do
        print_message "$BLUE" "  Installing: $formula"
        eval "brew $formula" || print_message "$YELLOW" "  ⚠️  Failed: $formula"
    done
fi

# Install casks
if [ ${#CASKS[@]} -gt 0 ]; then
    print_message "$GREEN" "📦 Installing casks..."

    for cask in "${CASKS[@]}"; do
        cask_name=$(echo "$cask" | sed 's/cask[[:space:]]*"\([^"]*\)".*/\1/')
        print_message "$BLUE" "  Installing: $cask_name"

        if $IS_USER_LOCAL; then
            # Try to install to ~/Applications
            if brew install --cask "$cask_name" --appdir="$HOME/Applications" 2>/dev/null; then
                print_message "$GREEN" "  ✅ Installed to ~/Applications"
            else
                # Check if it requires global installation
                error_msg=$(brew install --cask "$cask_name" --appdir="$HOME/Applications" 2>&1 || true)

                if echo "$error_msg" | grep -q "requires.*system-wide"; then
                    FAILED_CASKS+=("$cask_name (requires system-wide installation)")
                    WARNINGS+=("$cask_name requires system-wide installation. Run: brew install --cask $cask_name")
                    print_message "$YELLOW" "  ⚠️  Skipped: requires system-wide installation"
                elif echo "$error_msg" | grep -q "already installed"; then
                    print_message "$BLUE" "  ℹ️  Already installed"
                else
                    FAILED_CASKS+=("$cask_name")
                    WARNINGS+=("$cask_name failed to install. Try manually: brew install --cask $cask_name")
                    print_message "$YELLOW" "  ⚠️  Failed: $cask_name"
                fi
            fi
        else
            # System-wide Homebrew - install normally
            if brew install --cask "$cask_name" 2>/dev/null; then
                print_message "$GREEN" "  ✅ Installed"
            elif brew list --cask "$cask_name" &>/dev/null; then
                print_message "$BLUE" "  ℹ️  Already installed"
            else
                FAILED_CASKS+=("$cask_name")
                WARNINGS+=("$cask_name failed to install. Try manually: brew install --cask $cask_name")
                print_message "$YELLOW" "  ⚠️  Failed: $cask_name"
            fi
        fi
    done
fi

echo ""
print_message "$GREEN" "✅ Brew bundle complete!"

# Show warnings if any
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    print_message "$YELLOW" "⚠️  Warnings (${#WARNINGS[@]}):"
    for warning in "${WARNINGS[@]}"; do
        print_message "$YELLOW" "  • $warning"
    done
    echo ""
    print_message "$YELLOW" "These casks were skipped but installation will continue."
    print_message "$YELLOW" "You can install them manually later if needed."
fi

# Exit successfully even if some casks failed
exit 0
