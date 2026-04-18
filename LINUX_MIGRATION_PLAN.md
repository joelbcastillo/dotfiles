# Linux Compatibility Plan — Public `dotfiles`

Branch: `linux-compat` (created fresh from current `main`, separate from the
audit branch).

## Decisions locked in from Phase 1 Q&A

- **Private repo:** audited separately by you. I only touch public.
- **Homebrew on Linux:** **Option C — no Linuxbrew.** apt for what it has
  cleanly, one-liner installers for the rest.
- **Brewfile:** split into `Brewfile.mac` (current full set including casks +
  mas) and `Brewfile.linux` (CLI superset — reference list only, not actually
  consumed by the Linux bootstrap, but kept for parity). `Brewfile` becomes an
  OS-selected symlink.
- **1Password SSH / signing:** use `op` CLI on both OSes; **no biometric
  (TouchID) requirement**; signing uses `op-ssh-sign` — detect Mac path
  (`/Applications/1Password.app/Contents/MacOS/op-ssh-sign`) or Linux path
  (`/opt/1Password/op-ssh-sign`, fallback to `$(command -v op-ssh-sign)`).
- **Target Linux profile:** **Dev** (shell + git + asdf + core CLI + CLI AI
  tools). Specifically including `claude`, `cursor-agent`, `copilot` CLI.
  GUI-only pieces of `full` (Hammerspoon, Finicky, Colima, TouchID,
  macOS-defaults, raycast, casks, mas) are **not** installed on Linux but
  their configs stay in the repo.
- **`chsh`:** `chsh -s $(command -v zsh)` on Linux.
- **CI:** add `ubuntu-latest` job now.
- **Remove 16 absolute-path symlinks** from public repo (they dangled on Mac
  too unless the user path matched, and they leak the Mac username).

## Open questions remaining
- **Q8 (GUI-only configs on Linux):** assumed keep-in-repo, skip-linking. If
  that's wrong, say so before Phase 3.
- **Ubuntu CI depth:** draft job will run `shellcheck` + a syntax check of
  `install` and `bootstrap-linux.sh`. Running the full `bootstrap-linux.sh`
  in CI is expensive (apt, network) and probably not worth it — ok?

## Approach / principles

1. **Guard, don't fork.** Where possible, keep one file with
   `[[ "$OSTYPE" == "darwin"* ]]` (or `[[ "$(uname -s)" == "Linux" ]]`)
   branches. Fork files only when the two implementations share almost
   nothing.
2. **Opt-out, not opt-in for Mac features.** The Mac bootstrap today Just
   Works; Linux becomes a parallel path. Mac-only Dotbot configs
   (`touchid`, `hammerspoon`, `colima`, `finicky`, `macos-defaults`) short-
   circuit with a "skipped on Linux" echo rather than erroring. This means
   you can keep the `full` profile and it degrades safely on Linux.
3. **No new abstractions.** No "cross-platform" helper libraries; each
   file takes the smallest possible change.
4. **Atomic commits.** Each commit is reviewable on its own and leaves the
   Mac path working.

## Commit sequence

