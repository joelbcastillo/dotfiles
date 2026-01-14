#!/bin/bash
# Open URL in Microsoft Edge with a specific profile
# Usage: open-edge-profile.sh <profile-directory> <url>
#
# This script works around macOS's limitation where Edge ignores
# --profile-directory when already running. Using 'open -na' forces
# a new instance that respects the profile argument.

PROFILE="${1:-Profile 1}"
URL="$2"

if [ -z "$URL" ]; then
    echo "Usage: $0 <profile-directory> <url>"
    exit 1
fi

# Use -na to open new instance that respects --args
open -na 'Microsoft Edge' --args --profile-directory="$PROFILE" "$URL"
