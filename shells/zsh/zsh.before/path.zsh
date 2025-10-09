# Add dotfiles scripts to PATH
export PATH="$DOTFILES/scripts:$PATH"

# Add custom scripts to PATH
export PATH="$PATH:$HOME/.oh-my-zsh/custom/scripts"

# Add local bin directory
export PATH="$HOME/.local/bin:$PATH"

# Add Homebrew paths
if [[ $platform == 'darwin' ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="/opt/homebrew/sbin:$PATH"
fi

# Add cargo bin directory
export PATH="$HOME/.cargo/bin:$PATH"

# Add go bin directory
export PATH="$HOME/go/bin:$PATH"

# Add python user bin directories (all versions)
if [[ -d "$HOME/Library/Python" ]]; then
  for pydir in "$HOME/Library/Python/"*/bin(N); do
    export PATH="$pydir:$PATH"
  done
fi
