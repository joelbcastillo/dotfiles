# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Append to history file instead of overwriting
setopt APPEND_HISTORY

# Add commands as they are typed, not at shell exit
setopt INC_APPEND_HISTORY

# Do not store duplications
setopt HIST_IGNORE_DUPS

# Remove unnecessary blanks
setopt HIST_REDUCE_BLANKS

# Do not store commands starting with space
setopt HIST_IGNORE_SPACE

# Share history between sessions
setopt SHARE_HISTORY 