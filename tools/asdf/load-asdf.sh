#!/usr/bin/env bash
# Sourceable helper that locates asdf and loads it into the current shell.
# Usage:  . "$HOME/.dotfiles/tools/asdf/load-asdf.sh"
# Exits non-zero (from the sourcing shell) if asdf cannot be found.

_asdf_path=""

# 1. Homebrew-installed asdf (macOS default, optional on Linuxbrew)
if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [ -n "$_brew_prefix" ] && [ -f "$_brew_prefix/opt/asdf/libexec/asdf.sh" ]; then
        _asdf_path="$_brew_prefix/opt/asdf/libexec/asdf.sh"
    fi
fi

# 2. Git-cloned asdf (Linux default; ~/.asdf)
if [ -z "$_asdf_path" ] && [ -f "$HOME/.asdf/asdf.sh" ]; then
    _asdf_path="$HOME/.asdf/asdf.sh"
fi

# 3. Distro package (e.g. apt install asdf)
if [ -z "$_asdf_path" ] && [ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]; then
    _asdf_path="/usr/local/opt/asdf/libexec/asdf.sh"
fi

if [ -z "$_asdf_path" ]; then
    echo "⚠️  asdf not found. Install via brew (macOS) or git clone (Linux)." >&2
    unset _asdf_path _brew_prefix
    return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1090
. "$_asdf_path"
unset _asdf_path _brew_prefix
