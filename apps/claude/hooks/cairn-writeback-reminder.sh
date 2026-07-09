#!/bin/bash
# SessionEnd: remind about Cairn vault write-back when the session ran in a work-classified repo
d=$(jq -r '.cwd // empty' 2>/dev/null)
case "$d" in
  */.repos/github.com/jbctechsolutions/*|*/.repos/github.com/joshua-project/*)
    repo=$(basename "$d")
    printf '{"systemMessage":"📝 Cairn write-back: this session ran in %s — if it produced a decision, status change, or new fact, add a dated line under ## Log in its ~/vaults/cairn/20-projects/ note (see the repo CLAUDE.md for which one) and commit."}\n' "$repo"
    ;;
  *)
    : # non-work repo — no reminder
    ;;
esac
exit 0
