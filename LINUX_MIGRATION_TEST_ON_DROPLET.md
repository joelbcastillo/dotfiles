# Linux Migration — Test on a Fresh Ubuntu 24.04 Droplet

**Goal:** clone both repos on a fresh Ubuntu droplet and verify the same shell experience you get on the Mac.
**Time:** ~15 minutes (most of it waiting for apt + asdf downloads).
**Assumes:** a fresh Ubuntu 24.04 droplet you can SSH into as a user with passwordless sudo. If you want to test the full IaC path, run everything with `NONINTERACTIVE=1` set in the environment.

Expected home is `/home/<user>/`; substitute your actual user below.

All commands are copy-pasteable. Each section has an "Expected" block — glance at it and you can tell if something's off without scrolling through logs.

---

## Provision the droplet (2 min, optional)

Skip this if you already have a droplet. Otherwise, use `doctl` (install: `brew install doctl`; auth: `doctl auth init`).

```bash
# Pick your SSH key fingerprint (the one you want to SSH in with)
doctl compute ssh-key list

# Create an Ubuntu 24.04 droplet in NYC3, smallest size (s-1vcpu-1gb, ~$6/mo)
# Replace <SSH_KEY_FINGERPRINT> below.
doctl compute droplet create linux-compat-test \
    --region nyc3 \
    --size s-1vcpu-1gb \
    --image ubuntu-24-04-x64 \
    --ssh-keys <SSH_KEY_FINGERPRINT> \
    --wait

# Grab the IP
DROPLET_IP="$(doctl compute droplet get linux-compat-test --format PublicIPv4 --no-header)"
echo "$DROPLET_IP"

# SSH in (default user is root — create a non-root user to match real usage)
ssh root@"$DROPLET_IP"
```

Inside the droplet, create a sudo user (so the rest of this guide runs as non-root, matching real usage):

```bash
adduser joel                          # set a password; accept defaults
usermod -aG sudo joel
# Copy your SSH key so you can log in as that user
rsync --archive --chown=joel:joel ~/.ssh /home/joel
# Give passwordless sudo for NONINTERACTIVE=1 testing
echo "joel ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-joel
exit
```

Re-SSH as the new user:

```bash
ssh joel@"$DROPLET_IP"
```

**Tear-down when you're done:** `doctl compute droplet delete linux-compat-test` (add `-f` to skip confirmation).

---

## 0. Prereqs (30 sec)

SSH to the droplet, then:

```bash
sudo apt-get update -y
sudo apt-get install -y git curl ca-certificates
```

**Expected:** no errors. `git --version` and `curl --version` both resolve.

---

## 1. Clone both repos (1 min)

```bash
# Public
git clone -b linux-compat https://github.com/joelbcastillo/dotfiles.git ~/.dotfiles

# Private (requires GitHub credentials — use a PAT or SSH forward)
git clone -b linux-compat git@github.com:joelbcastillo/dotfiles-private.git ~/.dotfiles-private
```

If you don't have SSH key-forward, use HTTPS with a short-lived PAT:

```bash
git clone -b linux-compat https://<USER>:<PAT>@github.com/joelbcastillo/dotfiles-private.git ~/.dotfiles-private
```

**Expected:** both clones succeed. Check:

```bash
(cd ~/.dotfiles && git log --oneline -1)
(cd ~/.dotfiles-private && git log --oneline -1)
```

Top commit on public should be from the `linux-compat` PR; same for private.

---

## 2. Run Linux bootstrap (5–8 min)

