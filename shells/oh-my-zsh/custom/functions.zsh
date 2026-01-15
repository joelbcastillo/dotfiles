# Development Functions

# Create a new Python virtual environment
function venv() {
    local venv_name=${1:-.venv}
    python3 -m venv "$venv_name"
    echo "Created virtual environment: $venv_name"
    echo "Activate with: source $venv_name/bin/activate"
}

# Git configuration function for project-specific setups
function git-config() {
    local config_suffix="$1"
    
    if [ -z "$config_suffix" ]; then
        echo "Usage: git-config <suffix>"
        echo "Available configs:"
        ls ~/.dotfiles/tools/git/gitconfig.* 2>/dev/null | sed 's/.*gitconfig\./  /' | grep -v template
        return 1
    fi
    
    local config_file="$HOME/.dotfiles/tools/git/gitconfig.$config_suffix"
    
    if [ ! -f "$config_file" ]; then
        echo "Error: Git config file '$config_file' not found"
        echo "Available configs:"
        ls ~/.dotfiles/tools/git/gitconfig.* 2>/dev/null | sed 's/.*gitconfig\./  /' | grep -v template
        return 1
    fi
    
    # Create symlink to the specified config
    ln -sf "$config_file" ~/.gitconfig.user
    
    echo "Git configuration switched to: $config_suffix"
    echo "Current git user: $(git config user.name) <$(git config user.email)>"
}

# Create a new directory and cd into it
function mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Extract various archive formats
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a new git repository with initial commit
function gitinit() {
    git init
    git add .
    git commit -m "Initial commit"
    echo "Git repository initialized with initial commit"
}

# System Functions

# Get process info by name
function psgrep() {
    ps aux | grep -i "$1" | grep -v grep
}

# Kill process by name
function killp() {
    local pid
    pid=$(ps aux | grep -i "$1" | grep -v grep | awk '{print $2}')
    if [ -n "$pid" ]; then
        kill -9 "$pid"
        echo "Killed process $pid"
    else
        echo "No process found matching '$1'"
    fi
}

# Show disk usage for current directory
function dusage() {
    du -sh * | sort -hr
}

# Network Functions

# Get local IP address
function localip() {
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
}

# Test network connectivity
function pingtest() {
    ping -c 4 "$1" | grep "packet loss"
}

# Development Environment Functions

# Update all development tools
function update-dev() {
    echo "Updating Homebrew..."
    brew update && brew upgrade

    echo "Updating pip packages..."
    pip3 list --outdated | cut -d ' ' -f1 | tail -n +3 | xargs -n1 pip3 install -U

    echo "Updating npm packages..."
    npm update -g

    echo "Updating VS Code extensions..."
    code --list-extensions | xargs -n 1 code --install-extension

    echo "Development tools updated!"
}

