#!/usr/bin/env bash
#
# check-mcp-installed.sh - Check and optionally install MCP configuration
#
# Usage:
#   check-mcp-installed.sh [OPTIONS] [TARGET_DIR]
#
# Options:
#   -i, --install     Install MCP config if not present (default: check only)
#   -f, --force       Force reinstall even if config exists
#   -t, --type TYPE   Config type: claude-desktop, cursor, claude-cli, vscode, boltai, project, all (default: all)
#   -d, --dir DIR     Target directory for project-level .mcp.json (defaults to current directory)
#   -q, --quiet       Suppress non-error output
#   -h, --help        Show this help message
#
# Exit codes:
#   0 - MCP is installed (or was installed with -i)
#   1 - MCP is not installed (when -i not used)
#   2 - Error occurred during installation
#   3 - Invalid arguments
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
INSTALL=false
FORCE=false
CONFIG_TYPE="all"
QUIET=false
PROJECT_DIR=""

# Colors (disabled if not a tty)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

log_info() {
  [[ "$QUIET" == "true" ]] || echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  [[ "$QUIET" == "true" ]] || echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS] [TARGET_DIR]

Check if MCP (Model Context Protocol) configuration is installed and optionally install it.

Options:
  -i, --install     Install MCP config if not present (default: check only)
  -f, --force       Force reinstall even if config exists
  -t, --type TYPE   Config type (default: all)
                    Types: claude-desktop, cursor, claude-cli, vscode, boltai, project, all
  -d, --dir DIR     Target directory for project-level .mcp.json (defaults to current directory)
  -q, --quiet       Suppress non-error output
  -h, --help        Show this help message

Config locations:
  claude-desktop:   ~/Library/Application Support/Claude/claude_desktop_config.json
  cursor:           ~/.cursor/mcp.json
  claude-cli:       Configured via 'claude mcp' commands
  vscode:           ~/Library/Application Support/Code/User/mcp.json
  boltai:           ~/.boltai/mcp.json
  project:          .mcp.json in specified directory (or current directory)

Examples:
  $(basename "$0")                        # Check all app MCP configs
  $(basename "$0") -i                     # Install all app MCP configs if missing
  $(basename "$0") -t cursor -i           # Install Cursor MCP config only
  $(basename "$0") -f -t claude-desktop   # Force reinstall Claude Desktop config
  $(basename "$0") -t project -i          # Install .mcp.json in current directory
  $(basename "$0") -t project -i -d ~/myproject  # Install .mcp.json in specified directory

Exit codes:
  0 - MCP is installed (or was installed with -i)
  1 - MCP is not installed (when -i not used)
  2 - Error occurred during installation
  3 - Invalid arguments
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install)
      INSTALL=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -t|--type)
      CONFIG_TYPE="$2"
      shift 2
      ;;
    -d|--dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      log_error "Unknown option: $1"
      usage
      exit 3
      ;;
    *)
      # Positional argument - treat as project directory
      PROJECT_DIR="$1"
      shift
      ;;
  esac
done

# Set default project directory to current directory
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(pwd)"
fi

# Validate config type
case "$CONFIG_TYPE" in
  claude-desktop|cursor|claude-cli|vscode|boltai|project|all)
    ;;
  *)
    log_error "Invalid config type: $CONFIG_TYPE"
    log_error "Valid types: claude-desktop, cursor, claude-cli, vscode, boltai, project, all"
    exit 3
    ;;
esac

# Get default paths
get_claude_desktop_config_dir() {
  echo "$HOME/Library/Application Support/Claude"
}

get_claude_desktop_config_file() {
  echo "$(get_claude_desktop_config_dir)/claude_desktop_config.json"
}

get_cursor_config_dir() {
  echo "$HOME/.cursor"
}

get_cursor_config_file() {
  echo "$(get_cursor_config_dir)/mcp.json"
}

get_vscode_config_dir() {
  echo "$HOME/Library/Application Support/Code/User"
}

get_vscode_config_file() {
  echo "$(get_vscode_config_dir)/mcp.json"
}

get_boltai_config_dir() {
  echo "$HOME/.boltai"
}

get_boltai_config_file() {
  echo "$(get_boltai_config_dir)/mcp.json"
}

get_project_config_file() {
  echo "$PROJECT_DIR/.mcp.json"
}

