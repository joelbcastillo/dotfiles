# mac-reboot — planned reboot of a headless Mac that skips the FileVault
# unlock prompt on next boot. Uses `fdesetup authrestart`, which keeps the
# disk key in memory across the restart so sshd comes back up immediately
# and the box is reachable again without anyone at the console.
#
# Usage: mac-reboot [hostname]   (default: jbc-dev-mac)
#
# Requires: sudo on the remote host (you'll be prompted via ssh -t).

mac-reboot() {
  local host="${1:-jbc-dev-mac}"

  printf 'rebooting %s now (FileVault skipped on next boot via authrestart)...\n' "$host"
  ssh -t "$host" 'sudo fdesetup authrestart -delayminutes 0'
}
