#!/bin/bash

# Create plugins directory if it doesn't exist
mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# Function to install or update a plugin
install_plugin() {
    local repo=$1
    local plugin_name
    plugin_name=$(basename "$repo" .git)
    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
    
    if [ ! -d "$plugin_dir" ]; then
        echo "Installing $plugin_name..."
        git clone "https://github.com/$repo" "$plugin_dir"
    else
        echo "Updating $plugin_name..."
        cd "$plugin_dir" && git pull
    fi
}

# Install required plugins
install_plugin "zsh-users/zsh-autosuggestions"
install_plugin "zsh-users/zsh-syntax-highlighting" 