# Check if MCP config file exists and has mcpServers configured
check_mcp_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    return 1
  fi

  # Check if file has mcpServers key with content
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.mcpServers | length > 0' "$config_file" >/dev/null 2>&1; then
      return 0
    fi
    return 1
  else
    # Fallback: simple grep check
    if grep -q '"mcpServers"' "$config_file" 2>/dev/null; then
      return 0
    fi
    return 1
  fi
}

# Check if Claude CLI has MCP servers configured
check_claude_cli_mcp() {
  if ! command -v claude >/dev/null 2>&1; then
    return 1
  fi

  # Check if any MCP servers are configured
  if claude mcp list 2>/dev/null | grep -q -E '^\s*\S+'; then
    return 0
  fi
  return 1
}

# Generic MCP config installer
install_mcp_config() {
  local config_dir="$1"
  local config_file="$2"
  local template_path="$3"
  local app_name="$4"

  if [[ ! -f "$template_path" ]]; then
    log_error "Template not found: $template_path"
    return 2
  fi

  log_info "Installing $app_name MCP configuration..."

  # Create directory if needed
  mkdir -p "$config_dir"

  # Remove existing file (symlink or regular file)
  if [[ -L "$config_file" ]] || [[ -f "$config_file" ]]; then
    rm -f "$config_file"
  fi

  # Copy template
  cp "$template_path" "$config_file"

  # Resolve 1Password secrets if available
  if command -v op >/dev/null 2>&1; then
    if [[ -f "$DOTFILES_DIR/scripts/resolve-1password-secrets.sh" ]]; then
      log_info "Resolving 1Password secrets..."
      "$DOTFILES_DIR/scripts/resolve-1password-secrets.sh" "$config_file" || {
        log_warn "Could not resolve 1Password secrets. Config will use placeholder values."
      }
    fi
  else
    log_warn "1Password CLI not available. Config will use placeholder values."
  fi

  # Replace USERNAME placeholder with actual home directory
  sed -i '' "s|/Users/USERNAME|$HOME|g" "$config_file"

  log_success "$app_name MCP configuration installed: $config_file"
  return 0
}

# Install MCP config for Claude Desktop
install_claude_desktop_mcp() {
  install_mcp_config \
    "$(get_claude_desktop_config_dir)" \
    "$(get_claude_desktop_config_file)" \
    "$DOTFILES_DIR/tools/mcp/claude_desktop_config.json.template" \
    "Claude Desktop"
}

# Install MCP config for Cursor
install_cursor_mcp() {
  install_mcp_config \
    "$(get_cursor_config_dir)" \
    "$(get_cursor_config_file)" \
    "$DOTFILES_DIR/tools/mcp/cursor_mcp.json.template" \
    "Cursor"
}

# Install MCP config for VS Code
install_vscode_mcp() {
  install_mcp_config \
    "$(get_vscode_config_dir)" \
    "$(get_vscode_config_file)" \
    "$DOTFILES_DIR/tools/mcp/cursor_mcp.json.template" \
    "VS Code"
}

# Install MCP config for BoltAI
install_boltai_mcp() {
  install_mcp_config \
    "$(get_boltai_config_dir)" \
    "$(get_boltai_config_file)" \
    "$DOTFILES_DIR/tools/mcp/cursor_mcp.json.template" \
    "BoltAI"
}

# Install MCP config for project directory
install_project_mcp() {
  local config_file
  config_file=$(get_project_config_file)
  local template_path="$DOTFILES_DIR/tools/mcp/cursor_mcp.json.template"

  if [[ ! -f "$template_path" ]]; then
    log_error "Template not found: $template_path"
    return 2
  fi

  log_info "Installing project-level MCP configuration..."

  # Create directory if needed
  mkdir -p "$PROJECT_DIR"

  # Remove existing file (symlink or regular file)
  if [[ -L "$config_file" ]] || [[ -f "$config_file" ]]; then
    rm -f "$config_file"
  fi

  # Copy template
  cp "$template_path" "$config_file"

  # Resolve 1Password secrets if available
  if command -v op >/dev/null 2>&1; then
    if [[ -f "$DOTFILES_DIR/scripts/resolve-1password-secrets.sh" ]]; then
      log_info "Resolving 1Password secrets..."
      "$DOTFILES_DIR/scripts/resolve-1password-secrets.sh" "$config_file" || {
        log_warn "Could not resolve 1Password secrets. Config will use placeholder values."
      }
    fi
  else
    log_warn "1Password CLI not available. Config will use placeholder values."
  fi

  # Replace USERNAME placeholder with actual home directory
  sed -i '' "s|/Users/USERNAME|$HOME|g" "$config_file"

  log_success "Project MCP configuration installed: $config_file"
  return 0
}

