#!/usr/bin/env bash
# Verify Tailscale on a headless macOS host and set the node hostname.
# We do NOT auto-install Tailscale here: the headless Mac is expected to
# already be signed in (a one-time interactive step). This script just
# confirms state and renames the node.
#
# Pass the desired hostname as $1. Defaults to `$HOSTNAME` if unset.

set -euo pipefail

log() { printf '[tailscale] %s\n' "$*" >&2; }

want_hostname="${1:-${HOSTNAME:-$(scutil --get LocalHostName 2>/dev/null || true)}}"
if [[ -z "$want_hostname" ]]; then
  log "could not determine target hostname (no arg, no \$HOSTNAME, empty LocalHostName)."
  exit 3
fi

if ! command -v tailscale >/dev/null 2>&1; then
  log "tailscale CLI not found."
  log "install with: brew install --cask tailscale   (or via the Mac App Store)"
  log "then run:    sudo tailscale up"
  exit 1
fi

# Require an authenticated, running daemon.
if ! tailscale status --json >/dev/null 2>&1; then
  log "tailscaled is not running or not signed in."
  log "run: sudo tailscale up"
  exit 2
fi

# Pipefail + explicit empty-check: if the JSON is unexpectedly shaped, bail
# rather than silently falling through to `tailscale set --hostname=""`.
current="$(tailscale status --json | /usr/bin/python3 -c \
  'import json, sys
data = json.load(sys.stdin)
host = data.get("Self", {}).get("HostName")
sys.exit(1) if not host else print(host)')"
if [[ -z "$current" ]]; then
  log "failed to determine current tailscale hostname from status JSON."
  exit 3
fi

if [[ "$current" == "$want_hostname" ]]; then
  log "tailscale hostname already '$want_hostname'."
  exit 0
fi

log "renaming tailscale node: '$current' -> '$want_hostname'"
sudo tailscale set --hostname="$want_hostname"

log "done. MagicDNS may take up to ~30s to propagate."
