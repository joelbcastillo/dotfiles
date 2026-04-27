# Linux Migration Plan — Public dotfiles

**Repo:** `dotfiles` (public)
**Branch:** `linux-compat`
**Plan date:** 2026-04-20 (revised after combining with prior remote work)
**Companion:** `dotfiles-private/LINUX_MIGRATION_PLAN.md`

> **Revision note:** This branch was discovered to already contain ~22
> commits of related Linux work from a prior session. The design
> diverged in three places — Linuxbrew support, a separate `linux`
> profile, and the op-ssh-sign approach — which were resolved in the
> user's favor: no Linuxbrew, self-skipping configs inside the existing
> `full` profile, and dynamic detection of `op-ssh-sign` with
> `ssh-keygen` fallback (the prior session's approach, which matches the
> user's clarified intent: use 1Password SSH keys for signing but not
> the agent on a headless droplet).
>
> The plan below describes the original 16-commit structure as a
> reference; the actual `git log` on this branch starts from the prior
> work and layers the additional changes on top.

This plan executes Phase 3 of the Linux compatibility pass. Each commit
listed is atomic and revertable. Commits paired with the private repo are
called out explicitly — they should land together, but each PR is a draft
so you control merge order.

---

## OS-branching idiom (locked)

Used consistently across both repos:

| Layer | Idiom | Notes |
|-------|-------|-------|
| zsh shell files | `[[ $platform == 'darwin' ]]` / `[[ $platform == 'linux' ]]` | `$platform` is set once by `shells/zsh/zsh.before/00-os.zsh` (sourced first via `00-` prefix in the existing glob loop). Values: `darwin` / `linux` / `unknown`. Matches the existing convention in `aliases.zsh.template`. |
| bash scripts (`install`, `scripts/*.sh`) | `[[ "$OSTYPE" == "darwin"* ]]` / `[[ "$OSTYPE" == "linux-gnu"* ]]` | No shared helper — bash scripts are run standalone, can't assume zsh init has happened. |
| dotbot YAML configs | `if [[ "$OSTYPE" == "darwin"* ]]; then …; fi` inside `command:` snippets | Same as bash. Used to skip Mac-only steps on Linux (and vice versa where applicable). |

**Why one helper file (not inline detection in every zsh file):** keeps a single source of truth, removes the duplicated `uname` detection currently in `aliases.zsh.template`, and follows the existing zsh.before/ directory pattern (each file is small, sourced in order). The `00-` prefix guarantees it loads before any sibling that uses `$platform`.

**Where the helper lives:** `shells/zsh/zsh.before/00-os.zsh` (public repo). Private repo doesn't ship its own helper — it sources from the public one transitively (private aliases run after public init).

---

## Commit list (public repo)

Each line: `[#] <commit message>` plus inline annotation if cross-repo paired.

1. `[1] feat(shell): add 00-os.zsh helper exporting $platform`
   New file `shells/zsh/zsh.before/00-os.zsh`. Sets `$platform` from `uname` to `darwin`/`linux`/`unknown`. Sourced by the existing `~/.zsh.before/*.zsh` glob loop in `zshrc`. No behavior change — just adds the variable.

2. `[2] refactor(zshenv): scope Homebrew detection to darwin`
   Wrap the brew shellenv detection block (`zshenv:12-29`) in `[[ "$OSTYPE" == "darwin"* ]]`. On Linux, fall through and rely on apt-installed binaries on default PATH. Keeps `umask 0002` and the GitHub PAT block (line 37+) outside the guard since they're OS-agnostic.

3. `[3] refactor(zprofile,zshrc.minimal): mirror zshenv Homebrew guard`
   Same pattern — wrap brew detection in darwin guard. Removes redundancy at the same time.

4. `[4] refactor(path.zsh): make Mac-only PATH entries darwin-guarded`
   Lines 11-14 (`/opt/homebrew/{bin,sbin}`) already use `$platform == 'darwin'` — confirms the helper from commit 1 is in scope. Lines 23-27 (`$HOME/Library/Python/*/bin`) wrapped under darwin. Linux doesn't need this; pip user-install bin is `$HOME/.local/bin` and is already added unconditionally on line 8.

