#!/usr/bin/env bash
# seed-known-marketplaces — reconcile ~/.claude/plugins/known_marketplaces.json
# with the tracked template.
#
# Why this is not a dotbot link: Claude Code *writes* to that file, stamping
# each entry with an installLocation (an absolute, per-machine path) and a
# lastUpdated timestamp. Symlinking it into the repo meant every plugin refresh
# dirtied the working tree, and committing that churn pushed one machine's home
# directory into config the other machine reads.
#
# So ownership is split: the template is the source of truth for *which*
# marketplaces exist, Claude Code owns the live file and its runtime fields.
# This script adds template entries the live file is missing and never touches
# entries it already has.
#
# Idempotent. Safe to run on every dotbot pass.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
TEMPLATE="${DOTFILES_ROOT}/apps/claude/plugins/known_marketplaces.template.json"
CLAUDE_HOME="${CLAUDE_HOME:-${HOME}/.claude}"
LIVE="${CLAUDE_HOME}/plugins/known_marketplaces.json"

log() { printf '[known-marketplaces] %s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }

[ -f "$TEMPLATE" ] || die "template not found at $TEMPLATE"
command -v python3 >/dev/null 2>&1 || die "python3 is required but was not found on PATH"

mkdir -p "$(dirname "$LIVE")"

# Migration: older installs symlinked this into the repo. Replace the link with
# a real file so Claude Code's writes stop landing in git. Resolve through the
# link first so the current content survives the switch.
if [ -L "$LIVE" ]; then
    target="$(readlink "$LIVE")"
    case "$target" in
        *"/apps/claude/plugins/known_marketplaces"*)
            log "migrating: $LIVE was a symlink into the repo"
            if [ -e "$LIVE" ]; then
                tmp="$(mktemp)"
                cat "$LIVE" > "$tmp"
                rm -f "$LIVE"
                mv "$tmp" "$LIVE"
                chmod 644 "$LIVE"
                log "  kept existing content as a real file"
            else
                rm -f "$LIVE"
                log "  link was dangling; removed"
            fi
            ;;
        *) die "$LIVE is a symlink to an unexpected target ($target); refusing to touch it" ;;
    esac
fi

if [ ! -f "$LIVE" ]; then
    cp "$TEMPLATE" "$LIVE"
    chmod 644 "$LIVE"
    log "seeded $LIVE from the template"
    exit 0
fi

# Merge: add only the keys the live file lacks. Existing entries keep their
# runtime fields untouched, so this can never clobber Claude Code's state.
added="$(python3 - "$TEMPLATE" "$LIVE" <<'PY'
import json, sys

template_path, live_path = sys.argv[1], sys.argv[2]

with open(template_path) as fh:
    template = json.load(fh)
try:
    with open(live_path) as fh:
        live = json.load(fh)
except (json.JSONDecodeError, ValueError):
    # A corrupt live file is Claude Code's to repair; do not overwrite it.
    print("SKIP", end="")
    raise SystemExit(0)

if not isinstance(live, dict):
    print("SKIP", end="")
    raise SystemExit(0)

missing = [k for k in template if k not in live]
for key in missing:
    live[key] = template[key]

if missing:
    with open(live_path, "w") as fh:
        json.dump(live, fh, indent=2)
        fh.write("\n")

print(",".join(missing), end="")
PY
)" || die "failed to merge template into $LIVE"

case "$added" in
    SKIP) log "live file is not valid JSON; leaving it alone for Claude Code to repair" ;;
    "")   log "up to date; no marketplaces to add" ;;
    *)    log "added missing marketplace(s): ${added//,/, }" ;;
esac
