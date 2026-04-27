# Claude Code companion tools: Happy, dmux, Paseo
# Personal env vars (HAPPY_SERVER_URL, CORTEX_VPS) are in dotfiles-private

# Aliases
alias cc='claude'
alias hc='happy'
alias dm='dmux'

# Refresh npm CLIs (dmux, happy-coder, Paseo) to @latest without re-running full dotbot
upgrade-claude-npm-tools() {
  local root="${DOTFILES:-$HOME/.dotfiles}"
  command "$root/scripts/upgrade-claude-npm-tools.sh"
}