5. `[5] feat(shell): make 1password.zsh SSH_AUTH_SOCK OS-aware`
   `shells/zsh/zsh.before/1password.zsh` becomes:
   ```zsh
   if [[ $platform == 'darwin' ]]; then
     export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
   elif [[ $platform == 'linux' ]] && [[ -S "$HOME/.1password/agent.sock" ]]; then
     export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
   fi
   # Headless Linux: leave SSH_AUTH_SOCK unset; ssh-agent or fetched-key flow takes over.
   ```
   **Paired with private commit [P-2]** (`ssh/config` IdentityAgent branching). Must ship together to avoid SSH-to-GitHub breaking on a Linux droplet.

6. `[6] refactor(zshrc,zshrc.minimal): drop duplicate SSH_AUTH_SOCK line`
   Remove `zshrc:32` and `zshrc.minimal:24` so `1password.zsh` is the single source of truth.

7. `[7] feat(shell): editor fallback chain — cursor → code → nvim → vim`
   `zshrc:24-28` becomes a small loop that picks the first available binary. Same in `zshrc.minimal:21-23`. SSH-connection still forces `vim`.

8. `[8] feat(shell): add os-compat.zsh providing pbcopy/pbpaste/open on Linux`
   New file `shells/zsh/zsh.before/os-compat.zsh`. Defines the three aliases only when `$platform == 'linux'`. Detects Wayland (`wl-copy`/`wl-paste`) vs X11 (`xclip`). `open` aliased to `xdg-open`. Mac uses native commands as today.

9. `[9] feat(git): add gitconfig.os.{darwin,linux} for op-ssh-sign path`
   New files `tools/git/gitconfig.os.darwin` and `tools/git/gitconfig.os.linux`. Each sets `[gpg "ssh"] program = …` for that OS. Public dotbot symlinks the right one to `~/.gitconfig.os` based on `$OSTYPE`. **Paired with private commit [P-3]** (private gitconfigs `[include]` it and drop their hardcoded paths).

10. `[10] refactor(install): accept Linux as a supported platform`
    `check_platform()` now branches:
    - `darwin*` → existing `sw_vers` + minimum version check
    - `linux-gnu*` → distro detection (Ubuntu only for now), require Ubuntu 24.04+
    - other → fail with helpful message.
    `check_xcode_tools()` skipped on Linux. `bootstrap()` dispatches to `bootstrap_macos()` (existing flow) or `bootstrap_linux()` (calls the new ubuntu installer in [11]).

11. `[11] feat(scripts): add scripts/bootstrap-ubuntu.sh apt installer`
    New script. Idempotent. Driven by `NONINTERACTIVE=1` env var (or auto-detected when stdin is not a tty — IaC-friendly). Runs:
    - `sudo apt-get update`
    - `sudo apt-get install -y` of the base list (build-essential, curl, wget, git, zsh, tmux, vim, unzip, jq, ripgrep, fzf, fd-find, bat, eza, direnv, shellcheck, pre-commit, python3, python3-pip, python3-venv, xclip, wl-clipboard, xdg-utils, fontconfig, ca-certificates, gnupg, lsb-release)
    - 1Password CLI install (apt repo)
    - asdf clone to `~/.asdf` (matches Mac flow which uses the submodule)
    - Starship installer to `~/.local/bin`
    - Two Nerd Fonts (FiraCode, JetBrainsMono) to `~/.local/share/fonts` + `fc-cache -fv`
    Interactive mode: prompts before sudo. NONINTERACTIVE: assumes consent, exits non-zero if sudo isn't available.

12. `[12] refactor(scripts): make backup.sh + check-mcp-installed.sh OS-aware`
    `backup.sh:43-44, 110-112` and `check-mcp-installed.sh:82-85, 162-184` switch path lookup based on `$OSTYPE`:
    - macOS: `~/Library/Application Support/{Code,Claude,Cursor}/...`
    - Linux: `~/.config/{Code,Claude,Cursor}/...`
    Tiny helper function inside each script; no shared library.

