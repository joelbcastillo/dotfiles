# README Documentation Update Design

**Date:** 2026-02-27
**Approach:** Surgical update — fix inaccuracies, add missing sections, remove stale references

## Audience

Personal reference + potential template users/forks. Keep template-friendly tone.

## dotfiles (public) README Changes

### Fix Profiles Section
- Remove `minimal` and `devcontainer` (don't exist)
- Add `ai-tools` profile with description
- Update `default` profile contents to match actual: brew, git, ssh, oh-my-zsh, starship, zsh, asdf, vscode, tmux, ripgrep, utils, neofetch, touchid
- Update `full` profile contents to match actual: all default + colima, 1password, languages, gh, aws, doctl, ssh, ghostty, hammerspoon, ai-tools
- Keep `template` profile

### Update Features List
- Add AI/Claude tools (Claude CLI, Claude Code, Cursor Agent)
- Add MCP server management
- Add Hammerspoon automation
- Add Ghostty terminal
- Add workspace orchestration (dmux)

### Update Directory Structure
- Show `apps/` with subdirs (claude, cursor, ghostty, hammerspoon, vscode)
- Show `tools/` with key subdirs
- Add `docs/`, `templates/`, `tests/`, `.dmux/`
- Show `scripts/`

### Fix Default Profile Description
- Remove AWS CLI (not in default)
- Add touchid, neofetch, utils

### Add AI Tools Section
- Brief description of ai-tools profile
- What it includes: Claude CLI, Claude Code, Cursor Agent, MCP servers, API keys

### Add Workspace Orchestration Section
- Hammerspoon integration
- dmux workspace management

## dotfiles-private README Changes

### Update Repository Structure
Add missing directories:
- `dotbot/` (7 YAML profile configs)
- `shells/` (zprofile, secure_profiles/)
- `tools/` (accounts.json, claude/, claude-tools/, finicky/)
- `secrets/` (1password/, aws/, ssh/)
- `cursor/`, `apps/cursor/`
- `vscode/`
- `context/` (historical audit docs)

### Fix File References
- `gitconfig.user` → `gitconfig.personal`
- Add `gitconfig.jbctechsolutions`

### Add Dotbot Profiles Section
- Document profile-based identity switching
- List: personal, carequant, jbctechsolutions
- Explain SSH profile variants

### Add 1Password Multi-Account Section
- Three accounts: Personal, CareQuant, JBC Tech Solutions
- SSH key fetching from 1Password (not stored in repo)

### Add Claude Tools Section
- dmux configuration
- Claude plugins for zsh
- Secure profiles (ai, aws, claude, jbctech_cloud)

### Fix Manual Copy Paths
- Update to correct actual paths

### Update Security Notes
- SSH private keys fetched from 1Password, not stored
- Git history was cleaned (reference context/ docs)
