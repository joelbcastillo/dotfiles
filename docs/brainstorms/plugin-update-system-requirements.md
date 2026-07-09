---
date: 2026-07-09
topic: plugin-update-system
---

# Claude Code Plugin Update System (dotfiles-tracked)

## Summary

A `dot plugins` update system in the dotfiles that pins every Claude Code plugin to an exact version in a committed lockfile, re-applies local in-plugin edits as strict git patches after each install, and tracks all custom hook scripts — making `dot plugins update` a deliberate, committed act and letting a fresh machine reproduce the full plugin setup.

---

## Problem Frame

Claude Code installs plugins into versioned cache directories (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`). Any local edit inside a plugin's own files is destroyed when that plugin updates to a new version directory — as happened this session with the marker-guard that quiets the superpowers `session-start` auto-injection. Custom SessionStart hook scripts (`compound-first.sh`, `cairn-writeback-reminder.sh`) live in `~/.claude/hooks/`, which is not dotfiles-tracked, so they do not reproduce on a fresh machine. Plugin versions are recorded only in Claude Code's own `installed_plugins.json` (with `version` + `gitCommitSha`), which is likewise untracked. The result: local customization is fragile against updates, and the machine's plugin state cannot be reliably rebuilt.

---

## Actors

- A1. Joel: runs `dot plugins update`, reviews and commits the resulting lockfile/patch changes.
- A2. Claude Code plugin installer: owns marketplace clones and versioned plugin installs; the source of truth the lockfile is derived from and restored through.
- A3. dotbot: the dotfiles installer that symlinks tracked hook scripts and runs the plugin restore/patch step during bootstrap.

---

## Key Flows

- F1. Update
  - **Trigger:** Joel runs `dot plugins update` (manual, deliberate).
  - **Actors:** A1, A2
  - **Steps:** update marketplaces to latest → surface which plugins have newer versions → on accepted bumps, update the plugin and regenerate the lockfile entry (version + SHA) → re-apply tracked patches for affected plugins → relink hooks → report a diff of version + patch changes for Joel to commit.
  - **Outcome:** lockfile and any refreshed patches are staged for commit; local customizations intact.
  - **Covered by:** R1, R2, R4, R5, R7

- F2. Fresh-machine restore
  - **Trigger:** dotbot bootstrap on a new machine (or `dot plugins restore`).
  - **Actors:** A2, A3
  - **Steps:** ensure marketplaces are registered → install each plugin at its **pinned** lockfile version → apply tracked patches (install-then-patch order) → symlink tracked hook scripts into `~/.claude/hooks/` → place marker files.
  - **Outcome:** plugin set, versions, patches, and hooks match the committed dotfiles state.
  - **Covered by:** R1, R3, R5, R6, R8

---

## Requirements

**Version pinning**
- R1. Maintain a committed lockfile in the dotfiles recording every enabled plugin's exact version and git commit SHA, derived from Claude Code's `installed_plugins.json`.
- R2. `dot plugins update` bumps lockfile entries only as a deliberate action; a version change is never silent — it surfaces for review and lands as a committed diff.
- R3. Restore installs each plugin at its pinned lockfile version, not latest.

**Local patches**
- R4. Store in-plugin edits as strict git patch files in the dotfiles, one identifiable per (plugin, pinned version).
- R5. Apply patches after the pinned plugin is installed; a patch that fails to apply (e.g., upstream changed the target file after a bump) must fail loudly and stop, signalling that the patch needs re-deriving — never silently skip or force.
- R6. The superpowers quiet-guard is the first tracked patch; its marker file (`.superpowers-quiet`) is reproduced by the restore flow.

**Hook scripts + reproduction**
- R7. Track all custom Claude Code hook scripts (`compound-first.sh`, `cairn-writeback-reminder.sh`, future ones) in the dotfiles and symlink them into `~/.claude/hooks/` via dotbot, so `settings.json` hook references resolve on any machine.
- R8. Bootstrap ordering guarantees install-then-patch-then-link: patches and hook links are only valid once Claude Code has installed the pinned plugins.

**Operability**
- R9. Provide a status/verify command that reports drift — installed versions vs. lockfile, and patches that are unapplied or failing.

---

## Acceptance Examples

- AE1. **Covers R5.** Given superpowers is pinned at a version whose `session-start` file matches the patch, when restore runs, the guard patch applies cleanly and the injection is quieted.
- AE2. **Covers R2, R5.** Given `dot plugins update` bumps superpowers to a version whose `session-start` file changed, when the patch is applied, the step fails loudly and halts with the failing patch named — rather than leaving a half-patched or unpatched plugin silently.
- AE3. **Covers R1, R3.** Given a fresh machine with only the dotfiles, when bootstrap runs, every plugin is installed at its pinned lockfile version and the resulting state matches the committed lockfile.

---

## Success Criteria

- A superpowers (or any patched-plugin) update no longer silently loses local customizations — the patch either re-applies or fails visibly.
- A fresh machine reproduces the same plugin versions, patches, hooks, and marker files from the committed dotfiles alone.
- Joel can see, before committing, exactly which plugin versions and patches changed in an update.
- A downstream implementer (ce-plan / ce-work) can build this without inventing the version-pin source, the patch failure policy, or the bootstrap ordering.

---

## Scope Boundaries

- Vendoring whole plugins into the dotfiles — rejected; pinning + marketplace installs is enough.
- Scheduled or automatic updates (cron, session-hook triggered) — updates stay a manual, deliberate command.
- MCP-server management — out of scope; the existing `local/outlook-mcp` plugin stays as-is.
- Cross-tool (Codex/OpenCode) plugin management — this system targets Claude Code only.
- Self-healing / overlay patch mechanisms — deliberately not chosen in favor of strict, fail-loud patches.

---

## Key Decisions

- Pin all plugins via a committed lockfile (over floating latest): reproducibility is a stated goal; updates become deliberate committed bumps.
- Strict git patches (over idempotent-reapply or file-overlay): a broken patch after a version bump should fail loudly so it gets re-derived, not silently mis-applied or clobber upstream fixes.
- Extend the existing dotfiles plugin-script family (`quick-add-plugin.sh`, `setup-project-plugins.sh`) and dotbot, rather than introduce a new install mechanism.

---

## Dependencies / Assumptions

- The lockfile is derivable from `installed_plugins.json`, which already records `version` + `gitCommitSha` per plugin (verified this session).
- dotbot can run a shell step during bootstrap to invoke the plugin restore/patch flow, in addition to symlinking hook scripts.
- Marketplace sources are already tracked (`known_marketplaces.json` in dotfiles) and stable.

---

## Outstanding Questions

### Deferred to Planning

- [Affects R2, F1][Technical] Should `dot plugins update` drive Claude Code's own plugin-update path (keeping `installed_plugins.json` authoritative), or manage the marketplace git repos and cache directly? Determines how the lockfile is generated and restored.
- [Affects R6][Technical] Fold the superpowers "quiet" into the patch unconditionally, or keep it gated on the `.superpowers-quiet` marker? Marker keeps a runtime off-switch; unconditional is simpler.
- [Affects R7][Technical] Move `compound-first.sh` and `cairn-writeback-reminder.sh` into `~/.dotfiles/apps/claude/hooks/` and symlink, vs. another tracked location — layout detail for planning.
