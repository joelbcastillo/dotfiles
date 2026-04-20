# Linux Migration Audit — Public dotfiles

**Repo:** `dotfiles` (public)
**Branch:** `linux-compat`
**Audit date:** 2026-04-19
**Target:** Ubuntu 24.04 LTS (fresh droplet), preserving Mac behavior

This audit lists every Mac-specific assumption in the public repo, what is
already portable, what needs OS branching, what needs to be added for Linux,
and what stays Mac-only. All findings cite `file:line`.

Paths are relative to the repo root. The companion audit lives at
`dotfiles-private/LINUX_MIGRATION_AUDIT.md` (private repo, `linux-compat`
branch).

---

## 1. Mac-specific assumptions

### 1.1 Bootstrap / install script — hard blocks Linux

| # | File | Lines | Finding |
|--|------|-------|---------|
| 1 | `install` | 10 | `MIN_MACOS_VERSION="13.0"` — only a macOS floor defined |
| 2 | `install` | 11 | `REQUIRED_TOOLS=("git" "curl" "xcode-select")` — `xcode-select` is Mac-only |
| 3 | `install` | 64-72 | `check_platform()`: `[[ "$OSTYPE" != "darwin"* ]]` hard-returns 1 with "macOS only" message — **this is the primary blocker** |
| 4 | `install` | 77-91 | `sw_vers -productVersion` — Mac-only |
| 5 | `install` | 111-120 | `check_xcode_tools` → `xcode-select -p` / `xcode-select --install` — Mac-only |
| 6 | `install` | 132 | `"$HOME/Library/Application Support/Code/User/settings.json"` in backup list |
| 7 | `install` | 308-318 | `exists brew` → Homebrew installer script — Mac default; linuxbrew possible but different |
| 8 | `install` | 321-334 | `brew install --cask 1password-cli` — cask syntax does not exist on linuxbrew |

### 1.2 Homebrew paths baked into shell init

| # | File | Lines | Finding |
|--|------|-------|---------|
| 9 | `shells/zsh/zshenv` | 12-29 | Homebrew detection walks `$HOME/.homebrew`, `/opt/homebrew`, `/usr/local` and calls `brew shellenv` — all Mac paths |
| 10 | `shells/zsh/zprofile` | 3-10 | Same Homebrew detection, redundant to zshenv |
| 11 | `shells/zsh/zsh.before/path.zsh` | 11-14 | `if [[ $platform == 'darwin' ]]; then export PATH="/opt/homebrew/bin:..."` — Mac-only PATH entries |
| 12 | `shells/zsh/zsh.before/path.zsh` | 23-27 | `$HOME/Library/Python/*/bin` — macOS Python user site bin |
| 13 | `shells/zsh/zshrc.minimal` | 85 | Hardcoded `/opt/homebrew/bin/brew shellenv` (no fallback) |

### 1.3 macOS-only 1Password SSH agent socket

| # | File | Lines | Finding |
|--|------|-------|---------|
| 14 | `shells/zsh/zshrc` | 32 | `export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock` |
| 15 | `shells/zsh/zsh.before/1password.zsh` | 2 | Same socket export (canonical location for this) |
| 16 | `shells/zsh/zshrc.minimal` | 24 | Same socket export |

### 1.4 macOS-only CLIs and GUI-app commands

| # | File | Lines | Finding |
|--|------|-------|---------|
| 17 | `shells/zsh/zshrc` | 27 | `EDITOR='cursor --wait'` (Cursor.app has a Linux build, but not guaranteed) |
| 18 | `shells/zsh/zshrc.minimal` | 21-23 | Same |
| 19 | `shells/zsh/zsh.before/aliases.zsh.template` | 141-142 | `defaults write com.apple.finder ...` / `killall Finder /System/Library/CoreServices/Finder.app` — macOS Finder |
| 20 | `tools/macos-defaults/run.sh` | entire | `sw_vers`, `defaults write`, macOS-only |
| 21 | `scripts/install-touchid-for-sudo.sh` | entire | `pam_tid.so` in `/etc/pam.d/sudo` — macOS Touch ID PAM |
| 22 | `scripts/check-mcp-installed.sh` | 82-85, 162-184 | `~/Library/Application Support/Claude/`, `~/Library/Application Support/Code/User/mcp.json` |
| 23 | `scripts/backup.sh` | 43-44, 110-112 | Backs up `~/Library/Application Support/Code/User/` |

