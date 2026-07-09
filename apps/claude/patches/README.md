# Claude Code plugin patches

Strict, fail-loud patches for local edits *inside* a plugin's own files — edits
that Claude Code's versioned plugin cache would otherwise clobber on update.

Applied and re-applied by `apps/claude/scripts/claude-plugins.sh` (`dot plugins
restore` / `update` / `status`).

## Layout

```
patches/<plugin-short-name>/<version>-<slug>.patch
```

- `<plugin-short-name>` matches the part before `@` in the plugin id
  (e.g. `superpowers` for `superpowers@claude-plugins-official`). The script maps
  it back to the enabled plugin id via the lockfile.
- `<version>` is the plugin version the patch was derived against.
- Paths inside the patch are **relative to the plugin's install root**
  (e.g. `hooks/session-start`), applied with `git apply --directory=<install root>`.

## Conventions

- **No `index` line.** Blob SHAs and file-mode assertions drift; the diff hunks
  are the contract. Generate, then strip any `index …` line.
- **Fail loud.** The script runs `git apply --check` before applying. If a patch
  no longer applies (upstream changed the file after a version bump), the script
  halts and names the patch — it never `--force`s or skips.
- **Refreshing after a version bump:** re-derive the patch against the new pinned
  version and rename the file to the new `<version>-<slug>.patch`. A patch that
  fails `--check` is the signal to do this, not a bug.

## Current patches

- `superpowers/6.1.1-quiet-session-start.patch` — disables superpowers'
  `SessionStart` auto-injection unconditionally, so the compound-engineering
  pipeline owns the workflow (see `apps/agents/AGENTS.md` + the compound-first
  SessionStart hook). Skills remain invocable on demand via the Skill tool.
