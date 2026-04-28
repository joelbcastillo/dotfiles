# mac-* helpers for managing a headless Mac (default: jbc-dev-mac) over SSH.
#
#   mac-reboot       — `fdesetup authrestart`: reboot now, skipping the
#                      FileVault prompt on next boot. Refuses if the box is
#                      in travel mode (the in-memory key handoff is the
#                      whole risk window if it's not on a trusted network).
#   mac-travel-mode  — disables auto-login and arms a sentinel that blocks
#                      `mac-reboot`. Use before taking the box to a
#                      conference / hotel / anywhere physical access is
#                      hostile.
#   mac-home-mode    — clears the sentinel. Reminds you to manually
#                      re-enable auto-login (sysadminctl needs the user
#                      password and we don't want it on a command line).
#   mac-fix-term     — ships the local terminfo entry for $TERM to the
#                      remote so cursor redraws / autosuggestions don't
#                      produce doubled letters.

mac-reboot() {
  local host="${1:-jbc-dev-mac}"

  # Refuse if travel mode is armed. authrestart holds the FV key in
  # memory across the reboot — fine on your home Tailnet, real risk if
  # the box could be physically grabbed during the boot window.
  if ssh -o BatchMode=yes "$host" 'test -f ~/.travel_mode' 2>/dev/null; then
    printf 'refusing: %s is in travel mode. run mac-home-mode first, or reboot at the console.\n' "$host" >&2
    return 1
  fi

  printf 'rebooting %s now (FileVault skipped on next boot via authrestart)...\n' "$host"
  ssh -t "$host" 'sudo fdesetup authrestart -delayminutes 0'
}

mac-travel-mode() {
  local host="${1:-jbc-dev-mac}"
  printf 'arming travel mode on %s...\n' "$host"
  ssh -t "$host" '
    sudo sysadminctl -autologin off &&
    touch ~/.travel_mode &&
    cat <<MSG

travel mode ON
  - auto-login disabled (FV password required at console after reboot)
  - mac-reboot blocked
  REMINDER: shut down (not sleep) when the box is unattended.
MSG
  '
}

mac-home-mode() {
  local host="${1:-jbc-dev-mac}"
  printf 'disarming travel mode on %s...\n' "$host"
  ssh -t "$host" '
    rm -f ~/.travel_mode &&
    cat <<MSG

travel mode OFF. mac-reboot allowed.

To re-enable auto-login, run on the Mac (sysadminctl needs the password
on its command line, so do it at the console or a fresh ssh session):
  sudo sysadminctl -autologin set -userName "$USER" -password '"'"'YOUR_PASSWORD'"'"'
MSG
  '
}

mac-fix-term() {
  local host="${1:-jbc-dev-mac}"
  local term="${2:-$TERM}"
  if ! infocmp -x "$term" >/dev/null 2>&1; then
    printf 'no local terminfo entry for %s — nothing to ship.\n' "$term" >&2
    return 1
  fi
  printf 'shipping terminfo for %s to %s...\n' "$term" "$host"
  infocmp -x "$term" | ssh "$host" 'tic -x -' &&
    printf 'done. open a fresh ssh session for it to take effect.\n'
}
