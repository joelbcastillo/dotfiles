# Context: Audit Private Information

**Date:** 2025-10-09
**Task:** Ensure no private information is in the template repo

## Current Status

### Files with Private Information (Untracked - Need to be removed/ignored)
1. `.dotbot/configs/carequant.yaml` - Company-specific config
2. `.dotbot/configs/personal.yaml` - Personal config
3. `apps/cursor/settings.json` - Personal Cursor settings
4. `apps/vscode/settings.json` - Personal VSCode settings
5. `shells/zsh/zsh.before/company-aliases.zsh` - Company aliases
6. `tools/git/gitconfig.carequant` - Company git config
7. `tools/git/gitconfig.personal` - Personal git config

### Modified Files (Need Review)
1. `.dotbot/configs/brew.yaml` - Modified, may contain personal packages
2. `config.json.example` - Modified example config
3. `shells/zsh/zprofile` - Contains Homebrew path (fixed from /opt/homebrew to ~/.homebrew)
4. `shells/zsh/zsh.before/aliases.zsh` - Typechange (file → symlink expected)
5. `shells/zsh/zshrc` - Fixed infinite loop issue
6. `tools/ssh/config` - Typechange (file → symlink expected)

### Private Dotfiles Repository Structure
Located at: `~/.dotfiles-private/`

Contains:
- `dotbot/carequant.yaml` - Company dotbot config
- `dotbot/personal.yaml` - Personal dotbot config
- `dotbot/ssh-personal.yaml` - SSH config for personal
- `dotbot/ssh-carequant.yaml` - SSH config for company
- `cursor/settings.json` - Cursor settings
- `git/` - Git configurations
- `aliases/` - Private aliases
- `ssh/config` - SSH configuration
- `secrets/` - 1Password and AWS secrets

## Next Steps
1. ✅ Identify all files with private info
2. ⏳ Create context files for tracking
3. ⏳ Move files that should be symlinked to private repo
4. ⏳ Update .gitignore to prevent leaks
5. ⏳ Document the symlink setup process
