# Phase 4 — Sandbox Smoke Test Results

Ran the `linux-compat` branch inside the CI sandbox, which happens to be
Ubuntu 24.04.4 LTS. This is a **smoke test, not a full verification** —
you'll still need to run `LINUX_MIGRATION_TEST_ON_DROPLET.md` on a real
droplet.

## What I ran

- Cloned the branch into `/home/user/dotfiles`.
- Initialized submodules.
- Invoked individual `.dotbot/install-config` configs directly to observe
  OS-branching behavior.
- Did **not** run `scripts/bootstrap-linux.sh` (would modify system state
  and apt-install ~15 packages; user instructed this is a smoke test
  only).

## Loads cleanly

- ✅ `./install` usage prints; does not reject Linux.
- ✅ `check_platform` logic correctly identifies Ubuntu 24.04.4 (verified
  via inline logic test; the full function also prints `PRETTY_NAME` from
  `/etc/os-release`).
- ✅ `tools/homebrew/select-brewfile.sh` creates
  `Brewfile -> Brewfile.linux`.
- ✅ `tools/tmux/clip-copy` falls through to `cat >/dev/null` when no
  clipboard helper is present (headless smoke).
- ✅ `tools/asdf/load-asdf.sh` correctly reports missing asdf and returns
  1 (before asdf is installed).
- ✅ `bash -n` syntax check passes for every modified shell script:
  `install`, `scripts/bootstrap-linux.sh`, `scripts/backup.sh`,
  `scripts/detect-homebrew.sh`, `tools/tmux/clip-copy`,
  `tools/asdf/load-asdf.sh`, `tools/homebrew/select-brewfile.sh`.

## Dotbot config behavior (OS guards)

Ran `.dotbot/install-config <name>` for each macOS-only config; confirmed
the skip messages fire:

| Config | Behavior on Linux | Result |
|---|---|---|
| `touchid` | Output suppressed by `stdin/stdout/stderr: false`, but script exits 0 without editing `/etc/pam.d/sudo`. | ✅ skipped safely |
| `hammerspoon` | Prints "⏭  Skipping Hammerspoon — macOS-only". | ✅ |
| `colima` | Prints "⏭  Skipping Colima — macOS-only..." (x3 shell steps). | ✅ |
| `finicky` | Prints "⏭  Skipping Finicky — macOS-only". | ✅ |
| `brew` | Prints "⏭  Skipping Homebrew setup — not on macOS" and "⏭  Skipping brew bundle — not on macOS". | ✅ |
| `vscode` | Created `~/.config/Code/User/settings.json` symlink (Linux XDG path). | ✅ |
| `cursor` | Created `~/.config/Cursor/User/settings.json` symlink. | ✅ |
| `git` (lazygit part) | Created `~/.config/lazygit/config.yml` symlink (Linux XDG path). | ✅ |
| `asdf` | Git-cloned asdf to `~/.asdf`, linked `~/.asdfrc` and `~/.tool-versions`. | ✅ |

## Errors (expected / not actionable)

- `zsh.yaml` failed because `command -v zsh` returned empty (zsh not
  installed in the sandbox — intentional, bootstrap-linux.sh would install
  it first). On a real droplet this fires after bootstrap installs zsh.
- Several link tasks hit "nonexistent target" because my sandbox has the
  repo at `/home/user/dotfiles`, not the conventional `~/.dotfiles`. This
  is pre-existing behavior from the tracked dotbot configs that use
  `~/.dotfiles` as an absolute-path prefix; works on a real install.
- `bash -n` can't validate zsh-only syntax (`*/bin(N)` glob qualifier in
  `path.zsh`, `autoload` in `functions.zsh`). Not a regression —
  pre-existing zsh-specific syntax. Would need `zsh -n` to validate.

## What I did NOT test

- `scripts/bootstrap-linux.sh` end-to-end — would install ~15 apt packages
  and reach out to GitHub / 1Password / starship / zoxide installers.
- `./install profile linux` end-to-end — would require zsh installed +
  the rest of the bootstrap stack.
- Runtime behavior of a live zsh session (no zsh in sandbox).
- `tmux send-keys | clip-copy | xclip` end-to-end roundtrip.
- 1Password SSH agent behavior.
- Starship prompt rendering.

## Overall signal

The Linux compatibility path **loads cleanly** at the level this smoke
test reached:
- OS guards work.
- Cross-platform link targets resolve to the right paths.
- Mac-only configs skip without error.

Real verification is the droplet test.