# ASDF Upgrade Helper
# Updates all asdf-managed tools to their latest versions with interactive selection
# Usage: asdf-upgrade [-i|--interactive] [-d|--dry-run] [-s|--skip PLUGIN] [-h|--help] [PLUGIN...]
function asdf-upgrade() {
    # Colors (respect terminal capabilities)
    local RED GREEN YELLOW BLUE CYAN NC
    if [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
    fi

    # Helper functions
    _asdf_log_info()    { echo -e "${BLUE}[INFO]${NC} $1" }
    _asdf_log_success() { echo -e "${GREEN}[OK]${NC} $1" }
    _asdf_log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1" >&2 }
    _asdf_log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2 }

    # Default options
    local interactive=false
    local dry_run=false
    local -a skip_plugins=()
    local -a target_plugins=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interactive) interactive=true; shift ;;
            -d|--dry-run)     dry_run=true; shift ;;
            -s|--skip)        skip_plugins+=("$2"); shift 2 ;;
            -a|--all)         shift ;;  # Default behavior
            -h|--help)
                echo "Usage: asdf-upgrade [OPTIONS] [PLUGIN...]"
                echo ""
                echo "Update asdf-managed tools to their latest versions."
                echo ""
                echo "Options:"
                echo "  -i, --interactive  Select global versions interactively with fzf"
                echo "  -d, --dry-run      Show what would be done without making changes"
                echo "  -s, --skip PLUGIN  Skip specific plugin (can be used multiple times)"
                echo "  -a, --all          Update all plugins (default if no plugins specified)"
                echo "  -h, --help         Show this help message"
                echo ""
                echo "Arguments:"
                echo "  PLUGIN...          Specific plugins to update (optional)"
                echo ""
                echo "Examples:"
                echo "  asdf-upgrade              # Update all, set latest as global"
                echo "  asdf-upgrade -i           # Update all, interactively choose versions"
                echo "  asdf-upgrade nodejs       # Update nodejs only"
                echo "  asdf-upgrade -s rust      # Update all except rust"
                return 0 ;;
            -*)
                _asdf_log_error "Unknown option: $1"
                return 1 ;;
            *)
                target_plugins+=("$1"); shift ;;
        esac
    done

    # Ensure asdf is available
    if ! command -v asdf &>/dev/null; then
        if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
            source "$HOME/.asdf/asdf.sh"
        else
            _asdf_log_error "asdf not found. Please install asdf first."
            return 1
        fi
    fi

    # Check for fzf if interactive mode
    if [[ "$interactive" == true ]] && ! command -v fzf &>/dev/null; then
        _asdf_log_warn "fzf not found. Falling back to non-interactive mode."
        interactive=false
    fi

    # Get list of plugins to process
    local -a plugins
    if [[ ${#target_plugins[@]} -gt 0 ]]; then
        plugins=("${target_plugins[@]}")
    else
        plugins=($(asdf plugin list 2>/dev/null))
    fi

    # Filter out skipped plugins
    local -a filtered_plugins=()
    for plugin in "${plugins[@]}"; do
        local skip=false
        for skip_plugin in "${skip_plugins[@]}"; do
            if [[ "$plugin" == "$skip_plugin" ]]; then
                skip=true
                break
            fi
        done
        if [[ "$skip" == false ]]; then
            filtered_plugins+=("$plugin")
        fi
    done
    plugins=("${filtered_plugins[@]}")

    if [[ ${#plugins[@]} -eq 0 ]]; then
        _asdf_log_warn "No plugins to update."
        return 0
    fi

    # Display header
    echo ""
    _asdf_log_info "ASDF Upgrade - Checking ${#plugins[@]} plugin(s)..."
    echo ""

    # Gather information and display summary
    local -A current_versions latest_versions
    printf "%-15s %-15s %-15s %s\n" "PLUGIN" "CURRENT" "LATEST" "STATUS"
    printf "%-15s %-15s %-15s %s\n" "------" "-------" "------" "------"

    for plugin in "${plugins[@]}"; do
        local current=$(asdf current "$plugin" 2>/dev/null | awk '{print $2}')
        local latest=$(asdf latest "$plugin" 2>/dev/null)
        current_versions[$plugin]="$current"
        latest_versions[$plugin]="$latest"

        local plugin_status=""
        if [[ -z "$latest" ]]; then
            plugin_status="${YELLOW}unknown${NC}"
        elif [[ "$current" == "$latest" ]]; then
            plugin_status="${GREEN}up-to-date${NC}"
        else
            plugin_status="${CYAN}update available${NC}"
        fi

        printf "%-15s %-15s %-15s %b\n" "$plugin" "${current:-none}" "${latest:-?}" "$plugin_status"
    done
    echo ""

    # Dry run stops here
    if [[ "$dry_run" == true ]]; then
        _asdf_log_info "Dry run complete. No changes made."
        return 0
    fi

    # Install latest versions
    _asdf_log_info "Installing latest versions..."
    local -a failed_installs=()
    local -a successful_installs=()

    for plugin in "${plugins[@]}"; do
        local latest="${latest_versions[$plugin]}"
        if [[ -z "$latest" ]]; then
            _asdf_log_warn "Could not determine latest version for $plugin, skipping."
            continue
        fi

        # Check if latest is already installed
        if asdf list "$plugin" 2>/dev/null | grep -q "^[* ]*$latest$"; then
            _asdf_log_info "$plugin $latest already installed"
            successful_installs+=("$plugin:$latest")
            continue
        fi

        _asdf_log_info "Installing $plugin $latest..."
        if asdf install "$plugin" "$latest" 2>&1; then
            _asdf_log_success "Installed $plugin $latest"
            successful_installs+=("$plugin:$latest")
        else
            _asdf_log_error "Failed to install $plugin $latest"
            failed_installs+=("$plugin")
        fi
    done

    echo ""

    # Interactive version selection
    if [[ "$interactive" == true ]]; then
        _asdf_log_info "Interactive version selection..."
        echo ""

        for plugin in "${plugins[@]}"; do
            local current="${current_versions[$plugin]}"
            local versions=$(asdf list "$plugin" 2>/dev/null | sed 's/^[ *]*//')

            if [[ -z "$versions" ]]; then
                _asdf_log_warn "No versions installed for $plugin"
                continue
            fi

            # Build fzf list with labels
            local fzf_list=""
            while IFS= read -r version; do
                local label=""
                [[ "$version" == "${latest_versions[$plugin]}" ]] && label=" [latest]"
                [[ "$version" == "$current" ]] && label="${label} [current]"
                fzf_list+="${version}${label}"$'\n'
            done <<< "$versions"
            fzf_list+="[skip - keep current]"

            local selected=$(echo "$fzf_list" | fzf \
                --height 40% \
                --reverse \
                --header="Select global version for $plugin (current: ${current:-none})" \
                --prompt="$plugin > ")

            # Extract version (remove labels)
            selected=$(echo "$selected" | awk '{print $1}')

            if [[ -n "$selected" && "$selected" != "[skip" ]]; then
                _asdf_log_info "Setting $plugin global to $selected"
                asdf global "$plugin" "$selected"
                _asdf_log_success "$plugin global set to $selected"
            else
                _asdf_log_info "Keeping $plugin at ${current:-none}"
            fi
        done
    else
        # Non-interactive: set latest as global for each
        _asdf_log_info "Setting latest versions as global..."
        for plugin in "${plugins[@]}"; do
            local latest="${latest_versions[$plugin]}"
            if [[ -n "$latest" ]] && asdf list "$plugin" 2>/dev/null | grep -q "^[* ]*$latest$"; then
                asdf global "$plugin" "$latest"
                _asdf_log_success "$plugin global set to $latest"
            fi
        done
    fi

    # Final summary
    echo ""
    _asdf_log_success "ASDF upgrade complete!"

    if [[ ${#failed_installs[@]} -gt 0 ]]; then
        echo ""
        _asdf_log_warn "Failed to install: ${failed_installs[*]}"
        _asdf_log_info "Try running manually: asdf install <plugin> latest"
    fi

    echo ""
    _asdf_log_info "Current global versions:"
    asdf current 2>/dev/null | column -t
}

# Git Functions

# Create a new branch and switch to it
function gb() {
    git checkout -b "$1"
}

# Push current branch to remote
function gp() {
    git push -u origin "$(git branch --show-current)"
}

# Pull latest changes and rebase
function gpr() {
    git pull --rebase origin "$(git branch --show-current)"
}

# Show git status with more details
function gs() {
    git status -sb
    echo "\nStaged changes:"
    git diff --cached --stat
    echo "\nUnstaged changes:"
    git diff --stat
}

# Docker Functions

# List all containers (running and stopped)
function dls() {
    docker ps -a
}

# Remove all stopped containers
function drm() {
    docker container prune -f
}

# Remove all unused images
function drmi() {
    docker image prune -af
}

# AWS Functions

# List all AWS profiles
function awsprofiles() {
    grep '\[profile' ~/.aws/config | sed 's/\[profile //' | sed 's/\]//'
}

# Switch AWS profile
function awsprofile() {
    export AWS_PROFILE="$1"
    echo "Switched to AWS profile: $AWS_PROFILE"
}

# Utility Functions

# Create a backup of a file
function backup() {
    cp "$1" "$1.bak"
    echo "Created backup: $1.bak"
}

# Restore a file from backup
function restore() {
    if [ -f "$1.bak" ]; then
        cp "$1.bak" "$1"
        echo "Restored from backup: $1.bak"
    else
        echo "No backup found for $1"
    fi
}

# Generate a random password
function genpass() {
    local length=${1:-16}
    openssl rand -base64 "$length" | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c "$length"
    echo
}

# Show weather information
function weather() {
    curl "wttr.in/$1"
}

# Show calendar with events
function cal() {
    if command -v gcal >/dev/null 2>&1; then
        gcal --starting-day=1 --with-week-number
    else
        command cal "$@"
    fi
}

# Development Workflow Functions

# Create a new project with specified type
function new-project() {
    local project_name="$1"
    local project_type="$2"
    
    if [ -z "$project_name" ] || [ -z "$project_type" ]; then
        echo "Usage: new-project <name> <type>"
        echo "Types: python, node, go, rust"
        return 1
    fi
    
    mkdir -p "$project_name"
    cd "$project_name" || return 1
    
    case "$project_type" in
        python)
            python3 -m venv .venv
            echo "# $project_name" > README.md
            echo "Python project created with virtual environment"
            ;;
        node)
            npm init -y
            echo "# $project_name" > README.md
            echo "Node.js project created"
            ;;
        go)
            go mod init "$project_name"
            echo "// $project_name" > main.go
            echo "package main" >> main.go
            echo "func main() {}" >> main.go
            echo "Go project created"
            ;;
        rust)
            cargo init --bin
            echo "Rust project created"
            ;;
        *)
            echo "Unknown project type: $project_type"
            return 1
            ;;
    esac
    
    echo "Project '$project_name' created successfully!"
}

# Start a new feature branch
function start-feature() {
    local feature_name="$1"
    git checkout main
    git pull
    git checkout -b "feature/$feature_name"
    echo "Started new feature branch: feature/$feature_name"
}

# Start a new bugfix branch
function start-bugfix() {
    local bug_name="$1"
    git checkout main
    git pull
    git checkout -b "bugfix/$bug_name"
    echo "Started new bugfix branch: bugfix/$bug_name"
}

# Start a new release branch
function start-release() {
    local version="$1"
    git checkout main
    git pull
    git checkout -b "release/$version"
    echo "Started new release branch: release/$version"
}

# Clean up git branches
function cleanup-branches() {
    git fetch -p
    git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -D
    echo "Cleaned up deleted remote branches"
}

# Show git log with graph
function glog() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

# Development Environment Setup

# Setup Python development environment
function setup-pyenv() {
    local project_name="$1"
    # Only cd if not already in the project directory
    if [ "$(basename "$PWD")" != "$project_name" ]; then
        mkcd "$project_name"
    fi
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install black pylint pytest
    echo "Python development environment setup complete"
}

# Setup Go development environment
function setup-goenv() {
    go mod init "$1"
    go mod tidy
    echo "Go development environment setup complete"
}

# Setup Node.js development environment
function setup-nodeenv() {
    npm init -y
    npm install eslint prettier --save-dev
    echo "Node.js development environment setup complete"
}

# Setup Rust development environment
function setup-rustenv() {
    cargo init --bin "$1"
    echo "Rust development environment setup complete"
}

# System Information

# Show system information
function sysinfo() {
    echo "System Information"
    echo "System: $(uname -a)"
    echo "Uptime: $(uptime)"
    
    # Memory info for macOS
    if command -v vm_stat >/dev/null 2>&1; then
        local memory_info
        memory_info=$(vm_stat | grep -E "Pages (free|active|inactive|wired|speculative)" | awk '{sum+=$3} END {print sum*4096/1024/1024/1024 " GB"}')
        echo "Memory: $memory_info"
    else
        echo "Memory: $(system_profiler SPHardwareDataType | grep "Memory:" | awk '{print $2, $3}')"
    fi
    
    echo "Disk: $(df -h / | awk '/\// {print $3 "/" $2}')"
}

# Show network information
function netinfo() {
    echo "Public IP: $(curl -s ifconfig.me)"
    echo "Local IP: $(localip)"
    echo "Ping: $(pingtest google.com)"
}

# Show git repository information
function gitinfo() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Branch: $(git branch --show-current)"
        echo "Last commit: $(git log -1 --pretty=format:'%s (%cr)')"
        echo "Remote: $(git remote -v | awk '/\(fetch\)/ {print $2}')"
    else
        echo "Not a git repository"
    fi
}

# Show environment information
function envinfo() {
    echo "Shell: $SHELL"
    echo "Python: $(which python3)"
    echo "Go: $(which go)"
    echo "Node: $(which node)"
    echo "Git: $(which git)"
    echo "VS Code: $(which code)"
}

# Zoxide, fzf, and Cursor integration
# Function to open a directory with a specified command, using zoxide.
# If a directory query is passed, it opens the best match.
# Otherwise, it opens an interactive fzf menu.
# Usage: _z_open "opener_command" [directory_query]
_z_open() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: _z_open <opener_command> [directory_query]" >&2
        return 1
    fi

    # Dependencies check
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "zoxide is not installed. Please install it first." >&2
        return 1
    fi

    local opener_command="$1"
    local dir_query="$2"
    local dir

    if [ -n "$dir_query" ]; then
        dir=$(zoxide query -- "$dir_query")
        if [ -z "$dir" ]; then
            echo "No directory found for '$dir_query'." >&2
            return 1
        fi
    else
        if ! command -v fzf >/dev/null 2>&1; then
            echo "fzf is not installed. Please install it first." >&2
            return 1
        fi
        dir=$(zoxide query -l | fzf --height 40% --reverse)
    fi

    if [ -n "$dir" ]; then
        # Using eval to correctly handle commands with arguments
        eval "$opener_command \"\$dir\""
    else
        echo "No directory selected. Staying put."
    fi
}

# Function to cd into a directory using zoxide.
# If a directory query is passed, it cds to the best match.
# Otherwise, it opens an interactive fzf menu.
# It falls back to the builtin 'cd' for special paths like '..', '-', or anything with a '/'.
# Usage: z [directory_query]
_z_cd() {
    # Fallback to builtin 'cd' for special paths
    if [[ "$1" == "-" ]] || [[ "$1" == *..* ]] || [[ "$1" == */* ]]; then
        builtin cd "$@"
        return
    fi

    # Dependency check
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "zoxide is not installed. Please install it first." >&2
        return 1
    fi

    local dir_query="$1"
    local dir

    if [ -n "$dir_query" ]; then
        dir=$(zoxide query -- "$dir_query")
        if [ -z "$dir" ]; then
            echo "No directory found for '$dir_query'." >&2
            return 1
        fi
    else
        if ! command -v fzf >/dev/null 2>&1; then
            echo "fzf is not installed. Please install it first." >&2
            return 1
        fi
        dir=$(zoxide query -l | fzf --height 40% --reverse)
    fi

    if [ -n "$dir" ]; then
        builtin cd "$dir"
    elif [ -z "$dir_query" ]; then
        # This message should only appear if fzf was invoked and cancelled.
        echo "No directory selected. Staying put."
    fi
}

# Function to securely run a command after loading secrets from 1Password.
# Usage: _secure_run <profile> <command> [args...]
_secure_run() {
    # Check for a profile and command argument.
    if [ "$#" -lt 2 ]; then
        echo "Error: Usage is _secure_run <profile> <command> [args...]" >&2
        return 1
    fi

    local profile="$1"
    local command_to_run="$2"
    local profile_path="$DOTFILES/shells/oh-my-zsh/custom/secure_profiles/$profile"
    shift 2 # The rest of the arguments are for the command.

    if [ ! -f "$profile_path" ]; then
        echo "Error: Profile '$profile' not found at $profile_path." >&2
        return 1
    fi

    # Use set -e for the duration of secret loading.
    set -e

    # Source the profile to load secrets
    # shellcheck source=/dev/null
    source "$profile_path"

    # Disable 'exit on error' before running the user's command.
    set +e

    # After loading profile secrets, check for a local .env file.
    # This allows the .env file to override the profile for local development.
    if [ -f "./.env" ]; then
        echo "Found local .env file. Loading and exporting variables..."
        set -o allexport
        source "./.env"
        set +o allexport
    fi

    # Run the command with the loaded secrets and any passed arguments.
    command "$command_to_run" "$@"
}

# Function to help create a new profile for the _secure_run command.
new_secure_profile() {
    if [ -z "$1" ]; then
        echo "Usage: new_secure_profile <profile_name>" >&2
        return 1
    fi

    local profile_name="$1"
    local profile_path="$DOTFILES/shells/oh-my-zsh/custom/secure_profiles/$profile_name"

    if [ -f "$profile_path" ]; then
        echo "Profile '$profile_name' already exists at $profile_path." >&2
        return 1
    fi

    echo "Creating a new profile for '$profile_name' at $profile_path"

    # Create a template file for the new profile
    cat > "$profile_path" <<EOF
# Add your secret-loading commands here.
# For example:
# export MY_API_KEY=\$(op read "op://Vault/Item/field")
EOF

    echo "New profile '$profile_name' created at $profile_path"
    echo "You can now edit this file to add your secrets."
    echo ""
    echo "Opening the profile file for you now..."
    sleep 2 # Give user a moment to read

    # Use the user's preferred editor, default to 'code'
    ${EDITOR:-code} "$profile_path"
}

# MCP Functions

# Check or install MCP configuration
# Usage: mcp-check              # Check all MCP configs
#        mcp-check -i           # Install all missing MCP configs
#        mcp-check -t project   # Check project-level .mcp.json in current dir
#        mcp-check -t project -i  # Install .mcp.json in current dir
function mcp-check() {
    ~/.dotfiles/scripts/check-mcp-installed.sh "$@"
}

# Quick install MCP in current project directory
# Usage: mcp-init               # Install .mcp.json in current directory
#        mcp-init /path/to/dir  # Install .mcp.json in specified directory
function mcp-init() {
    local target_dir="${1:-.}"

    # Install the main .mcp.json
    ~/.dotfiles/scripts/check-mcp-installed.sh -t project -i -d "$target_dir"

    # Copy profile templates for mcp-switch support
    local mcp_templates_dir="$HOME/.dotfiles/tools/mcp"
    if [[ -d "$mcp_templates_dir" ]]; then
        echo ""
        echo "Installing MCP profile templates..."
        for template in "$mcp_templates_dir"/.mcp.*.json; do
            if [[ -f "$template" ]]; then
                local filename=$(basename "$template")
                cp "$template" "${target_dir}/${filename}"
                # Replace USERNAME placeholder
                sed -i '' "s|/Users/USERNAME|$HOME|g" "${target_dir}/${filename}"
                echo "  Installed: $filename"
            fi
        done
        echo ""
        echo "Available profiles: mcp-switch <profile>"
        echo "  - notion-only    (Notion only)"
        echo "  - docs-focus     (Notion + Google Drive)"
        echo "  - project-focus  (Notion + Linear)"
        echo "  - all-tools      (All MCP servers)"
    fi
}

# Source MCP Profile Manager functions
if [ -f "$DOTFILES/mcp-profile-functions.zsh" ]; then
    source "$DOTFILES/mcp-profile-functions.zsh"
fi
