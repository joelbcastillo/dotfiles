#!/usr/bin/env bash
# Enable macOS Remote Login (sshd) and install the secure-defaults drop-in.
# Designed to be idempotent and safe to re-run.
#
# Per-host drop-ins (e.g. AllowUsers) should be installed separately by the
# caller; this script only handles the portion that applies to every headless
# box.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/sshd_config.d/00-secure-defaults.conf"
DST="/etc/ssh/sshd_config.d/00-secure-defaults.conf"

log() { printf '[ssh] %s\n' "$*" >&2; }

[[ "$(uname -s)" == "Darwin" ]] || { log "macOS only."; exit 1; }
[[ -f "$SRC" ]] || { log "missing: $SRC"; exit 1; }

# 1. Enable Remote Login if not already on.
if sudo systemsetup -getremotelogin 2>/dev/null | grep -qi 'on'; then
  log "Remote Login already enabled."
else
  log "Enabling Remote Login (sshd)…"
  sudo systemsetup -setremotelogin on >/dev/null
fi

# 2. Install secure-defaults drop-in.
sudo mkdir -p /etc/ssh/sshd_config.d
if sudo diff -q "$SRC" "$DST" >/dev/null 2>&1; then
  log "drop-in unchanged: $DST"
else
  log "writing drop-in: $DST"
  sudo install -m 0644 -o root -g wheel "$SRC" "$DST"
fi

# 3. Validate sshd config before asking launchd to notice.
log "validating sshd config…"
if ! sudo /usr/sbin/sshd -t; then
  log "sshd config invalid; aborting without reloading."
  exit 2
fi

# 4. Kick sshd so it picks up the new drop-in. `launchctl kickstart -k`
#    replaces the (obsolete) `launchctl stop/start` dance.
log "reloading sshd…"
sudo launchctl kickstart -k system/com.openssh.sshd >/dev/null 2>&1 || true

log "done."
