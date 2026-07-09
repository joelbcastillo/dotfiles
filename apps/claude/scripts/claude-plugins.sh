#!/usr/bin/env bash
# claude-plugins.sh — pinned, dotfiles-tracked Claude Code plugin management.
#
# Subcommands:
#   status   Report drift (installed vs lockfile) and patch state. Non-zero on drift.
#   update   Update marketplaces/plugins to latest, regenerate lockfile, reapply
#            patches, relink hooks, and print a committable diff. Never auto-commits.
#   restore  Rebuild pinned state from the lockfile (install-then-patch), for a
#            fresh machine or drift repair.
#   gen-lock Regenerate the lockfile from current machine state (used by update).
#
# Pinning model (hybrid, per marketplace type — see docs/plans/2026-07-09-001):
#   git-backed marketplace   -> true pin: checkout the marketplace commit SHA, then
#                               install, then ASSERT the marketplace is still at that
#                               SHA (catches an install-time re-pull that would defeat
#                               the pin).
#   GCS official marketplace -> drift-assert: record version, install latest on
#                               restore, assert installed == locked, fail loud on drift.
#                               Exact historical GCS versions cannot be reinstalled via
#                               the Claude CLI (no --version flag, no git history).
#
# Patches (in-plugin edits) are strict git patches, applied fail-loud. Hooks are
# symlinked from apps/claude/hooks via dotbot; relink here is a safety net.

set -euo pipefail

