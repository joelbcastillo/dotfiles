#!/usr/bin/env bash

# Dynamic private files linker
# Automatically symlinks files from private repo to dotfiles based on directory structure
# Supports multiple companies/profiles without hardcoding paths
#
# Usage: PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./scripts/setup-private-files.sh
#
# Private repo structure:
#   git/              → tools/git/
#   ssh/              → tools/ssh/
#   1password/        → tools/1password/
#   aliases/          → shells/zsh/zsh.before/
#   vscode/           → apps/vscode/
#   cursor/           → apps/cursor/
#   aws/              → tools/aws/
#   company1/         → (company-specific overrides)
#   company2/         → (company-specific overrides)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIVATE_REPO_URL="${PRIVATE_REPO_URL:-}"
PRIVATE_DIR="${HOME}/.dotfiles-private"
ACTIVE_PROFILE="${ACTIVE_PROFILE:-}"  # e.g., "company1", "company2", "personal"
GIT_USER_CONFIG="${GIT_USER_CONFIG:-gitconfig.user}"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Mapping of private repo directories to dotfiles directories
# Compatible with Bash 3.2 (macOS default)
get_target_dir() {
    case "$1" in
        git) echo "tools/git" ;;
        ssh) echo "tools/ssh" ;;
        onepassword) echo "tools/1password" ;;
        aliases) echo "shells/zsh/zsh.before" ;;
        vscode) echo "apps/vscode" ;;
        cursor) echo "apps/cursor" ;;
        aws) echo "tools/aws" ;;
        gcp) echo "tools/gcp" ;;
        azure) echo "tools/azure" ;;
        docker) echo "tools/docker" ;;
        kubernetes) echo "tools/kubernetes" ;;
        shells/secure_profiles) echo "shells/oh-my-zsh/custom/secure_profiles" ;;
        *) echo "" ;;
    esac
}

# List of all private subdirectories to check
PRIVATE_SUBDIRS=(
    "git"
    "ssh"
    "onepassword"
    "aliases"
    "vscode"
    "cursor"
    "aws"
    "gcp"
    "azure"
    "docker"
    "kubernetes"
    "shells/secure_profiles"
)

# Compute path of $1 relative to directory $2. Uses perl's File::Spec
# because BSD realpath on macOS doesn't have GNU's --relative-to flag.
# Perl ships with macOS, so no extra dep.
_rel_path() {
    perl -MFile::Spec -e 'print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$1" "$2"
}

