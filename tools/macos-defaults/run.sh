#!/usr/bin/env bash

# macOS Defaults Configuration Runner
# Detects macOS version and runs appropriate defaults script

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "⏭  Skipping macOS defaults — not on macOS"
  exit 0
fi

# Detect macOS version
MACOS_VERSION=$(sw_vers -productVersion | cut -d '.' -f 1)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Configuring macOS defaults...${NC}"
echo -e "${BLUE}Detected macOS version: $MACOS_VERSION${NC}"

# Check if version is supported
case $MACOS_VERSION in
  26)
    echo -e "${GREEN}Running defaults for macOS Sequoia (26.x)${NC}"
    MACOS_NAME="Sequoia"
    ;;
  15)
    echo -e "${GREEN}Running defaults for macOS Sonoma (15.x)${NC}"
    MACOS_NAME="Sonoma"
    ;;
  14)
    echo -e "${GREEN}Running defaults for macOS Ventura (14.x)${NC}"
    MACOS_NAME="Ventura"
    ;;
  *)
    echo -e "${YELLOW}Warning: macOS version $MACOS_VERSION is not explicitly supported.${NC}"
    echo -e "${YELLOW}Attempting to run common defaults anyway...${NC}"
    MACOS_NAME="Unknown"
    ;;
esac

# Check if version-specific script exists
VERSION_SCRIPT="$SCRIPT_DIR/versions/macos-$MACOS_VERSION.sh"
if [[ -f "$VERSION_SCRIPT" ]]; then
  echo -e "${BLUE}Found version-specific script, running: $VERSION_SCRIPT${NC}"
  chmod +x "$VERSION_SCRIPT"
  "$VERSION_SCRIPT"
else
  # Run common defaults that work across all versions
  echo -e "${BLUE}Running common defaults script...${NC}"
  if [[ -f "$SCRIPT_DIR/macos-common.sh" ]]; then
    chmod +x "$SCRIPT_DIR/macos-common.sh"
    "$SCRIPT_DIR/macos-common.sh"
  else
    echo -e "${RED}Error: Could not find macos-common.sh${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✓ macOS defaults configured successfully!${NC}"
echo -e "${YELLOW}Note: Some changes require a logout/restart to take effect.${NC}"
