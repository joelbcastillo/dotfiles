# Context: Cleanup Strategy for Template Repo

**Date:** 2025-10-09
**Task:** Clean up private information using existing infrastructure

## Existing Infrastructure

### ✅ Scripts Available
1. **`scripts/setup-private-files.sh`** - Automatically symlinks files from private repo
   - Maps directories from `~/.dotfiles-private/` to appropriate locations
   - Supports directory mappings for git, ssh, 1password, aliases, vscode, cursor, aws, etc.
   - Creates symlinks automatically

### ✅ Documentation Available
1. **`docs/private-setup.md`** - Main documentation for private repo setup
2. **`~/.dotfiles-private/README.md`** - Private repo documentation
3. **`~/.dotfiles-private/SETUP.md`** - Setup guide for private repo

## Current Situation

### Files Already Symlinked (Correct)
- `shells/zsh/zsh.before/aliases.zsh` → `~/.dotfiles-private/aliases/aliases.zsh`
- `tools/ssh/config` → `~/.dotfiles-private/ssh/config`

### Untracked Files in Public Repo (Need to Remove)
These exist in public repo but are NOT tracked by git:
1. `.dotbot/configs/carequant.yaml` - Company config
2. `.dotbot/configs/personal.yaml` - Personal config
3. `apps/cursor/settings.json` - Personal Cursor settings
4. `apps/vscode/settings.json` - Personal VSCode settings
5. `shells/zsh/zsh.before/company-aliases.zsh` - Company aliases
6. `tools/git/gitconfig.carequant` - Company git config
7. `tools/git/gitconfig.personal` - Personal git config

### Files Already in Private Repo
Located at `~/.dotfiles-private/`:
- `dotbot/carequant.yaml`
- `dotbot/personal.yaml`
- `dotbot/ssh-personal.yaml`
- `dotbot/ssh-carequant.yaml`
- `cursor/settings.json`
- `git/` directory with configs
- `aliases/` directory
- `ssh/config`
- `secrets/` directory

## Cleanup Strategy

### Step 1: Remove Untracked Private Files
Since these files are untracked and already exist in the private repo, we can safely remove them:
```bash
# These are untracked, so removal won't affect git history
rm -f .dotbot/configs/carequant.yaml
rm -f .dotbot/configs/personal.yaml
rm -f apps/cursor/settings.json
rm -f apps/vscode/settings.json
rm -f shells/zsh/zsh.before/company-aliases.zsh
rm -f tools/git/gitconfig.carequant
rm -f tools/git/gitconfig.personal
```

### Step 2: Update .gitignore
Add patterns to prevent future commits of private files:
- `.dotbot/configs/*-specific.yaml` patterns
- `apps/*/settings.json` (keep templates)
- `tools/git/gitconfig.*` (except templates)
- `shells/zsh/zsh.before/*-aliases.zsh` (except main aliases.zsh)

### Step 3: Verify Modified Files
Check the modified tracked files for private data:
- `.dotbot/configs/brew.yaml` - May contain personal packages
- `shells/zsh/zprofile` - Contains Homebrew path (already fixed to ~/.homebrew)
- `shells/zsh/zshrc` - Fixed infinite loop, no private data
- `config.json.example` - Example file, should be safe

### Step 4: Re-run Setup Script
After cleanup, run the setup script to ensure symlinks are correct:
```bash
PRIVATE_REPO_URL=https://github.com/joelbcastillo/dotfiles-private.git ./install private
```

## Notes
- The `setup-private-files.sh` script handles symlink creation automatically
- No need to manually create symlinks - the script does it
- The private repo structure matches the script's expectations
- Dotbot configs in private repo need to be symlinked to `.dotbot/configs/`
