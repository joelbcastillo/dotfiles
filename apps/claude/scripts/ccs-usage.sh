#!/usr/bin/env bash
# Render the overall Claude 5-hour usage segment for the tmux bar from the
# account-global rate_limits data that statusline.sh taps on every refresh (see
# latest.json). No ccusage, no CLAUDE_CONFIG_DIR, no transcript scan — the
# official number comes straight from Claude Code's statusline stdin.
#
#   ccs-usage.sh update   read latest.json, compute burn vs the prior sample, and
#                         write the formatted segment. Driven by com.jbctech.ccs-usage
#                         (launchd, every 60s) — a single writer, so burn is race-free.
#   ccs-usage.sh          print the cached segment (nothing if missing/stale).
#                         Called by the tmux-powerkit external plugin.
set -euo pipefail

# launchd hands us a minimal PATH; make python3 resolvable.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ccs-usage"
SEGMENT_FILE="$CACHE_DIR/segment.txt"
STALE_AFTER=180   # seconds; blank the segment if no session has reported recently

read_segment() {
  [ -f "$SEGMENT_FILE" ] || exit 0
  local mtime now
  mtime=$(stat -f %m "$SEGMENT_FILE" 2>/dev/null) || exit 0
  now=$(date +%s)
  [ $(( now - mtime )) -le "$STALE_AFTER" ] || exit 0
  cat "$SEGMENT_FILE"
}

update() {
  mkdir -p "$CACHE_DIR"
  local seg
  # shellcheck disable=SC2016
  seg=$(CACHE_DIR="$CACHE_DIR" STALE_AFTER="$STALE_AFTER" python3 -c '
import json, os, sys, time

now = int(time.time())
stale = int(os.environ["STALE_AFTER"])
cache = os.environ["CACHE_DIR"]

try:
    d = json.load(open(os.path.join(cache, "latest.json")))
except Exception:
    sys.exit(0)
if now - int(d.get("ts", 0)) > stale:
    sys.exit(0)                          # no active session recently
used = d.get("used")
if used is None:
    sys.exit(0)

# reset countdown from resets_at (epoch)
reset = ""
ra = d.get("resets_at")
if ra:
    rem = int(ra) - now
    if rem > 0:
        h, m = divmod(rem // 60, 60)
        reset = f"{h}h{m:02d}m" if h else f"{m}m"

# burn as %/hr vs the previous single-writer sample (anchor); single writer, no race
burn = ""
anchor_path = os.path.join(cache, "anchor.json")
try:
    prev = json.load(open(anchor_path))
except Exception:
    prev = None

if (prev is None
        or now - int(prev.get("ts", 0)) > 300         # refresh window
        or used < prev.get("used", used)):            # block reset (usage dropped)
    try:
        tmp = anchor_path + f".{os.getpid()}.tmp"
        open(tmp, "w").write(json.dumps({"used": used, "ts": now}))
        os.replace(tmp, anchor_path)
    except Exception:
        pass
elif now - int(prev.get("ts", 0)) >= 120:             # enough spread to be meaningful
    dt_h = (now - int(prev["ts"])) / 3600.0
    rate = (used - prev.get("used", used)) / dt_h if dt_h > 0 else 0
    if rate >= 0.5:
        burn = f"~{round(rate)}%/h"

parts = [f"{round(used)}%"]
if reset:
    parts.append(reset)
if burn:
    parts.append(burn)
print(" · ".join(parts))
') || exit 0

  [ -n "$seg" ] || exit 0
  printf '%s' "$seg" > "$SEGMENT_FILE.tmp" && mv "$SEGMENT_FILE.tmp" "$SEGMENT_FILE"
}

case "${1:-read}" in
  update)   update ;;
  read|"")  read_segment ;;
  *)        echo "usage: ${0##*/} [update|read]" >&2; exit 2 ;;
esac