Interactive (you'll see apt prompts you can approve):

```bash
cd ~/.dotfiles
scripts/bootstrap-linux.sh
```

Or unattended (IaC-style — requires passwordless sudo):

```bash
cd ~/.dotfiles
NONINTERACTIVE=1 scripts/bootstrap-linux.sh
```

**Expected tail of output:**
```
[bootstrap-linux.sh] Installing Nerd Font: FiraCode
[bootstrap-linux.sh] Installing Nerd Font: JetBrainsMono
[bootstrap-linux.sh] Base bootstrap complete.
[bootstrap-linux.sh]
[bootstrap-linux.sh] Next steps:
[bootstrap-linux.sh]   1. git submodule update --init --recursive
[bootstrap-linux.sh]   2. ./install profile full
[bootstrap-linux.sh]   3. exec zsh -l
```

Verify the key binaries landed:

```bash
command -v zsh starship op gh xclip zoxide eza
ls -d ~/.asdf
ls ~/.local/share/fonts | head -5
```

**Expected:** every command prints a path (not empty). `~/.asdf` exists. Fonts dir has `FiraCode`/`JetBrainsMono` entries.

---

## 3. Init submodules + install profile (3–5 min)

```bash
cd ~/.dotfiles
git submodule update --init --recursive
./install profile full
```

**Expected:** every Mac-only config self-skips with messages like:
```
⏭  Skipping Homebrew setup — not on macOS
⏭  Skipping TouchID for sudo — not on macOS
⏭  Skipping Hammerspoon — macOS-only
⏭  Skipping Finicky — macOS-only
⏭  Skipping brew bundle — not on macOS
```

And the Linux/cross-platform configs proceed:
- apt runs bootstrap-linux.sh again (idempotent — exits fast)
- zsh, oh-my-zsh, starship, git, asdf, languages, gh, ripgrep, tmux, ssh, vscode, cursor, ai-tools configs apply

Last lines of output should include `Profile 'full' installed successfully` (or similar) and no red error lines.

---

## 4. Private repo layering (1 min)

```bash
cd ~/.dotfiles
./install private
```

**Expected:** prints `Linked ...` lines for every file it symlinks from `~/.dotfiles-private` into `~/.dotfiles`. No errors. Then:

```bash
# Verify a few symlinks landed
ls -la ~/.dotfiles/shells/zsh/zsh.before/aliases.zsh
ls -la ~/.dotfiles/tools/git/gitconfig.personal
ls -la ~/.dotfiles/tools/ssh/config
```

**Expected:** all three are symlinks (`->` in output) pointing into `~/.dotfiles-private/...`.

---

## 5. Shell smoke check (1 min)

Open a fresh zsh login shell and poke at it:

```bash
exec zsh -l
```

You should see the Starship prompt render with Nerd Font glyphs (or boxes if your terminal doesn't have Nerd Fonts — that's fine on a droplet).

Then, inside the new shell:

```bash
echo "platform=$platform"
echo "EDITOR=$EDITOR"
echo "VISUAL=$VISUAL"
echo "SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-<unset>}"
command -v pbcopy && alias pbcopy
command -v open && alias open
type ll
type gs     # git status alias from private aliases
```

**Expected on a headless droplet (no 1Password desktop):**
```
platform=linux
EDITOR=vim                                  # or nvim if installed
VISUAL=vim
SSH_AUTH_SOCK=<unset>                       # expected — no GUI agent running
/usr/bin/wl-copy  OR  /usr/bin/xclip        # whichever is available
pbcopy=xclip -selection clipboard -in       # or wl-copy
/usr/bin/xdg-open
open=xdg-open
ll is an alias for ls -alh --color=auto     # GNU ls with --color flag
gs is an alias for git status
```

**If `$platform` is empty:** aliases.zsh didn't load. Check `ls -la ~/.dotfiles/shells/zsh/zsh.before/aliases.zsh` resolves.

**If `$EDITOR` is empty:** the editor fallback chain found nothing. Confirm `vim` installed (`command -v vim`).

---

## 6. Git config applied + signing fallback (1 min)

```bash
cat ~/.gitconfig.os
git config --global --get user.name
git config --global --get user.email
git config --global --get gpg.ssh.program 2>&1 || echo "<unset — ssh-keygen fallback>"
```

**Expected:** `~/.gitconfig.os` is either empty (headless — no 1Password installed) or contains a `program = /opt/1Password/op-ssh-sign` line. `user.name`/`user.email` come from your private identity gitconfig if you set one up. `gpg.ssh.program` is either `/opt/1Password/op-ssh-sign` or unset (fallback to ssh-keygen).

Try a throwaway signed commit (requires having an SSH key fetched to disk — `./install config ssh` should have done this):

```bash
tmpdir=$(mktemp -d)
(cd "$tmpdir" && git init -q && git commit --allow-empty -S -m "droplet signing test")
rm -rf "$tmpdir"
```

**Expected:** commit succeeds. If your key isn't set up yet, you'll see a clear "signing failed" error — that's a setup issue, not a bug in the branch.

---

## 7. tmux config loads (30 sec)

```bash
tmux -f ~/.tmux.conf new-session -d -s droplet-test "sleep 5"
tmux ls
tmux kill-session -t droplet-test
```

**Expected:** `droplet-test: 1 windows (created ...)` with no error lines above it.

---

## 8. SSH fallback to ssh-agent (bonus, 1 min)

On a headless droplet without 1Password desktop, ssh-to-github should fall through to `ssh-agent` + a key on disk:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github 2>/dev/null || echo "(no github key on disk yet — fine)"
ssh -T git@github.com 2>&1 | head -3
```

**Expected (if you have a key added):** `Hi <username>! You've successfully authenticated…`
**Expected (no key):** `Permission denied (publickey)` — that's a key-setup issue, not a branch bug.

---

## 9. Regression quick-check — make sure nothing Mac-specific is on

```bash
# None of these should resolve on a Linux box
ls /opt/homebrew/bin/brew 2>&1 | head -1        # expected: "No such file"
ls ~/Library/ 2>&1 | head -1                    # expected: "No such file"
echo "$SSH_AUTH_SOCK" | grep -q "Group Containers" && echo "FAIL: Mac SSH socket in env" || echo "OK"
```

**Expected:** three "No such file" / "OK" lines.

---

## Failure response

If any expected line is missing or wrong:

1. Copy the full output of the failing step.
2. Paste it into the PR thread (or Slack — wherever we're tracking).
3. Don't `rm -rf ~/.dotfiles` — preserve the state for debugging.

Known rough edges on the droplet (not bugs, just things the test doesn't cover):

- **Cursor on Linux:** the Linux build isn't installed by bootstrap-linux.sh. Opening Cursor from `$EDITOR` falls through to code → nvim → vim.
- **1Password GUI:** headless droplets don't run the desktop app, so biometric signing isn't available. Git signing uses `ssh-keygen` with a disk-based key (fetched via `./install config ssh`).
- **Ghostty:** not installed on Linux; config file stays portable for when you add it.

Everything else should feel like the Mac experience.
