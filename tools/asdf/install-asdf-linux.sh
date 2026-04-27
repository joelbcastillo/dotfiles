#!/usr/bin/env bash
# Idempotent: install the official asdf v0.16+ Linux binary to ~/.asdf/bin if
# asdf is not already on PATH (e.g. from Homebrew on macOS).
#
# Usage: bash path/to/install-asdf-linux.sh
#   or from repo: ./tools/asdf/install-asdf-linux.sh

set -euo pipefail

ASDF_V="${ASDF_VERSION:-0.16.7}"
_asd="${ASDF_DATA_DIR:-$HOME/.asdf}"

if command -v asdf >/dev/null 2>&1; then
  echo "✅ asdf already on PATH: $(command -v asdf)"
  exit 0
fi

if [ -x "$_asd/bin/asdf" ]; then
  echo "✅ asdf present at $_asd/bin/asdf (add bin + shims to PATH)"
  exit 0
fi

[ "$(uname -s)" = "Linux" ] || {
  echo "This tarball installer is for Linux only. On macOS use: brew install asdf" >&2
  exit 1
}

arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$arch" in
  amd64)   uarch="amd64" ;;
  arm64)   uarch="arm64" ;;
  aarch64) uarch="arm64" ;;
  *)
    echo "Unsupported CPU architecture: $arch" >&2
    exit 1
    ;;
esac

url="https://github.com/asdf-vm/asdf/releases/download/v${ASDF_V}/asdf-v${ASDF_V}-linux-${uarch}.tar.gz"
echo "Installing asdf v${ASDF_V} for linux-${uarch}..."
mkdir -p "$_asd/bin" "$_asd/shims"
td="$(mktemp -d)"
# shellcheck disable=SC2064
trap 'rm -rf "$td"' EXIT
curl -fsSL "$url" -o "$td/asdf.tgz"
tar -xzf "$td/asdf.tgz" -C "$_asd/bin"
chmod +x "$_asd/bin/asdf"
echo "✅ Installed: $_asd/bin/asdf"
