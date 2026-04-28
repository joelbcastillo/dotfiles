# Claude Code companion tools: Happy, dmux, Paseo
# Personal env vars (HAPPY_SERVER_URL, CORTEX_VPS) are in dotfiles-private

# Claude Code CLI: prefer npm global (@anthropic-ai/claude-code), then Homebrew.
# Use a function (not an alias) so dmux/sh -c can still resolve `claude` on PATH while
# interactive shells get _secure_run + secrets. Remove any private `alias claude=...`
# that points at Homebrew so this definition is used.
_claude_cli_path() {
  local p
  [[ -x "${HOME}/.local/bin/claude" ]] && { echo "${HOME}/.local/bin/claude"; return; }
  if command -v npm >/dev/null 2>&1; then
    p="$(npm config get prefix 2>/dev/null)/bin/claude"
    [[ -x "$p" ]] && { echo "$p"; return; }
  fi
  [[ -x /opt/homebrew/bin/claude ]] && { echo /opt/homebrew/bin/claude; return; }
  [[ -x /usr/local/bin/claude ]] && { echo /usr/local/bin/claude; return; }
  echo claude
}

claude() {
  _secure_run ai "$(_claude_cli_path)" "$@"
}

# Aliases
alias cc='claude'
alias hc='happy'
alias dm='dmux'

# Refresh npm CLIs (dmux, happy-coder, Paseo) to @latest without re-running full dotbot
upgrade-claude-npm-tools() {
  local root="${DOTFILES:-$HOME/.dotfiles}"
  command "$root/scripts/upgrade-claude-npm-tools.sh"
}
