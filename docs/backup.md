# Backup System

The dotfiles template includes a comprehensive backup system to help you manage and restore your configurations safely.

## Features

- **Automatic Backups**: Create timestamped backups of all configurations
- **Integrity Verification**: SHA256 checksums ensure backup integrity
- **Selective Restore**: Restore specific configurations or entire profiles
- **Backup Management**: List and clean old backups
- **Safe Operations**: Non-destructive backup and restore operations

## Usage

### Creating a Backup

To create a new backup of your current configurations:

```bash
./scripts/backup.sh backup
```

This will:
1. Create a timestamped backup directory
2. Copy all configuration files
3. Generate a manifest with SHA256 checksums
4. Store the backup in `~/.dotfiles_backup/`

### Listing Backups

To view all available backups:

```bash
./scripts/backup.sh list
```

This shows all backup directories with their timestamps.

### Restoring from Backup

To restore configurations from a specific backup:

```bash
./scripts/backup.sh restore <backup_name>
```

For example:
```bash
./scripts/backup.sh restore 20240315_123456
```

The restore process:
1. Verifies backup integrity using SHA256 checksums
2. Restores all configuration files
3. Preserves original file permissions
4. Handles missing files gracefully

### Cleaning Old Backups

To remove backups older than a specified number of days:

```bash
./scripts/backup.sh clean [days]
```

Default is 30 days if not specified:
```bash
./scripts/backup.sh clean 30
```

## What Gets Backed Up

The backup system includes:

1. **Shell Configurations**
   - `.zshrc`
   - Oh My Zsh customizations

2. **Git Configurations**
   - `.gitconfig`
   - `.gitignore_global`

3. **VS Code Settings**
   - `settings.json`
   - Installed extensions

4. **Tool Configurations**
   - SSH config
   - AWS credentials
   - Tmux config
   - GitHub CLI config
   - Python tools
   - System tools

## Best Practices

1. **Regular Backups**
   - Create backups before major changes
   - Schedule regular backups using cron

2. **Backup Management**
   - Keep only necessary backups
   - Clean old backups regularly
   - Verify backup integrity before restoring

3. **Security**
   - Backups include sensitive files
   - Store backups securely
   - Use appropriate permissions

4. **Testing**
   - Test restore process periodically
   - Verify configurations after restore
   - Keep backup of important changes

## Automation

You can automate backups using cron. Add this to your crontab:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/dotfiles/scripts/backup.sh backup

# Weekly cleanup of old backups
0 3 * * 0 /path/to/dotfiles/scripts/backup.sh clean 30
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure script is executable: `chmod +x scripts/backup.sh`
   - Check directory permissions

2. **Backup Failed**
   - Verify disk space
   - Check file permissions
   - Review error messages

3. **Restore Issues**
   - Verify backup integrity
   - Check file conflicts
   - Review restore logs

### Getting Help

If you encounter issues:
1. Check the backup logs
2. Verify file permissions
3. Review the backup manifest
4. Test with a small subset of files 