# Claude Code companion tools: Happy, dmux, Paseo
# Personal env vars (HAPPY_SERVER_URL, CORTEX_VPS) are in dotfiles-private

# ccs/claude/ccr are npm globals under the ~/.tool-versions node; their asdf
# shims fail in repos pinning a different node. bin/claude-tools wrappers run
# them on the global node directly; the PATH prepend lives in zshrc (must come
# after the final asdf shims prepend there to win resolution).

# Claude Code CLI: prefer the native build (~/.local/bin/claude, self-updating via
# `claude install`), then npm global (@anthropic-ai/claude-code), then Homebrew.
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

# Per-pane CCS account picker for dmux.
# dmux launches Claude by typing `claude ...` into each pane's interactive zsh,
# so this function is the hook point. Inside a dmux worktree pane, ask once
# which ccs account to use and remember it in the worktree's private git dir
# (never committed, dies with the worktree) so `claude --continue` resumes
# with the same account. Override without prompting: DMUX_CCS_PROFILE=jp dmux,
# or `ccs-pane <profile>` to change the current pane's stored account.
_dmux_ccs_profile() {
  [[ "$PWD" == */.dmux/worktrees/* ]] || return 1

  local gitdir store
  gitdir="$(command git rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  store="$gitdir/ccs-profile"

  if [[ -n "$DMUX_CCS_PROFILE" ]]; then
    print -r -- "$DMUX_CCS_PROFILE" >| "$store"
  elif [[ ! -f "$store" ]]; then
    [[ -t 0 ]] || return 1
    local -a profiles
    profiles=("${(@f)$(command ls "$HOME/.ccs/instances" 2>/dev/null)}")
    (( ${#profiles} )) || return 1
    local i choice
    print -u2 -- "── dmux pane: pick Claude account ──"
    for (( i = 1; i <= ${#profiles}; i++ )); do
      print -u2 -- "  $i) ${profiles[i]}"
    done
    print -u2 -- "  0) default claude (no ccs)"
    read -r "choice?account [0]: "
    if [[ "$choice" == <1-> ]] && (( choice <= ${#profiles} )); then
      print -r -- "${profiles[choice]}" >| "$store"
    else
      print -r -- "default" >| "$store"
    fi
  fi

  local saved
  saved="$(<"$store")"
  [[ -n "$saved" && "$saved" != "default" ]] || return 1
  print -r -- "$saved"
}

# Change (or clear) the stored ccs account for the current dmux worktree pane
ccs-pane() {
  local gitdir
  gitdir="$(command git rev-parse --absolute-git-dir 2>/dev/null)" || {
    echo "not inside a git worktree" >&2; return 1
  }
  if [[ -z "$1" ]]; then
    echo "current: $(cat "$gitdir/ccs-profile" 2>/dev/null || echo '(unset)')"
    echo "usage: ccs-pane <profile>|default|clear   (profiles: $(command ls "$HOME/.ccs/instances" | tr '\n' ' '))"
    return 0
  fi
  if [[ "$1" == "clear" ]]; then
    rm -f "$gitdir/ccs-profile"; echo "cleared — next claude launch will ask"
  else
    print -r -- "$1" >| "$gitdir/ccs-profile"; echo "pane account: $1"
  fi
}

claude() {
  local _ccs_profile
  if _ccs_profile="$(_dmux_ccs_profile)"; then
    _secure_run ai ccs "$_ccs_profile" "$@"
  else
    _secure_run ai "$(_claude_cli_path)" "$@"
  fi
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
