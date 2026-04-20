# Linux shims for macOS-only CLIs that scripts and aliases call by name.
# macOS provides pbcopy/pbpaste/open natively; on Linux we wrap the
# nearest equivalents so the rest of the config doesn't need to branch.

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v wl-copy >/dev/null 2>&1 && [[ -n "$WAYLAND_DISPLAY" ]]; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
  elif command -v xclip >/dev/null 2>&1; then
    alias pbcopy='xclip -selection clipboard -in'
    alias pbpaste='xclip -selection clipboard -out'
  elif command -v xsel >/dev/null 2>&1; then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
  fi

  if command -v xdg-open >/dev/null 2>&1; then
    alias open='xdg-open'
  fi
fi
