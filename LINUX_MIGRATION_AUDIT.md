# Linux Compatibility Audit — Public `dotfiles` repo

Branch: `claude/linux-compat-audit-fK2SM`

**Scope note:** This audit covers only the public `joelbcastillo/dotfiles` repo.
The `dotfiles-private` repo was **not** audited — it is not checked out in the
sandbox, and the GitHub integration is scoped to the public repo only. A
separate audit of the private repo is required to complete Phase 1. See the
"Open questions" section below.

## Summary

- **Mac-specific assumptions identified:** ~85 actionable issues across ~50
  files (not counting docs that only *mention* macOS).
- The repo currently **refuses to bootstrap on non-darwin** (`install` line 64).
- Homebrew is load-bearing for almost everything (shell env, asdf, language
  runtimes, tool installs).
- 16 tracked symlinks in the public repo point at `/Users/joel.castillo.cq/
  .dotfiles-private/...` (absolute paths). On Linux they will dangle and break
  Dotbot's `relink: force: true` links. This also leaks the Mac username into
  the public repo, which is worth addressing regardless of Linux support.
- No cross-contamination found yet: the public repo references the private
  repo (by path), but **no content** from private appears to have been copied
  into the public tree. Private is pulled in at runtime via `./install private`
  and `.dotbot/configs/private.yaml`.

## Categories of Mac-specific assumption

### 1. Platform gate (1 file)
- `install` — hard-rejects non-darwin, requires `sw_vers`, `xcode-select`.

### 2. Homebrew paths baked in (≈15 files)
Hard-coded `/opt/homebrew`, `/usr/local/bin/brew`, or `$HOME/.homebrew`:
- `shells/zsh/zshenv`, `shells/zsh/zprofile`, `shells/zsh/zprofile.template`
- `shells/zsh/zsh.before/path.zsh` (guards Homebrew to darwin but drops it on Linux with no replacement)
- `.dotbot/configs/brew.yaml`, `zsh.yaml`, `oh-my-zsh.yaml`, `ai-tools.yaml`,
  `asdf.yaml`, `languages/{python,nodejs,go,ruby,rust}.yaml`, `utils.yaml`, `gh.yaml`
- `scripts/detect-homebrew.sh`, `scripts/setup-homebrew-userlocal.sh`,
  `scripts/setup-homebrew-group.sh`, `scripts/migrate-to-userlocal-homebrew.sh`,
  `scripts/brew-bundle-safe.sh`
- `tools/homebrew/Brewfile` — 75 casks + 12 mas entries that will all fail on Linux.

### 3. Mac-only tools in profiles/configs (≈10 files)
- `.dotbot/profiles/default` references `touchid`
- `.dotbot/profiles/full` references `touchid`, `hammerspoon`, `colima`,
  `finicky`, `ghostty` cask, `vscode` cask, `cursor` cask
- `.dotbot/configs/touchid.yaml` — writes `/etc/pam.d/sudo` with `pam_tid.so`
- `.dotbot/configs/colima.yaml` + `tools/colima/setup.sh` — Colima is Mac-only
  (Linux uses native Docker)
- `.dotbot/configs/finicky.yaml` + `tools/finicky/**` — Mac-only browser router
- `.dotbot/configs/hammerspoon.yaml` + `apps/hammerspoon/**` — Mac-only
- `tools/sleepwatcher/**` — Mac-only sleep daemon
- `tools/macos-defaults/**` — uses `defaults write`, `killall Finder`, `sw_vers`

