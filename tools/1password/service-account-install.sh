#!/usr/bin/env bash
# Interactive setup for a 1Password service account token on a headless Mac.
# Prompts once per machine, writes ~/.config/op/token.sh (mode 600) and
# ensures ~/.zshrc sources it on shell startup.
#
# Idempotent: re-running with a token already configured is a no-op.
# Non-interactive: if stdin isn't a tty and no token exists, prints
#   instructions and exits 0 (so dotbot doesn't fail the whole profile).
#
# Token creation (run on the admin laptop as a signed-in user):
#   op --account <biz-account> service-account create <name> \
#     --can-create-vaults --expires-in 2159h \
#     --vault "Vault1:read_items,write_items" ...
# 1P max expiry is ~90 days (2160h ceiling); rotate before it lapses.

set -euo pipefail

CFG_DIR="$HOME/.config/op"
TOKEN_FILE="$CFG_DIR/token.sh"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='[[ -f ~/.config/op/token.sh ]] && source ~/.config/op/token.sh'

log() { printf '[op-sa] %s\n' "$*" >&2; }

mkdir -p "$CFG_DIR"
chmod 700 "$CFG_DIR"

ensure_zshrc_source() {
  if [[ -f "$ZSHRC" ]] && grep -qF "op/token.sh" "$ZSHRC"; then
    return 0
  fi
  {
    printf '\n# 1Password service account token (headless profile)\n'
    printf '%s\n' "$SOURCE_LINE"
  } >> "$ZSHRC"
  log "added source line to $ZSHRC"
}

token_configured() {
  [[ -f "$TOKEN_FILE" ]] || return 1
  grep -qE '^export OP_SERVICE_ACCOUNT_TOKEN=.+' "$TOKEN_FILE"
}

if token_configured; then
  log "token already configured at $TOKEN_FILE; skipping prompt"
  ensure_zshrc_source
  exit 0
fi

if [[ ! -t 0 ]]; then
  log "no token file and stdin is not a tty; skipping prompt"
  log "to configure later, run: bash $0"
  ensure_zshrc_source
  exit 0
fi

cat >&2 <<'EOF'

  1Password service account setup
  -------------------------------
  Paste the service account token (starts with ops_...).
  Stored at ~/.config/op/token.sh (mode 600). Leave blank to skip.

EOF
printf '  token: ' >&2
# -s hides input; -r disables backslash mangling.
read -rs token
printf '\n' >&2

if [[ -z "${token:-}" ]]; then
  log "skipped (no token entered)"
  ensure_zshrc_source
  exit 0
fi

if [[ "$token" != ops_* ]]; then
  log "warning: token doesn't start with 'ops_' — writing anyway"
fi

umask 077
printf 'export OP_SERVICE_ACCOUNT_TOKEN=%q\n' "$token" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
unset token
log "token written to $TOKEN_FILE (mode 600)"

ensure_zshrc_source

log "open a new shell, or run: source ~/.config/op/token.sh && op whoami"
