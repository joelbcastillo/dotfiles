# asdf 0.16+ is a Go binary on PATH; only thing left to do here is wire up
# the shims directory and completions.
export PATH="$HOME/.asdf/shims:$PATH"
fpath=("${ASDF_DATA_DIR:-$HOME/.asdf}/completions" $fpath)
autoload -Uz compinit && compinit -C
