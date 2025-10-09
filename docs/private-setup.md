# Private Repository Setup

This document explains how to set up and manage your private dotfiles repository for secure handling of personal configurations.

## 🔒 What Should Be Private

Only files containing **sensitive personal information** should be kept in your private repository:

### ✅ Keep Private
- **Git configurations** with your real name and email
- **SSH keys and credentials**
- **AWS credentials and API keys**
- **Company-specific aliases** and configurations
- **1Password configurations**
- **Personal VS Code settings** (if they contain sensitive data)

### ❌ Keep Public
- **General aliases** and shell functions
- **VS Code settings** (without personal data)
- **Tool configurations** (without credentials)
- **macOS defaults** and system settings
- **Shell themes** and plugins

## 🚀 Setting Up Your Private Repository

### Complete Setup Process

For a complete dotfiles setup with private files, you need to run **both** commands:

```bash
# 1. Install the full profile (public configurations)
./install profile full

# 2. Setup private files (requires private repository)
./install config private
```

**Important**: The "full" profile does **not** include private files by design. Private files must be set up separately for security and flexibility reasons.

## SSH Configuration Management

The dotfiles support dynamic SSH configuration selection. SSH configs must follow a specific naming convention in your private repository:

### SSH Config Naming Convention

SSH configurations must be named `ssh-{name}.yaml` in your private repository's `dotbot/` directory:

```
~/.dotfiles-private/
├── dotbot/
│   ├── ssh-personal.yaml      # Personal SSH config
│   ├── ssh-work.yaml          # Work SSH config  
│   ├── ssh-client1.yaml       # Client 1 SSH config
│   └── ssh-work.yaml          # Work SSH config
```

### SSH Config Usage

**Setup:** Copy and edit the example config:
```bash
cp config.json.example config.json
# Edit with your private repository URL
```

**Usage:**
```bash
# Setup with all SSH configs (uses config file)
./install private

# Setup with all SSH configs explicitly
./install private all

# Setup with specific SSH config
./install private personal
./install private work
./install private client1
```

The system will automatically:
- Detect all available SSH configs in your private repository
- Show you which configs are available
- Link the specified config(s) to your dotfiles

### Step 1: Create Private Repository

1. **Create a new private repository** on GitHub:
   - Name: `dotfiles-private` (or your preferred name)
   - Make it **Private**
   - Don't initialize with any files

2. **Note the repository URL** (e.g., `https://github.com/yourusername/dotfiles-private.git`)

### Step 2: Structure Your Private Repository

Create the following structure in your private repository:

```
dotfiles-private/
├── git/
│   ├── gitconfig.user          # Your personal git config
│   └── gitconfig.work          # Your work git config
├── aliases/
│   └── company-aliases.zsh     # Company-specific aliases
├── ssh/                        # SSH keys and configs (optional)
├── aws/                        # AWS credentials (optional)
└── 1password/                  # 1Password configs (optional)
```

### Step 3: Add Your Private Files

1. **Git Configurations**:
   ```bash
   # Copy your personal git configs
   cp ~/.dotfiles/tools/git/gitconfig.user ~/dotfiles-private/git/
   cp ~/.dotfiles/tools/git/gitconfig.work ~/dotfiles-private/git/
   ```

2. **Company Aliases**:
   ```bash
   # Create company-specific aliases
   cat > ~/dotfiles-private/aliases/company-aliases.zsh << 'EOF'
   # Company-specific aliases
   alias myproject="_secure_run ai cursor ~/.repos/github.com/company/myproject"
   # Add more company aliases here
   EOF
   ```

3. **Other Private Files** (if needed):
   ```bash
   # SSH configurations
   cp -r ~/.dotfiles/tools/ssh ~/dotfiles-private/
   
   # AWS credentials
   cp -r ~/.dotfiles/tools/aws ~/dotfiles-private/
   
   # 1Password configurations
   cp -r ~/.dotfiles/tools/1password ~/dotfiles-private/
   ```

### Step 4: Commit and Push

```bash
cd ~/dotfiles-private
git add .
git commit -m "Initial commit: Private dotfiles configurations"
git push -u origin main
```

## 🔧 Using Private Files

### Pulling in Private Files

To pull in your private files during setup:

```bash
PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./install private
```

### Updating Private Files

To update your private repository with current files:

```bash
cd ~/.dotfiles-private
git add .
git commit -m "Update private configurations"
git push origin main
```

### Manual Setup

You can also manually copy files:

```bash
# Copy git configs
cp ~/.dotfiles-private/git/gitconfig.user ~/.dotfiles/tools/git/
cp ~/.dotfiles-private/git/gitconfig.work ~/.dotfiles/tools/git/

# Copy company aliases
cp ~/.dotfiles-private/aliases/company-aliases.zsh ~/.dotfiles/shells/zsh/zsh.before/
```

## 📁 File Organization

### Private Repository Structure

```
dotfiles-private/
├── git/
│   ├── gitconfig.user          # Personal git config
│   └── gitconfig.work          # Work git config
├── aliases/
│   └── company-aliases.zsh     # Company-specific aliases
├── ssh/                        # SSH keys and configs
│   ├── keys/
│   └── config
├── aws/                        # AWS credentials
│   └── credentials
└── 1password/                  # 1Password configurations
    ├── config
    └── secret-paths.json
```

### Public Repository Structure

```
dotfiles/
├── tools/git/
│   ├── gitconfig.user.template     # Template for new users
│   ├── gitconfig.work.template
│   └── gitconfig                   # Public git config
├── shells/zsh/zsh.before/
│   ├── aliases.zsh                 # Public aliases
│   └── company-aliases.zsh         # Private aliases (ignored by git)
└── scripts/
    ├── setup-private-files.sh      # Private file setup script
    └── setup-new-user.sh           # New user setup script
```

## 🔄 Workflow

### For You (Repository Owner)

1. **Make changes** to your dotfiles
2. **Update private files** if needed:
   ```bash
   cd ~/.dotfiles-private
   # Copy updated files
   cp ~/.dotfiles/tools/git/gitconfig.user git/
   git add . && git commit -m "Update private files"
   git push origin main
   ```
3. **Commit public changes**:
   ```bash
   cd ~/.dotfiles
   git add . && git commit -m "Update public configurations"
   git push origin main
   ```

### For New Users

1. **Clone the public repository**:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Bootstrap the system**:
   ```bash
   ./install bootstrap
   ```

3. **Set up personal configurations**:
   ```bash
   ./scripts/setup-new-user.sh
   ```

4. **Install the default profile**:
   ```bash
   ./install profile default
   ```

## 🛡️ Security Best Practices

1. **Never commit sensitive data** to the public repository
2. **Use environment variables** for API keys when possible
3. **Regularly audit** your private repository for sensitive data
4. **Use strong authentication** for your private repository
5. **Consider using a secrets manager** (like 1Password) for highly sensitive data

## 🚨 Troubleshooting

### Private Repository Not Found

If you get an error about the private repository not being found:

1. **Check the URL** is correct
2. **Verify the repository exists** and is accessible
3. **Check your SSH keys** if using SSH authentication

### Permission Denied

If you get permission denied errors:

1. **Check your SSH keys** are set up correctly
2. **Verify you have access** to the private repository
3. **Use HTTPS** instead of SSH if needed

### Files Not Updating

If private files aren't updating:

1. **Check the private repository** has the latest changes
2. **Run the setup script again**:
   ```bash
   PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./install private
   ```
3. **Manually copy files** if needed

## 📚 Additional Resources

- [GitHub Private Repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories)
- [SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Environment Variables](https://docs.github.com/en/actions/learn-github-actions/environment-variables)
