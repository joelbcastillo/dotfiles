#!/usr/bin/env bash
# SessionStart context injection — compound-engineering first.
# Measured replacement for the (now-quieted) superpowers session-start injection.
# Reinforces ~/.config/agents/AGENTS.md by naming the pipeline entry points so the
# agent reaches for ce-brainstorm / ce-debug before the superpowers equivalents.
# A hook can only inject an instruction; it cannot auto-run a skill.
set -euo pipefail

MSG='Workflow default (reinforces CLAUDE.md): nontrivial feature/bug work runs the compound-engineering pipeline.\n- New feature / \"let'\''s build X\" → use ce-brainstorm (NOT superpowers:brainstorming).\n- Bug / \"why is this failing\" → use ce-debug (NOT superpowers:systematic-debugging).\n- Then ce-plan → ce-work → ce-code-review → ce-commit-push-pr → ce-compound.\n- Superpowers is the discipline layer only (test-driven-development, verification-before-completion, worktrees), invoked INSIDE ce-work — never a competing pipeline.\n- Small fixes, chores, one-file changes: skip both, stay lightweight.'

printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$MSG"