### 1.5 Brewfile — entire package list is Mac

| # | File | Finding |
|--|------|---------|
| 24 | `tools/homebrew/Brewfile` | taps, formulae, `cask "..."`, `mas "..."` — none of these are apt-compatible. The formulae subset is mostly portable (git, jq, ripgrep, fzf, etc. all exist on apt), but `cask`/`mas` lines are Mac-only. |

### 1.6 Dotbot configs that do Mac-only work

| # | File | Finding |
|--|------|---------|
| 25 | `.dotbot/configs/touchid.yaml` | PAM edits — Mac only |
| 26 | `.dotbot/configs/finicky.yaml` | Finicky (macOS URL router) config link — Mac only |
| 27 | `.dotbot/configs/hammerspoon.yaml` | Hammerspoon (macOS automation) link — Mac only |
| 28 | `.dotbot/configs/brew.yaml` | Brewfile bundle runner — Mac only (linuxbrew optional, out of scope) |
| 29 | `.dotbot/profiles/full` | Includes touchid/hammerspoon/finicky — needs a Linux-skip path |

### 1.7 Aliases using BSD tools / Mac-only binaries

| # | File | Lines | Finding |
|--|------|-------|---------|
| 30 | `shells/zsh/zsh.before/aliases.zsh.template` | 48-51 | `alias ls='ls -Gh'` (`-G` is BSD color; GNU `ls` uses `--color=auto`). **This file already has the `$platform == 'linux'` branch on lines 45-47**, so it's handled — flagging for clarity. |
| 31 | *(none other found in public repo)* | — | No `pbcopy`/`pbpaste`/`open`/`osascript`/`mdfind`/`say` usage detected in public shell files (they live in private or are just not currently used). |

> Note: `aliases.zsh` sourced at runtime is a symlink to the private repo's `aliases/aliases.zsh`, which uses `defaults write` and `/usr/bin/xattr` — see the private-repo audit.

---

## 2. Already portable

| File | Notes |
|------|-------|
| `shells/oh-my-zsh/custom/functions.zsh` | POSIX-friendly zsh functions (venv, mkcd, extract, git helpers). No Mac-specific CLIs. |
| `shells/zsh/zsh.before/history.zsh` | Pure zsh history options |
| `shells/zsh/zsh.before/completion.zsh` | Pure zsh completion setup |
| `shells/zsh/zsh.before/asdf.zsh` | asdf init — works on Linux once asdf is installed |
| `shells/zsh/zsh.before/direnv.zsh` | Direnv hook — portable |
| `shells/zsh/zsh.before/zoxide.zsh` | Zoxide init — portable |
| `shells/zsh/zsh.before/key-bindings.zsh`, `noglob.zsh`, `rm.zsh`, `zmv.zsh` | Pure zsh |
| `shells/zsh/zsh.before/aliases.zsh.template` | Has a `linux / darwin` branch already for `ls` (lines 45-51) |
| `shells/zsh/zshrc` | `starship init` block (line 43-45) is portable; `oh-my-zsh` block is portable |
| `tools/tmux/tmux.conf` | Pure tmux, no platform branching needed |
| `tools/git/gitconfig`, `tools/git/gitconfig.user.template` | Standard git config — portable (caveat: the private gitconfig identity files hardcode `/Applications/1Password.app/...`, see private audit) |
| `tools/ruby/*`, `tools/python/*`, `tools/nodejs/*`, `tools/go/*`, `tools/rust/*` | Tool-specific config files (rubocop.yml, .prettierrc, mypy.ini, etc.) — portable |
| `tools/asdf/asdfrc`, `tools/asdf/tool-versions` | Portable |
| `tools/starship/starship.toml` (if present) | Portable |
| `tools/ghostty/ghostty.conf` | Config is portable; installation differs (Ghostty has a Linux build) |
| `mcp-profile-functions.zsh` | Pure shell + jq + find + cp — portable |
| `scripts/sshop` | Already has a macOS vs Linux branch for `stat -c` / `stat -f` (lines 222-225) |
| Most files under `tools/` other than `tools/homebrew/` and `tools/macos-defaults/` | Config-only, portable |
| `.shellcheckrc`, `.gitignore`, `.gitmodules`, `.pre-commit-config.yaml`, `.editorconfig` | Portable |
| `.dotbot/profiles/*` (the ones not naming Mac-only configs) | Dotbot itself is cross-platform Python |

