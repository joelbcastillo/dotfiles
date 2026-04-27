# asdf: 0.16+ (bin + shims) or Homebrew, or legacy asdf.sh — keep in sync with
# tools/asdf/load-asdf.sh (bash) for zsh logins.
_asdf_d="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$_asdf_d/bin:$_asdf_d/shims:$PATH"

if ! command -v asdf &>/dev/null; then
  if command -v brew &>/dev/null; then
    _b="$(brew --prefix asdf 2>/dev/null || true)"
    if [[ -n "$_b" && -x "$_b/bin/asdf" ]]; then
      export PATH="$_b/bin:$_asdf_d/shims:$PATH"
    elif [[ -n "$_b" && -f "$_b/libexec/asdf.sh" ]]; then
      # shellcheck disable=SC1090
      . "$_b/libexec/asdf.sh"
    fi
  fi
  if ! command -v asdf &>/dev/null && [[ -f "$_asdf_d/asdf.sh" ]]; then
    # shellcheck disable=SC1090
    . "$_asdf_d/asdf.sh"
  fi
  unset _b
fi

fpath=("$_asdf_d/completions" $fpath)
autoload -Uz compinit && compinit -C
unset _asdf_d