### 4. macOS-specific paths (≈10 files)
- `shells/zsh/zshrc` + `shells/zsh/zsh.before/1password.zsh`:
  `SSH_AUTH_SOCK=~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- `shells/zsh/zsh.before/path.zsh`: iterates `$HOME/Library/Python/*/bin`
- `.dotbot/configs/git.yaml`: `~/Library/Application Support/jesseduffield/lazygit/config.yml`
- `.dotbot/configs/vscode.yaml`: `~/Library/Application Support/Code/User/settings.json`
- `.dotbot/configs/cursor.yaml`: `~/Library/Application Support/Cursor/User/settings.json`
- `.dotbot/configs/oh-my-zsh.yaml`: references `secrets/macos`
- `.dotbot/configs/claude-code.yaml`: checks `$HOME/Library/Application Support/com.conductor.app`
- `scripts/backup.sh`: reads/writes `~/Library/Application Support/Code/...`
- `tools/git/gitconfig`: `[gpg "ssh"] program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign`

### 5. Mac-only CLI calls in shell code (≈7 files)
- `tools/tmux/tmux.conf` — three uses of `pbcopy`
- `shells/oh-my-zsh/custom/functions.zsh` — `vm_stat`, `system_profiler`, `ifconfig`
- `shells/zsh/zsh.before/aliases.zsh.template` — `killall Finder`, `defaults write
  com.apple.finder`, hard-codes `/usr/bin/xattr` for an `alias xattr`
- `apps/ghostty/ghostty.conf` — `mouse-url-launcher = "open"`
- `apps/vscode/settings.json.template` + `apps/cursor/settings.json.template`
  — `terminal.integrated.defaultProfile.osx` only (no `.linux`)
- `scripts/backup.sh` — `shasum` (Linux uses `sha256sum`)
- `shells/oh-my-zsh/zshrc` — `code --wait` (fine everywhere; but refers to fig)

### 6. Shell / default-shell assumptions (2 files)
- `.dotbot/configs/zsh.yaml`: `chsh -s /opt/homebrew/bin/zsh` unconditionally
- `.dotbot/configs/oh-my-zsh.yaml`: appends `exec /opt/homebrew/bin/zsh -l` to `~/.zshrc`

### 7. CI (1 file)
- `.github/workflows/test.yml` runs on `macos-latest` only, no Linux matrix.

### 8. Tracked broken symlinks leaking private path (16 files)
These are **committed symlinks** in the public repo that point to
`/Users/joel.castillo.cq/.dotfiles-private/...` — they don't violate the
public/private boundary (they don't embed private *content*), but they leak a
Mac username and can't resolve on a Linux box. Dotbot will attempt to relink
them and may fail. Full list:
- `.dotbot/configs/carequant.yaml`, `jbctechsolutions.yaml`, `personal.yaml`
- `apps/cursor/settings.json`, `apps/vscode/settings.json`
- `shells/oh-my-zsh/custom/secure_profiles/{ai,aws,claude,jbctech_cloud}`
- `shells/zsh/zsh.before/aliases.zsh`, `company-aliases.zsh`
- `tools/claude/plugins.zsh`
- `tools/git/gitconfig.carequant`, `gitconfig.personal`
- `tools/ssh/configs/configs`, `tools/ssh/configs/tsc`

These appear to be artifacts of a past `./install private` run that were
accidentally committed. `MCP_INTEGRATION_MANIFEST.txt:7` also contains
`/Users/joel.castillo.cq/conductor/workspaces/...`.

## Top 5 files that need changes
1. `install` — platform gate blocks Linux outright; also assumes `xcode-select`, `sw_vers`, brew/cask for 1Password.
2. `shells/zsh/zshenv` — only detects Homebrew on Mac paths; needs Linuxbrew or apt fallback, plus a Linux SSH agent path.
3. `tools/homebrew/Brewfile` — ~90 casks/mas entries silently fail on Linux; needs a split Brewfile or apt package list alternative.
4. `.dotbot/profiles/full` + `.dotbot/profiles/default` — reference `touchid`/`hammerspoon`/`colima`/`finicky` that can't run on Linux; need a `linux` profile.
5. `.dotbot/configs/languages/*.yaml` (and `asdf.yaml`) — hard-code `/opt/homebrew/opt/asdf/libexec/asdf.sh`; break on Linux even with asdf installed from source.

## Open questions (need your input before Phase 2)

1. **Private repo audit.** I can only see the public repo. Should I (a) treat
   the private repo as untouchable and just make the public repo Linux-safe
   regardless of how private behaves, or (b) wait for you to grant access to
   `dotfiles-private` so I can audit it too? If (a), any Linux changes to the
   `./install private` path will only be tested against a mock/empty private.
2. **Homebrew on Linux: approach.** You said "prefer apt, don't install
   Homebrew on Linux without approval." Options:
   - A. Skip Homebrew entirely on Linux; install tools via apt + asdf from
     source + direct installers. Cleaner but a lot of per-tool plumbing.
   - B. Allow Linuxbrew (`/home/linuxbrew/.linuxbrew`) as an opt-in fallback
     when apt can't supply a tool. More parity with Mac, less work.
   - C. Two tracks: core shell (zsh, starship, git, tmux, asdf, ripgrep, fzf,
     gh, bat, eza, fd, zoxide, direnv, jq, tree, wget) via apt; rest skipped.
   My recommendation is C unless you want full parity. Which do you want?
3. **Brewfile split.** The `Brewfile` is 75 casks + 12 `mas` lines — all of
   which are GUI apps (browsers, Slack, Zoom, Notion, 1Password desktop, etc.)
   that don't belong on a droplet. OK to add `Brewfile.linux` (CLI-only subset)
   and leave the current `Brewfile` Mac-only? That's simpler than inline
   guards.
4. **1Password SSH agent on Linux.** The 1Password Linux desktop app exposes
   its agent at `~/.1password/agent.sock` (when installed). On a headless
   droplet there's no GUI — do you want me to (a) just not set
   `SSH_AUTH_SOCK` on Linux, (b) detect the Linux agent path when present, or
   (c) assume you'll use a plain `ssh-agent` + `op read` for keys?
5. **Default shell / chsh.** Safe to change `chsh` target to
   `$(command -v zsh)` on Linux, assuming `zsh` is apt-installed? Or do you
   want to keep the Mac path and add a Linux branch?
6. **Tracked symlinks to `/Users/joel.castillo.cq/...`.** These look
   accidental. Three options, pick one:
   - A. Remove them from the public repo entirely (I'd recommend this — it
     also de-leaks your Mac username). `./install private` would recreate them
     at install time.
   - B. Replace each with an `ignore-missing`-friendly no-op placeholder.
   - C. Leave as-is (they'll dangle on Linux but still work on your Mac if
     that path exists). This is the status quo.
7. **Linux profile scope.** What's the target shell experience on the droplet?
   - Minimal (shell-only): zsh + oh-my-zsh + starship + tmux + git + asdf +
     core CLI (rg, fd, fzf, bat, eza, zoxide, direnv, jq, gh, tree).
   - Dev (above + one or two language toolchains via asdf).
   - Full (above + Docker, 1Password CLI, Claude Code, MCP).
   My recommendation: Dev. Confirm?
8. **GUI-only configs on Linux.** Ghostty, Hammerspoon, Finicky, Raycast,
   VS Code, Cursor, Hammerspoon — all Mac GUIs. Keep their configs in the
   repo but skip linking on Linux, right? (I'll gate via Dotbot profile, not
   delete them.)
9. **`tools/git/gitconfig` signing.** The SSH signing `program` path points
   at the Mac 1Password app bundle. On Linux, with 1Password desktop it's
   `/opt/1Password/op-ssh-sign`; without it, you'd drop `commit.gpgsign` or
   switch to a different signer. Preference?
10. **CI.** Should I add an Ubuntu job to `.github/workflows/test.yml` in this
    pass, or leave CI Mac-only for now? (Adding one is cheap and catches
    regressions.)

## Mac assumptions I am NOT treating as blockers
- Most `docs/*.md` files reference macOS narratively; leaving docs alone
  unless the bootstrap docs (`README.md`, `START_HERE.md`) need a Linux
  section.
- `.editorconfig`, `.shellcheckrc`, `.pre-commit-config.yaml`, `LICENSE`,
  `CONTRIBUTING.md` — already portable.
- Submodules in `.dotbot/` and `shells/` — portable as-is.
- Starship, tmux-plugins, oh-my-zsh, prezto — all cross-platform upstream.
