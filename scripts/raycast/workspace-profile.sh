#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Switch Workspace Profile
# @raycast.mode silent
# @raycast.packageName Workspace

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.argument1 { "type": "text", "placeholder": "Profile name (or 'list')" }

HAMMERSPOON_PORT=17421
BASE_URL="http://localhost:${HAMMERSPOON_PORT}"

PROFILE="$1"

if [ -z "$PROFILE" ] || [ "$PROFILE" = "list" ]; then
  PROFILES=$(curl -s "${BASE_URL}/profiles" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Error: Hammerspoon not responding on port ${HAMMERSPOON_PORT}"
    exit 1
  fi
  echo "$PROFILES" | python3 -c "import sys,json; [print(p) for p in json.load(sys.stdin)['profiles']]"
  exit 0
fi

RESULT=$(curl -s -X POST "${BASE_URL}/profiles/${PROFILE}/activate" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Error: Hammerspoon not responding"
  exit 1
fi

STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$STATUS" = "activated" ]; then
  echo "Activated profile: ${PROFILE}"
else
  ERROR=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error','Unknown error'))" 2>/dev/null)
  echo "Error: ${ERROR}"
  exit 1
fi
