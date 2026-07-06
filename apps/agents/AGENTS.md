<!--
Canonical cross-tool agent instructions (global).
Symlinked from each tool's global instruction file:
  ~/.claude/CLAUDE.md          (Claude Code)
  ~/.codex/AGENTS.md           (OpenAI Codex CLI)
  ~/.config/opencode/AGENTS.md (OpenCode)
Cursor has no global file-based rules: paste this content into
Cursor Settings -> Rules (User Rules). Edit THIS file, not the symlinks.
-->

# Global Preferences

## Communication
- Be concise. Skip summaries of what was just done — I can read the diff.
- Default to action over explanation unless I ask "why".

## Code Style
- Prefer simple, direct solutions. Don't over-engineer.
- Don't add comments, docstrings, or type annotations to code you didn't change.
- Follow existing patterns in the codebase.

## Git & PRs
- Default: feature branches from `main`, PRs target `main`, merge + tag for release. Delete the feature branch after merge.
- Exception: repos with a staging/production split (currently only `jp-adopt-platform`) keep `dev` → `main` (push to dev deploys staging, push to main deploys production). For these, feature branches cut from `dev`, PRs target `dev`.
- Use conventional commit style (feat:, fix:, chore:, etc.).

## Tools & Environment
- macOS, zsh, tmux, asdf for version management
- `npx` can have issues with asdf — prefer `node node_modules/.bin/<tool>` or `node node_modules/<pkg>/bin/<tool>` when npx fails

## Vault write-back

At the end of any session with a meaningful decision, status change, or new client/project/product fact, append a dated 1–3 line entry to the relevant Cairn note in `~/vaults/cairn`:
- Client/product facts → that effort's `20-projects/` note (under `## Log`)
- JP facts → `20-projects/JP-*` notes or the JP KB only — never elsewhere, never toward any remote connector
- Decisions → the note itself, plus a line wherever the relevant MOC or decisions note tracks them

Then commit via Cairn's normal git flow. Never write secrets; restricted content (donor PII, personnel specifics, private financials) never enters the vault.
