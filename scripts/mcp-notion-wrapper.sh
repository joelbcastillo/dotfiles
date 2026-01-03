#!/bin/bash
# Wrapper script for Notion MCP server
# Constructs the OPENAPI_MCP_HEADERS from NOTION_API_KEY environment variable
# Usage: This script is called by op run with NOTION_API_KEY injected

set -e

if [ -z "$NOTION_API_KEY" ]; then
    echo "Error: NOTION_API_KEY environment variable is not set" >&2
    exit 1
fi

# Construct the headers JSON and export it
export OPENAPI_MCP_HEADERS="{\"Authorization\": \"Bearer $NOTION_API_KEY\", \"Notion-Version\": \"2022-06-28\"}"

# Execute the Notion MCP server
exec npx -y @notionhq/notion-mcp-server "$@"
