## Dotfiles Audit Remediation Plan

**Audit Date:** 2025-01-08
**Total Issues:** 32
**Status:** In Progress

---

## ✅ COMPLETED ISSUES

### Critical Priority
- **Issue #1: Hard-coded ARM Homebrew paths** ✅ FIXED (Commit: 75ae0b9)
  - Auto-detection for `/opt/homebrew`, `/usr/local`, and `~/.homebrew`
  - Support for Intel Macs and user-local installations
  - Multi-user Homebrew documentation added

### High Priority
- **Issue #6: Missing gitconfig.user validation** ✅ FIXED (Commit: 5868226)
  - Added validation in private setup script
  - Helpful error messages with remediation steps
  - Support for alternative git config names

---

## 🔴 CRITICAL PRIORITY (Must Fix Before Sharing)

### Issue #16: Personal data in git history
**Status:** ⏳ PENDING
**Priority:** P0 - Critical
**Impact:** Privacy/security leak

**Current State:**
- Git commits contain `joel.castillo@carequant.health`
- Company name "carequant" in commit messages
- Personal information exposed if shared as template

**Remediation Options:**
1. **Squash history** (Recommended for template)
   ```bash
   # Create orphan branch
   git checkout --orphan clean-main
   git add -A
   git commit -m "chore: Initial clean dotfiles template"
   git branch -D main
   git branch -m main
   git push -f origin main
   ```

2. **BFG Repo-Cleaner** (For removing sensitive data)
   ```bash
   brew install bfg
   bfg --replace-text sensitive.txt
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

3. **Create separate template repo** (Safest)
   - Keep current repo personal
   - Create new public template without history
   - Use `scripts/create-template-repo.sh`

**Decision Required:** Which approach to use?

---

### Issue #17: Company-specific configurations
**Status:** ⏳ PENDING
**Priority:** P0 - Critical
**Impact:** Company information disclosure

**Files to Update:**
- `.dotbot/configs/private.yaml` (lines 60-62, 68-70)
- `.dotbot/configs/ssh.yaml` (lines 25-27)
- Any other references to "carequant"

**Action Plan:**
1. Search for all "carequant" references:
   ```bash
   rg -i "carequant" --type yaml --type sh
   ```

2. Replace with generic placeholders:
   - `carequant` → `company` or `work`
   - `carequant.1password.com` → `company.1password.com`
   - Create examples with `company1`, `company2` naming

3. Move actual company configs to private repository

**Estimated Time:** 30 minutes

---

### Issue #18: 1Password account domain exposed
**Status:** ⏳ PENDING
**Priority:** P0 - Critical
**Impact:** Company infrastructure disclosure

**Current:** Hard-coded `"carequant.1password.com"`
**Location:** `.dotbot/configs/ssh.yaml:27`

**Solution:**
1. Add to `config.json`:
   ```json
   {
     "onepassword_account": "company.1password.com"
   }
   ```

2. Read from config in scripts
3. Provide example in templates

**Estimated Time:** 15 minutes

---

## 🟡 HIGH PRIORITY (Critical for Reliability)

### Issue #2: Hard-coded Python 3.12 path
**Status:** ⏳ PENDING
**Priority:** P1 - High
**Impact:** Breaks when Python version changes

**Location:** `shells/zsh/zsh.before/path.zsh:23`

**Current:**
```zsh
export PATH="$HOME/Library/Python/3.12/bin:$PATH"
```

**Solution:**
```zsh
# Add all Python user bin directories
for pydir in "$HOME/Library/Python/"*/bin(N); do
    export PATH="$pydir:$PATH"
done
```

**Estimated Time:** 5 minutes

---

### Issue #7: No brew installation verification
**Status:** ⏳ PENDING
**Priority:** P1 - High
**Impact:** Silent failures in package installation

**Location:** `.dotbot/configs/brew.yaml:4-6`

**Solution:**
```yaml
- shell:
  - command: |
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if ! command -v brew >/dev/null 2>&1; then
        echo "ERROR: Homebrew installation failed"
        exit 1
      fi
    description: Install and verify Homebrew
    stdout: true
