#!/usr/bin/env bash
# bootstrap-linux.sh — one-shot Ubuntu bootstrap for dotfiles.
#
# Idempotent. Safe to re-run. Installs the CLI tools the Mac setup gets from
# Homebrew, using apt + direct installers. Does NOT install Homebrew.
#
# Honors NONINTERACTIVE=1 (or non-tty stdin) for IaC use: sudo runs with
# -n (NOPASSWD or pre-cached creds required), apt uses
# DEBIAN_FRONTEND=noninteractive.
#
# After this runs, follow up with:
#   ./install profile full

set -eu

SELF="$(basename "$0")"
info()    { printf "\033[0;34m[%s]\033[0m %s\n" "$SELF" "$*"; }
warn()    { printf "\033[1;33m[%s]\033[0m %s\n" "$SELF" "$*" >&2; }
die()     { printf "\033[0;31m[%s]\033[0m %s\n" "$SELF" "$*" >&2; exit 1; }

# Detect non-interactive (IaC) mode.
if [ "${NONINTERACTIVE:-0}" = "1" ] || [ ! -t 0 ]; then
    NONINTERACTIVE=1
else
    NONINTERACTIVE=0
fi
info "NONINTERACTIVE=$NONINTERACTIVE"

sudo_run() {
    if [ "$NONINTERACTIVE" = "1" ]; then
        sudo -n "$@" || die "sudo failed in NONINTERACTIVE mode (need NOPASSWD or pre-cached creds): $*"
    else
        sudo "$@"
    fi
}

[ "$(uname -s)" = "Linux" ] || die "bootstrap-linux.sh only runs on Linux"

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    info "Detected: ${PRETTY_NAME:-$NAME}"
fi

if ! command -v apt-get >/dev/null 2>&1; then
    die "apt-get not found — this script assumes Debian/Ubuntu. Adapt as needed."
fi

# --- 1. apt packages ---------------------------------------------------------
info "Updating apt and installing base packages..."
DEBIAN_FRONTEND=noninteractive sudo_run apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo_run apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    software-properties-common \
    unzip \
    wget \
    zsh \
    tmux \
    vim \
    jq \
    tree \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    fd-find \
    fzf \
    direnv \
    bat \
    htop \
    neofetch \
    xclip

# fd/bat ship under different names on Ubuntu; shim to the conventional names
mkdir -p "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
export PATH="$HOME/.local/bin:$PATH"

# --- 2. GitHub CLI (gh) ------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
    info "Installing GitHub CLI..."
    sudo_run mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo_run tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo_run chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo_run tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    DEBIAN_FRONTEND=noninteractive sudo_run apt-get update -y
    DEBIAN_FRONTEND=noninteractive sudo_run apt-get install -y gh
fi

# --- 3. 1Password CLI --------------------------------------------------------
if ! command -v op >/dev/null 2>&1; then
    info "Installing 1Password CLI..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc \
        | sudo_run gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
        | sudo_run tee /etc/apt/sources.list.d/1password.list >/dev/null
    sudo_run mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
        | sudo_run tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
    sudo_run mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc \
        | sudo_run gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    DEBIAN_FRONTEND=noninteractive sudo_run apt-get update -y
    DEBIAN_FRONTEND=noninteractive sudo_run apt-get install -y 1password-cli
fi

# --- 4. Starship prompt ------------------------------------------------------
if ! command -v starship >/dev/null 2>&1; then
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
fi

# --- 5. zoxide ---------------------------------------------------------------
if ! command -v zoxide >/dev/null 2>&1; then
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
        | bash
fi

# --- 6. eza (modern ls) ------------------------------------------------------
if ! command -v eza >/dev/null 2>&1; then
    info "Installing eza..."
    if apt-cache show eza >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive sudo_run apt-get install -y eza
    else
        # Fallback: download latest release binary
        EZA_VERSION="$(curl -sS https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep tag_name | head -n1 | cut -d'"' -f4)"
        arch="$(dpkg --print-architecture)"
        case "$arch" in
            amd64) eza_arch="x86_64-unknown-linux-gnu" ;;
            arm64) eza_arch="aarch64-unknown-linux-gnu" ;;
            *) warn "Unknown arch $arch; skipping eza"; eza_arch="" ;;
        esac
        if [ -n "$eza_arch" ]; then
            tmp="$(mktemp -d)"
            curl -sSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${eza_arch}.tar.gz" \
                -o "$tmp/eza.tar.gz"
            tar -xzf "$tmp/eza.tar.gz" -C "$tmp"
            install -m 0755 "$tmp/eza" "$HOME/.local/bin/eza"
            rm -rf "$tmp"
        fi
    fi
fi

# --- 7. asdf -----------------------------------------------------------------
if [ ! -d "$HOME/.asdf" ] && ! command -v asdf >/dev/null 2>&1; then
    info "Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.1
fi

# --- 8. Nerd Fonts -----------------------------------------------------------
# Two fonts (FiraCode, JetBrainsMono) for the Starship prompt + terminal.
# Skipped in NONINTERACTIVE mode if curl access to GitHub releases is
# restricted; the install will still finish.
NERD_FONT_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
NERD_FONTS=(FiraCode JetBrainsMono)
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
fonts_added=0
for font in "${NERD_FONTS[@]}"; do
    if find "$FONT_DIR" -iname "*${font}*Nerd*" -print -quit 2>/dev/null | grep -q .; then
        continue
    fi
    info "Installing Nerd Font: $font"
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/$font.zip" "$NERD_FONT_BASE/$font.zip"; then
        unzip -q -o "$tmp/$font.zip" -d "$FONT_DIR/$font"
        fonts_added=1
    else
        warn "Failed to download $font Nerd Font; continuing"
    fi
    rm -rf "$tmp"
done
if [ "$fonts_added" = "1" ] && command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR" >/dev/null
fi

# --- 9. Node.js (via asdf, for Claude Code) ---------------------------------
# Leave language installs to ./install profile full — this script just gets
# the system ready.

info "Base bootstrap complete."
info ""
info "Next steps:"
info "  1. git submodule update --init --recursive"
info "  2. ./install profile full"
info "  3. exec zsh -l"
