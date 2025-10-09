# Feature Backlog

Enhancement ideas and future improvements for the dotfiles system.

---

## 🔥 High Priority

### 1. DMG/PKG Installer Support
**Status:** Proposed  
**Priority:** High  
**Use Case:** Install apps not available in Homebrew

**Description:**
Add support for installing applications from DMG, PKG, or ZIP files. This would handle:
- Company VPN clients
- Beta software
- Proprietary tools
- Custom builds
- Apps from vendor websites

**Proposed Implementation:**

#### Option A: Declarative YAML Config
```yaml
# .dotbot/configs/custom-apps.yaml
- custom_installer:
  - name: "Company VPN"
    type: dmg
    source: "~/Downloads/CompanyVPN.dmg"
    mount_name: "Company VPN Installer"
    app_name: "Company VPN.app"
    destination: /Applications
    verify_checksum: sha256:abc123...
    
  - name: "Custom Tool"
    type: pkg
    source: "https://company.com/tools/custom-tool.pkg"
    installer_args: ["-target", "/"]
    require_sudo: true
    
  - name: "CLI Tool"
    type: zip
    source: "~/Downloads/tool.zip"
    extract_to: "~/.local/bin"
    executable: "tool"
```

#### Option B: Script-Based Approach
```bash
# scripts/install-custom-apps.sh
install_from_dmg() {
    local dmg_path=$1
    local app_name=$2
    local dest=${3:-/Applications}
    
    # Mount DMG
    hdiutil attach "$dmg_path" -quiet
    
    # Find mount point
    local mount_point=$(hdiutil info | grep "$dmg_path" | awk '{print $1}')
    
    # Copy app
    cp -R "/Volumes/$mount_name/$app_name" "$dest/"
    
    # Unmount
    hdiutil detach "$mount_point" -quiet
}
```

#### Option C: Custom Dotbot Plugin
Create `dotbot-custom-installer` plugin with these commands:
- `dmg`: Install from DMG
- `pkg`: Run PKG installer
- `zip`: Extract and install from ZIP
- `download`: Download and verify checksums

**Features to Include:**
- ✅ Checksum verification (SHA256)
- ✅ Idempotency (skip if already installed)
- ✅ Version checking
- ✅ Backup existing versions
- ✅ Silent/unattended installation
- ✅ Cleanup temporary files
- ✅ Logging installation history
- ✅ Support for user vs system installations

**Related Files:**
- New: `scripts/install-dmg.sh`
- New: `scripts/install-pkg.sh`
- New: `.dotbot/configs/custom-apps.yaml`
- New: `.dotbot/plugins/dotbot-custom-installer/` (optional)

**Estimated Effort:** 4-6 hours

---

## 🎯 Medium Priority

### 2. Automated Backup Before Major Changes
**Status:** Proposed  
**Priority:** Medium

Create automatic backups before:
- Homebrew migrations
- Major system updates
- Profile switches
- Dotbot full installs

### 3. Profile Switching Command
**Status:** Proposed  
**Priority:** Medium

```bash
./install switch-profile work    # Switch to work profile
./install switch-profile personal # Switch to personal
```

Should:
- Update config.json
- Re-run private file linking
- Re-apply dotbot configs
- Update SSH keys from 1Password

### 4. Health Check Command
**Status:** Proposed  
**Priority:** Medium

```bash
./install health-check
```

Should verify:
- All symlinks are valid
- Required tools are installed
- Git configs are present
- SSH keys are accessible
- 1Password CLI is signed in
- Homebrew is working

### 5. Secrets Management Improvements
**Status:** Proposed  
**Priority:** Medium

Enhancements to 1Password integration:
- Support for other secret managers (Bitwarden, LastPass)
- Encrypted local secret storage fallback
- Secret rotation reminders
- Audit log for secret access

---

## 💡 Low Priority / Nice to Have

### 6. GUI Installer
Create a simple GUI (using AppleScript or Swift) for:
- Profile selection
- Configuration options
- Installation progress
- Error reporting

### 7. Dotfiles Update Checker
Periodic check for updates to:
- Template repository
- Plugins
- Tool versions

### 8. Multi-Machine Sync Status
Dashboard showing:
- Which machines are up to date
- Last sync time per machine
- Configuration drift detection

### 9. VS Code Extensions Manager
Similar to Homebrew bundle, manage VS Code extensions:
```json
{
  "extensions": [
    "ms-python.python",
    "github.copilot"
  ]
}
```

### 10. macOS Defaults Manager
Enhanced macOS settings with:
- Per-profile defaults
- Backup/restore
- Diff viewer for changes

---

## 🐛 Known Issues / Technical Debt

### 1. Submodule Management
**Issue:** Submodule updates can be confusing for new users
**Potential Fix:** Add `./install update-plugins` command

### 2. Dotbot Plugin Loading
**Issue:** Plugin loading happens every time
**Potential Fix:** Cache plugin metadata

### 3. Error Messages
**Issue:** Some errors lack context
**Potential Fix:** Add detailed error codes and troubleshooting links

---

## 📝 Documentation Improvements

### 1. Video Tutorials
- Fresh installation walkthrough
- Private repository setup
- Profile switching
- 1Password integration

### 2. Troubleshooting Guide
Common issues and solutions:
- Homebrew conflicts
- Git configuration problems
- SSH key issues
- Permission problems

### 3. Architecture Documentation
Explain the system design:
- Why symlinks?
- Profile system design
- Private repository pattern
- 1Password integration architecture

---

## 🚀 Contributing

Want to work on any of these features?

1. **Open an issue** to discuss the approach
2. **Create a feature branch**: `git checkout -b feature/dmg-installer`
3. **Implement with tests** (if applicable)
4. **Update documentation**
5. **Submit a pull request**

### Feature Request Template
```markdown
**Feature Name:** Install from DMG/PKG
**Priority:** High
**Use Case:** Install company VPN client
**Proposed Solution:** Script-based approach with checksum verification
**Estimated Effort:** 4-6 hours
**Dependencies:** None
**Breaking Changes:** No
```

---

## 📊 Prioritization Criteria

Features are prioritized based on:
1. **User Impact** - How many users benefit?
2. **Frequency** - How often is this needed?
3. **Complexity** - How hard to implement?
4. **Dependencies** - What else is needed first?
5. **Maintenance** - Long-term support burden?

---

## 🔄 Review Schedule

This backlog is reviewed:
- **Monthly** - Re-prioritize based on feedback
- **Quarterly** - Add new feature requests
- **Yearly** - Remove obsolete items

Last Updated: 2025-01-08
Next Review: 2025-02-08