---

## 3. Needs OS branching

For each, show Mac value → Linux equivalent. The same OS-branching idiom should be used throughout. We already have a pattern: `aliases.zsh.template` uses a `platform` variable set from `uname`. We should either (a) standardize on `[[ "$OSTYPE" == "darwin"* ]]` / `[[ "$OSTYPE" == "linux-gnu"* ]]`, or (b) source a helper that sets `$platform` once. **Plan will pick one.**

### 3.1 Package manager / Homebrew detection

| File:line | Mac | Linux |
|-----------|-----|-------|
| `shells/zsh/zshenv:12-29` | `brew shellenv` from `/opt/homebrew` or `/usr/local` or `~/.homebrew` | Skip `brew shellenv` entirely; apt puts binaries in `/usr/bin` and `/usr/local/bin` which are already on default PATH |
| `shells/zsh/zprofile:3-10` | Same | Skip |
| `shells/zsh/zsh.before/path.zsh:11-14` | Prepend `/opt/homebrew/{bin,sbin}` | Skip (or append `$HOME/.linuxbrew/bin` if user opts in — see Q1) |
| `shells/zsh/zsh.before/path.zsh:23-27` | `$HOME/Library/Python/*/bin` | `$HOME/.local/bin` (pip user install default on Linux — already added once in zshenv:9) |
| `shells/zsh/zshrc.minimal:85` | Hardcoded `/opt/homebrew/bin/brew` | Same treatment as zshenv |

### 3.2 1Password SSH agent socket

| File:line | Mac | Linux |
|-----------|-----|-------|
| `shells/zsh/zsh.before/1password.zsh:2` | `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` | On Linux: `~/.1password/agent.sock` (standard 1Password for Linux path, created when the GUI app runs) — see Q2 for the headless-droplet case |
| `shells/zsh/zshrc:32` | Same | Same — and this line is duplicated with `1password.zsh`, should be removed from `zshrc` (source of truth → `1password.zsh`) |
| `shells/zsh/zshrc.minimal:24` | Same | Same |

### 3.3 Editor

| File:line | Mac | Linux |
|-----------|-----|-------|
| `shells/zsh/zshrc:24-28` | `cursor --wait` interactive, `vim` over SSH | Detect in order: `cursor --wait` (Linux build) → `code --wait` → `nvim` → `vim`. Already SSH-guarded. |
| `shells/zsh/zshrc.minimal:21-23` | Same | Same |

### 3.4 VS Code / Cursor / Claude Desktop config paths

| File:line | Mac | Linux |
|-----------|-----|-------|
| `install:132` | `~/Library/Application Support/Code/User/settings.json` | `~/.config/Code/User/settings.json` |
| `scripts/backup.sh:43-44,110-112` | Same | Same |
| `scripts/check-mcp-installed.sh:162-168` | `~/Library/Application Support/Claude/` | `~/.config/Claude/` |
| `scripts/check-mcp-installed.sh:170-176` | `~/Library/Application Support/Cursor/` (if referenced) | `~/.config/Cursor/User/` |
| `.dotbot/configs/vscode.yaml` | `~/Library/Application Support/Code/User/settings.json` (confirm file) | `~/.config/Code/User/settings.json` |
| `.dotbot/configs/cursor.yaml` | `~/Library/Application Support/Cursor/User/settings.json` | `~/.config/Cursor/User/settings.json` |

### 3.5 Clipboard helpers (not yet in repo — add under Linux-only §4)

