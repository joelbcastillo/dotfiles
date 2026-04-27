# Linux Migration — Test on Mac

**Goal:** confirm the `linux-compat` branch does not regress macOS behavior.
**Time:** ~5 minutes.
**Assumes:** you already have `dotfiles` and `dotfiles-private` installed on this Mac on `main`.

All commands assume you're at the repo root (`~/.dotfiles`). None of them should prompt for sudo; if one does, stop and report.

---

## 0. Setup

Save your current state so you can roll back:

```bash
cd ~/.dotfiles
git status          # must be clean — commit or stash before continuing
git rev-parse HEAD  # remember this hash
```

Check out the branch:

```bash
git fetch origin linux-compat
git checkout linux-compat
git log --oneline main..HEAD | head -5
```

**Expected:** you see the top of the commit list (e.g. `24cd0d2 fix(bootstrap-linux): add vim…`, `bd069ee fix(shell): editor fallback chain…`, etc.).

---

## 1. Static sanity check (30 sec)

```bash
# Shell files parse as valid zsh
for f in shells/zsh/zshrc shells/zsh/zshenv shells/zsh/zprofile shells/zsh/zsh.before/*.zsh; do
  zsh -n "$f" || echo "FAIL: $f"
done
echo done
```

**Expected:** only `done` — no FAIL lines.

```bash
# Install script parses as valid bash
bash -n install && echo OK
bash -n scripts/bootstrap-linux.sh && echo OK
bash -n scripts/backup.sh && echo OK
```

**Expected:** three `OK` lines.

---

## 2. Fresh zsh shell — prompt, aliases, `$platform`, `$EDITOR` (1 min)

```bash
# Launch a new interactive zsh and probe it (non-destructive — exits immediately)
zsh -i -c '
  echo "---"
  echo "platform=$platform"
  echo "EDITOR=$EDITOR"
  echo "VISUAL=$VISUAL"
  echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
  echo "pbcopy=$(command -v pbcopy)"
  echo "starship=$(command -v starship)"
  type ll 2>/dev/null | head -1
  echo "---"
'
```

**Expected (on a healthy Mac with 1Password + Cursor):**
```
---
platform=darwin
EDITOR=cursor --wait
VISUAL=cursor --wait
SSH_AUTH_SOCK=/Users/you/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
pbcopy=/usr/bin/pbcopy                         # native macOS — not an alias
starship=/opt/homebrew/bin/starship            # or wherever brew put it
ll is an alias for ls -alGh                    # BSD ls with color flag (darwin branch)
---
```

**If `pbcopy` resolves to an `xclip`/`wl-copy` alias instead of a native binary:** a regression — means `os-compat.zsh` applied on Mac. Report.

**If `SSH_AUTH_SOCK` is unset or points at `~/.1password/agent.sock`:** a regression — the darwin branch of `1password.zsh` isn't firing. Report.

**If `EDITOR` is `vim` instead of `cursor --wait` (and you're not over SSH):** probably fine if Cursor isn't installed, but worth noting.

---

## 3. Mac-only configs still load via dotbot (2 min)

Dry-run the configs that should be macOS-only. None of these should fail or print "Skipping …".

```bash
./install config brew        # should proceed with Homebrew operations
./install config touchid     # should mention pam_tid configuration
./install config hammerspoon # should link ~/.hammerspoon
```

**Expected:** each config runs its macOS flow. None say "Skipping … not on macOS".

Quick spot-check that the Linux counterpart is a no-op:

```bash
./install config apt 2>&1 | head -5
```

**Expected:** `⏭  Skipping apt setup — not on Linux`

---

## 4. Git signing still works (30 sec)

```bash
# The OS-aware gitconfig.os should point at the Mac op-ssh-sign
cat ~/.gitconfig.os
```

**Expected:** includes `program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign` (or empty if 1Password CLI resolves a different path — also valid).

```bash
# Make a trivial signed commit in a throwaway repo
tmpdir=$(mktemp -d)
(cd "$tmpdir" && git init -q && git commit --allow-empty -S -m "signing smoke test") && echo "SIGNING: OK" || echo "SIGNING: FAIL"
rm -rf "$tmpdir"
```

**Expected:** `SIGNING: OK` (requires 1Password app unlocked; if prompted for biometric, approve).

---

## 5. tmux clipboard still works (30 sec)

```bash
# Dry-run the tmux config
tmux -f ~/.tmux.conf -C attach 2>&1 | head -3
# If that opens tmux, type "detach-client" and Enter, or Ctrl-C
```

**Expected:** no error lines. `%begin`/`%end` markers only.

---

## 6. Clean up

```bash
# Switch back to main if you don't want to leave the branch checked out
git checkout main
```

---

## Failure response

If any step fails unexpectedly, note which one and paste the full output into the PR thread. Don't `reset --hard` or force things — the branch is a draft, we can ship fixes.
