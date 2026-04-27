#!/usr/bin/env bash
# Install or upgrade npm-published Claude companion CLIs to @latest.
# Idempotent. Safe to run repeatedly (e.g. weekly or before a dmux-heavy day).
#
# Used by: .dotbot/configs/claude-tools.yaml
# Manual:  ~/.dotfiles/scripts/upgrade-claude-npm-tools.sh
# Zsh:     upgrade-claude-npm-tools (see shells/zsh/zsh.before/claude-tools.zsh)
#
# Requires: npm on PATH (Node from asdf, Homebrew, etc.)

set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
  echo "upgrade-claude-npm-tools: npm not found. Install Node.js first (e.g. ./install profile full or asdf nodejs)." >&2
  exit 1
fi

echo "npm install -g (Claude tools @latest)..."
npm install -g \
  dmux@latest \
  happy-coder@latest \
  "@getpaseo/cli@latest"

echo "Installed versions:"
for cmd in happy dmux paseo; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  %s: %s\n' "$cmd" "$($cmd --version 2>/dev/null || echo ok)"
  else
    printf '  %s: not on PATH yet (try a new shell)\n' "$cmd"
  fi
done
