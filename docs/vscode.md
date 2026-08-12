# VS Code Configuration

This document describes the VS Code configuration included in this template.

## Settings

The VS Code settings are located in `apps/vscode/settings.json`. These settings are designed to provide a productive development environment with the following features:

### Editor Settings
- Font: JetBrains Mono with ligatures
- Font size: 14px
- Line height: 1.5
- Tab size: 2 spaces
- Insert spaces: true
- Word wrap: on
- Auto save: after delay
- Format on save: true

### Terminal Settings
- Font: JetBrains Mono
- Font size: 14px
- Line height: 1.2
- Minimum contrast ratio: 4.5

### Language Specific Settings
- HTML: Prettier formatter
- JSON: Prettier formatter
- YAML: Prettier formatter
- Python: Black formatter
- Shell Script: shfmt formatter
- Markdown: Prettier formatter

### File Associations
- `.tf`: Terraform
- `.tfvars`: Terraform
- `.hcl`: Terraform
- `.yaml`: YAML
- `.yml`: YAML

### Git Settings
- Auto fetch: true
- SSH protocol: true

### Security Settings
- Workspace trust: enabled
- Terminal exit confirmation: enabled

## Extensions

The VS Code extensions are listed in `apps/vscode/extensions`. They are organized into the following categories:

### Essential Extensions
- GitLens
- IntelliCode
- Error Lens
- Path Intellisense

### Language Support
- Python
- Pylance
- Python Test Explorer
- Python Docstring Generator
- Python Type Hint
- Python Indent
- Python Environment Manager
- Python Extension Pack

### Infrastructure as Code
- Terraform
- HashiCorp HCL
- Docker
- Kubernetes
- YAML

### Git
- GitLens
- Git Graph
- Git History
- Git Blame

### Docker
- Docker
- Remote - Containers

### Remote Development
- Remote - SSH
- Remote - Containers
- Remote - WSL

### Markdown
- Markdown All in One
- Markdown Preview Enhanced
- markdownlint

### Shell
- Shell-Format
- shellcheck

### Utilities
- EditorConfig
- Prettier
- ESLint
- Path Intellisense
- Auto Rename Tag
- Auto Close Tag
- Color Highlight
- Color Picker
- Material Icon Theme
- Todo Tree
- Bookmarks
- Code Spell Checker
- Error Lens
- Import Cost
- Indent Rainbow
- Rainbow Brackets
- Trailing Spaces
- vscode-icons

## Customization

To customize VS Code settings:

1. Edit `apps/vscode/settings.json` to modify settings
2. Edit `apps/vscode/extensions` to add or remove extensions
3. Run `./install bootstrap` to apply changes

## Best Practices

1. Keep settings organized by category
2. Document any non-obvious settings
3. Use workspace-specific settings when needed
4. Regularly update extensions
5. Use the integrated terminal for development tasks 