# Load any user customizations prior to load
#
if [ -d $HOME/.zsh.before/personal/ ]; then
  if [ "$(ls -A $HOME/.zsh.before/personal/)" ]; then
    for config_file ($HOME/.zsh.before/personal/*.zsh) source $config_file
  fi
fi
