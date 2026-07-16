#!/usr/bin/env bash
# Lightweight Claude Code statusline + account-usage tap.
#
# Renders the per-pane line (model · dir · ctx%) from the JSON Claude Code pipes
# on stdin — no transcript scan. Also taps rate_limits.five_hour (account-global,
# present on every session's stdin as of Claude Code 2.1.90+) into a shared cache
# so the tmux bar can show one overall usage readout with no ccusage scan. The
# bar side (format + display) lives in ccs-usage.sh.
# shellcheck disable=SC2016
exec python3 -c '
import json, sys, os, time

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

# --- per-pane line ---
model = (d.get("model") or {}).get("display_name") or "?"
ws = d.get("workspace") or {}
cur = ws.get("current_dir") or d.get("cwd") or ""
name = os.path.basename(cur.rstrip("/")) or cur
worktree = ws.get("git_worktree") or ""

parts = [model, name]
if worktree and worktree != name:
    parts.append(worktree)
seg = "  ".join(parts)

pct = (d.get("context_window") or {}).get("used_percentage")
if pct is not None:
    seg += f"  ctx {round(pct)}%"

print(seg)

# --- tap the account-global rate limits (5-hour + weekly) into the shared cache ---
rl = d.get("rate_limits") or {}
fh = rl.get("five_hour") or {}
wk = rl.get("seven_day") or {}
used = fh.get("used_percentage")
if used is None:
    sys.exit(0)                       # null before first API call / just after /compact

cache_dir = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "ccs-usage")
try:
    os.makedirs(cache_dir, exist_ok=True)
    payload = json.dumps({
        "used": used, "resets_at": fh.get("resets_at"),
        "wk_used": wk.get("used_percentage"), "wk_resets_at": wk.get("resets_at"),
        "ts": int(time.time())})
    tmp = os.path.join(cache_dir, f".latest.{os.getpid()}.tmp")
    with open(tmp, "w") as f:
        f.write(payload)
    os.replace(tmp, os.path.join(cache_dir, "latest.json"))   # atomic; last pane wins
except Exception:
    pass
'
