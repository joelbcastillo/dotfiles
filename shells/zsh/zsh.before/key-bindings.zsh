# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# Use vi key bindings
bindkey -v

# Search backward incrementally for a specified string
bindkey '^r' history-incremental-search-backward

# emacs style
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# Make numpad enter work
bindkey -s "^[Op" "0"
bindkey -s "^[Ol" "."
bindkey -s "^[OM" "^M"
