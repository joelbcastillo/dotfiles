# Claudian (Obsidian) ↔ ccs instance switching.
# Claudian's settings point CLAUDE_CONFIG_DIR at the stable symlink
# ~/.ccs/claudian-active; this function swings the symlink between ccs
# instances. Restart the Claudian session (or Obsidian) after switching.
claudian-switch() {
  local target="$1"
  local base="$HOME/.ccs/instances"
  case "$target" in
    main) target="jbctech-main" ;;
    code) target="jbctech-code" ;;
    jp)   target="jp" ;;
    ""|status)
      echo "claudian-active -> $(readlink "$HOME/.ccs/claudian-active" 2>/dev/null || echo '(unset)')"
      echo "usage: claudian-switch main|code|jp"
      return 0 ;;
  esac
  if [[ ! -d "$base/$target" ]]; then
    echo "claudian-switch: no ccs instance '$target' in $base" >&2
    return 1
  fi
  ln -sfn "$base/$target" "$HOME/.ccs/claudian-active"
  echo "claudian-active -> $target  (restart the Claudian session in Obsidian to take effect)"
}
