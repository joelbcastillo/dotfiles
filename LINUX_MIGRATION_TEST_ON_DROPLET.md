# Ubuntu 24.04 Droplet Test Plan

Full verification on a fresh DigitalOcean (or any Ubuntu 24.04) droplet.
Assumes:

- Brand-new Ubuntu 24.04 box.
- You have SSH access as a non-root user with `sudo`.
- 1Password account available (for `op signin` later — optional for the
  smoke portion).

## 0. Prep

```bash
# On the droplet
sudo apt-get update -y
sudo apt-get install -y git curl
```

## 1. Clone

```bash
git clone https://github.com/joelbcastillo/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git switch linux-compat
```

## 2. Run the Linux bootstrap

This installs zsh + the CLI stack via apt and direct installers. It will
prompt for your sudo password.

```bash
scripts/bootstrap-linux.sh
```

Expected:

- [ ] `apt-get install` completes for `zsh tmux git jq tree ripgrep fd-find
      fzf direnv bat htop neofetch xclip` etc. without errors.
- [ ] `gh` installs via the GitHub apt repo.
- [ ] `1password-cli` installs via the 1Password apt repo.
- [ ] `starship`, `zoxide`, `eza` install via their installers / apt.
- [ ] `~/.asdf/` exists (git-cloned).
- [ ] `~/.local/bin/{fd,bat}` are symlinks to `fdfind`/`batcat`.
- [ ] Final line: `Base bootstrap complete.`

Sanity-check that the bootstrap actually put tools on `PATH`:

```bash
exec bash -l   # pick up updated PATH
for t in zsh tmux git rg fd fzf bat eza zoxide direnv jq gh op starship; do
    command -v "$t" >/dev/null && echo "✅ $t" || echo "❌ $t MISSING"
done
```

## 3. Init submodules + install the Linux profile

```bash
cd ~/.dotfiles
git submodule update --init --recursive
./install profile linux
```

Watch for:

- [ ] Every macOS-only config prints `⏭  Skipping ... — not on macOS` (or
      `macOS-only`). Specifically:
      - `brew`: "⏭  Skipping Homebrew setup — not on macOS"
      - `hammerspoon`: "⏭  Skipping Hammerspoon — macOS-only"
      - `colima`: "⏭  Skipping Colima — macOS-only (Linux uses native Docker)"
      - `finicky`: "⏭  Skipping Finicky — macOS-only"
      - `touchid`: "⏭  Skipping TouchID for sudo — not on macOS" (stdout
        may be suppressed; confirm `/etc/pam.d/sudo` is unchanged).
- [ ] `zsh` config links succeed:
      `ls -la ~/.zshenv ~/.zprofile ~/.zshrc ~/.zsh.before ~/.zsh.after`
      should all be symlinks into `~/.dotfiles/shells/zsh/`.
- [ ] `chsh` prompts once for your password and succeeds (`echo $SHELL`
      shows `/usr/bin/zsh` on next login).
- [ ] `~/.gitconfig.os` is a symlink to
      `~/.dotfiles/tools/git/gitconfig.os.linux`.
- [ ] `~/.config/Code/User/settings.json`, `~/.config/Cursor/User/settings.json`,
      `~/.config/lazygit/config.yml` are symlinks to the repo.
- [ ] `~/.asdfrc`, `~/.tool-versions` are symlinks.
- [ ] AI tools step installs:
      - `claude` → `npm install -g @anthropic-ai/claude-code`
      - `cursor-agent` → curl installer to `~/.local/bin`
      - GitHub Copilot CLI → `gh extension install github/gh-copilot`

## 4. Fresh shell

```bash
exec zsh -l
```

Expected:

- [ ] Starship prompt renders.
- [ ] No "command not found" errors on startup.
- [ ] Submodule-supplied plugins (zsh-autosuggestions,
      zsh-syntax-highlighting) load.
- [ ] `localip`, `sysinfo`, `extract` functions work.
- [ ] `z foo` / `zoxide` works.
- [ ] `SSH_AUTH_SOCK` is either unset (no 1P agent yet) or points at
      `~/.1password/agent.sock` (if you later set up the 1P Linux app).

## 5. AI / dev tools smoke

```bash
claude --version            # expect: version string
cursor-agent --version      # expect: version string
gh copilot --help           # expect: gh-copilot help text
asdf --version              # expect: 0.14.x
python3 --version           # expect: 3.12.x (or whatever asdf picked)
node --version              # after `asdf install nodejs ...` if not yet done
```

## 6. tmux clipboard

```bash
tmux new-session -d -s clip-test
tmux send-keys -t clip-test "echo hello-droplet | ~/.dotfiles/tools/tmux/clip-copy" Enter
sleep 1
xclip -selection clipboard -out   # expect: hello-droplet
tmux kill-session -t clip-test
```

If the droplet is headless (no X), `clip-copy` will fall back to swallowing
stdin and tmux copy-mode will still populate tmux's own buffer — that's
expected.

## 7. 1Password on Linux (optional)

If you install the 1Password Linux desktop app and want SSH signing:

```bash
# After signing in to the 1Password Linux app and enabling SSH agent:
echo "$SSH_AUTH_SOCK"   # expect: $HOME/.1password/agent.sock
ssh-add -l               # expect: your 1P keys

# Test git signing:
cd /tmp && git init sign-test && cd sign-test
echo hi > a && git add a && git commit -S -m test
# expect: signed commit. `gitconfig.os.linux` points gpg.ssh.program at
# /opt/1Password/op-ssh-sign.
```

If you're on a headless droplet without the Linux desktop, skip this step
— signing will fail because `/opt/1Password/op-ssh-sign` doesn't exist. In
that case either:
- set `git config --global commit.gpgsign false` locally on the droplet, or
- install a different SSH-signer and update `~/.gitconfig.os` (or the
  tracked `gitconfig.os.linux`) to point at it.

## 8. Private repo (optional)

If / when you want your private bits on the droplet (aliases, SSH configs,
secure profiles), and after I've finished the separate private-repo Linux
audit:

```bash
cp config.json.example config.json
# Edit config.json with your private repo URL.
./install private
```

Verify the symlinks get recreated under
`~/.dotfiles/shells/zsh/zsh.before/aliases.zsh`,
`~/.dotfiles/shells/oh-my-zsh/custom/secure_profiles/*`, etc., pointing into
`~/.dotfiles-private/...` (which was cloned to `$HOME` — no `/Users/...`
path required).

## 9. Report

- All checks pass: comment "Droplet clean" on PR #20 — we can mark it
  ready-for-review.
- Any failure: paste the failing command + output into the PR. Don't
  merge.

## Notes / known caveats

- `bootstrap-linux.sh` installs to `$HOME/.local/bin` and expects it on
  PATH. The Linux `zshenv` already ensures that; if you run commands before
  sourcing zsh, you may need `export PATH="$HOME/.local/bin:$PATH"`.
- Python/Node install via `asdf` (kicked off by the profile) takes a while
  the first time — it's compiling, not fetching binaries.
- `brew bundle` is **not** run on Linux. `Brewfile.linux` is tracked as a
  reference only.
- This branch does not install VS Code desktop, Cursor desktop, or
  `code-server` on Linux — those are a separate follow-up if you want them.
