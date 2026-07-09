#!/usr/bin/env bash
# Tests for apps/claude/scripts/claude-plugins.sh
#
# Fully hermetic: mocks the `claude` binary and runs against fixture dirs via the
# CLAUDE_BIN / CLAUDE_HOME / DOTFILES_ROOT env seams. Never touches live plugin state.
#
# Run directly:  bash tests/claude-plugins.test.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${REPO_ROOT}/apps/claude/scripts/claude-plugins.sh"

pass=0; fail=0
ok()   { echo "✅ PASS: $1"; pass=$((pass+1)); }
bad()  { echo "❌ FAIL: $1"; echo "   $2"; fail=$((fail+1)); }

assert_success() { if eval "$1" >/dev/null 2>&1; then ok "$2"; else bad "$2" "command failed: $1"; fi; }
assert_failure() { if eval "$1" >/dev/null 2>&1; then bad "$2" "command unexpectedly succeeded: $1"; else ok "$2"; fi; }
assert_contains() { if printf '%s' "$2" | grep -q -- "$1"; then ok "$3"; else bad "$3" "expected to contain '$1', got: $2"; fi; }
assert_missing()  { if printf '%s' "$2" | grep -q -- "$1"; then bad "$3" "expected NOT to contain '$1'"; else ok "$3"; fi; }

# --- fixture -----------------------------------------------------------------
# Canonicalize: macOS mktemp lives under /var -> /private/var (a symlink), and
# `git apply` refuses paths beyond a symlink even with --unsafe-paths. pwd -P
# resolves it so fixtures sit on a real path, matching production (~/.claude/...).
T="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$T"' EXIT
export DOTFILES_ROOT="$T/dotfiles"
export CLAUDE_HOME="$T/claude-home"
export CLAUDE_BIN="$T/bin/claude"
export MOCK_LIST_JSON="$T/list.json"

mkdir -p "$DOTFILES_ROOT/apps/claude/plugins" \
         "$DOTFILES_ROOT/apps/claude/patches" \
         "$DOTFILES_ROOT/apps/claude/hooks" \
         "$CLAUDE_HOME/plugins/marketplaces" \
         "$T/bin"

# mock claude binary: `plugin list` emits the fixture JSON; everything else is a no-op success
cat > "$CLAUDE_BIN" <<'MOCK'
#!/usr/bin/env bash
[ "$1" = "plugin" ] || exit 0
case "${2:-}" in
  list) cat "$MOCK_LIST_JSON" ;;
  *) : ;;
esac
MOCK
chmod +x "$CLAUDE_BIN"

