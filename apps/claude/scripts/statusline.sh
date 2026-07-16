#!/usr/bin/env bash
# Lightweight Claude Code statusline. Renders from the JSON Claude Code pipes on
# stdin — model, working dir / worktree, and context-window usage — with NO
# transcript scanning. Replaces `ccusage statusline`, whose per-refresh scan of
# every transcript pinned a core per instance. The aggregate usage view now
# lives once in the tmux bar (see ccs-usage.sh); this line stays per-pane and cheap.
exec python3 -c '
import json, sys, os
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

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
'
