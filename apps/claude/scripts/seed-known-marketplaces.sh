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

# Every write goes through here. The temp file is a sibling of the target, so
# the rename is same-filesystem and therefore atomic — an interrupted run
# leaves the original intact rather than a truncated file. That matters because
# the merge below skips invalid JSON, so a half-written file would persist
# across runs instead of self-healing.
write_atomic() {
    local dest="$1" tmp
    tmp="$(mktemp "${dest}.XXXXXX")" || die "cannot create a temp file next to $dest"
    cat > "$tmp" || { rm -f "$tmp"; die "failed writing $tmp"; }
    chmod 644 "$tmp"
    mv -f "$tmp" "$dest" || { rm -f "$tmp"; die "failed replacing $dest"; }
}

# Migration: older installs symlinked this into the repo. Replace the link with
# a real file so Claude Code's writes stop landing in git.
#
# The target must be exactly the legacy tracked path — matching loosely would
# also accept known_marketplaces-backup.json or a stray file, and this script
# then rewrites whatever it points at. Compared by suffix rather than against
# DOTFILES_ROOT so a link into another checkout or worktree still migrates.
if [ -L "$LIVE" ]; then
    target="$(readlink "$LIVE")"
    case "$target" in
        */apps/claude/plugins/known_marketplaces.json)
            log "migrating: $LIVE was a symlink into the repo"
            if [ -e "$LIVE" ]; then
                # Read through the link, then rename over it — never unlink
                # first, or a failure here would lose the content outright.
                content="$(cat "$LIVE")" || die "cannot read $LIVE via its symlink"
                printf '%s\n' "$content" | write_atomic "$LIVE"
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
    write_atomic "$LIVE" < "$TEMPLATE"
    log "seeded $LIVE from the template"
    exit 0
fi

# Merge: add only the keys the live file lacks. Existing entries keep their
# runtime fields untouched, so this can never clobber Claude Code's state.
#
# The merged document goes to stdout and is written by write_atomic, so the
# read-modify-write never truncates the live file. This still is not locked
# against a Claude Code write landing between the read and the rename; that
# window is small and this only runs during a dotbot pass, so the tradeoff is
# a lost marketplace *addition* at worst, never a corrupted file.
merged="$(python3 - "$TEMPLATE" "$LIVE" <<'PY'
import json, sys

template_path, live_path = sys.argv[1], sys.argv[2]

with open(template_path) as fh:
    template = json.load(fh)
try:
    with open(live_path) as fh:
        live = json.load(fh)
except (json.JSONDecodeError, ValueError):
    # A corrupt live file is Claude Code's to repair; do not overwrite it.
    print("SKIP")
    raise SystemExit(0)

if not isinstance(live, dict):
    print("SKIP")
    raise SystemExit(0)

missing = [k for k in template if k not in live]
for key in missing:
    live[key] = template[key]

# First line is the status, remainder is the document (empty when unchanged).
print(",".join(missing))
if missing:
    json.dump(live, sys.stdout, indent=2)
    sys.stdout.write("\n")
PY
)" || die "failed to merge template into $LIVE"

added="$(printf '%s' "$merged" | head -1)"
if [ -n "$added" ] && [ "$added" != "SKIP" ]; then
    printf '%s' "$merged" | tail -n +2 | write_atomic "$LIVE"
fi

case "$added" in
    SKIP) log "live file is not valid JSON; leaving it alone for Claude Code to repair" ;;
    "")   log "up to date; no marketplaces to add" ;;
    *)    log "added missing marketplace(s): ${added//,/, }" ;;
esac
