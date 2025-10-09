#!/bin/bash

# Setup group-based Homebrew permissions for shared administration
# This allows multiple users to manage a shared Homebrew installation

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
GROUP_NAME="${1:-homebrewadmin}"
GROUP_ID="${2:-2000}"
HOMEBREW_PREFIX="${3:-$(brew --prefix 2>/dev/null || echo "/opt/homebrew")}"

print_message "${BLUE}" "🍺 Setting up group-based Homebrew permissions"
print_message "${BLUE}" "Group: $GROUP_NAME (GID: $GROUP_ID)"
print_message "${BLUE}" "Homebrew: $HOMEBREW_PREFIX"
echo ""

# Check if Homebrew exists
if [ ! -d "$HOMEBREW_PREFIX" ]; then
    print_message "${RED}" "❌ Homebrew not found at $HOMEBREW_PREFIX"
    print_message "${YELLOW}" "Please install Homebrew first or specify the correct path:"
    print_message "${YELLOW}" "  $0 <group_name> <group_id> <homebrew_path>"
    exit 1
fi

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    print_message "${RED}" "❌ This script must be run with sudo"
    print_message "${YELLOW}" "Usage: sudo $0 [group_name] [group_id] [homebrew_path]"
    print_message "${YELLOW}" "Example: sudo $0 homebrewadmin 2000 /opt/homebrew"
    exit 1
fi

# Create group if it doesn't exist
if dscl . -read /Groups/$GROUP_NAME &>/dev/null; then
    print_message "${YELLOW}" "⚠️  Group $GROUP_NAME already exists"
else
    print_message "${GREEN}" "Creating group $GROUP_NAME..."
    dscl . -create /Groups/$GROUP_NAME
    dscl . -create /Groups/$GROUP_NAME PrimaryGroupID $GROUP_ID
    dscl . -create /Groups/$GROUP_NAME RealName "Homebrew Administrators"
    print_message "${GREEN}" "✅ Group created"
fi

# Prompt for users to add
print_message "${BLUE}" "Enter usernames to add to $GROUP_NAME (one per line, empty line to finish):"
USERS=()
while true; do
    read -p "Username: " username
    if [ -z "$username" ]; then
        break
    fi

    # Verify user exists
    if id "$username" &>/dev/null; then
        USERS+=("$username")
        print_message "${GREEN}" "✅ Added $username to list"
    else
        print_message "${RED}" "❌ User $username does not exist, skipping"
    fi
done

# Add users to group
if [ ${#USERS[@]} -eq 0 ]; then
    print_message "${YELLOW}" "⚠️  No users specified. You can add them later with:"
    print_message "${YELLOW}" "  sudo dseditgroup -o edit -a <username> -t user $GROUP_NAME"
else
    for user in "${USERS[@]}"; do
        dseditgroup -o edit -a "$user" -t user "$GROUP_NAME"
        print_message "${GREEN}" "✅ Added $user to $GROUP_NAME"
    done
fi

# Set group ownership on Homebrew directories
print_message "${BLUE}" "Setting group ownership on Homebrew directories..."

# Key directories to change
DIRECTORIES=(
    "$HOMEBREW_PREFIX"
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/etc"
    "$HOMEBREW_PREFIX/include"
    "$HOMEBREW_PREFIX/lib"
    "$HOMEBREW_PREFIX/sbin"
    "$HOMEBREW_PREFIX/share"
    "$HOMEBREW_PREFIX/var"
    "$HOMEBREW_PREFIX/opt"
    "$HOMEBREW_PREFIX/Cellar"
    "$HOMEBREW_PREFIX/Caskroom"
    "$HOMEBREW_PREFIX/Frameworks"
)

for dir in "${DIRECTORIES[@]}"; do
    if [ -d "$dir" ]; then
        chgrp -R "$GROUP_NAME" "$dir" 2>/dev/null || true
        chmod -R g+w "$dir" 2>/dev/null || true
        print_message "${GREEN}" "✅ Updated $dir"
    fi
done

# Set proper permissions
print_message "${BLUE}" "Setting permissions..."
chmod -R g+w "$HOMEBREW_PREFIX"
chmod g+s "$HOMEBREW_PREFIX"  # Set SGID bit so new files inherit group

print_message "${GREEN}" "✅ Permissions updated"

# Create Homebrew configuration for the group
HOMEBREW_CONFIG="$HOMEBREW_PREFIX/etc/homebrew.env"
cat > "$HOMEBREW_CONFIG" <<EOF
# Homebrew Group Configuration
# This file is sourced by group members to ensure proper permissions

# Ensure new files have group write permissions
umask 0002

# Set Homebrew to use group-writable directories
export HOMEBREW_PREFIX="$HOMEBREW_PREFIX"
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"

# Prevent Homebrew from changing permissions
export HOMEBREW_NO_ENV_HINTS=1
EOF

chmod 644 "$HOMEBREW_CONFIG"
chgrp "$GROUP_NAME" "$HOMEBREW_CONFIG"

print_message "${GREEN}" "✅ Created Homebrew configuration at $HOMEBREW_CONFIG"

# Create instructions file
INSTRUCTIONS_FILE="$HOMEBREW_PREFIX/GROUP_SETUP_INFO.txt"
cat > "$INSTRUCTIONS_FILE" <<EOF
Homebrew Group-Based Setup
===========================

Group: $GROUP_NAME (GID: $GROUP_ID)
Created: $(date)

Members can install and manage Homebrew packages.

Current Members:
$(dscl . -read /Groups/$GROUP_NAME GroupMembership 2>/dev/null | sed 's/GroupMembership: /  - /' || echo "  None")

To Add More Users:
  sudo dseditgroup -o edit -a <username> -t user $GROUP_NAME

To Remove Users:
  sudo dseditgroup -o edit -d <username> -t user $GROUP_NAME

User Setup:
  Members should add this to their ~/.zshrc or ~/.zshenv:

  # Set umask for Homebrew group permissions
  umask 0002

  # Source Homebrew group configuration
  [ -f "$HOMEBREW_PREFIX/etc/homebrew.env" ] && source "$HOMEBREW_PREFIX/etc/homebrew.env"

Troubleshooting:
  If permission errors occur:
    sudo $0 $GROUP_NAME $GROUP_ID $HOMEBREW_PREFIX
EOF

chmod 644 "$INSTRUCTIONS_FILE"
chgrp "$GROUP_NAME" "$INSTRUCTIONS_FILE"

print_message "${GREEN}" "✅ Created instructions at $INSTRUCTIONS_FILE"

echo ""
print_message "${GREEN}" "🎉 Group-based Homebrew setup complete!"
echo ""
print_message "${BLUE}" "📋 Next Steps for Group Members:"
print_message "${BLUE}" "1. Log out and log back in (or run: newgrp $GROUP_NAME)"
print_message "${BLUE}" "2. Add to your ~/.zshrc or ~/.zshenv:"
echo ""
echo "  # Homebrew group configuration"
echo "  umask 0002"
echo "  [ -f \"$HOMEBREW_PREFIX/etc/homebrew.env\" ] && source \"$HOMEBREW_PREFIX/etc/homebrew.env\""
echo ""
print_message "${BLUE}" "3. Test with: brew install hello"
echo ""
print_message "${YELLOW}" "⚠️  Cask Note: Casks still install to /Applications (requires sudo)"
print_message "${YELLOW}" "   Consider using --appdir=~/Applications for user-local casks"
