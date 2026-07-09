---
date: 2026-07-09
status: active
type: feat
origin: docs/brainstorms/plugin-update-system-requirements.md
title: "feat: Claude Code plugin update system (pinned, dotfiles-tracked)"
---

# feat: Claude Code Plugin Update System

**Target repo:** `~/.dotfiles` (paths below are relative to the dotfiles root). Branch `feat/plugin-update-system` is checked out.

## Summary

Build a `dot plugins` command (update / restore / status) plus a committed lockfile and a strict-patch store so every Claude Code plugin is pinned, local in-plugin edits survive updates, and a fresh machine reproduces the whole setup. Updating becomes a deliberate, committed act; restore rebuilds pinned state install-then-patch.

---

## Problem Frame

Claude Code installs plugins into versioned cache dirs (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`) that are clobbered on update, destroying any local edit inside a plugin's files (e.g. the superpowers `session-start` quiet-guard). Custom hook scripts and plugin versions are not fully tracked, so machine state can't be rebuilt. See origin: `docs/brainstorms/plugin-update-system-requirements.md`.

---

## Research Findings (grounding)

- **Claude Code CLI surface** (`claude plugin …`): `install <plugin>` (no `--version` flag), `update <plugin>` (latest only), `list --json` (machine-readable installed set), `marketplace update [name]`, `enable`/`disable`, `uninstall`. Marketplaces are git repos under `~/.claude/plugins/marketplaces/<name>`.
- **Pinning must live at the marketplace-git-SHA layer** — because `install` has no version flag, the pinned version is whatever the marketplace repo's checked-out commit exposes. `installed_plugins.json` already records per-plugin `version` + `gitCommitSha` + `installPath` + `scope`.
- **Shared marketplaces:** `claude-plugins-official` hosts superpowers, vercel, frontend-design, commit-commands, etc. Per-plugin pins are honored during restore by *sequencing* — checkout marketplace@SHA → install that plugin → next.
- **dotbot** drives install via `.dotbot/configs/*.yaml`; `claude.yaml` already symlinks `~/.claude/{settings.json,scripts,hooks}` and `known_marketplaces.json`. Shell steps run in file order.
- **Test idiom:** plain shell tests (`tests/*.test.sh` via `tests/run_tests.sh`); shellcheck enforced by `.pre-commit-config.yaml`. No bats.
- **Existing pattern to mirror:** `apps/claude/scripts/quick-add-plugin.sh` — colored output helpers, `set -e`, python3 for JSON edits.

---

## Requirements Traceability

Carried from origin (all addressed): R1 lockfile → U1; R2 deliberate bump → U5; R3 pinned restore → U6; R4 patch storage → U3; R5 fail-loud apply → U3; R6 superpowers first patch (**revised: unconditional, marker dropped**) → U3; R7 tracked hooks → already shipped this session (`apps/claude/hooks/` + `claude.yaml`), verified in U7; R8 install-then-patch ordering → U6/U7; R9 status/drift → U4.

---

## Key Technical Decisions

- **Drive Claude Code's CLI for operations; pin at the marketplace-SHA layer.** Never hand-manage cache dirs (would reimplement the installer and drift from `installed_plugins.json`). The lockfile records, per plugin: `marketplace`, `version`, `gitCommitSha` (the marketplace commit), and `scope`. Restore checks out the marketplace at that SHA, then installs. (origin fork 1)
- **Superpowers quiet is an unconditional patch; drop the `.superpowers-quiet` marker.** One fewer artifact to reproduce; "off switch" = don't apply the patch. Revises origin R6. (origin fork 2)
- **Hook layout settled at `apps/claude/hooks/`** — already shipped and dotbot-wired this session. (origin fork 3)
- **Strict git patches, fail-loud.** Patches stored per `(plugin, version)`; applied with `git apply --check` then `git apply`; any failure halts with the patch named — never `--force`, never skip.
- **Lockfile is generated, not hand-edited.** Source of truth for *current* state is Claude Code; the lockfile is a committed snapshot diffed on update.

---

## Output Structure

```text
apps/claude/plugins/
  plugins.lock.json              # U1 — committed pin snapshot
apps/claude/scripts/
  claude-plugins.sh              # U2 — dot plugins dispatcher (update|restore|status)
apps/claude/patches/
  superpowers/
    6.1.1-quiet-session-start.patch   # U3 — unconditional quiet, seeded
    README.md                    # U3 — patch naming + refresh convention
bin/
  dot                            # U7 — thin entrypoint (or zsh function)
.dotbot/configs/
  claude-plugins.yaml            # U7 — bootstrap restore, ordered after marketplaces
tests/
  claude-plugins.test.sh         # per-unit scenarios
docs/plans/
  2026-07-09-001-feat-plugin-update-system-plan.md
```

The tree is a scope declaration; per-unit **Files** are authoritative.

---

## Implementation Units

### U1. Lockfile format + generator

- **Goal:** Define `plugins.lock.json` and a generator that snapshots current pinned state from Claude Code.
- **Requirements:** R1.
- **Dependencies:** none.
- **Files:** `apps/claude/plugins/plugins.lock.json` (generated artifact, committed), generator logic inside `apps/claude/scripts/claude-plugins.sh` (created in U2 — U1 defines the format + the pure generator function it will call), `tests/claude-plugins.test.sh`.
- **Approach:** Merge `claude plugin list --json` with `~/.claude/plugins/installed_plugins.json` and each marketplace's `git -C <marketplace> rev-parse HEAD`. Emit a stable, sorted JSON: top-level `generatedFrom` note + `plugins` object keyed by `plugin@marketplace`, each `{ version, gitCommitSha, marketplace, scope, enabled }`. Sort keys for clean diffs. Only include plugins that are enabled in `settings.json` (pins track the active set).
- **Technical design (directional, not spec):**
  ```jsonc
  {
    "plugins": {
      "superpowers@claude-plugins-official": {
        "version": "6.1.1", "gitCommitSha": "<marketplace sha>",
        "marketplace": "claude-plugins-official", "scope": "user", "enabled": true
      }
    }
  }
  ```
- **Patterns to follow:** python3 JSON handling as in `apps/claude/scripts/quick-add-plugin.sh`.
- **Test scenarios:**
  - Happy: given a known `list --json` + `installed_plugins.json` fixture, generator emits sorted lock with correct version/sha/marketplace per plugin.
  - Edge: a plugin present in `installed_plugins.json` but disabled in `settings.json` is omitted.
  - Edge: two plugins sharing one marketplace both record that marketplace's SHA.
  - Error: missing/malformed `installed_plugins.json` → non-zero exit with a clear message, no partial lock written.
- **Verification:** Running the generator on the live machine produces a lock whose entries match `claude plugin list` output.

### U2. `claude-plugins.sh` scaffold + subcommand dispatch

- **Goal:** Create the script skeleton with `update|restore|status` dispatch and shared helpers.
- **Requirements:** R1–R9 (host).
- **Dependencies:** U1 (format).
- **Files:** `apps/claude/scripts/claude-plugins.sh`, `tests/claude-plugins.test.sh`.
- **Approach:** `set -euo pipefail`; colored `info/warn/ok/die` helpers mirroring `quick-add-plugin.sh`; resolve the real `claude` binary robustly (the interactive shell wraps it in a zsh function — use `command -v claude` fallback to `/opt/homebrew/bin/claude`, guarded); `usage()` for unknown subcommands; locate dotfiles root relative to the script.
- **Patterns to follow:** `apps/claude/scripts/quick-add-plugin.sh` structure.
- **Test scenarios:**
  - Happy: `claude-plugins.sh status` dispatches to the status function; unknown subcommand prints usage and exits non-zero.
  - Edge: script run from any cwd resolves the dotfiles root and lockfile path correctly.
  - `Covers` shellcheck: file passes `shellcheck` clean (pre-commit gate).
- **Verification:** `shellcheck` passes; dispatch routes each subcommand.

### U3. Patch store + strict fail-loud apply; seed superpowers patch

- **Goal:** Establish `apps/claude/patches/` with naming convention, a strict apply function, and the seeded unconditional superpowers quiet patch.
- **Requirements:** R4, R5, R6 (revised), R8.
- **Dependencies:** U2.
- **Files:** `apps/claude/patches/superpowers/6.1.1-quiet-session-start.patch`, `apps/claude/patches/superpowers/README.md`, apply logic in `apps/claude/scripts/claude-plugins.sh`, `tests/claude-plugins.test.sh`.
- **Approach:** Patch path convention `patches/<plugin>/<version>-<slug>.patch`, targeting paths relative to the plugin's install root. Apply = resolve plugin install root from the lockfile/`installed_plugins.json`, `git apply --check` first, then `git apply --directory=<install root>`; on any failure `die` with the patch name and the failing hunk, leaving the plugin unpatched (no `--force`, no partial). **Re-derive the seeded patch as unconditional** — the current cache guard reads the `.superpowers-quiet` marker; the tracked patch instead makes `session-start` exit before the injection unconditionally. Delete the now-obsolete marker from the machine as part of this unit.
- **Execution note:** Derive the seeded patch from the actual pinned `session-start` file so `git apply --check` is clean at the pinned version.
- **Test scenarios:**
  - Happy: applying the superpowers patch against the pinned `session-start` yields a hook that emits no injection (exit 0, empty stdout).
  - Error (fail-loud): applying against a mutated/newer `session-start` fails `--check` → script halts, names the patch, plugin left unpatched. `Covers AE2.`
  - Idempotence: re-applying an already-applied patch is detected and does not double-apply or error spuriously.
  - Edge: patch for a plugin whose install root is missing → clear error, non-zero exit.
- **Verification:** Fresh-installed superpowers at pinned version + apply → injection quieted; bumping to an incompatible version makes apply fail visibly.

### U4. `status` subcommand (drift detection)

- **Goal:** Report installed-vs-lockfile version drift and unapplied/failing patches.
- **Requirements:** R9.
- **Dependencies:** U1, U3.
- **Files:** `apps/claude/scripts/claude-plugins.sh`, `tests/claude-plugins.test.sh`.
- **Approach:** Regenerate current state (U1 generator, in-memory), diff against committed `plugins.lock.json`; for each tracked patch, `git apply --check --reverse` to detect whether it is currently applied. Print a table: plugin, locked vs installed, patch state (applied / unapplied / would-fail). Exit non-zero when drift or a failing patch exists (usable as a pre-commit/CI check).
- **Test scenarios:**
  - Happy: lock matches installed + patches applied → "clean", exit 0.
  - Edge: installed version ahead of lock → drift row, exit non-zero.
  - Edge: tracked patch not currently applied → flagged, exit non-zero.
  - Error: no lockfile present → actionable message ("run `dot plugins restore` or regenerate"), non-zero.
- **Verification:** Introduce a manual version bump → status flags it; apply patch → status shows applied.

### U5. `update` subcommand (deliberate bump)

- **Goal:** Update marketplaces/plugins to latest, surface bumps for review, regenerate lockfile, reapply patches, relink hooks, report a committable diff.
- **Requirements:** R2, R5, R7.
- **Dependencies:** U1, U3, U4.
- **Files:** `apps/claude/scripts/claude-plugins.sh`, `tests/claude-plugins.test.sh`.
- **Approach:** `claude plugin marketplace update` → compute available bumps (`list --available --json` vs current) → present the bump set and apply (`claude plugin update <plugin>`) → regenerate `plugins.lock.json` → reapply each tracked patch at its new version (fail-loud; a version-changed patch that no longer applies halts with a "refresh this patch" message) → run the hook relink step → print `git diff --stat` of lock + patches for Joel to commit. Never auto-commit.
- **Execution note:** A patch failing after a bump is expected signal, not a bug — surface the exact patch to re-derive.
- **Test scenarios:**
  - Happy: a plugin with a newer version → lock entry bumped, diff surfaced.
  - Edge: shared-marketplace bump surfaces sibling plugins as also-updatable (documented behavior, not silent).
  - Error: post-bump patch no longer applies → halts, names the patch, does not leave a half-updated commit staged.
  - Edge: no updates available → "up to date", no lock change.
- **Verification:** Run against a plugin with an upstream bump; confirm lock diff + patch reapply + surfaced report.

### U6. `restore` subcommand (pinned rebuild, install-then-patch)

- **Goal:** Rebuild pinned plugin state from the lockfile on a fresh machine.
- **Requirements:** R3, R8.
- **Dependencies:** U1, U3.
- **Files:** `apps/claude/scripts/claude-plugins.sh`, `tests/claude-plugins.test.sh`.
- **Approach:** Ensure marketplaces registered (`claude plugin marketplace add` when absent, sourced from tracked `known_marketplaces.json`). For each locked plugin, in sequence: `git -C <marketplace> checkout <gitCommitSha>` → `claude plugin install <plugin@marketplace> --scope <scope>` → assert installed version == locked version (else fail-loud) → apply its tracked patch. Then symlink hooks (dotbot owns this; restore is idempotent with it).
- **Deferred to implementation (verify at execution):** whether `claude plugin install` installs from the *local* marketplace checkout or re-pulls the remote to latest. If it re-pulls, SHA-checkout alone won't pin — fall back to a post-install version assert plus either a pinned marketplace mirror or a detached-worktree checkout. The version-assert step above already fails loud if pinning didn't take, so restore is safe either way; this only decides whether an extra mirror step is needed.
- **Test scenarios:**
  - Happy (mocked `claude`): each locked plugin triggers checkout→install→assert→patch in order; final state matches lock. `Covers AE3.`
  - Error: installed version ≠ locked after install → fail-loud, restore halts on that plugin.
  - Edge: marketplace not yet registered → added from tracked config before install.
  - Edge: plugin already installed at locked version → skip reinstall, still verify patch applied.
- **Verification:** On a scratch profile / dry-run, restore reproduces locked versions + applied patches; version-assert catches a deliberate mismatch.

### U7. dotbot bootstrap wiring + `dot` entrypoint

- **Goal:** Make restore run on fresh-machine bootstrap (correctly ordered) and expose the `dot plugins` entrypoint.
- **Requirements:** R7, R8.
- **Dependencies:** U6.
- **Files:** `.dotbot/configs/claude-plugins.yaml`, `bin/dot` (or a zsh function in `shells/`), verify `apps/claude/hooks/` link in `.dotbot/configs/claude.yaml` (shipped), `tests/claude-plugins.test.sh`.
- **Approach:** New dotbot config with a shell step invoking `apps/claude/scripts/claude-plugins.sh restore`, ordered **after** marketplace registration and Claude Code install checks (sequence via the config's position in the profile). Add a `dot` entrypoint (thin `bin/dot` dispatcher, or zsh function) so `dot plugins <cmd>` maps to the script — keep it minimal, matching how existing tools are exposed. Confirm the hooks symlink from `claude.yaml` resolves (`compound-first.sh`, `cairn-writeback-reminder.sh`).
- **Test scenarios:**
  - Happy: `dot plugins status` routes to the script.
  - Edge: bootstrap config ordering places restore after marketplace setup (assert file/profile order).
  - Test expectation: dotbot yaml itself is declarative config — validate via `dot plugins status` post-bootstrap rather than unit-testing the yaml.
- **Verification:** Dry-run bootstrap on a scratch `$HOME` (or documented manual check) installs pinned plugins then applies patches then links hooks, in that order.

---

## Scope Boundaries

- Vendoring whole plugins into dotfiles — out (pinning + marketplace installs suffice).
- Scheduled/automatic updates — out; `dot plugins update` stays manual.
- MCP-server management — out; `local/outlook-mcp` unchanged.
- Cross-tool (Codex/OpenCode) plugin management — out; Claude Code only.
- Self-healing / overlay patch mechanisms — out; strict fail-loud only.

### Deferred to Follow-Up Work

- A `dot plugins verify` CI gate wired into `.pre-commit-config.yaml` or `.github/workflows/` — natural extension of U4's non-zero-exit `status`, but a separate PR.

---

## Risks & Mitigations

- **`claude plugin install` may re-pull the marketplace to latest**, defeating SHA checkout. *Mitigation:* U6's post-install version-assert fails loud; escalate to a pinned mirror only if the execution check shows re-pull behavior.
- **Shared-marketplace pins interact** — bumping one plugin advances the marketplace clone for siblings. *Mitigation:* update surfaces sibling updatability explicitly; restore sequences per-plugin SHA checkouts.
- **Patch rot on version bumps.** *Mitigation:* strict `git apply --check` fails loud with the patch named; refresh is a deliberate step, consistent with the pinning philosophy.
- **Mutating live plugin state during test runs.** *Mitigation:* tests mock the `claude` binary and use fixtures; live verification is dry-run / scratch-profile only.

---

## Verification Strategy

- `shellcheck` clean (pre-commit) for all new shell.
- `tests/run_tests.sh` green for `tests/claude-plugins.test.sh`.
- Live smoke: regenerate lock → `status` clean; apply superpowers patch → injection quieted; deliberate version mismatch → `restore`/`status` fail loud.

---

## Outstanding Questions

### Deferred to Planning
(none — forks resolved above)

### Deferred to Implementation
- [Affects U6] Does `claude plugin install` honor the local marketplace checkout or re-pull remote? Determines whether a marketplace mirror step is needed. Verify before finalizing restore.
- [Affects U7] `dot` entrypoint form — thin `bin/dot` dispatcher vs zsh function — pick whichever matches existing tool exposure once in the repo.
