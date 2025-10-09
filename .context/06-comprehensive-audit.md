# Context: Comprehensive Audit - Security and Configuration Issues

**Date:** 2025-10-09
**Status:** 🔍 IN PROGRESS

## Critical Security Issues Found

### 🚨 IMMEDIATE ACTION REQUIRED

1. **Public SSH Key Committed to Repository**
   - **File:** `tools/ssh/keys/personal/github.pub`
   - **Status:** ⚠️ TRACKED by git
   - **Risk:** Public exposure of SSH key
   - **Action:** Remove from git history and add to .gitignore

2. **1Password Config File Committed**
   - **File:** `tools/1password/config`
   - **Status:** ⚠️ TRACKED by git
   - **Content:** Contains device IDs and account identifiers
   - **Action:** Remove from git history and add to .gitignore

## CLAUDE Comments Found (Feature Requests)

### 1. macOS Defaults Script (`tools/macos:3`)
```bash
# CLAUDE: Review this file and make sane changes to support the last 3 versions
# of MACOS. We can create multiple version and run the appropriate one based on
# the version of the OS in the dotbot configuration.
```

**Issue:** The script uses hardcoded `defaults write` commands that may not work across macOS versions (Sequoia 26.0, Sonoma 15.x, Ventura 14.x)

**Recommendation:**
- Create versioned scripts: `tools/macos/macos-26.sh`, `macos-15.sh`, `macos-14.sh`
- Add version detection in dotbot config
- Extract common settings to a shared script
- Test compatibility for deprecated/changed defaults

### 2. Sleepwatcher Save Script (`tools/sleepwatcher/sleep:12`)
```bash
# CLAUDE: Make sure any editor that we install using brew also saves work
```

**Issue:** Only saves work for VS Code, ignoring other editors installed via brew

**Current Code:**
```bash
osascript -e 'tell application "System Events" to tell process "Code" to keystroke "s" using {command down}'
```

**Recommendation:**
- Dynamically detect installed editors from brew
- Add save commands for: Cursor, VSCode, Zed, Sublime Text, etc.
- Create a loop that iterates through known editor processes

## Configuration Issues

### 3. Hardcoded Homebrew Path in zprofile
**File:** `shells/zsh/zprofile`
**Current:**
```bash
eval "$(/Users/joel.castillo.cq/.homebrew/bin/brew shellenv)"
```

**Issue:** Hardcoded to user-specific path instead of dynamic detection

**Solution:** Should use the same logic as `brew.yaml`:
```bash
# Detect Homebrew location
if [[ -x "$HOME/.homebrew/bin/brew" ]]; then
  BREW_PREFIX="$HOME/.homebrew"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  BREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
  BREW_PREFIX="/usr/local"
fi

[[ -n "$BREW_PREFIX" ]] && eval "$($BREW_PREFIX/bin/brew shellenv)"
```

### 4. zprofile Template Needs Update
**File:** `shells/zsh/zprofile.template`
**Current:**
```bash
# eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Issue:**
- Commented out and hardcoded to `/opt/homebrew`
- Should adapt based on actual brew installation location
- Template should be generated during setup

**Solution:**
- Make this dynamic during install process
- Generate from detection logic
- Add to setup-private-files.sh or bootstrap

### 5. Outdated asdf Tool Versions
**File:** `tools/asdf/tool-versions`

**Current Versions:**
```
nodejs 20.19.1   # Latest: 22.x LTS (23.x current)
python 3.12.2    # Latest: 3.13.x
ruby 3.3.0       # Latest: 3.3.6
golang 1.22.0    # Latest: 1.23.x
rust 1.85.0      # Latest: 1.8x (check current)
```

**Action:** Update to latest stable versions

### 6. Git Config References Public Key
**Files:**
- `tools/git/gitconfig.user.template:4`
- `scripts/setup-new-user.sh:37`

**Current:**
```ini
signingkey = ~/.ssh/github.pub
```

**Issue:** References a public key file that should be:
1. Not committed to the repository
2. Potentially pulled from 1Password instead

**Recommendation:**
- Remove public key from repo
- Add documentation for users to generate their own
- Consider 1Password integration for automatic key retrieval
- Or symlink from private repo

## File Status Summary

### ✅ Safe Files (No Private Data)
- `.dotbot/configs/brew.yaml` - Only package names
- `shells/zsh/zshrc` - Fixed (no private data)
- `shells/zsh/zprofile` - Hardcoded path, but not sensitive
- `.context/*` - Documentation files

### ⚠️ Tracked Files That Should Be Removed
1. `tools/1password/config` - **TRACKED** - Contains device/account IDs
2. `tools/ssh/keys/personal/github.pub` - **TRACKED** - Public key

### 📝 Template Files (OK to Keep)
- `tools/1password/accounts.json.template` ✅
- `tools/1password/secret-paths.json.template` ✅
- `tools/git/gitconfig.user.template` ✅ (but needs signingkey fix)
- `shells/zsh/zprofile.template` ⚠️ (needs dynamic brew detection)

## Action Plan

### Phase 1: Security Fixes (CRITICAL)
1. ✅ Add to `.gitignore`:
   ```
   # SSH keys
   tools/ssh/keys/**/*.pub
   tools/ssh/keys/**/*_rsa
   tools/ssh/keys/**/*_ed25519
   !tools/ssh/keys/.gitkeep

   # 1Password config (keep templates)
   tools/1password/config
   !tools/1password/*.template
   ```

2. Remove tracked sensitive files:
   ```bash
   git rm --cached tools/1password/config
   git rm --cached tools/ssh/keys/personal/github.pub
   ```

3. Add instructions for users to generate SSH keys or pull from 1Password

### Phase 2: Configuration Improvements
1. Fix zprofile to use dynamic Homebrew detection
2. Update zprofile.template with proper logic
3. Update asdf tool versions to latest
4. Document the template generation process

### Phase 3: Feature Enhancements
1. Create versioned macOS defaults scripts (26, 15, 14)
2. Add version detection to dotbot config
3. Update sleepwatcher to save work in all brew-installed editors
4. Evaluate 1Password integration for SSH keys

### Phase 4: Documentation
1. Update README with SSH key setup instructions
2. Document Homebrew installation locations
3. Add migration guide for existing users
4. Document 1Password integration options

## Notes

- The repository structure with `~/.dotfiles-private` is working well
- Most private files are already properly excluded
- The main issues are legacy files that were committed before the private repo setup
- Need to be careful with git history cleanup if these files contain sensitive data

## Next Steps

1. Start with security fixes (Phase 1)
2. Test changes don't break existing setup
3. Proceed with configuration improvements
4. Implement feature enhancements based on CLAUDE comments
