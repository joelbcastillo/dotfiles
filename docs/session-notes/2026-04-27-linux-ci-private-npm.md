# Session notes — 2026-04-27

Internal recap of work and decisions from the Cursor session (Linux CI, private repo CI, npm / dmux upkeep).

## Linux CI (`joelbcastillo/dotfiles`)

- **Failure:** `test-linux-bootstrap` (Docker) failed with `mkdir: cannot create directory '/root': Permission denied` near end of bootstrap.
- **Cause:** `sudo -u ci -E env …` preserved **`HOME=/root`** while running as user **`ci`**, so scripts targeted `/root`.
- **Fix:** In `scripts/test-linux-docker.sh`, stop using **`sudo -E`**. Use e.g. `sudo -u ci bash -c "export NONINTERACTIVE=1 CI=1; …"` so `HOME` resolves to `/home/ci`. Avoid apostrophes inside the outer single-quoted `docker … bash -c '…'` block (they break parsing).
- **Status:** Landed on branch **`linux-compat`** (PR **#20**); re-run CI to confirm `test-linux`, `test-linux-bootstrap`, and `test-macos` are green before merge.

## Private dotfiles CI (`joelbcastillo/dotfiles-private`)

- **Gap:** No `.github/workflows` on **`linux-compat`** / PR **#3**.
- **Added:** `.github/workflows/test.yml` with **`test-linux`** and **`test-macos`**, both running **`scripts/test-static.sh`**.
- **`scripts/test-static.sh`:** `zsh -n` on all `*.zsh`; `bash -n` + optional `shellcheck` (warn-only) on `install` and `*.sh` (includes the script itself). No Docker bootstrap (no `bootstrap-linux.sh` in that repo).
- **Commit:** `03f1a18` on **`linux-compat`**; CI run **24976635209** succeeded.

## dmux / npm globals (public dotfiles)

- **Question:** Keep **dmux** (and related CLIs) up to date without a second version manager (mise) parallel to **asdf**.
- **Decision:** Use **`npm install -g …@latest`** from one script; no Homebrew formula dependency for dmux.
- **Implementation (on `main`, commit `e8d1c63`):**
  - **`scripts/upgrade-claude-npm-tools.sh`** — installs `dmux@latest`, `happy-coder@latest`, `@getpaseo/cli@latest`.
  - **`.dotbot/configs/claude-tools.yaml`** — runs that script when `npm` is on `PATH`, so re-running the **`claude-tools`** config refreshes versions.
  - **`shells/zsh/zsh.before/claude-tools.zsh`** — function **`upgrade-claude-npm-tools`** for ad-hoc upgrades.
- **Caveat:** Profile **`ai-tools`** runs **`claude-tools`** without **`languages/nodejs`**; **`npm`** must already exist. Profile **`full`** orders Node before **`claude-tools`**.

## dmux in dotfiles (Mac vs Linux)

- **Install path:** `.dotbot/configs/claude-tools.yaml` (profiles **`full`**, **`ai-tools`**).
- **Shell:** `alias dm='dmux'` in `shells/zsh/zsh.before/claude-tools.zsh`.
- **Private:** `~/.config/dmux/config.yaml` via **`dotfiles-private`** (`claude-tools-private.yaml`).
- **Linux:** Full **`./install profile full`** requires the **Linux-capable** `install` script (e.g. **`linux-compat`** merge) plus **`scripts/bootstrap-linux.sh`** first; classic **`main`** `install` may still be macOS-only until merged.

## Local / uncommitted (machine state)

- **`~/.dotfiles-private/vscode/settings.json`:** local edits (theme + blank-line cleanup) were left unstaged when adding private CI — do not assume they are on the remote.

## Follow-ups (optional)

- Merge **public PR #20** and **private PR #3** when CI and review are satisfied.
- Merge **`linux-compat`** → **`main`** on public dotfiles so Linux install path and CI fixes ride with default branch.
- Droplet smoke: **`LINUX_MIGRATION_TEST_ON_DROPLET.md`** (public repo) when ready.
