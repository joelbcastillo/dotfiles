#!/bin/bash
# Create macOS launcher .apps for separate Claude Desktop profiles.
#
# Each wrapper has its own bundle ID (distinct Dock/Launchpad identity) and
# exec's the real Claude binary with a dedicated --user-data-dir, so each
# profile keeps its own account login, connectors, and Projects.
# Idempotent: re-running rebuilds the wrappers in ~/Applications.
#
# Usage: ./make-claude-profiles.sh
set -euo pipefail

CLAUDE_BIN="/Applications/Claude.app/Contents/MacOS/Claude"
CLAUDE_ICNS="/Applications/Claude.app/Contents/Resources/electron.icns"
[ -x "$CLAUDE_BIN" ] || { echo "Claude Desktop not found at /Applications/Claude.app" >&2; exit 1; }

ICONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../icons" && pwd)"

# name | profile dir (under ~/Library/Application Support) | bundle id | custom icns (optional)
PROFILES=(
  "Claude JBCTech Main|Claude-JBCTech-Main|com.jbctech.claude.main|claude-jbctech-main.icns"
  "Claude JBCTech Code|Claude-JBCTech-Code|com.jbctech.claude.code|claude-jbctech-code.icns"
  "Claude Joshua Project|Claude-JoshuaProject|com.jbctech.claude.jp|claude-joshuaproject.icns"
)

mkdir -p "$HOME/Applications"
for entry in "${PROFILES[@]}"; do
  IFS='|' read -r NAME PROFILE BID ICNS <<< "$entry"
  APP="$HOME/Applications/$NAME.app"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>$BID</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>launcher</string>
  <key>CFBundleIconFile</key><string>icon.icns</string>
</dict></plist>
PLIST
  cat > "$APP/Contents/MacOS/launcher" <<LAUNCH
#!/bin/bash
# If this profile is already running, focus it instead of spawning a
# doomed second instance (Electron single-instance lock exits silently).
PID=\$(pgrep -f -- "--user-data-dir=.*$PROFILE\$" | head -1)
if [ -n "\$PID" ]; then
  exec osascript -e "tell application \\"System Events\\" to set frontmost of (first process whose unix id is \$PID) to true"
fi
# open -n via LaunchServices: proper activation context (exec'ing the raw
# binary from a foreign bundle leaves windows unable to become key/clickable)
exec open -n -a "Claude" --args --user-data-dir="\$HOME/Library/Application Support/$PROFILE"
LAUNCH
  chmod +x "$APP/Contents/MacOS/launcher"
  if [ -n "${ICNS:-}" ] && [ -f "$ICONS_DIR/$ICNS" ]; then
    cp "$ICONS_DIR/$ICNS" "$APP/Contents/Resources/icon.icns"
  else
    cp "$CLAUDE_ICNS" "$APP/Contents/Resources/icon.icns"
  fi
  codesign --force -s - "$APP" 2>/dev/null || true
  echo "created: $APP"
done

LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
for entry in "${PROFILES[@]}"; do
  IFS='|' read -r NAME _ _ <<< "$entry"
  "$LSREG" -f "$HOME/Applications/$NAME.app" 2>/dev/null || true
done
echo "done — launchers registered; pin from ~/Applications or Spotlight"
