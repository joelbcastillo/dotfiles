#!/usr/bin/env bash
# Persistent power-management settings for a headless Mac on AC power.
# Uses `pmset` (persistent), not `caffeinate` (process-scoped).
#
# Applied in the AC-power profile only (`-c`). Battery profile intentionally
# left untouched so a disconnected Mac still sleeps normally.
#
# References:
#   pmset(1) — man page
#   https://ss64.com/mac/pmset.html
#   https://www.dssw.co.uk/reference/pmset/

set -euo pipefail

log() { printf '[power] %s\n' "$*" >&2; }

[[ "$(uname -s)" == "Darwin" ]] || { log "macOS only."; exit 1; }

# Read current values so we can no-op if nothing would change.
current="$(pmset -g | tr -s ' ')"
want() { grep -qE "(^| )$1 $2(\$| )" <<<"$current"; }

needs_change=false
while IFS=' ' read -r k v; do
  [[ -z "$k" ]] && continue
  want "$k" "$v" || { needs_change=true; break; }
done <<'EOF'
sleep 0
disksleep 0
displaysleep 1
womp 1
powernap 0
autopoweroff 0
standby 0
EOF
# `disablesleep` is not in `pmset -g` output by default; check separately.
if ! pmset -g custom 2>/dev/null | grep -qE 'disablesleep +1'; then
  needs_change=true
fi

if ! $needs_change; then
  log "pmset already configured for headless on AC; no change."
  exit 0
fi

log "applying pmset AC-power settings for headless…"
sudo pmset -c \
  sleep 0 \
  disksleep 0 \
  displaysleep 1 \
  womp 1 \
  powernap 0 \
  autopoweroff 0 \
  standby 0 \
  disablesleep 1

log "result:"
pmset -g custom | sed 's/^/[power]   /' >&2
