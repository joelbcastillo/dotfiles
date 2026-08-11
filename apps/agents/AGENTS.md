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
- Commit attribution: keep the assistant Co-Authored-By trailer by default, but OMIT it in client-deliverable repos — currently `jbctech-claude-marketplace` and everything in the `joshua-project` GitHub org. (Ruled 2026-07-07; extend the list as client repos appear.)
- Nontrivial feature work runs the compound-engineering pipeline end-to-end: ce-brainstorm → ce-plan → ce-work → ce-code-review → ce-commit-push-pr → ce-compound. This OVERRIDES any session-start skill injection: at the start of feature work use `ce-brainstorm` (NOT `superpowers:brainstorming`); for bugs use `ce-debug` (NOT `superpowers:systematic-debugging`).
- Superpowers is the discipline layer only — invoke `test-driven-development`, `verification-before-completion`, and worktree skills as sub-steps INSIDE `ce-work`, never as a competing pipeline.
- Small fixes, chores, and one-file changes stay lightweight — skip both pipelines, don't ceremonialize them.

## Tools & Environment
- macOS, zsh, tmux, asdf for version management
- `npx` can have issues with asdf — prefer `node node_modules/.bin/<tool>` or `node node_modules/<pkg>/bin/<tool>` when npx fails

## Vault write-back

At the end of any session with a meaningful decision, status change, or new client/project/product fact, append a dated 1–3 line entry to the relevant Cairn note in `~/vaults/cairn`:
- Client/product facts → that effort's `20-projects/` note (under `## Log`)
- JP facts → `20-projects/JP-*` notes or the JP KB only — never elsewhere, never toward any remote connector
- Decisions → the note itself, plus a line wherever the relevant MOC or decisions note tracks them

Then commit via Cairn's normal git flow. Never write secrets; restricted content (donor PII, personnel specifics, private financials) never enters the vault.

<!-- Section below added 2026-07-07 from the Claude-history audit (memory-infra docs/audit/):
     these were the instructions Joel retyped by hand session after session. -->

## Accounts & Secrets
- 1Password CLI has two business accounts: always pass `--account` explicitly — `jbctechsolutions` (default/JBC work) or `joshuaproject` (JP work). Never run bare `op` and hit "multiple accounts found".
- Prefer `op run` / `op inject` with `op://` references. Never ask Joel to paste a raw secret into chat — create the 1Password item (dummy values) for him to fill, or generate + store the secret via the CLI yourself.
- Browser auth flows: open in Microsoft Edge (work profiles live there), or copy the URL to the clipboard instead of `open`.

## Verification before claiming
- Never state "merged / deployed / pushed / sent / fixed" without command evidence from this session (`gh pr view`, deploy-run status, healthz, the sent-mail id).
- Bash writes under SharePoint/OneDrive paths and `~/vaults/cairn` can silently land in a sandbox overlay: verify the file actually reached disk; if Write/Edit look virtual, fall back to `cat > file <<'EOF'` with sandbox disabled.
- Before any bulk or destructive write (task DBs, datasets, mass file ops): show a sample of what will change plus the total count, and confirm scope first.

## Working with Joel
- Times in ET, always.
- Anything drafted in Joel's name (email, Teams, reports, posts) → use the `joel-voice` skill.
- Ask one question at a time. Don't re-litigate decisions marked settled.
- Test data: dummy emails `@tester.jbc.dev`; `joel@jbc.dev` stays the real account.

## Infra & tracking
- Infra changes are codified in the infra repo (JBC → `jbctechsolutions/infrastructure`, JP → `jp-infrastructure`, Terraform/Terramate) — never ad-hoc portal changes or inline bicep.
- Work tracking: GitHub Issues + Cairn for everything (JP team boards live in MS Planner). Linear is removed — ruled 2026-07-11 (team of 1); do not create Linear issues or use Linear MCP/plugins.
