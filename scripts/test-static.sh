#!/usr/bin/env bash
# Cross-platform static checks (syntax + shellcheck) aligned with the Linux CI
# job. Safe to run on macOS and Linux — no root required.
# Usage: ./scripts/test-static.sh   (from repo root)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v shellcheck &>/dev/null; then
  echo "test-static: install shellcheck (brew install shellcheck  OR  apt install shellcheck)" >&2
  exit 1
fi

echo "==> Syntax: install (bash + zsh)"
bash -n install
if command -v zsh &>/dev/null; then
  zsh -n install
fi

echo "==> Syntax: key helper scripts (bash -n)"
for f in \
  scripts/bootstrap-linux.sh \
  tools/tmux/clip-copy \
  tools/asdf/load-asdf.sh; do
  [[ -f "$f" ]] || { echo "Missing $f" >&2; exit 1; }
  bash -n "$f"
done
# Optional scripts (not all branches ship every helper)
if [[ -f tools/homebrew/select-brewfile.sh ]]; then
  bash -n tools/homebrew/select-brewfile.sh
fi
if [[ -f tools/asdf/install-asdf-linux.sh ]]; then
  bash -n tools/asdf/install-asdf-linux.sh
fi

echo "==> shellcheck: scripts matching CI path excludes"
# Mirror .github/workflows/test.yml
# Match CI: warn, do not fail the step (some legacy scripts are noisy).
set +e
while IFS= read -r script; do
  shellcheck -e SC2317,SC1091,SC2329,SC2086,SC2034,SC2155,SC2162,SC2181,SC2001,SC2248,SC2030,SC2031 "$script" \
    || echo "::warning file=$script::shellcheck reported issues"
done < <(find . -type f \( -name "*.sh" -o -name "install" \) \
  -not -path "./.dotbot/dotbot/*" \
  -not -path "./.dotbot/plugins/*" \
  -not -path "./shells/prezto/prezto/*" \
  -not -path "./shells/oh-my-zsh/custom/plugins/zsh-*" \
  2>/dev/null)
set -e

echo "==> test-static: OK"
