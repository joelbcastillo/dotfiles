# 1Password SSH Agent Configuration
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# ── Multi-account `op` wrapper ──────────────────────────────────────────────
#
# Service-account mode binds OP_SERVICE_ACCOUNT_TOKEN to exactly one business
# account, so on a headless box each account gets its own token file at
# ~/.config/op/token-${account}.sh. Bare `op …` reads OP_SERVICE_ACCOUNT_TOKEN
# from the environment as usual (default token sourced from ~/.config/op/token.sh
# in zshenv); `op --account NAME …` swaps the token in a subshell so the
# parent shell never holds a non-default token.
#
# NAME can be either:
#   - the accounts.json key      (e.g. work, client-a)
#   - the 1P domain shorthand    (e.g. work.1password.com) — the
#     wrapper strips ".1password.com" and looks for the matching token file
#
# In biometric mode (no SA token), this wrapper is a no-op: `op --account` is
# already supported natively by the CLI.
op() {
  emulate -L zsh
  local cfg="${HOME}/.config/op"

  # Only intervene when the user explicitly chose an account AND we're in
  # service-account mode. Otherwise let the real op binary handle it.
  if [[ "$1" == "--account" || "$1" == "-a" ]] && [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    local acct="$2"
    shift 2
    local key="${acct%.1password.com}"
    local tf="${cfg}/token-${key}.sh"
    if [[ ! -f "$tf" ]]; then
      print -u2 "op: no service-account token for '$key' (looked for $tf)"
      print -u2 "op: rotate one with: bash ~/.repos/github.com/your-org/your-laptop-repo/scripts/laptop/rotate-service-account.sh <ssh-target> ${key}"
      return 1
    fi
    ( unset OP_SERVICE_ACCOUNT_TOKEN
      source "$tf"
      command op "$@" )
    return $?
  fi

  command op "$@"
}
