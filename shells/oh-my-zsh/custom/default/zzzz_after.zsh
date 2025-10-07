# Load any custom after code
if [ -d $HOME/.zsh.after/personal/ ]; then
  if [ "$(ls -A $HOME/.zsh.after/personal/)" ]; then
    for config_file ($HOME/.zsh.after/personal/*.zsh) source $config_file
  fi
fi
