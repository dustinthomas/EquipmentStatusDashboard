#!/bin/bash
# Restart MCP REPL server
# This is a wrapper for backwards compatibility.
# See mcp.sh for the full implementation.
#
# Usage: ./scripts/restart_mcp.sh [--force]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Handle --force flag
if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
    exec "$SCRIPT_DIR/mcp.sh" restart
else
    # Check if already running first
    if ss -tlnp 2>/dev/null | grep -q ':3000 '; then
        echo "MCP server is already running. Use --force to restart."
        exit 2
    fi
    exec "$SCRIPT_DIR/mcp.sh" start
fi
