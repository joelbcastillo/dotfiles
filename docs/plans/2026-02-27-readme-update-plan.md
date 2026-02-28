# README Documentation Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update both dotfiles and dotfiles-private READMEs to reflect current repository state.

**Architecture:** Surgical edits to existing README.md files — fix inaccuracies, add missing sections, remove stale references. No new files created (except this plan).

**Tech Stack:** Markdown

---

### Task 1: Update dotfiles README — Features section

**Files:**
- Modify: `~/.dotfiles/README.md:24-35`

**Step 1: Update features list**

Replace the current features list to include AI tools, MCP, Hammerspoon, Ghostty:

```markdown
- 🛠 **Modular Design**: Organized by tool and environment
- 🔧 **Easy Customization**: Simple to modify and extend
- 🔒 **Private File Support**: Secure handling of personal configurations
- 🤖 **AI Tools Integration**: Claude CLI, Claude Code, Cursor Agent, MCP servers
- 🎨 **Curated Configurations**:
  - Shell (Zsh with Oh My Zsh + Starship prompt)
  - Git (with 1Password SSH signing)
  - VS Code and Cursor editors
  - Ghostty terminal
  - Homebrew
  - tmux
  - macOS defaults
  - Hammerspoon automation
  - And more!
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update features list in README"
```

---

### Task 2: Update dotfiles README — Profiles section

**Files:**
- Modify: `~/.dotfiles/README.md:216-248`

**Step 1: Replace profiles section**

Replace the 4 profiles (default, minimal, full, devcontainer) with the actual 4 (default, full, ai-tools, template):

```markdown
1. **default** - Essential development setup:
   - Homebrew, Git, SSH
   - Oh My Zsh + Starship prompt
   - Zsh configuration
   - asdf (version manager)
   - VS Code
   - tmux, ripgrep, utils
   - neofetch, TouchID for sudo

2. **full** - Complete development environment:
   - All default tools, plus:
   - Colima (Docker runtime)
   - 1Password CLI
   - Languages: Python, Node.js, Go, Ruby, Rust
   - GitHub CLI, AWS CLI, DigitalOcean CLI
   - Cursor editor, Ghostty terminal
   - Hammerspoon automation
   - AI tools: Claude CLI, Claude Code, Cursor Agent, MCP servers, API keys

3. **ai-tools** - AI and Claude-focused setup:
   - Claude CLI and Claude Code
   - Cursor Agent
   - Claude tools integration
   - MCP server configuration
   - API key management (via 1Password)

4. **template** - Starter kit for customization:
   - Generates template files for creating your own private repo
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: fix profiles section to match actual profiles"
```

---

### Task 3: Update dotfiles README — Directory structure

**Files:**
- Modify: `~/.dotfiles/README.md:309-324`

**Step 1: Replace directory structure**

```markdown
```
.
├── .dotbot/              # Dotbot framework, profiles, and configs
│   ├── configs/          # 42 tool configuration YAML files
│   ├── profiles/         # Installation profiles (default, full, ai-tools, template)
│   └── plugins/          # Dotbot plugins
├── apps/                 # Application configurations
│   ├── claude/           # Claude Desktop settings
│   ├── cursor/           # Cursor editor settings
│   ├── ghostty/          # Ghostty terminal config
│   ├── hammerspoon/      # Hammerspoon automation
│   └── vscode/           # VS Code settings and extensions
├── shells/               # Shell configurations
│   ├── zsh/              # Zsh config and custom functions
│   ├── oh-my-zsh/        # Oh My Zsh plugins and themes
│   └── starship/         # Starship prompt config
├── tools/                # Tool configurations (27 directories)
│   ├── 1password/        # 1Password CLI integration
│   ├── git/              # Git config and hooks
│   ├── homebrew/         # Brewfile and package management
│   ├── mcp/              # MCP server configurations
│   ├── ssh/              # SSH config templates
│   └── ...               # Python, Node.js, Go, Ruby, Rust, etc.
├── scripts/              # Utility and setup scripts
├── docs/                 # Documentation and guides
├── templates/            # Configuration templates for new users
├── tests/                # Test suite
└── install               # Main installation script
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update directory structure to reflect current state"
```

---

### Task 4: Update dotfiles README — Default Profile description

**Files:**
- Modify: `~/.dotfiles/README.md:161-211`

**Step 1: Update the Default Profile section**

Remove AWS CLI and database tools references. Update to match actual default profile contents. Keep the macOS Configuration subsection as-is (it's accurate).

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: fix default profile description"
```

