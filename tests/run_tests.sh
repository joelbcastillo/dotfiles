#!/bin/bash

# Source the shell functions
source "$(dirname "$0")/../shells/oh-my-zsh/custom/functions.zsh"

# Run the test suite
"$(dirname "$0")/shell_functions.test.sh" 