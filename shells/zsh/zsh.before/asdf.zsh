# asdf 0.16+ is a Go binary on PATH; only thing left to do here is wire up
# the shims directory and completions. The compinit call is OMZ's job —
# running it again here was a redundant ~150ms per shell.
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
fpath=("${ASDF_DATA_DIR:-$HOME/.asdf}/completions" $fpath)
