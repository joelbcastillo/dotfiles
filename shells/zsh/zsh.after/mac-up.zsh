# mac-up — ask Tailscale whether a named node is online.
# Usage: mac-up [hostname]   (default: jbc-dev-mac)
#
# Prints one of: online | offline | unknown
# Exit codes: 0 online, 1 offline, 2 not in tailnet, 3 tailscale unreachable.
#
# Intended as the whole monitoring story for headless tailnet boxes.

mac-up() {
  local host="${1:-jbc-dev-mac}"
  local short="${host%%.*}"

  if ! command -v tailscale >/dev/null 2>&1; then
    printf 'tailscale: not installed\n' >&2
    return 3
  fi

  local status
  status="$(tailscale status --json 2>/dev/null)" || {
    printf 'tailscale: daemon not reachable\n' >&2
    return 3
  }

  local result
  result="$(printf '%s' "$status" | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
target = sys.argv[1]
for peer in list(data.get("Peer", {}).values()) + [data.get("Self", {})]:
    if peer.get("HostName") == target:
        print("online" if peer.get("Online") else "offline")
        break
else:
    print("unknown")
' "$short" 2>/dev/null)" || {
    printf 'mac-up: parse failed\n' >&2
    return 3
  }

  printf '%s\n' "$result"
  case "$result" in
    online)  return 0 ;;
    offline) return 1 ;;
    *)       return 2 ;;
  esac
}
