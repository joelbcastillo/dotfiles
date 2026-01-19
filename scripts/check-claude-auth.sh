#!/bin/bash

# Script to check Claude Code authentication status
# Shows which authentication method is currently active

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Claude Code Authentication Status"
echo "================================="
echo ""

# Check if API key is set
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  ANTHROPIC_API_KEY is set${NC}"
    echo "   This means you're using pay-as-you-go billing"
    echo "   Prefix: ${ANTHROPIC_API_KEY:0:15}..."
    echo ""
    echo "   To use subscription instead:"
    echo "     unset ANTHROPIC_API_KEY"
    echo "     claude /status"
else
    echo -e "${GREEN}✓ ANTHROPIC_API_KEY is NOT set${NC}"
    echo "   Subscription authentication will be used"
    echo ""
fi

# Check Claude Code status
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code Status:"
    echo "------------------"
    claude /status 2>&1 || echo "  (Could not get status - may need to run 'claude login')"
    echo ""
else
    echo -e "${RED}✗ Claude Code CLI not found${NC}"
    echo "   Install with: brew install --cask claude"
    echo ""
fi

# Summary
echo "Summary:"
echo "--------"
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}Current: Using API key (pay-as-you-go)${NC}"
    echo "To switch to subscription: unset ANTHROPIC_API_KEY"
else
    echo -e "${GREEN}Current: Using subscription (if logged in)${NC}"
    echo "To use API key temporarily: use-api-key"
fi
