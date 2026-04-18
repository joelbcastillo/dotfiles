# Mac Regression Test Plan

Use this when you pull the `linux-compat` branch onto your Mac. The goal is
to confirm **nothing on the Mac path regressed**. All commands assume your
repo is cloned to `~/.dotfiles` as usual.

## 0. Snapshot

Before anything, take a safety net:

```bash
cp ~/.zshrc  ~/.zshrc.pre-linux-compat          2>/dev/null || true
cp ~/.gitconfig ~/.gitconfig.pre-linux-compat   2>/dev/null || true
cp ~/.tmux.conf ~/.tmux.conf.pre-linux-compat   2>/dev/null || true
git -C ~/.dotfiles rev-parse HEAD > ~/.dotfiles.pre-linux-compat.sha
```

## 1. Pull the branch

```bash
cd ~/.dotfiles
git fetch origin
git switch linux-compat
git submodule update --init --recursive
```

## 2. Sanity checks (no install yet)

```bash
# Install usage still prints
./install

# Platform check still accepts macOS
uname -s                        # expect: Darwin
./install profile               # expect: usage error about missing profile arg,
                                #         NOT a "designed for macOS only" rejection

# Brewfile selector picks the mac variant
./tools/homebrew/select-brewfile.sh
readlink tools/homebrew/Brewfile    # expect: Brewfile.mac

# asdf loader locates the brew-installed asdf
bash -c 'source tools/asdf/load-asdf.sh && command -v asdf'
# expect: the asdf path, no warning
```

## 3. Regression test the Mac path

```bash
# Re-run your usual profile. Should succeed without new prompts.
./install profile full
```

Watch for:

- [ ] No new "⏭  Skipping ..." messages (those only fire on Linux).
- [ ] `brew bundle` still runs and reports the same package state as before.
- [ ] `Colima`, `Hammerspoon`, `Finicky`, `TouchID`, `macos-defaults` all run
      their Mac-only paths (no skip messages).
- [ ] `VS Code` settings link still resolves to
      `~/Library/Application Support/Code/User/settings.json`.
- [ ] `Cursor` settings link still resolves to
      `~/Library/Application Support/Cursor/User/settings.json`.
- [ ] `lazygit` config still at
      `~/Library/Application Support/jesseduffield/lazygit/config.yml`.
- [ ] `~/.gitconfig.os` exists and points at `.../tools/git/gitconfig.os.macos`.
- [ ] `~/Brewfile` link resolves to `tools/homebrew/Brewfile.mac`.

## 4. Private files still work

```bash
# If you normally run this:
./install private

# Confirm private symlinks are recreated under ~/.dotfiles:
ls -la .dotbot/configs/{carequant,jbctechsolutions,personal}.yaml 2>&1
ls -la shells/zsh/zsh.before/aliases.zsh 2>&1
ls -la apps/{cursor,vscode}/settings.json 2>&1
# Each should be a symlink into ~/.dotfiles-private/... (not dangling).
```

## 5. Runtime smoke

Open a fresh terminal and verify:

```bash
# zsh loads without complaints
exec zsh -l

# Starship prompt renders
echo ready

# 1Password SSH agent still reachable
echo "$SSH_AUTH_SOCK"
# expect: ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
ssh-add -l          # expect: your keys listed

# git signing still works
cd /tmp && git init sign-test && cd sign-test
echo hi > a && git add a && git -c user.email=you@example.com \
    -c user.name=You commit -S -m test
# expect: commit created, signed. No prompt for a missing op-ssh-sign binary.

# tmux clipboard still copies to pasteboard
tmux new-session -d -s clip-test 'sleep 5'
tmux send-keys -t clip-test "echo hello-from-tmux | ~/.dotfiles/tools/tmux/clip-copy" Enter
sleep 1 && pbpaste        # expect: hello-from-tmux
tmux kill-session -t clip-test

# Shell functions still work
localip                   # expect: your LAN IP
sysinfo                   # expect: system info including memory line
```

## 6. If anything fails

- Restore the snapshots from step 0.
- Reply on PR #20 with the failure and the relevant log lines.
- `git switch main` if you need to go back.

## 7. If everything passes

- Great — drop a comment on PR #20 saying "Mac regression clean" so I know
  we can proceed to the droplet test.
