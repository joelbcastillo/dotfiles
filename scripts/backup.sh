#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup directory
BACKUP_DIR="${HOME}/.dotfiles_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"

# OS-aware helpers
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User"
    SHA256="shasum -a 256"
else
    VSCODE_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User"
    SHA256="sha256sum"
fi

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create backup
create_backup() {
    print_message "${YELLOW}" "Creating backup at ${BACKUP_PATH}..."
    
    # Create backup directory
    mkdir -p "${BACKUP_PATH}"
    
    # Backup shell configurations
    print_message "${GREEN}" "Backing up shell configurations..."
    cp -r "${HOME}/.zshrc" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.oh-my-zsh" "${BACKUP_PATH}/" 2>/dev/null || true
    
    # Backup Git configurations
    print_message "${GREEN}" "Backing up Git configurations..."
    cp -r "${HOME}/.gitconfig" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.gitignore_global" "${BACKUP_PATH}/" 2>/dev/null || true
    
    # Backup VS Code configurations
    print_message "${GREEN}" "Backing up VS Code configurations..."
    mkdir -p "${BACKUP_PATH}/vscode"
    cp -r "${VSCODE_USER_DIR}/settings.json" "${BACKUP_PATH}/vscode/" 2>/dev/null || true
    cp -r "${VSCODE_USER_DIR}/extensions" "${BACKUP_PATH}/vscode/" 2>/dev/null || true
    
    # Backup tool configurations
    print_message "${GREEN}" "Backing up tool configurations..."
    cp -r "${HOME}/.ssh" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.aws" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.tmux.conf" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.config/gh" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.config/pipx" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.pip" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.pythonrc" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.config/htop" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.ripgreprc" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.sleep" "${BACKUP_PATH}/" 2>/dev/null || true
    cp -r "${HOME}/.wakeup" "${BACKUP_PATH}/" 2>/dev/null || true
    
    # Create backup manifest
    print_message "${GREEN}" "Creating backup manifest..."
    (cd "${BACKUP_PATH}" && find . -type f -not -name manifest.txt -not -path "*/\.*" -exec $SHA256 {} \; > manifest.tmp && mv manifest.tmp manifest.txt)
    
    print_message "${GREEN}" "Backup completed successfully!"
    print_message "${YELLOW}" "Backup location: ${BACKUP_PATH}"
}

# Function to list backups
list_backups() {
    if [ ! -d "${BACKUP_DIR}" ]; then
        print_message "${RED}" "No backups found."
        exit 1
    fi
    
    print_message "${YELLOW}" "Available backups:"
    for backup in "${BACKUP_DIR}"/*; do
        if [ -d "${backup}" ]; then
            basename "${backup}"
        fi
    done
}

# Function to restore from backup
restore_backup() {
    local backup_name=$1
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    if [ ! -d "${backup_path}" ]; then
        print_message "${RED}" "Backup not found: ${backup_name}"
        exit 1
    fi
    
    print_message "${YELLOW}" "Restoring from backup: ${backup_name}"
    
    # Verify backup integrity
    print_message "${GREEN}" "Verifying backup integrity..."
    (cd "${backup_path}" && $SHA256 -c manifest.txt) || {
        print_message "${RED}" "Backup integrity check failed!"
        exit 1
    }
    
    # Restore configurations
    print_message "${GREEN}" "Restoring configurations..."
    cp -r "${backup_path}/.zshrc" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.oh-my-zsh" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.gitconfig" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.gitignore_global" "${HOME}/" 2>/dev/null || true
    
    # Restore VS Code configurations
    mkdir -p "${VSCODE_USER_DIR}"
    cp -r "${backup_path}/vscode/settings.json" "${VSCODE_USER_DIR}/" 2>/dev/null || true
    cp -r "${backup_path}/vscode/extensions" "${VSCODE_USER_DIR}/" 2>/dev/null || true
    
    cp -r "${backup_path}/.ssh" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.aws" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.tmux.conf" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/gh" "${HOME}/.config/" 2>/dev/null || true
    cp -r "${backup_path}/pipx" "${HOME}/.config/" 2>/dev/null || true
    cp -r "${backup_path}/.pip" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.pythonrc" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/htop" "${HOME}/.config/" 2>/dev/null || true
    cp -r "${backup_path}/.ripgreprc" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.sleep" "${HOME}/" 2>/dev/null || true
    cp -r "${backup_path}/.wakeup" "${HOME}/" 2>/dev/null || true
    
    print_message "${GREEN}" "Restore completed successfully!"
}

# Function to clean old backups
clean_backups() {
    local days=$1
    if [ -z "${days}" ]; then
        days=30
    fi
    
    print_message "${YELLOW}" "Cleaning backups older than ${days} days..."
    find "${BACKUP_DIR}" -type d -mtime +"${days}" -exec rm -rf {} \; 2>/dev/null || true
    print_message "${GREEN}" "Cleanup completed!"
}

# Main script logic
case "$1" in
    "backup")
        create_backup
        ;;
    "list")
        list_backups
        ;;
    "restore")
        if [ -z "$2" ]; then
            print_message "${RED}" "Please specify a backup to restore"
            exit 1
        fi
        restore_backup "$2"
        ;;
    "clean")
        clean_backups "$2"
        ;;
    *)
        echo "Usage: $0 {backup|list|restore <backup_name>|clean [days]}"
        exit 1
        ;;
esac 