```

**Estimated Time:** 10 minutes

---

### Issue #8: Missing asdf validation
**Status:** ⏳ PENDING
**Priority:** P1 - High
**Impact:** Language setup fails silently

**Location:** `.dotbot/configs/asdf.yaml:4`

**Solution:**
```yaml
- shell:
  - command: |
      BREW_PREFIX=$(brew --prefix)
      if [ -f "$BREW_PREFIX/opt/asdf/libexec/asdf.sh" ]; then
        . "$BREW_PREFIX/opt/asdf/libexec/asdf.sh"
      else
        echo "WARNING: asdf not found, skipping language setup"
        exit 0
      fi
    description: Source asdf with validation
```

**Estimated Time:** 10 minutes

---

### Issue #11: No clear Linux compatibility statement
**Status:** ⏳ PENDING
**Priority:** P1 - High
**Impact:** User confusion, wasted time

**Solution:**
Add to README.md:
```markdown
## Platform Requirements

**Supported:**
- macOS Ventura (13.0) or later
- Apple Silicon (M1/M2/M3/M4) and Intel Macs

**Not Supported:**
- Linux (may work with modifications, but untested)
- Windows (including WSL)
- macOS Monterey (12.x) or earlier

For Linux users, consider using [yadm](https://yadm.io/) or [chezmoi](https://www.chezmoi.io/).
```

**Estimated Time:** 10 minutes

---

### Issue #12: Missing config.json setup instructions
**Status:** ⏳ PENDING
**Priority:** P1 - High
**Impact:** Private setup confusing for new users

**Solution:**
Update `install` script to auto-create config.json:
```bash
if [ ! -f "config.json" ]; then
    if [ -f "config.json.example" ]; then
        cp config.json.example config.json
        echo "Created config.json from example"
        echo "Please edit config.json with your settings"
        exit 1
    fi
fi
```

**Estimated Time:** 15 minutes

---

### Issue #21: macOS version detection incomplete
**Status:** ⏳ PENDING
**Priority:** P1 - High
**Impact:** Confusing errors on non-macOS systems

**Location:** `install:62-72`

**Solution:**
```bash
check_platform() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        red_echo "Platform Check" "This setup is designed for macOS only"
        red_echo "Platform Check" "Current OS: $OSTYPE"
        red_echo "Platform Check" "For Linux, consider: https://github.com/yadm-dev/yadm"
        return 1
    fi

    # Then check macOS version
    check_macos_version
}
```

**Estimated Time:** 15 minutes

---

## 🟢 MEDIUM PRIORITY (Better UX)

### Issue #3: Hard-coded directory assumptions
**Status:** ⏳ PENDING
**Priority:** P2 - Medium
**Impact:** Minor failures if VS Code not installed

**Solution:**
```bash
# In backup function
for file in "${files_to_backup[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$backup_dir/"
        blue_echo "Backup" "Backed up $file"
    fi
done
```

**Estimated Time:** 10 minutes

---

### Issue #9: No error handling in submodule updates
**Status:** ⏳ PENDING
**Priority:** P2 - Medium
**Impact:** Silent failures in plugin installation

**Solution:** Already improved with sync command (Commit: b1e1a31), but could add better error reporting

**Estimated Time:** 15 minutes

---

### Issue #13: Undocumented SSH_PROFILE variable
**Status:** ⏳ PENDING
**Priority:** P2 - Medium

**Options:**
1. Document in README
2. Remove complexity (recommended)

**Decision Required:** Keep or remove SSH_PROFILE?

---

### Issue #24-27: Installation order dependencies
**Status:** ⏳ PENDING
**Priority:** P2 - Medium

**Solution:**
Add dependency validation to profile installation:
```bash
# Before installing profile
validate_dependencies() {
    case "$PROFILE" in
        "full")
            # Check if Homebrew installed
            if ! command -v brew >/dev/null; then
                red_echo "Profile" "Homebrew required for full profile"
                blue_echo "Profile" "Run: ./install bootstrap"
                return 1
            fi
            ;;
    esac
}
```

**Estimated Time:** 30 minutes

---

### Issue #28: Touch ID sudo setup requires sudo
**Status:** ⏳ PENDING
**Priority:** P2 - Medium

**Solution:**
```bash
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges"
    exec sudo bash "$0" "$@"