| # | Scope | One-liner |
|---|---|---|
| 1 | `install` | Allow non-darwin, OS-gate `xcode-select`/`sw_vers`, skip brew/cask install of 1Password on Linux. |
| 2 | `shells/zsh/zshenv`, `zprofile`, `zprofile.template` | Detect brew on Linux PATH; set `SSH_AUTH_SOCK` per OS (Mac 1P socket, Linux `~/.1password/agent.sock` or unset). |
| 3 | `shells/zsh/zsh.before/path.zsh` | Stop hard-coding `/opt/homebrew` on Linux; skip `$HOME/Library/Python` loop on Linux. |
| 4 | `shells/zsh/zsh.before/1password.zsh` | OS-gate `SSH_AUTH_SOCK`. |
| 5 | `shells/zsh/zsh.before/aliases.zsh.template` | Wrap `killall Finder`, `defaults write`, `xattr` alias in darwin guard. |
| 6 | `shells/oh-my-zsh/custom/functions.zsh` | `localip`/`sysinfo` branch on `$OSTYPE`; `update-dev` skip `brew` on Linux. |
| 7 | `tools/tmux/tmux.conf` | Pipe to `pbcopy` on Mac, `xclip -selection clipboard` on Linux with X, `wl-copy` on Wayland (via small `if-shell`). |
| 8 | `tools/git/gitconfig` | Use include-if-os + a pair of `gitconfig.macos` / `gitconfig.linux` for the `gpg.ssh.program` path. Drop biometric. |
| 9 | `tools/homebrew/` | Rename existing Brewfile → `Brewfile.mac`; add `Brewfile.linux` (CLI superset); add `select-brewfile.sh` that symlinks `Brewfile` → the OS-appropriate file; update `.gitignore`. |
| 10 | `.dotbot/configs/brew.yaml` | Call `select-brewfile.sh`; Linux branch is a no-op (or invokes bootstrap-linux). |
| 11 | `.dotbot/profiles/linux` | New profile: `zsh oh-my-zsh starship git asdf languages/python languages/nodejs gh ripgrep tmux ssh ai-tools claude claude-code claude-tools cursor-agent utils`. |
| 12 | `.dotbot/configs/{touchid,hammerspoon,colima,finicky}.yaml` + `tools/macos-defaults/run.sh` | Early-exit with "skipped on Linux" when `$(uname -s)` != Darwin. |
| 13 | `.dotbot/configs/vscode.yaml`, `cursor.yaml` | Branch link target between `~/Library/Application Support/...` and `~/.config/Code/User/...` (VS Code) / `~/.config/Cursor/User/...`. |
| 14 | `.dotbot/configs/git.yaml` | Branch `lazygit` path between Mac `Library/Application Support/...` and Linux `~/.config/lazygit/config.yml`. |
| 15 | `.dotbot/configs/claude.yaml`, `claude-code.yaml`, `oh-my-zsh.yaml` | Replace Mac-only path refs with OS-detecting snippets. |
| 16 | `.dotbot/configs/asdf.yaml` + `scripts/install-asdf.sh` | If `brew` present, source from brew prefix; else clone to `~/.asdf` (already does this partially, but gate it) and symlink `asdf.sh` from that path; drop hard-coded `/opt/homebrew/opt/asdf`. |
| 17 | `.dotbot/configs/languages/{python,nodejs,go,ruby,rust}.yaml` | Use `$ASDF_DIR/asdf.sh` with fallback, not `/opt/homebrew/opt/asdf/libexec/asdf.sh`. |
| 18 | `.dotbot/configs/zsh.yaml` | `chsh -s $(command -v zsh)`; add zsh path to `/etc/shells` if missing. |
| 19 | `.dotbot/configs/ai-tools.yaml` | Linux install: `claude` via `npm i -g @anthropic-ai/claude-code` (since no brew); `cursor-agent` via its curl installer (already works); `copilot` via `gh extension install github/gh-copilot` or direct; no `/opt/homebrew/bin/claude` symlink on Linux. |
| 20 | `scripts/bootstrap-linux.sh` (new) | apt installs (zsh, tmux, git, curl, build-essential, python3, jq, tree, wget, unzip, ripgrep, fd-find, fzf, direnv, bat), Starship via curl, gh via apt keyring, eza via cargo-or-apt, zoxide via curl, 1Password CLI via apt, asdf via git clone. Idempotent. |
| 21 | `scripts/{backup,detect-homebrew,setup-homebrew-*}.sh` | `backup.sh`: cross-platform VS Code path + `sha256sum` fallback. `detect-homebrew.sh`: return a "no-op on Linux" path when no brew. The `setup-homebrew-*` scripts stay Mac-only with an early-exit guard. |
| 22 | Tracked symlinks | Remove the 16 absolute-path symlinks. `./install private` still creates them at install time, so no functional regression on Mac. |
| 23 | `.github/workflows/test.yml` | Add `ubuntu-latest` matrix entry running shellcheck + install syntax check. |
| 24 | `README.md` | Add a "Linux (Ubuntu 24.04)" section with the three-line bootstrap. |

Commits are intentionally granular (~2-20 lines each) to keep the PR
reviewable. Nothing touches `main`. Nothing pushes force. Private repo not
modified.

## Out of scope for this pass
- Installing/configuring GUI apps on Linux (VS Code server, Cursor desktop,
  etc.). If you later want `code-server`, it belongs in a follow-up.
- Migrating `hammerspoon`/`finicky`/etc. configs to Linux equivalents
  (sxhkd, xdotool, etc.). Not asked for.
- Changing the `full` profile to run on Linux. The `linux` profile is
  separate.
- Auditing `dotfiles-private`. You'll do that.

## Rollback plan
Every commit leaves `main` untouched. The draft PR can be closed without
side-effects. If a specific change turns out wrong, `git revert <sha>` on
the `linux-compat` branch — the commits are granular enough that each
reverts cleanly.