# Install MCP for Claude CLI
install_claude_cli_mcp() {
  if ! command -v claude >/dev/null 2>&1; then
    log_warn "Claude CLI not found. Skipping Claude CLI MCP setup."
    return 0
  fi

  log_info "Setting up MCP servers for Claude CLI..."

  # Check if OutlookMCP already exists
  if ! claude mcp list 2>&1 | grep -q "OutlookMCP"; then
    local bun_path="$HOME/.bun/bin/bun"
    local outlook_mcp_path="$HOME/.repos/github.com/syedazharmbnr1/claude-outlook-mcp/index.ts"

    if [[ -x "$bun_path" ]] && [[ -f "$outlook_mcp_path" ]]; then
      log_info "Adding OutlookMCP to Claude CLI..."
      claude mcp add OutlookMCP --transport stdio -- "$bun_path" run "$outlook_mcp_path" 2>&1 || {
        log_warn "Could not add OutlookMCP to Claude CLI"
        return 0
      }
      log_success "OutlookMCP added to Claude CLI"
    else
      log_warn "OutlookMCP dependencies not found. Run './install config mcp' first."
    fi
  else
    log_info "OutlookMCP already configured in Claude CLI"
  fi

  return 0
}

# Ensure OutlookMCP dependencies are installed
ensure_outlook_mcp() {
  local outlook_mcp_dir="$HOME/.repos/github.com/syedazharmbnr1/claude-outlook-mcp"

  # Check and setup bun
  if ! command -v bun >/dev/null 2>&1; then
    if [[ -f "$HOME/.bun/bin/bun" ]]; then
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
    else
      log_warn "Bun not found. OutlookMCP requires Bun."
      log_info "Install Bun by running: ./install config bun"
      return 0
    fi
  fi

  # Clone or update OutlookMCP
  if [[ ! -d "$outlook_mcp_dir" ]]; then
    log_info "Cloning claude-outlook-mcp..."
    mkdir -p "$(dirname "$outlook_mcp_dir")"
    git clone https://github.com/syedazharmbnr1/claude-outlook-mcp.git "$outlook_mcp_dir" || {
      log_error "Failed to clone claude-outlook-mcp"
      return 2
    }
  else
    log_info "Updating claude-outlook-mcp..."
    (cd "$outlook_mcp_dir" && git pull) || log_warn "Could not update claude-outlook-mcp"
  fi

  # Install dependencies
  if command -v bun >/dev/null 2>&1; then
    log_info "Installing claude-outlook-mcp dependencies..."
    (cd "$outlook_mcp_dir" && bun install) || {
      log_error "Failed to install claude-outlook-mcp dependencies"
      return 2
    }
    chmod +x "$outlook_mcp_dir/index.ts" 2>/dev/null || true
  fi

  return 0
}

# Handle single config type check/install
handle_single_type() {
  local type="$1"
  local check_func="$2"
  local install_func="$3"
  local name="$4"
  local installed=false
  local exit_code=0

  if $check_func; then
    installed=true
    if [[ "$FORCE" == "true" ]] && [[ "$INSTALL" == "true" ]]; then
      $install_func || exit_code=2
    else
      log_success "$name MCP is installed"
    fi
  else
    if [[ "$INSTALL" == "true" ]]; then
      $install_func || exit_code=2
    else
      log_info "$name MCP is NOT installed"
    fi
  fi

  if [[ "$exit_code" -ne 0 ]]; then
    return $exit_code
  elif [[ "$INSTALL" == "true" ]]; then
    return 0
  elif [[ "$installed" == "false" ]]; then
    return 1
  else
    return 0
  fi
}

