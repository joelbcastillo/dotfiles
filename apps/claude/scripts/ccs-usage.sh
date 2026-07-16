#!/usr/bin/env bash
# Aggregate ccusage's active 5-hour block across every ccs instance into a
# single tmux status-bar segment, via a cache file so the slow scan never runs
# in the render path.
#
#   ccs-usage.sh update   slow (~6s): scan all instances, write the cache atomically.
#                         Driven by com.jbctech.ccs-usage (launchd, every 60s).
#   ccs-usage.sh          instant: print the cached segment (nothing if missing/stale).
#                         Called by the tmux-powerkit `external` plugin.
#
# ccs runs each Claude instance with an isolated CLAUDE_CONFIG_DIR under
# ~/.ccs/instances/<name>/; ccusage reads a comma-separated CLAUDE_CONFIG_DIR to
# aggregate across them.
set -euo pipefail

# launchd hands us a minimal PATH; make homebrew ccusage and python3 resolvable.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ccs-usage"
CACHE_FILE="$CACHE_DIR/segment.txt"
INSTANCES_ROOT="$HOME/.ccs/instances"
CCUSAGE="${CCUSAGE_BIN:-ccusage}"
STALE_AFTER=180   # seconds; blank the segment if the writer has stopped

read_segment() {
  [ -f "$CACHE_FILE" ] || exit 0
  local mtime now
  mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null) || exit 0
  now=$(date +%s)
  [ $(( now - mtime )) -le "$STALE_AFTER" ] || exit 0
  cat "$CACHE_FILE"
}

update() {
  mkdir -p "$CACHE_DIR"

  local dirs=""
  for d in "$INSTANCES_ROOT"/*/; do
    [ -d "$d/projects" ] && dirs+="$d,"
  done
  dirs=${dirs%,}
  [ -n "$dirs" ] || exit 0

  local json
  json=$(CLAUDE_CONFIG_DIR="$dirs" "$CCUSAGE" blocks --active --json --token-limit max 2>/dev/null) || exit 0

  local seg
  seg=$(printf '%s' "$json" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
b = (d.get("blocks") or [None])[0]
if not b:
    sys.exit(0)
tok = b.get("totalTokens") or 0
lim = (b.get("tokenLimitStatus") or {}).get("limit") or 0
pct = round(tok / lim * 100) if lim else 0
rem = (b.get("projection") or {}).get("remainingMinutes") or 0
h, m = divmod(int(rem), 60)
reset = f"{h}h{m:02d}m" if h else f"{m}m"
cph = (b.get("burnRate") or {}).get("costPerHour") or 0
print(f"{pct}% · {reset} · ${round(cph)}/h")
') || exit 0

  [ -n "$seg" ] || exit 0
  printf '%s' "$seg" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

case "${1:-read}" in
  update)   update ;;
  read|"")  read_segment ;;
  *)        echo "usage: ${0##*/} [update|read]" >&2; exit 2 ;;
esac
