#!/bin/bash
if [ ! -d ~/.asdf ]; then
    echo "Installing ASDF"
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.16.7
fi
