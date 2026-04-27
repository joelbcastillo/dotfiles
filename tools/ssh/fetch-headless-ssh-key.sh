#!/usr/bin/env bash
# Fetch a 1Password-stored ed25519 SSH key onto a headless Mac and
# pin it for github.com. Designed for clamshell-mode Macs that don't
# run the 1Password desktop app — auth uses an on-disk key placed by
# this script rather than the 1P SSH agent socket (which doesn't exist).
#
# Idempotent. No-op when:
#   - OP_SERVICE_ACCOUNT_TOKEN isn't set (e.g., on a laptop with biometric)
#   - the key is already on disk in OpenSSH format
#
# Pre-req: a 1Password "SSH Key" item must already exist in the configured
# vault. Generate it from a signed-in shell:
#   op item create --category "SSH Key" --vault "Local Dev" \
#     --title "$(hostname -s)" --ssh-generate-key=ed25519
# Then add the public key to https://github.com/settings/keys before the
# headless box runs this script.
#
# Env overrides:
#   OP_SSH_KEY_VAULT  default: "Local Dev"
#   OP_SSH_KEY_ITEM   default: $(hostname -s)
#   SSH_KEY_FILE      default: $HOME/.ssh/id_ed25519

set -euo pipefail

VAULT="${OP_SSH_KEY_VAULT:-Local Dev}"
ITEM="${OP_SSH_KEY_ITEM:-$(hostname -s)}"
KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519}"
PUB_FILE="${KEY_FILE}.pub"
SSH_CFG="$HOME/.ssh/config"

log() { printf '[fetch-ssh] %s\n' "$*" >&2; }

if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
  if [[ -f "$HOME/.config/op/token.sh" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.config/op/token.sh"
  fi
fi

if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
  log "no OP_SERVICE_ACCOUNT_TOKEN set; skipping (laptop / biometric mode)"
  exit 0
fi

command -v op >/dev/null 2>&1 || { log "op CLI not found; skipping"; exit 0; }

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

key_is_openssh() {
  [[ -s "$KEY_FILE" ]] && head -1 "$KEY_FILE" | grep -q "BEGIN OPENSSH PRIVATE KEY"
}

if key_is_openssh; then
  log "key already present at $KEY_FILE (OpenSSH format)"
else
  log "fetching SSH key from 1P: op://${VAULT}/${ITEM}"
  umask 077
  # ssh-format=openssh ensures `-----BEGIN OPENSSH PRIVATE KEY-----` not PKCS8.
  if ! op read "op://${VAULT}/${ITEM}/private key?ssh-format=openssh" > "$KEY_FILE.tmp"; then
    log "error: could not read 'op://${VAULT}/${ITEM}/private key'"
    log "  make sure the SSH Key item exists and the SA has read access"
    rm -f "$KEY_FILE.tmp"
    exit 1
  fi
  mv -f "$KEY_FILE.tmp" "$KEY_FILE"
  chmod 600 "$KEY_FILE"

  if op read "op://${VAULT}/${ITEM}/public key" > "$PUB_FILE.tmp" 2>/dev/null; then
    mv -f "$PUB_FILE.tmp" "$PUB_FILE"
    chmod 644 "$PUB_FILE"
  else
    rm -f "$PUB_FILE.tmp"
    log "note: public key field missing in 1P item; skipping pubkey"
  fi
  log "key written to $KEY_FILE"
fi

# Pin github.com to the on-disk key (idempotent).
touch "$SSH_CFG"
chmod 600 "$SSH_CFG"
if ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com[[:space:]]*$' "$SSH_CFG"; then
  cat >> "$SSH_CFG" <<CFG

# Headless: github.com uses on-disk key (no 1P agent on this Mac).
# Source: tools/ssh/fetch-headless-ssh-key.sh (headless dotbot profile).
Host github.com
  IdentityFile ${KEY_FILE/#$HOME/~}
  IdentitiesOnly yes
CFG
  log "added github.com host pin to $SSH_CFG"
else
  log "github.com host pin already present in $SSH_CFG"
fi
