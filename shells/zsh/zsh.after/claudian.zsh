# Claudian (Obsidian) ↔ ccs instance switching.
# Claude Code keychains OAuth tokens by the LITERAL CLAUDE_CONFIG_DIR string,
# so a symlink indirection breaks auth. Instead this rewrites the env var in
# the vault's .claudian/claudian-settings.json to the real instance path.
# Restart Obsidian (or reload the Claudian plugin) after switching.
claudian-switch() {
  local target="$1" vault="${2:-$HOME/vaults/cairn}"
  local base="$HOME/.ccs/instances"
  local settings="$vault/.claudian/claudian-settings.json"
  case "$target" in
    main) target="jbctech-main" ;;
    code) target="jbctech-code" ;;
    jp)   target="jp" ;;
    ""|status)
      grep -o 'CLAUDE_CONFIG_DIR=[^"]*' "$settings" 2>/dev/null || echo "(no CLAUDE_CONFIG_DIR set in $settings)"
      echo "usage: claudian-switch main|code|jp [vault-path]"
      return 0 ;;
  esac
  [[ -d "$base/$target" ]] || { echo "no ccs instance '$target'" >&2; return 1; }
  [[ -f "$settings" ]] || { echo "no Claudian settings at $settings" >&2; return 1; }
  python3 - "$settings" "$base/$target" <<'PY'
import json, sys, re
p, inst = sys.argv[1], sys.argv[2]
d = json.load(open(p))
env = d.get('sharedEnvironmentVariables', '')
line = f'CLAUDE_CONFIG_DIR={inst}'
if 'CLAUDE_CONFIG_DIR=' in env:
    env = re.sub(r'CLAUDE_CONFIG_DIR=[^\n]*', line, env)
else:
    env = (env + '\n' + line).strip()
d['sharedEnvironmentVariables'] = env
json.dump(d, open(p, 'w'), indent=2)
PY
  echo "Claudian ($vault) -> $target  — restart Obsidian (or reload the Claudian plugin) to take effect"
}
