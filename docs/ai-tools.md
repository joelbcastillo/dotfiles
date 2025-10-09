# AI Tools Configuration

This dotfiles repository includes configuration for multiple AI coding assistants and tools.

## Available AI Tools

### 1. Claude Code
Official Claude CLI from Anthropic for command-line AI assistance.

**Config Files:**
- `.dotbot/configs/claude-code.yaml` - Configuration setup
- `tools/claude/config.json.template` - Config template (uses 1Password for API keys)

**Installation:**
```bash
./install config claude-code
```

**Features:**
- API key management via 1Password
- Model selection (claude-4.5-sonnet by default)
- Theme and log level configuration

---

### 2. Claude CLI
Legacy Claude CLI tool.

**Config Files:**
- `.dotbot/configs/claude.yaml` - Setup and validation

**Installation:**
```bash
./install config claude
```

---

### 3. Cursor Editor
AI-powered code editor based on VS Code.

**Config Files:**
- `.dotbot/configs/cursor.yaml` - Editor configuration
- `apps/cursor/settings.json.template` - Settings template

**Installation:**
```bash
./install config cursor
```

---

### 4. Cursor Agent
Command-line tool for Cursor AI.

**Config Files:**
- `.dotbot/configs/cursor-agent.yaml` - Agent setup
- `tools/cursor-agent/config.json.template` - Config template

**Installation:**
```bash
./install config cursor-agent
```

---

## Installation Profiles

### Install All AI Tools
The `ai-tools` profile installs and configures all AI development tools:

```bash
./install profile ai-tools
```

This profile includes:
- cursor-agent installation
- Claude Code installation
- Symlink creation for ~/.local/bin
- Version verification

### Install Individual Tools
You can install tools individually:

```bash
# Just Claude Code
./install config claude-code

# Just Cursor Agent
./install config cursor-agent

# Just Cursor Editor
./install config cursor
```

---

## Configuration Architecture

### Why Multiple Config Files?

Each AI tool has its own configuration file because:

1. **Separation of Concerns** - Each tool has different setup requirements
2. **Independent Installation** - Users can install only the tools they need
3. **Scoped Settings** - Tool-specific settings don't interfere with each other
4. **Maintainability** - Easier to update individual tool configs

### Config Hierarchy

```
ai-tools.yaml              # Master installer - installs all tools
├── claude.yaml            # Claude CLI setup
├── claude-code.yaml       # Claude Code config
├── cursor.yaml            # Cursor editor config
└── cursor-agent.yaml      # Cursor agent config
```

---

## API Key Management

All AI tools use **1Password integration** for secure API key storage.

### Setup 1Password Secrets

1. Create items in your 1Password vault:
   - "Claude API Key" in "API Keys" vault
   - "Cursor API Key" in "API Keys" vault
   - etc.

2. Configure `tools/1password/secret-paths.json`:
   ```json
   {
     "ai_tools": {
       "claude_api_key": {
         "item": "Claude API Key",
         "field": "credential",
         "vault": "API Keys"
       }
     }
   }
   ```

3. Reference in config files:
   ```json
   {
     "api_key": "1password://claude_api_key"
   }
   ```

4. The `resolve-1password-secrets.sh` script automatically resolves these references.

---

## Customization

### Claude Code Settings

Edit `tools/claude/config.json.template`:

```json
{
  "api_key": "1password://claude_api_key",
  "model": "claude-4.5-sonnet",
  "max_tokens": 4000,
  "temperature": 0.7,
  "theme": "dark",
  "log_level": "info"
}
```

### Cursor Agent Settings

Edit `tools/cursor-agent/config.json.template`:

```json
{
  "api_key": "1password://cursor_api_key",
  "model": "gpt-4",
  "auto_complete": true
}
```

---

## Troubleshooting

### Claude not found in PATH

```bash
# Check if installed
which claude

# Verify symlink
ls -la ~/.local/bin/claude

# Re-run ai-tools setup
./install profile ai-tools
```

### API Key Issues

```bash
# Test 1Password CLI
op signin

# Verify secret paths
cat tools/1password/secret-paths.json

# Re-resolve secrets
./scripts/resolve-1password-secrets.sh ~/.config/claude/config.json
```

### Cursor Agent Not Working

```bash
# Check installation
cursor-agent --version

# Verify PATH
echo $PATH | grep -o "$HOME/.local/bin"

# Reinstall
./install config cursor-agent
```

---

## Adding New AI Tools

To add a new AI tool:

1. **Create config file**: `.dotbot/configs/my-tool.yaml`
2. **Add to ai-tools profile**: Edit `.dotbot/profiles/ai-tools`
3. **Add API key mapping**: Update `tools/1password/secret-paths.json`
4. **Create config template**: `tools/my-tool/config.json.template`
5. **Document it**: Update this file

Example config:

```yaml
- shell:
  -
    command: |
      if ! command -v my-tool >/dev/null 2>&1; then
        echo "Installing my-tool..."
        brew install my-tool
      else
        echo "my-tool is already installed"
      fi
    description: Install my-tool

- link:
    ~/.config/my-tool/config.json:
      path: tools/my-tool/config.json.template
      relink: true
      force: true

- shell:
  -
    command: |
      if command -v op >/dev/null 2>&1; then
        ~/.dotfiles/scripts/resolve-1password-secrets.sh ~/.config/my-tool/config.json
      fi
    description: Resolve secrets in my-tool config
```

---

## Best Practices

1. **Keep API keys in 1Password** - Never commit API keys
2. **Use templates** - Provide `.template` files in the public repo
3. **Test individually** - Each config should work standalone
4. **Document changes** - Update this file when adding tools
5. **Version lock carefully** - Pin versions in Brewfile if needed

---

## References

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Cursor Documentation](https://cursor.sh/docs)
- [1Password CLI](https://developer.1password.com/docs/cli)
