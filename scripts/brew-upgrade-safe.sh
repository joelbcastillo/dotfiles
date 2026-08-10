#!/bin/bash

# Safe Brew upgrade
# Formula upgrades are required to succeed. Cask upgrades are best-effort:
# GUI casks routinely fail on unattended/headless runs (stale Caskroom
# directories left by an interrupted upgrade, uninstall steps that need an
# interactive sudo), and a single one of those should not fail the install.

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

FAILED_CASKS=()
STALE_CASKROOM=()
NEEDS_SUDO=()

print_message "$BLUE" "🍺 Upgrading formulae..."
brew upgrade --formula

print_message "$BLUE" "📦 Upgrading casks..."
OUTDATED_CASKS=$(brew outdated --cask --quiet 2>/dev/null || true)

if [ -z "$OUTDATED_CASKS" ]; then
    print_message "$GREEN" "✅ No outdated casks"
else
    while IFS= read -r cask; do
        [ -z "$cask" ] && continue
        print_message "$BLUE" "  Upgrading: $cask"

        if error_msg=$(brew upgrade --cask "$cask" 2>&1); then
            print_message "$GREEN" "  ✅ Upgraded"
            continue
        fi

        FAILED_CASKS+=("$cask")

        if echo "$error_msg" | grep -q "already an App at"; then
            STALE_CASKROOM+=("$cask")
            print_message "$YELLOW" "  ⚠️  Stale Caskroom entry"
        elif echo "$error_msg" | grep -q "a terminal is required to read the password"; then
            NEEDS_SUDO+=("$cask")
            print_message "$YELLOW" "  ⚠️  Needs an interactive sudo"
        else
            print_message "$YELLOW" "  ⚠️  Failed"
        fi
    done <<< "$OUTDATED_CASKS"
fi

if [ ${#FAILED_CASKS[@]} -gt 0 ]; then
    echo ""
    print_message "$YELLOW" "⚠️  ${#FAILED_CASKS[@]} cask(s) did not upgrade (not fatal):"

    for cask in "${STALE_CASKROOM[@]}"; do
        print_message "$YELLOW" "   $cask — stale Caskroom dir from an interrupted upgrade"
        print_message "$BLUE" "     brew uninstall --cask --force $cask && brew install --cask $cask"
    done

    for cask in "${NEEDS_SUDO[@]}"; do
        print_message "$YELLOW" "   $cask — uninstall step needs a TTY for sudo"
        print_message "$BLUE" "     run at the console: brew upgrade --cask $cask"
    done

    for cask in "${FAILED_CASKS[@]}"; do
        case " ${STALE_CASKROOM[*]} ${NEEDS_SUDO[*]} " in
            *" $cask "*) continue ;;
            *) ;;
        esac
        print_message "$YELLOW" "   $cask"
        print_message "$BLUE" "     brew upgrade --cask $cask"
    done
fi

echo ""
print_message "$GREEN" "✅ Brew upgrade complete!"
