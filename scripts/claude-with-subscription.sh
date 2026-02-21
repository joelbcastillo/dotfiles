#!/bin/bash

# Wrapper script to run Claude Code with subscription login
# This ensures ANTHROPIC_API_KEY is unset so Claude Code uses your subscription
#
# Usage: claude-sub "your prompt"
#        claude-sub --help
#        etc.
#
# Note: Since we're using subscription for everything now, this script
# just ensures the API key is unset and runs claude normally.

# Unset API key to ensure subscription is used
unset ANTHROPIC_API_KEY

# Run claude with provided arguments
claude "$@"
