# Context: Symlinks Setup

**Date:** 2025-10-09
**Task:** Set up symlinks to ~/.dotfiles-private

## Current Symlink Status

### ✅ Already Symlinked
1. `shells/zsh/zsh.before/aliases.zsh` → `~/.dotfiles-private/aliases/aliases.zsh`
2. `tools/ssh/config` → `~/.dotfiles-private/ssh/config`

### Files That Need Symlinks (Currently untracked in public repo)

These files are in the public repo but should NOT be tracked:

1. **Dotbot Configs:**
   - `.dotbot/configs/carequant.yaml` - Already exists in private repo as `dotbot/carequant.yaml`
   - `.dotbot/configs/personal.yaml` - Already exists in private repo as `dotbot/personal.yaml`

2. **App Settings:**
   - `apps/cursor/settings.json` - Exists in private repo as `cursor/settings.json`
   - `apps/vscode/settings.json` - Need to check if in private repo

3. **Git Configs:**
   - `tools/git/gitconfig.carequant` - Exists in private repo (referenced in carequant.yaml)
   - `tools/git/gitconfig.personal` - Exists in private repo (referenced in personal.yaml)

4. **Aliases:**
   - `shells/zsh/zsh.before/company-aliases.zsh` - New file, needs to be moved to private repo

## Symlink Strategy

The dotfiles-private repo contains the actual files, and the public repo should have symlinks pointing to them.

## Next Steps
1. Delete untracked files from public repo (they're already in private repo)
2. Update .gitignore to ignore these file patterns
3. Document the symlink setup for future users
