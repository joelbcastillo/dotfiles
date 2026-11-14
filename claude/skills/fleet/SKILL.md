---
name: fleet
description: One screen for Joel's 50+ concurrent Claude sessions and the PRs they produced. Use when he asks "what's open", "where was I", "what can I ship", "show me the fleet", "what's shippable", or at the start of a session when he needs to pick up a thread across projects. Read-only.
---

# Fleet

Joel runs 50+ Claude sessions at once across ~19 repos, inside cmux. Two questions matter:
**hunt** ("where was I?") and **scan** ("what finished so I can ship it?"). This answers both.

Run the script — do not reimplement it, and do not read the raw data files yourself:

```bash
~/.dotfiles/bin/claude-tools/fleet
```

| flag | use |
|---|---|
| `--sessions` | hunt only. Instant, no network. |
| `--prs` | scan only. |
| `--repo <substr>` | narrow both halves to one project |
| `--all` | every session and PR, not just the top slice |
| `--limit N` | sessions shown (default 12) |
| `--refresh` | bypass the 10-minute PR cache |
| `--json` | machine-readable, for further filtering |
| `--serve` | live page at `http://127.0.0.1:8777`, auto-refreshing every 20s (`--port` to change) |

`--serve` binds the port before fetching anything, so the page is reachable in about a second;
the session half renders immediately and the PR half fills in when the first background fetch
lands (~20s cold). A failed PR fetch shows an error in the PR column instead of taking the
server down. It listens on loopback only — it is not reachable from jbc-dev-mac over SSH
without a tunnel.

## Reading the output

- **WAITING ON YOU** — the session's newest feed record is a `question` or `permissionRequest`.
  This is the trustworthy "needs Joel" signal. Do **not** use cmux's `agent_lifecycle: needsInput`
  for this; it also fires when a session is waiting on a *teammate message from another session*,
  which is agent-to-agent traffic Joel does not need to see.
- **WHERE YOU WERE** — sorted by when Joel last typed. The label is the session's **opening ask**
  pulled from its transcript, not its most recent message (which is usually "Yes" or "go for it").
  `●` green = running, `●` yellow = needsInput, `○` = idle.
- **SHIPPABLE** — open PRs that are green (or have no CI), not draft, not awaiting requested
  changes, and in a confirmed-ready merge state (`CLEAN`, `HAS_HOOKS`, or `BEHIND`). Grouped by
  repo, busiest repo first, then newest-updated within each group — so a brand-new PR in a quiet
  repo sits below a stack of older ones, and the default cuts off at 12 rows. Use `--all` for the
  whole list or `--repo <substr>` to narrow to one project.

## Where the data comes from

- Sessions: `cmux sessions list --agent claude --json --all` (local file, no socket needed)
- Session labels + branch: the live transcripts under `~/.ccs/instances/<instance>/projects/`,
  located via each record's `session_dir`. **Not** `~/.claude/projects`, which is stale —
  CCS redirects the config dir per instance, so anything reading `~/.claude/projects` (FleetView,
  herdr's session mods, `cmux vault sessions`) sees a months-old picture and misses the live fleet.
- Last-typed time: `~/.cmuxterm/workstream.jsonl`, cmux's unified hook feed across every session.
- PRs: `gh search prs --author @me` to find the repo set, then parallel `gh pr list` per repo.

Caches live in `~/.cache/fleet/` — `prs.json` (10 min TTL) and `intents.json` (keyed by
transcript mtime+size, so a session's opening ask is parsed once).

## Following up

When Joel picks something out of the list:
- To ship a PR → use the `ship` skill.
- To resume a session → `fleet --json` gives each row a `sid` and its full `cwd` (the `repo`
  field is a shortened display label, and two worktrees of the same repo share it — always
  resume from `cwd`, not `repo`):

  ```bash
  fleet --json --sessions | python3 -c "
  import sys,json
  for r in json.load(sys.stdin)['sessions'][:10]:
      print(f\"cd {r['cwd']} && claude --resume {r['sid']}   # {r['label'][:50]}\")"
  ```