13. `[13] refactor(dotbot): guard mac-only configs to skip on Linux`
    Wraps the `command:` snippets in `.dotbot/configs/{touchid,finicky,hammerspoon,brew,macos-defaults}.yaml` with a `[[ "$OSTYPE" == "darwin"* ]]` early-exit. Files stay; they just no-op on Linux. Profiles that include them work on both OSes without per-OS profile duplication.

14. `[14] feat(dotbot): apt.yaml — Linux-only counterpart to brew.yaml`
    New `.dotbot/configs/apt.yaml` that calls `scripts/bootstrap-ubuntu.sh` (only on Linux). Add to the `full` profile so `./install profile full` runs the right installer on each OS.

15. `[15] refactor(dotbot): editor settings configs use XDG path on Linux`
    `.dotbot/configs/{vscode,cursor}.yaml` symlink targets become OS-aware:
    - Mac: `~/Library/Application Support/{Code,Cursor}/User/settings.json`
    - Linux: `~/.config/{Code,Cursor}/User/settings.json`
    **Paired with private commit [P-5]** (Linux terminal profile keys added to the source JSONs).

16. `[16] docs: README + START_HERE updates for Linux support`
    Add a "Linux (Ubuntu 24.04)" section to README and START_HERE. Brief: clone, run `./install bootstrap` (or `NONINTERACTIVE=1 ./install bootstrap` for IaC), then `./install private`, then a profile.

---

## Cross-repo dependency map

| Public commit | Pairs with private commit | Must ship together? |
|---------------|---------------------------|---------------------|
| [5] 1password.zsh OS-aware | [P-2] ssh/config IdentityAgent OS-aware | **Yes** — half-applied = broken SSH on Linux |
| [9] gitconfig.os.{darwin,linux} | [P-3] private gitconfigs `[include]` it | **Yes** — half-applied = broken commit signing on Linux (or Mac, depending on direction) |
| [15] editor dotbot configs XDG on Linux | [P-5] Linux terminal profile keys in JSONs | Recommended together — half-applied = editor opens with wrong shell, but functional |

All other commits in either repo are independent and can land in any order.

---

## PR strategy

- **Two draft PRs**, one per repo, both titled "Linux compatibility pass".
- Each PR description links the parallel PR in the other repo.
- Public PR can be opened first (most commits live there).
- Merge order doesn't matter for non-paired commits, but for the 3 paired pairs (above), merge both PRs before testing on a fresh droplet.

---

## Bootstrap script plan

**Status today:** `install` exists. Hard-blocks Linux at line 64. Mac flow does Homebrew + 1Password CLI install + dotbot submodules.

**Minimum viable extension** (commits [10]-[11] above):
- `install` becomes OS-aware: `check_platform` accepts both `darwin*` and `linux-gnu*`.
- `bootstrap()` dispatches to existing Mac flow or new `bootstrap_linux()` that invokes `scripts/bootstrap-ubuntu.sh`.
- `bootstrap-ubuntu.sh` is the new Linux entry point — apt + asdf + starship + nerd fonts.
- `NONINTERACTIVE=1` (or non-tty stdin) skips prompts for IaC.
- Sudo is invoked **only** by `bootstrap-ubuntu.sh`, not `install` itself. Preserves the current "no sudo from install" property on Mac.

**Out of scope for this pass:**
- Other distros (Debian non-Ubuntu, Fedora, Arch). Add later if needed.
- linuxbrew. Skipped per Q1 answer.
- 1Password GUI on Linux. CLI only.

---

## Summary

| Item | Count |
|------|-------|
| Public repo commits | 16 |
| Paired commits with private repo | 3 |
| New files added | 5 (00-os.zsh, os-compat.zsh, gitconfig.os.darwin, gitconfig.os.linux, bootstrap-ubuntu.sh, apt.yaml) |
| Files modified | ~10 |
| PRs | 2 (both draft, can ship independently except for the 3 paired pairs) |