Current public repo doesn't define `pbcopy`/`pbpaste` aliases, so this is a §4 addition rather than a §3 branch. Private repo may use them; check private audit.

### 3.6 `install` script OS branching

Every function in `install` that calls a Mac-only CLI (`sw_vers`, `xcode-select`, `brew`) needs a Linux equivalent or a skip. Concretely:
- `check_platform()` → accept `darwin*` and `linux-gnu*` both
- `check_xcode_tools()` → skip on Linux (build-essential covers the equivalent; install it via apt in a Linux bootstrap step)
- Replace Homebrew install block with a dispatch: Mac → Homebrew installer; Linux → `apt install` list (user runs with sudo)

---

## 4. Linux-only to add

### 4.1 Apt package list (Ubuntu 24.04)

Minimum viable to reproduce the Mac shell experience. Derived from the Brewfile formulae and required shell tools:

```
# Base
build-essential curl wget git zsh tmux vim unzip ca-certificates gnupg

# Shell UX
jq ripgrep fzf fd-find bat eza direnv shellcheck pre-commit

# Languages — prefer asdf for user-level installs, but apt for the baseline
python3 python3-pip python3-venv

# Clipboard / XDG
xclip wl-clipboard xdg-utils

# Fonts
fontconfig
```

**Not** installed via apt (prefer user-level):
- `asdf` — git-clone install to `~/.asdf` (matches the public repo's asdf submodule flow)
- `starship` — install via their installer script to `~/.local/bin`
- `nerd-fonts` — download the two fonts we use (FiraCode, JetBrainsMono) into `~/.local/share/fonts` + `fc-cache -fv`

### 4.2 Clipboard wrapper (new file)

Add `shells/zsh/zsh.before/clipboard.zsh`. Only defines `pbcopy`/`pbpaste` on Linux (Mac provides them natively):

```zsh
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v wl-copy >/dev/null 2>&1 && [[ -n "$WAYLAND_DISPLAY" ]]; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
  elif command -v xclip >/dev/null 2>&1; then
    alias pbcopy='xclip -selection clipboard -in'
    alias pbpaste='xclip -selection clipboard -out'
  fi
fi
```

### 4.3 `open` wrapper

Add to the same clipboard.zsh or a separate `os-compat.zsh`:

```zsh
if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v xdg-open >/dev/null 2>&1; then
  alias open='xdg-open'
fi
```

### 4.4 OS helper file (proposed)

Rather than scatter `[[ "$OSTYPE" == ... ]]` blocks across files, add one helper that sets `$OS` once and gets sourced first. See the Plan phase for the final idiom.

### 4.5 Bootstrap — Linux branch

Extend `install` so `bootstrap` dispatches:
- Mac → existing Homebrew + cask flow
- Linux → detect distro (Ubuntu only for now), run `apt update && apt install -y <list>`, then asdf clone + starship install + nerd-font fetch.

Whether `install` should call `sudo apt` itself is an open question (Q5).

---

## 5. Leave Mac-only on Linux (gracefully skipped)

| Item | File that needs the skip |
|------|--------------------------|
| Hammerspoon | `.dotbot/configs/hammerspoon.yaml` — wrap commands in `[[ "$OSTYPE" == darwin* ]]` guard |
| Finicky | `.dotbot/configs/finicky.yaml` — skip on Linux |
| Touch ID for sudo | `.dotbot/configs/touchid.yaml` + `scripts/install-touchid-for-sudo.sh` — skip on Linux |
| macOS defaults | `tools/macos-defaults/run.sh` + any `.dotbot/configs/macos.yaml` — skip on Linux |
| Homebrew / Brewfile | `.dotbot/configs/brew.yaml` — skip on Linux (apt list runs instead) |
| Raycast scripts | `scripts/raycast/*` (if any) — do not install on Linux |
| `defaults write com.apple.finder` Finder aliases | `aliases.zsh.template` lines 141-142 — wrap in `darwin` guard (currently unguarded) |
| Mac-only Brewfile casks (`cask "ghostty"`, `cask "hammerspoon"`, `cask "finicky"`, `cask "raycast"`, `cask "cursor"`, `cask "font-*"`) | `tools/homebrew/Brewfile` — leave as-is; `.dotbot/configs/brew.yaml` not run on Linux |

These are all **configuration-level skips**, not deletions. The files stay in the repo for Mac use.

---

## 6. Open questions

1. **Linuxbrew — support or skip?** I recommend **skip**: Ubuntu 24.04 apt covers all the CLI we actually use, and linuxbrew adds complexity (separate prefix, sudo-less install has quirks, PATH conflicts). If you ever want linuxbrew as an opt-in, it's a small additive change later.
2. **1Password on a headless Ubuntu droplet.** The 1Password GUI agent is what provides `~/.1password/agent.sock` on Linux. On a droplet with no GUI, the socket doesn't exist. Options: (a) skip the SSH-agent export on headless Linux and rely on `ssh-agent` + keys fetched via 1Password CLI to disk (what `scripts/fetch-ssh-keys.sh` already does); (b) run `op-ssh-agent` standalone if/when it's available. Preferred default: (a). Confirm?
3. **Cursor on Linux.** Cursor has a Linux AppImage/deb. On a droplet you usually don't want a GUI editor. Proposed: fall back chain `cursor → code → nvim → vim`, so the same zshrc works in both environments.
4. **Ghostty on Linux.** Has a Linux build but no apt package. Skip installation on Linux in Phase 3; config file stays portable for when the user installs it manually.
5. **Should `install` call `sudo apt` itself?** Options: (a) require user to run `sudo apt install …` before calling `./install bootstrap`; (b) have `install` prompt for sudo. Mac never needed sudo from `install`, so I'd lean (a) to preserve that property — just print the exact apt command. Confirm?
6. **Profile organization.** Two options: keep one `full` profile and have each Mac-only config self-skip on Linux; or add a `linux` profile and a `macos` profile that each include only applicable configs. I'd lean on **self-skipping configs** to avoid profile duplication.
7. **`aliases.zsh.template` — is the "template" suffix important?** The live alias file is symlinked in from the private repo; the `.template` one in public looks like a stale export. Should it be updated, kept, or removed? (Not touching for this audit.)
8. **Starship vs Powerlevel10k.** Repo already initializes Starship if present (`zshrc:43-45`). No Mac-specific path used. Keep Starship as the cross-platform prompt. Confirm.

---

## 7. Cross-repo dependencies (from the private repo into here)

The file `.dotbot/configs/private.yaml` in this repo is the **seam**. It creates symlinks from `~/.dotfiles-private/**` into `~/.dotfiles/**`:

- Git identity files → `tools/git/gitconfig.{personal,jbctechsolutions,carequant}`
- Alias files → `shells/zsh/zsh.before/{aliases,claude-tools-env,company-aliases,claude-auth}.zsh`
- VS Code + Cursor settings → `apps/{vscode,cursor}/settings.json`
- SSH config + keys → `tools/ssh/{config,configs,keys}`
- Secure profiles → `shells/oh-my-zsh/custom/secure_profiles/*`
- Private dotbot configs → `.dotbot/configs/{personal,jbctechsolutions,carequant,ssh-*,claude-tools-private}.yaml`

The `private.yaml` logic is pure `ln -sf` (portable). The **content behind those links** has Mac-specific assumptions (see private repo audit sections 3 and 5) — those changes live in the private repo. This public repo is correct as the seam; the only coordination needed is **ordering**: on Linux, `./install private` should run before any profile that uses the private identities, same as on Mac.

No public-repo change is required to *enable* the cross-repo link; changes to the linked content are private-repo-only.

---

## Summary counts

| Bucket | Count |
|--------|-------|
| Mac-specific hard deps | 31 |
| Files already portable | ~20 |
| Needs OS branching | 13 call-sites across 8 files |
| Linux-only additions | 5 new chunks (apt list, clipboard helper, open alias, OS helper, install Linux branch) |
| Mac-only to skip on Linux | 8 configs / scripts / alias lines |
| Open questions | 8 |
