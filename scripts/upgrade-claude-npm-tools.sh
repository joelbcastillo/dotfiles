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

echo "npm install -g (Claude Code CLI + companion tools @latest)..."
# Install one package per invocation so one failure (e.g. happy-coder + npm 11
# "workspace:" protocol) does not skip the rest.
npm install -g "@anthropic-ai/claude-code@latest"
npm install -g "dmux@latest"
if ! npm install -g "happy-coder@latest"; then
  echo "upgrade-claude-npm-tools: happy-coder install failed (known issue on some npm versions with workspace: deps). Skipping." >&2
fi
npm install -g "@getpaseo/cli@latest"
# ccs: switch between multiple Claude subscription accounts (2 Max + 1 Teams) via OAuth.
npm install -g "@kaitranntt/ccs@latest"
# ccr: route Claude Code to other model providers via API keys (opt-in, needs its own config).
npm install -g "@musistudio/claude-code-router@latest"

echo "Installed versions:"
for cmd in claude happy dmux paseo ccs ccr; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  %s: %s\n' "$cmd" "$($cmd --version 2>/dev/null || echo ok)"
  else
    printf '  %s: not on PATH yet (try a new shell)\n' "$cmd"
  fi
done
