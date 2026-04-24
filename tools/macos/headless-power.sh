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

# Read current values from the AC-power section of `pmset -g custom` so we
# can no-op if nothing would change. `pmset -g` only reports the active
# profile — on battery it would misreport the AC profile and cause spurious
# "no change" results. `pmset -g custom` always lists both profiles; we
# extract only the AC section here.
ac_section="$(pmset -g custom 2>/dev/null \
  | awk '/^AC Power:/{flag=1;next} /^[A-Za-z].*:$/{flag=0} flag' \
  | tr -s ' ')"
want() { grep -qE "(^| )$1 $2(\$| )" <<<"$ac_section"; }

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
disablesleep 1
EOF

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