---

### Task 5: Update dotfiles-private README — Repository structure

**Files:**
- Modify: `~/.dotfiles-private/README.md:17-27`

**Step 1: Replace structure diagram**

```markdown
```
dotfiles-private/
├── git/                          # Git configurations for different identities
│   ├── gitconfig.personal        # Personal git config
│   ├── gitconfig.carequant       # CareQuant work git config
│   └── gitconfig.jbctechsolutions # JBC Tech Solutions git config
├── aliases/                      # Shell aliases and functions
│   ├── aliases.zsh               # General shell aliases
│   ├── claude-tools-env.zsh      # Claude tools environment setup
│   └── company-aliases.zsh       # Company/project-specific aliases
├── dotbot/                       # Dotbot profile configurations
│   ├── personal.yaml             # Personal profile
│   ├── carequant.yaml            # CareQuant profile
│   ├── jbctechsolutions.yaml     # JBC Tech Solutions profile
│   ├── ssh-personal.yaml         # Personal SSH setup
│   ├── ssh-carequant.yaml        # CareQuant SSH setup
│   ├── ssh-jbctechsolutions.yaml # JBC Tech SSH setup
│   └── claude-tools-private.yaml # Claude tools config
├── ssh/                          # SSH configuration
│   ├── config                    # Main SSH config (1Password agent)
│   ├── configs/                  # Host-specific SSH configs
│   └── keys/                     # Public keys only
├── shells/                       # Shell configurations
│   ├── zprofile                  # Zsh profile (Homebrew paths)
│   └── secure_profiles/          # Secure shell profiles
│       ├── ai                    # AI tools profile
│       ├── aws                   # AWS profile
│       ├── claude                # Claude profile
│       └── jbctech_cloud         # JBC Tech cloud profile
├── tools/                        # Tool-specific configurations
│   ├── accounts.json             # 1Password multi-account config
│   ├── claude/                   # Claude plugins
│   ├── claude-tools/             # dmux configuration
│   └── finicky/                  # URL routing config
├── secrets/                      # Secret management configs
│   ├── 1password/                # 1Password CLI config
│   ├── aws/                      # AWS credentials location
│   └── ssh/                      # SSH config references
├── cursor/                       # Cursor editor settings
├── vscode/                       # VS Code settings
└── context/                      # Historical audit documentation
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update repository structure to match current state"
```

---

### Task 6: Update dotfiles-private README — Fix file references and add sections

**Files:**
- Modify: `~/.dotfiles-private/README.md:104-141`

**Step 1: Fix git config references**

- Replace `gitconfig.user` → `gitconfig.personal` throughout
- Add `gitconfig.jbctechsolutions` entry

**Step 2: Add Dotbot Profiles section**

Add section documenting profile-based identity switching.

**Step 3: Add 1Password Multi-Account section**

Document the three-account setup (Personal, CareQuant, JBC Tech Solutions).

**Step 4: Add Claude Tools section**

Document dmux config, Claude plugins, secure profiles.

**Step 5: Update Security Notes**

Add note about SSH private keys being fetched from 1Password (not stored in repo).

**Step 6: Commit**

```bash
git add README.md
git commit -m "docs: update file references and add missing sections"
```

---

### Task 7: Update dotfiles-private CLAUDE.md

**Files:**
- Modify: `~/.dotfiles-private/CLAUDE.md`

**Step 1: Update structure and references**

Update the CLAUDE.md to reflect jbctechsolutions profile, Claude tools, dmux, finicky, and updated directory structure.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md to reflect current state"
```
