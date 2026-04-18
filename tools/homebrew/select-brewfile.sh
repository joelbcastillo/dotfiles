#!/usr/bin/env bash
# Symlink tools/homebrew/Brewfile → Brewfile.mac or Brewfile.linux based on OS.
# Safe to re-run; idempotent. Prints the chosen target and exits 0.

set -eu

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$OSTYPE" == "darwin"* ]]; then
    target="Brewfile.mac"
else
    target="Brewfile.linux"
fi

ln -sfn "$target" "$HERE/Brewfile"
echo "Brewfile -> $target"