# a git-backed marketplace (real repo → real SHA) and a gcs one (plain dir → no SHA)
GITMP="$CLAUDE_HOME/plugins/marketplaces/git-mp"
mkdir -p "$GITMP"; ( cd "$GITMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
GIT_SHA="$(git -C "$GITMP" rev-parse HEAD)"
mkdir -p "$CLAUDE_HOME/plugins/marketplaces/gcs-mp"   # no .git → treated as gcs

# fake install root for the gcs plugin, holding a "pristine" target file to patch
GCS_ROOT="$CLAUDE_HOME/plugins/cache/gcs-mp/widget/2.0.0"
mkdir -p "$GCS_ROOT/hooks"
printf 'set -euo pipefail\n# anchor\n' > "$GCS_ROOT/hooks/session-start"

# settings.json: alpha (git) + widget (gcs) enabled; ghost disabled
cat > "$CLAUDE_HOME/settings.json" <<EOF
{ "enabledPlugins": {
    "alpha@git-mp": true,
    "widget@gcs-mp": true,
    "ghost@gcs-mp": false
} }
EOF

write_list() { cat > "$MOCK_LIST_JSON"; }

# base list: alpha 1.2.3 (git), widget 2.0.0 (gcs) enabled; ghost disabled
write_list <<EOF
[
 {"id":"alpha@git-mp","version":"1.2.3","scope":"user","enabled":true,"installPath":"$CLAUDE_HOME/plugins/cache/git-mp/alpha/1.2.3"},
 {"id":"widget@gcs-mp","version":"2.0.0","scope":"user","enabled":true,"installPath":"$GCS_ROOT"},
 {"id":"ghost@gcs-mp","version":"9.9.9","scope":"user","enabled":false,"installPath":"/x"}
]
EOF

run() { bash "$SCRIPT" "$@"; }

# --- U1: gen-lock ------------------------------------------------------------
run gen-lock >/dev/null 2>&1
LOCK="$(cat "$DOTFILES_ROOT/apps/claude/plugins/plugins.lock.json")"
assert_contains '"alpha@git-mp"'  "$LOCK" "gen-lock: includes enabled git plugin"
assert_contains '"widget@gcs-mp"' "$LOCK" "gen-lock: includes enabled gcs plugin"
assert_missing  'ghost'           "$LOCK" "gen-lock: omits disabled plugin"
assert_contains "$GIT_SHA"        "$LOCK" "gen-lock: records git marketplace SHA"
assert_contains '"marketplaceType": "gcs"' "$LOCK" "gen-lock: marks gcs marketplace type"
assert_contains '"marketplaceType": "git"' "$LOCK" "gen-lock: marks git marketplace type"

# --- U4: status clean --------------------------------------------------------
assert_success "run status" "status: exit 0 when installed matches lock and no patches"

# --- U4: status drift on version change --------------------------------------
write_list <<EOF
[
 {"id":"alpha@git-mp","version":"1.2.3","scope":"user","enabled":true,"installPath":"$CLAUDE_HOME/plugins/cache/git-mp/alpha/1.2.3"},
 {"id":"widget@gcs-mp","version":"2.5.0","scope":"user","enabled":true,"installPath":"$GCS_ROOT"},
 {"id":"ghost@gcs-mp","version":"9.9.9","scope":"user","enabled":false,"installPath":"/x"}
]
EOF
assert_failure "run status" "status: exit non-zero when installed version drifts from lock"
write_list <<EOF
[
 {"id":"alpha@git-mp","version":"1.2.3","scope":"user","enabled":true,"installPath":"$CLAUDE_HOME/plugins/cache/git-mp/alpha/1.2.3"},
 {"id":"widget@gcs-mp","version":"2.0.0","scope":"user","enabled":true,"installPath":"$GCS_ROOT"},
 {"id":"ghost@gcs-mp","version":"9.9.9","scope":"user","enabled":false,"installPath":"/x"}
]
EOF

# --- U3/U6: patch apply via restore (install is a no-op; file pre-placed) -----
mkdir -p "$DOTFILES_ROOT/apps/claude/patches/widget"
cat > "$DOTFILES_ROOT/apps/claude/patches/widget/2.0.0-anchor.patch" <<'PATCH'
diff --git a/hooks/session-start b/hooks/session-start
--- a/hooks/session-start
+++ b/hooks/session-start
@@ -1,2 +1,3 @@
 set -euo pipefail
+exit 0
 # anchor
PATCH
run restore >/dev/null 2>&1
assert_contains "exit 0" "$(cat "$GCS_ROOT/hooks/session-start")" "restore: patch applied to install root"
assert_success "run status" "status: exit 0 after patch applied (reverse-check detects it)"
# idempotent: applying again does not error
assert_success "run restore" "restore: idempotent when patch already applied"

# --- relink_hooks wires the symlink ------------------------------------------
link_target="$(readlink "$CLAUDE_HOME/hooks" 2>/dev/null || true)"
if [ "$link_target" = "$DOTFILES_ROOT/apps/claude/hooks" ]; then
  ok "restore: ~/.claude/hooks symlink points at the dotfiles hooks dir"
else
  bad "restore: hooks symlink" "readlink=$link_target"
fi

# --- P1: gcs version drift makes restore die loud ----------------------------
cat > "$MOCK_LIST_JSON" <<EOF
[
 {"id":"alpha@git-mp","version":"1.2.3","scope":"user","enabled":true,"installPath":"$CLAUDE_HOME/plugins/cache/git-mp/alpha/1.2.3"},
 {"id":"widget@gcs-mp","version":"2.5.0","scope":"user","enabled":true,"installPath":"$GCS_ROOT"}
]
EOF
drift_out="$(run restore 2>&1 || true)"
assert_contains "version drift" "$drift_out" "restore: gcs version drift dies with a clear message"
# reset installed state to match the lock
write_list <<EOF
[
 {"id":"alpha@git-mp","version":"1.2.3","scope":"user","enabled":true,"installPath":"$CLAUDE_HOME/plugins/cache/git-mp/alpha/1.2.3"},
 {"id":"widget@gcs-mp","version":"2.0.0","scope":"user","enabled":true,"installPath":"$GCS_ROOT"}
]
EOF

# --- U3: fail-loud when patch no longer applies ------------------------------
printf 'totally different file\n' > "$GCS_ROOT/hooks/session-start"
assert_failure "run restore" "restore: fails loud when a patch no longer applies"

# --- P1: restore dies loud when a pinned marketplace isn't registered --------
cat > "$MOCK_LIST_JSON" <<EOF
[ {"id":"orphan@ghost-mp","version":"1.0.0","scope":"user","enabled":true,"installPath":"$CLAUDE_HOME/plugins/cache/ghost-mp/orphan/1.0.0"} ]
EOF
cat > "$CLAUDE_HOME/settings.json" <<EOF
{ "enabledPlugins": { "orphan@ghost-mp": true } }
EOF
run gen-lock >/dev/null 2>&1
orphan_out="$(run restore 2>&1 || true)"
assert_contains "not registered" "$orphan_out" "restore: unregistered marketplace with no known_marketplaces entry dies loud"

# --- P0: malformed lockfile fails loud (no silent success) -------------------
printf 'THIS IS NOT JSON {{{\n' > "$DOTFILES_ROOT/apps/claude/plugins/plugins.lock.json"
assert_failure "run restore" "restore: fails loud on a malformed lockfile (P0 regression guard)"
assert_failure "run update"  "update: fails loud on a malformed lockfile"

echo
echo "claude-plugins: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
