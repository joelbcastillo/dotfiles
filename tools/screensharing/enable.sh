#!/usr/bin/env bash
# Enable macOS Screen Sharing (built-in VNC, backed by ARD/screensharingd).
# Reachable only over the tailnet — macOS Application Firewall blocks 5900
# from non-tailnet interfaces when stealth mode is on.

set -euo pipefail

log() { printf '[screensharing] %s\n' "$*" >&2; }

[[ "$(uname -s)" == "Darwin" ]] || { log "macOS only."; exit 1; }

# Apple's supported knob is to load the screensharing LaunchDaemon.
# `kickstart -k` is a no-op if already running; if the daemon is disabled,
# `enable` flips it on and `kickstart` starts it.
sudo launchctl enable system/com.apple.screensharing 2>/dev/null || true
sudo launchctl kickstart -k system/com.apple.screensharing >/dev/null 2>&1 || true

# Confirm it's listening.
if sudo launchctl print system/com.apple.screensharing 2>/dev/null \
    | grep -q 'state = running'; then
  log "screensharing LaunchDaemon running."
else
  log "screensharing LaunchDaemon did NOT start; check Privacy & Security > Sharing."
  exit 2
fi

# VNC port 5900 — listening is enough; ACL is handled by the tailnet + firewall.
if sudo lsof -iTCP:5900 -sTCP:LISTEN >/dev/null 2>&1; then
  log "VNC (5900) listening."
else
  log "VNC (5900) not listening; Screen Sharing enabled but not reachable yet."
fi

log "done."
