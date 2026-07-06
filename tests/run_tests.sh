#!/bin/bash
# Shell functions require zsh syntax; delegate to the zsh test harness.
exec zsh "$(dirname "$0")/run_tests.zsh"