# --- output helpers ----------------------------------------------------------
if [ -t 1 ]; then
  C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[0;31m'; C_BLUE='\033[0;34m'; C_NC='\033[0m'
else
  C_GREEN=''; C_YELLOW=''; C_RED=''; C_BLUE=''; C_NC=''
fi
info() { printf '%b\n' "${C_BLUE}•${C_NC} $*"; }
ok()   { printf '%b\n' "${C_GREEN}✓${C_NC} $*"; }
warn() { printf '%b\n' "${C_YELLOW}⚠${C_NC} $*" >&2; }
die()  { printf '%b\n' "${C_RED}✗${C_NC} $*" >&2; exit 1; }

# --- paths (env-overridable for tests; production defaults unchanged) --------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
LOCKFILE="${DOTFILES_ROOT}/apps/claude/plugins/plugins.lock.json"
KNOWN_MARKETPLACES="${DOTFILES_ROOT}/apps/claude/plugins/known_marketplaces.json"
PATCHES_DIR="${DOTFILES_ROOT}/apps/claude/patches"
HOOKS_SRC="${DOTFILES_ROOT}/apps/claude/hooks"
CLAUDE_HOME="${CLAUDE_HOME:-${HOME}/.claude}"
MARKETPLACES_DIR="${CLAUDE_HOME}/plugins/marketplaces"
SETTINGS_JSON="${CLAUDE_HOME}/settings.json"

command -v python3 >/dev/null 2>&1 || die "python3 is required but was not found on PATH"

# --- claude binary (interactive shells wrap it in a zsh function) ------------
claude_bin() {
  if [ -n "${CLAUDE_BIN:-}" ]; then echo "$CLAUDE_BIN"
  elif [ -x /opt/homebrew/bin/claude ]; then echo /opt/homebrew/bin/claude   # Apple Silicon
  elif [ -x /usr/local/bin/claude ]; then echo /usr/local/bin/claude         # Intel Homebrew
  elif [ -x "${HOME}/.local/bin/claude" ]; then echo "${HOME}/.local/bin/claude"
  elif command -v claude >/dev/null 2>&1; then command -v claude
  else die "claude binary not found (checked /opt/homebrew, /usr/local, ~/.local/bin, PATH)"
  fi
}

# Cached `claude plugin list --json`; fetched at most once per command invocation.
LIST_JSON_CACHE=""
plugin_list_json() {
  if [ -z "$LIST_JSON_CACHE" ]; then
    LIST_JSON_CACHE="$("$(claude_bin)" plugin list --json 2>/dev/null)" \
      || die "could not read 'claude plugin list --json'"
  fi
  printf '%s' "$LIST_JSON_CACHE"
}
invalidate_list_cache() { LIST_JSON_CACHE=""; }

# Single source of truth for reading a field off an enabled, user-scope plugin record.
plugin_field() {
  local plugin_id="$1" field="$2"
  python3 -c '
import json, sys
pid, field = sys.argv[2], sys.argv[3]
for p in json.loads(sys.argv[1]):
    if p.get("id") == pid and p.get("scope") == "user" and p.get("enabled"):
        print(p.get(field, "")); break
' "$(plugin_list_json)" "$plugin_id" "$field"
}

# --- marketplace helpers -----------------------------------------------------
marketplace_is_git() { [ -d "${MARKETPLACES_DIR}/$1/.git" ]; }
marketplace_sha() {
  if marketplace_is_git "$1"; then
    git -C "${MARKETPLACES_DIR}/$1" rev-parse HEAD 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Ensure a marketplace is registered before we try to install from it; add it from
# the tracked known_marketplaces.json when missing (fresh-machine path).
ensure_marketplace() {
  local name="$1"
  [ -d "${MARKETPLACES_DIR}/${name}" ] && return 0
  [ -f "$KNOWN_MARKETPLACES" ] || die "marketplace '${name}' is not registered and no known_marketplaces.json exists to add it from"
  local src
  src="$(python3 -c '
import json, sys
m = json.load(open(sys.argv[1])).get(sys.argv[2], {}).get("source", {})
if m.get("source") == "github": print(m.get("repo", ""))
elif m.get("source") == "git": print(m.get("url", ""))
' "$KNOWN_MARKETPLACES" "$name")" \
    || die "cannot parse known_marketplaces.json"
  [ -n "$src" ] || die "marketplace '${name}' is pinned in the lockfile but has no entry in known_marketplaces.json — add it there first"
  info "  registering marketplace ${name} (${src})"
  "$(claude_bin)" plugin marketplace add "$src" >/dev/null 2>&1 \
    || die "failed to register marketplace ${name} from ${src}"
}

# --- lockfile ----------------------------------------------------------------
# Emit a sorted lock of enabled user-scope plugins, keyed "plugin@marketplace".
gen_lock() {
  local sha_map="" mp name sha
  for mp in "${MARKETPLACES_DIR}"/*/; do
    [ -d "$mp" ] || continue
    name="$(basename "$mp")"; sha="$(marketplace_sha "$name")"
    sha_map+="${name}=${sha}"$'\n'
  done
  SHA_MAP="$sha_map" SETTINGS="$SETTINGS_JSON" python3 - "$(plugin_list_json)" <<'PY'
import json, os, sys
plugins = json.loads(sys.argv[1])
settings = json.load(open(os.environ["SETTINGS"]))
enabled_cfg = {k for k, v in settings.get("enabledPlugins", {}).items() if v}
sha_map = {}
for line in os.environ.get("SHA_MAP", "").splitlines():
    if "=" in line:
        name, sha = line.split("=", 1); sha_map[name] = sha
out = {}
for p in plugins:
    pid = p.get("id", "")
    if pid not in enabled_cfg:                       # only plugins enabled in settings.json
        continue
    if p.get("scope") != "user" or not p.get("enabled"):
        continue
    marketplace = pid.split("@", 1)[1] if "@" in pid else ""
    sha = sha_map.get(marketplace, "")
    out[pid] = {
        "version": p.get("version", "unknown"),
        "marketplace": marketplace,
        "marketplaceType": "git" if sha else "gcs",
        "gitCommitSha": sha,
        "scope": "user",
    }
doc = {
    "_note": "Generated by claude-plugins.sh gen-lock. Do not hand-edit; run 'claude-plugins update'.",
    "plugins": dict(sorted(out.items())),
}
print(json.dumps(doc, indent=2))
PY
}

cmd_gen_lock() {
  mkdir -p "$(dirname "$LOCKFILE")"
  gen_lock > "${LOCKFILE}.tmp" || die "lockfile generation failed"
  mv "${LOCKFILE}.tmp" "$LOCKFILE"
  ok "Lockfile written: ${LOCKFILE#"$DOTFILES_ROOT"/}"
}

# TSV of lock entries: pid \t version \t marketplaceType \t gitCommitSha. Fails
# loud (non-zero) on a malformed lockfile so callers can die rather than silently
# iterate zero rows.
lock_entries() {
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))["plugins"]
for pid, meta in d.items():
    print("\t".join([pid, meta.get("version", "unknown"), meta.get("marketplaceType", "gcs"), meta.get("gitCommitSha", "")]))
' "$LOCKFILE"
}

# Normalized `plugins` object for stable diffing (sorted keys).
norm_plugins_file()   { python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))["plugins"], sort_keys=True, indent=2))' "$1"; }
norm_plugins_stdin()  { python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["plugins"], sort_keys=True, indent=2))'; }

# Map a patch directory (plugin short name) to its enabled plugin id via the lock.
lock_plugin_id_for() {
  [ -f "$LOCKFILE" ] || { echo ""; return; }
  python3 -c '
import json, sys
data = json.load(open(sys.argv[1])).get("plugins", {})
for pid in data:
    if pid.split("@", 1)[0] == sys.argv[2]:
        print(pid); break
' "$LOCKFILE" "$1"
}

# --- patches (strict, fail-loud) ---------------------------------------------
# Resolve a plugin's install root, canonicalized so `git apply --directory` never
# trips over a symlinked $HOME/.claude ("beyond a symbolic link").
plugin_install_root() {
  local root; root="$(plugin_field "$1" installPath)"
  [ -n "$root" ] || { echo ""; return 0; }
  (cd "$root" 2>/dev/null && pwd -P) || echo "$root"
}

# Apply every tracked patch for one plugin's install root. Fail loud.
apply_plugin_patches() {
  local short="$1" root="$2"
  local dir="${PATCHES_DIR}/${short}"
  [ -d "$dir" ] || return 0
  local patch rel
  for patch in "$dir"/*.patch; do
    [ -e "$patch" ] || continue
    rel="${patch#"$DOTFILES_ROOT"/}"
    { [ -n "$root" ] && [ -d "$root" ]; } || die "install root for patch ${rel} not found — cannot apply"
    if git apply --directory="$root" --unsafe-paths --check "$patch" >/dev/null 2>&1; then
      git apply --directory="$root" --unsafe-paths "$patch" || die "patch failed to apply after passing --check: ${rel}"
      ok "applied ${rel}"
    elif git apply --directory="$root" --unsafe-paths --reverse --check "$patch" >/dev/null 2>&1; then
      info "already applied: ${rel}"
    else
      die "patch does NOT apply cleanly (upstream file changed?): ${rel}
     Re-derive it against the current pinned version, then retry."
    fi
  done
}

# Apply patches for every patch directory (used by update; restore patches per-plugin).
apply_all_patches() {
  local any=0 dir short plugin_id
  for dir in "${PATCHES_DIR}"/*/; do
    [ -d "$dir" ] || continue
    short="$(basename "$dir")"
    plugin_id="$(lock_plugin_id_for "$short")"
    [ -n "$plugin_id" ] || { warn "no enabled plugin matches patch dir '${short}' — skipping"; continue; }
    any=1
    apply_plugin_patches "$short" "$(plugin_install_root "$plugin_id")"
  done
  [ "$any" -eq 1 ] || info "no patches to apply"
}

# --- hooks relink (safety net; dotbot owns the canonical link) ---------------
relink_hooks() {
  local target="${CLAUDE_HOME}/hooks"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$HOOKS_SRC" ]; then return 0; fi
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    warn "\$HOME/.claude/hooks exists and is not the expected symlink — leaving as-is (dotbot manages it)"
    return 0
  fi
  ln -sfn "$HOOKS_SRC" "$target"
  ok "linked \$HOME/.claude/hooks -> ${HOOKS_SRC#"$DOTFILES_ROOT"/}"
}

# --- subcommands -------------------------------------------------------------
cmd_status() {
  [ -f "$LOCKFILE" ] || die "no lockfile at ${LOCKFILE#"$DOTFILES_ROOT"/} — run 'claude-plugins gen-lock' or 'claude-plugins restore'"
  local drift=0 lock_norm cur_norm
  lock_norm="$(norm_plugins_file "$LOCKFILE")" || die "cannot read lockfile ${LOCKFILE#"$DOTFILES_ROOT"/}"
  cur_norm="$(gen_lock | norm_plugins_stdin)"    || die "cannot read current plugin state"
  if [ "$lock_norm" != "$cur_norm" ]; then
    warn "version drift between installed plugins and lockfile:"
    diff <(printf '%s\n' "$lock_norm") <(printf '%s\n' "$cur_norm") || true
    drift=1
  else
    ok "installed plugins match lockfile"
  fi
  # Patch state: is each tracked patch currently applied?
  local dir short plugin_id root patch rel
  for dir in "${PATCHES_DIR}"/*/; do
    [ -d "$dir" ] || continue
    short="$(basename "$dir")"
    plugin_id="$(lock_plugin_id_for "$short")"
    if [ -z "$plugin_id" ]; then
      warn "tracked patch dir '${short}' has no enabled plugin in the lockfile"; drift=1; continue
    fi
    root="$(plugin_install_root "$plugin_id")"
    for patch in "$dir"/*.patch; do
      [ -e "$patch" ] || continue
      rel="${patch#"$DOTFILES_ROOT"/}"
      if [ -z "$root" ] || [ ! -d "$root" ]; then
        warn "patch ${rel}: plugin not installed"; drift=1; continue
      fi
      if git apply --directory="$root" --unsafe-paths --reverse --check "$patch" >/dev/null 2>&1; then
        ok "patch applied: ${rel}"
      elif git apply --directory="$root" --unsafe-paths --check "$patch" >/dev/null 2>&1; then
        warn "patch NOT applied: ${rel}"; drift=1
      else
        warn "patch would FAIL (upstream changed): ${rel}"; drift=1
      fi
    done
  done
  [ "$drift" -eq 0 ] || exit 1
}

cmd_update() {
  [ -f "$LOCKFILE" ] || die "no lockfile — run 'claude-plugins gen-lock' or 'claude-plugins restore' first"
  local pids
  pids="$(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["plugins"].keys()))' "$LOCKFILE")" \
    || die "lockfile parse failed: ${LOCKFILE#"$DOTFILES_ROOT"/}"
  info "Updating marketplaces…"
  "$(claude_bin)" plugin marketplace update >/dev/null 2>&1 || warn "marketplace update reported an issue (continuing)"
  info "Updating enabled plugins to latest…"
  local pid
  while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    info "  update ${pid}"
    "$(claude_bin)" plugin update "$pid" >/dev/null 2>&1 || warn "  update failed for ${pid} (continuing)"
  done <<< "$pids"
  invalidate_list_cache
  info "Regenerating lockfile…"
  cmd_gen_lock
  info "Reapplying patches…"
  apply_all_patches
  relink_hooks
  echo
  info "Review and commit these changes:"
  git -C "$DOTFILES_ROOT" --no-pager diff --stat -- apps/claude/plugins/plugins.lock.json apps/claude/patches || true
}

cmd_restore() {
  [ -f "$LOCKFILE" ] || die "no lockfile at ${LOCKFILE#"$DOTFILES_ROOT"/} — nothing to restore"
  info "Restoring pinned plugins from lockfile…"
  local entries
  entries="$(lock_entries)" || die "lockfile parse failed: ${LOCKFILE#"$DOTFILES_ROOT"/}"
  local pid version mtype sha marketplace got_ver got_sha
  while IFS=$'\t' read -r pid version mtype sha; do
    [ -n "$pid" ] || continue
    marketplace="${pid##*@}"
    ensure_marketplace "$marketplace"
    if [ "$mtype" = "git" ] && [ -n "$sha" ] && marketplace_is_git "$marketplace"; then
      git -C "${MARKETPLACES_DIR}/${marketplace}" fetch --quiet --all 2>/dev/null || true
      git -C "${MARKETPLACES_DIR}/${marketplace}" checkout --quiet "$sha" 2>/dev/null \
        || die "cannot checkout ${marketplace}@${sha:0:8} — fetch it or refresh the pin ('claude-plugins update')"
    fi
    info "  install ${pid}"
    "$(claude_bin)" plugin install "$pid" --scope user >/dev/null 2>&1 || die "install failed for ${pid}"
    invalidate_list_cache
    got_ver="$(plugin_field "$pid" version)"
    [ -n "$got_ver" ] || die "plugin ${pid} is not present after install"
    if [ "$mtype" = "git" ] && [ -n "$sha" ]; then
      # Assert the pin actually took — install must not have re-pulled the marketplace.
      got_sha="$(marketplace_sha "$marketplace")"
      [ "$got_sha" = "$sha" ] || die "marketplace ${marketplace} is not at the pinned SHA after installing ${pid} (got ${got_sha:0:8}, want ${sha:0:8}) — the install re-pulled the marketplace; this pin is unenforceable via the current CLI"
    elif [ "$mtype" = "gcs" ] && [ "$version" != "unknown" ] && [ "$got_ver" != "$version" ]; then
      die "version drift for ${pid}: locked ${version}, installed ${got_ver}.
     The GCS marketplace has moved past the pin and old versions can't be reinstalled.
     Run 'claude-plugins update' to accept ${got_ver} and refresh any patches."
    fi
    # Transactional: patch this plugin now, so a later failure never leaves an
    # already-installed plugin unpatched.
    apply_plugin_patches "${pid%@*}" "$(plugin_install_root "$pid")"
  done <<< "$entries"
  relink_hooks
  ok "restore complete"
}

usage() {
  cat >&2 <<EOF
Usage: claude-plugins <command>

  status     Report drift + patch state (exit non-zero on drift; CI-friendly)
  update     Update to latest, regenerate lock, reapply patches, show diff
  restore    Rebuild pinned state from the lockfile (install-then-patch)
  gen-lock   Regenerate the lockfile from current machine state
EOF
  exit 2
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    status)   cmd_status "$@" ;;
    update)   cmd_update "$@" ;;
    restore)  cmd_restore "$@" ;;
    gen-lock) cmd_gen_lock "$@" ;;
    ""|-h|--help|help) usage ;;
    *) warn "unknown command: ${cmd}"; usage ;;
  esac
}

main "$@"