# Link files from a directory with optional prefix
link_directory_files() {
    local source_dir=$1
    local target_dir=$2
    local prefix=$3  # Optional: prefix for linked files (e.g., "company1-")

    if [ ! -d "$source_dir" ]; then
        echo 0
        return 0
    fi

    # Ensure target directory exists
    mkdir -p "$target_dir"

    local linked_count=0

    # Link all files from source to target. Relative symlink targets keep
    # the symlinks portable across machines (different $HOME paths) and
    # idempotent against the committed-symlink values, so `git status` stays
    # clean after every install.
    for file in "$source_dir"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local target_file="$target_dir/${prefix}${filename}"
            local rel_src=$(_rel_path "$file" "$target_dir")

            ln -sf "$rel_src" "$target_file"
            print_message "${GREEN}" "  ✅ Linked ${prefix}${filename}" >&2
            ((linked_count++))
        fi
    done

    # Recursively link subdirectories
    for subdir in "$source_dir"/*; do
        if [ -d "$subdir" ] && [ ! -L "$subdir" ]; then
            local subdir_name=$(basename "$subdir")
            local subdir_count=$(link_directory_files "$subdir" "$target_dir/$subdir_name" "$prefix")
            ((linked_count+=subdir_count))
        fi
    done

    echo $linked_count
}

# Function to setup private repository
setup_private_files() {
    # PRIVATE_REPO_URL is only required to CLONE the private repo for the
    # first time. If a clone already exists, we can re-materialize symlinks
    # (and `git pull` against the embedded remote) without the URL — this
    # is the path .dotbot/configs/private.yaml takes when invoked via
    # `./install config private`.
    if [ -z "$PRIVATE_REPO_URL" ] && [ ! -d "$PRIVATE_DIR" ]; then
        print_message "${YELLOW}" "No private repository URL provided and no existing clone at $PRIVATE_DIR."
        print_message "${BLUE}" "Usage: PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./scripts/setup-private-files.sh"
        return 1
    fi

    if [ -n "$PRIVATE_REPO_URL" ]; then
        print_message "${BLUE}" "🔒 Setting up private files from: $PRIVATE_REPO_URL"
    else
        print_message "${BLUE}" "🔒 Updating private files (existing clone at $PRIVATE_DIR)"
    fi

    # Clone or update private repository
    if [ -d "$PRIVATE_DIR" ]; then
        print_message "${GREEN}" "Private repository exists, updating..."
        cd "$PRIVATE_DIR"
        git pull origin main
    else
        print_message "${GREEN}" "Cloning private repository..."
        git clone "$PRIVATE_REPO_URL" "$PRIVATE_DIR"
    fi

    cd "$DOTFILES_DIR"

    # Enable the tracked git hooks in both repos. The post-merge hook auto-
    # runs `./install private` after any pull that touches private-linked
    # paths, so gitignored symlinks (vscode/cursor/secure_profiles/etc.) get
    # re-materialized on update. Idempotent — safe to run every install.
    git -C "$DOTFILES_DIR" config --local core.hooksPath scripts/git-hooks
    if [ -d "$PRIVATE_DIR/scripts/git-hooks" ]; then
        git -C "$PRIVATE_DIR" config --local core.hooksPath scripts/git-hooks
    fi

    # Show active profile if set
    if [ -n "$ACTIVE_PROFILE" ]; then
        print_message "${BLUE}" "📋 Active profile: $ACTIVE_PROFILE"
    fi

    print_message "${BLUE}" "🔗 Linking private files..."
    echo ""

    local total_linked=0

    # First, link base directories (common configs)
    for private_subdir in "${PRIVATE_SUBDIRS[@]}"; do
        local source_dir="$PRIVATE_DIR/$private_subdir"
        local target_dir_mapping=$(get_target_dir "$private_subdir")
        
        # Skip if no mapping exists for this subdirectory
        if [ -z "$target_dir_mapping" ]; then
            continue
        fi
        
        local target_dir="$DOTFILES_DIR/$target_dir_mapping"

        if [ -d "$source_dir" ]; then
            print_message "${BLUE}" "Linking $private_subdir/ → $target_dir_mapping/"
            local count=$(link_directory_files "$source_dir" "$target_dir" "")
            ((total_linked+=count))

            if [ $count -eq 0 ]; then
                print_message "${YELLOW}" "  ⚠️  No files found"
            fi
        fi
    done

    # Then, link profile-specific overrides if active profile is set
    if [ -n "$ACTIVE_PROFILE" ] && [ -d "$PRIVATE_DIR/$ACTIVE_PROFILE" ]; then
        print_message "${BLUE}" "Linking profile-specific files for: $ACTIVE_PROFILE"

        for private_subdir in "${PRIVATE_SUBDIRS[@]}"; do
            local source_dir="$PRIVATE_DIR/$ACTIVE_PROFILE/$private_subdir"
            local target_dir_mapping=$(get_target_dir "$private_subdir")
            
            # Skip if no mapping exists for this subdirectory
            if [ -z "$target_dir_mapping" ]; then
                continue
            fi
            
            local target_dir="$DOTFILES_DIR/$target_dir_mapping"

            if [ -d "$source_dir" ]; then
                print_message "${BLUE}" "Linking $ACTIVE_PROFILE/$private_subdir/ → $target_dir_mapping/ (with ${ACTIVE_PROFILE}- prefix)"
                local count=$(link_directory_files "$source_dir" "$target_dir" "${ACTIVE_PROFILE}-")
                ((total_linked+=count))
            fi
        done
    fi

    echo ""

    # Special handling for gitconfig.user requirement
    print_message "${BLUE}" "Validating required configurations..."

    if [ ! -e "$DOTFILES_DIR/tools/git/gitconfig.user" ]; then
        # Check if the configured git user config exists
        local git_config_path="$DOTFILES_DIR/tools/git/$GIT_USER_CONFIG"

        if [ -e "$git_config_path" ]; then
            # If it's not already named gitconfig.user, create an additional symlink
            if [ "$GIT_USER_CONFIG" != "gitconfig.user" ]; then
                ln -sf "$git_config_path" "$DOTFILES_DIR/tools/git/gitconfig.user"
                print_message "${GREEN}" "✅ Linked $GIT_USER_CONFIG as gitconfig.user"
            fi
        else
            print_message "${YELLOW}" "⚠️  Warning: gitconfig.user not found"
            print_message "${YELLOW}" "   Git configuration requires a user config file"
            print_message "${YELLOW}" "   Configured to use: $GIT_USER_CONFIG"
            print_message "${YELLOW}" ""
            print_message "${YELLOW}" "   Add one of these to your private repo:"
            print_message "${YELLOW}" "   1. git/$GIT_USER_CONFIG"

            if [ -n "$ACTIVE_PROFILE" ]; then
                print_message "${YELLOW}" "   2. $ACTIVE_PROFILE/git/$GIT_USER_CONFIG"
            fi

            print_message "${YELLOW}" ""
            print_message "${YELLOW}" "   Or copy the template:"
            print_message "${YELLOW}" "   cp tools/git/gitconfig.user.template tools/git/gitconfig.user"
        fi
    fi

    echo ""
    print_message "${GREEN}" "🎉 Private files setup complete!"
    print_message "${GREEN}" "   Total files linked: $total_linked"
    echo ""
    print_message "${YELLOW}" "📋 Next steps:"
    print_message "${YELLOW}" "1. Review the linked files"
    print_message "${YELLOW}" "2. Run: ./install"
    print_message "${YELLOW}" "3. Source your shell: source ~/.zshrc"
}

# Main function
main() {
    print_message "${BLUE}" "🚀 Setting up private files..."
    setup_private_files
}

# Run main function
main "$@"