# Main logic
main() {
  local exit_code=0

  # Check/install based on config type
  case "$CONFIG_TYPE" in
    claude-desktop)
      if [[ "$INSTALL" == "true" ]]; then
        ensure_outlook_mcp || true
      fi
      handle_single_type "claude-desktop" \
        "check_mcp_config $(get_claude_desktop_config_file)" \
        "install_claude_desktop_mcp" \
        "Claude Desktop"
      exit_code=$?
      ;;

    cursor)
      if [[ "$INSTALL" == "true" ]]; then
        ensure_outlook_mcp || true
      fi
      handle_single_type "cursor" \
        "check_mcp_config $(get_cursor_config_file)" \
        "install_cursor_mcp" \
        "Cursor"
      exit_code=$?
      ;;

    vscode)
      if [[ "$INSTALL" == "true" ]]; then
        ensure_outlook_mcp || true
      fi
      handle_single_type "vscode" \
        "check_mcp_config $(get_vscode_config_file)" \
        "install_vscode_mcp" \
        "VS Code"
      exit_code=$?
      ;;

    boltai)
      if [[ "$INSTALL" == "true" ]]; then
        ensure_outlook_mcp || true
      fi
      handle_single_type "boltai" \
        "check_mcp_config $(get_boltai_config_file)" \
        "install_boltai_mcp" \
        "BoltAI"
      exit_code=$?
      ;;

    project)
      if [[ "$INSTALL" == "true" ]]; then
        ensure_outlook_mcp || true
      fi
      handle_single_type "project" \
        "check_mcp_config $(get_project_config_file)" \
        "install_project_mcp" \
        "Project ($PROJECT_DIR)"
      exit_code=$?
      ;;

    claude-cli)
      if [[ "$INSTALL" == "true" ]]; then
        ensure_outlook_mcp || true
      fi
      handle_single_type "claude-cli" \
        "check_claude_cli_mcp" \
        "install_claude_cli_mcp" \
        "Claude CLI"
      exit_code=$?
      ;;

    all)
      local all_installed=true
      local claude_desktop_installed=false
      local cursor_installed=false
      local vscode_installed=false
      local boltai_installed=false
      local claude_cli_installed=false

      # Check Claude Desktop
      if check_mcp_config "$(get_claude_desktop_config_file)"; then
        claude_desktop_installed=true
        log_success "Claude Desktop MCP is installed"
      else
        all_installed=false
        log_info "Claude Desktop MCP is NOT installed"
      fi

      # Check Cursor
      if check_mcp_config "$(get_cursor_config_file)"; then
        cursor_installed=true
        log_success "Cursor MCP is installed"
      else
        all_installed=false
        log_info "Cursor MCP is NOT installed"
      fi

      # Check VS Code
      if check_mcp_config "$(get_vscode_config_file)"; then
        vscode_installed=true
        log_success "VS Code MCP is installed"
      else
        all_installed=false
        log_info "VS Code MCP is NOT installed"
      fi

      # Check BoltAI
      if check_mcp_config "$(get_boltai_config_file)"; then
        boltai_installed=true
        log_success "BoltAI MCP is installed"
      else
        all_installed=false
        log_info "BoltAI MCP is NOT installed"
      fi

      # Check Claude CLI
      if check_claude_cli_mcp; then
        claude_cli_installed=true
        log_success "Claude CLI MCP is installed"
      else
        all_installed=false
        log_info "Claude CLI MCP is NOT installed"
      fi

      # Install if requested
      if [[ "$INSTALL" == "true" ]]; then
        # Ensure OutlookMCP dependencies first
        ensure_outlook_mcp || exit_code=2

        if [[ "$FORCE" == "true" ]] || [[ "$claude_desktop_installed" == "false" ]]; then
          install_claude_desktop_mcp || exit_code=2
        fi

        if [[ "$FORCE" == "true" ]] || [[ "$cursor_installed" == "false" ]]; then
          install_cursor_mcp || exit_code=2
        fi

        if [[ "$FORCE" == "true" ]] || [[ "$vscode_installed" == "false" ]]; then
          install_vscode_mcp || exit_code=2
        fi

        if [[ "$FORCE" == "true" ]] || [[ "$boltai_installed" == "false" ]]; then
          install_boltai_mcp || exit_code=2
        fi

        if [[ "$FORCE" == "true" ]] || [[ "$claude_cli_installed" == "false" ]]; then
          install_claude_cli_mcp || exit_code=2
        fi
      fi

      # Return appropriate exit code
      if [[ "$exit_code" -ne 0 ]]; then
        return $exit_code
      elif [[ "$INSTALL" == "true" ]]; then
        return 0
      elif [[ "$all_installed" == "false" ]]; then
        return 1
      else
        return 0
      fi
      ;;

    *)
      log_error "Unknown config type: $CONFIG_TYPE"
      log_info "Valid types: claude-desktop, cursor, vscode, boltai, project, claude-cli, all"
      return 1
      ;;
  esac

  return $exit_code
}

main "$@"