fi
```

**Estimated Time:** 5 minutes

---

## 🟤 LOW PRIORITY (Polish)

### Issue #23: Deprecated VS Code setting
**Status:** ⏳ PENDING
**Priority:** P3 - Low

**Files:**
- `apps/vscode/settings.json.template:29`
- `apps/cursor/settings.json.template:29`

**Change:**
```json
"terminal.integrated.defaultProfile.osx": "zsh"
```

**Estimated Time:** 5 minutes

---

### Issue #30: Oh-My-Zsh deprecated URL
**Status:** ⏳ PENDING
**Priority:** P3 - Low

**Change:** `raw.github.com` → `raw.githubusercontent.com`

**Estimated Time:** 2 minutes

---

## 📊 SUMMARY BY STATUS

### Completed (2)
- ✅ Homebrew path detection (Intel/ARM/user-local support)
- ✅ Git config validation and flexibility

### In Progress (0)
- None currently

### Pending Critical (3)
- ⏳ Personal data in git history
- ⏳ Company-specific configurations
- ⏳ 1Password account exposure

### Pending High (6)
- ⏳ Python version detection
- ⏳ Homebrew installation verification
- ⏳ asdf validation
- ⏳ Platform compatibility docs
- ⏳ config.json auto-setup
- ⏳ macOS platform detection

### Pending Medium (6)
- ⏳ Directory assumption fixes
- ⏳ Submodule error handling
- ⏳ SSH_PROFILE documentation
- ⏳ Installation order validation
- ⏳ Touch ID sudo improvements
- ⏳ Various defensive checks

### Pending Low (2)
- ⏳ VS Code setting updates
- ⏳ URL modernization

---

## 🎯 RECOMMENDED EXECUTION ORDER

### Phase 1: Make Template-Safe (Before Public Sharing)
**Estimated Time:** 2 hours
1. Squash git history or create clean template repo
2. Remove all "carequant" references
3. Move company-specific configs to private repo
4. Add platform requirements to README

### Phase 2: Reliability Improvements
**Estimated Time:** 2 hours
1. Add Homebrew installation verification
2. Add asdf validation
3. Fix Python path detection
4. Improve error messages
5. Add config.json auto-creation

### Phase 3: UX Polish
**Estimated Time:** 1 hour
1. Add dependency validation
2. Improve error handling
3. Add defensive checks
4. Fix deprecated settings

### Phase 4: Documentation
**Estimated Time:** 1 hour
1. Update README with platform requirements
2. Document all environment variables
3. Create troubleshooting guide
4. Add examples for common scenarios

**Total Estimated Time:** 6 hours

---

## 🚀 QUICK WINS (Do These First)

These are high-impact, low-effort fixes:

1. **Update README with platform requirements** (10 min)
2. **Fix Python path detection** (5 min)
3. **Update deprecated VS Code settings** (5 min)
4. **Add config.json auto-copy** (15 min)
5. **Fix Oh-My-Zsh URL** (2 min)

**Total:** 37 minutes for 5 improvements

---

## 📝 DECISIONS NEEDED

1. **Git History:** Squash, BFG, or separate template repo?
2. **SSH_PROFILE:** Keep and document, or remove?
3. **Linux Support:** Explicitly not support, or add basic support?
4. **Private Repo:** Keep current structure or reorganize?

---

## 🔄 CONTINUOUS IMPROVEMENT

After remediation, add to CI/CD:
- Pre-commit hooks for sensitive data detection
- Shellcheck for script quality
- Automated testing on fresh VMs
- Documentation linting

---

**Next Action:** Execute Phase 1 (Template-Safe) before sharing publicly
