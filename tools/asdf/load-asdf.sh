#!/usr/bin/env bash
# Sourceable helper: put asdf (0.16+ or legacy) on PATH / load asdf into shell.
# Usage:  . "$HOME/.dotfiles/tools/asdf/load-asdf.sh"
# Exits with status 1 if asdf cannot be made available.
#
# Order:
#  1) Already on PATH
#  2) Homebrew: bin/asdf (0.16+) or libexec/asdf.sh (<=0.15)
#  3) ~/.asdf/bin/asdf (Linux tarball / manual 0.16+)
#  4) Legacy ~/.asdf/asdf.sh

_asd="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$_asd/bin:$_asd/shims:$PATH"

if command -v asdf >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

if command -v brew >/dev/null 2>&1; then
  _asdf_brew_root="$(brew --prefix asdf 2>/dev/null || true)"
  if [ -n "$_asdf_brew_root" ] && [ -x "$_asdf_brew_root/bin/asdf" ]; then
    export PATH="$_asdf_brew_root/bin:$_asd/shims:$PATH"
    unset _asdf_brew_root _asd
    return 0 2>/dev/null || exit 0
  fi
  if [ -n "$_asdf_brew_root" ] && [ -f "$_asdf_brew_root/libexec/asdf.sh" ]; then
    # shellcheck disable=SC1090,SC1091
    . "$_asdf_brew_root/libexec/asdf.sh"
    unset _asdf_brew_root _asd
    return 0 2>/dev/null || exit 0
  fi
  unset _asdf_brew_root
fi

if [ -x "$_asd/bin/asdf" ]; then
  export PATH="$_asd/bin:$_asd/shims:$PATH"
  unset _asd
  return 0 2>/dev/null || exit 0
fi

if [ -f "$_asd/asdf.sh" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$_asd/asdf.sh"
  unset _asd
  return 0 2>/dev/null || exit 0
fi

if [ -f /usr/local/opt/asdf/libexec/asdf.sh ]; then
  # shellcheck disable=SC1090,SC1091
  . /usr/local/opt/asdf/libexec/asdf.sh
  unset _asd
  return 0 2>/dev/null || exit 0
fi

echo "⚠️  asdf not found. On Linux run tools/asdf/install-asdf-linux.sh; on macOS: brew install asdf" >&2
unset _asd
return 1 2>/dev/null || exit 1
