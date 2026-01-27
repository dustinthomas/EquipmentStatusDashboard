#!/bin/bash
# Restart MCP REPL server in WezTerm pane to the right of Claude Code
# Usage: ./scripts/restart_mcp.sh

set -e

PROJECT_DIR="C:/Git/Projects/EqupimentStatusDashboard"
JULIA_CMD="julia --project=. -i scripts/start_mcp_repl.jl"
MCP_PORT=3000

# Kill any process listening on the MCP port
kill_mcp_process() {
    echo "Checking for existing MCP server on port $MCP_PORT..."

    # Find PID listening on port 3000
    local pid=$(netstat -aon | grep ":$MCP_PORT.*LISTENING" | awk '{print $5}' | head -1)

    if [ -n "$pid" ] && [ "$pid" != "0" ]; then
        echo "Found process $pid on port $MCP_PORT, killing it..."
        cmd //c "taskkill /F /PID $pid" 2>/dev/null || true
        sleep 2
        echo "Process killed."
    else
        echo "No existing MCP server found on port $MCP_PORT."
    fi
}

# Find the MCP pane directly, or get/create one to the right of pane 0
get_mcp_pane() {
    # Strategy 1: Look for existing pane with "julia" in title (case insensitive)
    local julia_pane=$(wezterm cli list --format json 2>/dev/null | \
        python -c "import sys, json; panes = json.load(sys.stdin); \
        matches = [p['pane_id'] for p in panes if 'julia' in p.get('title','').lower()]; \
        print(matches[0] if matches else '')" 2>/dev/null)

    if [ -n "$julia_pane" ]; then
        echo "$julia_pane"
        return
    fi

    # Strategy 2: Check if there's a pane to the right of pane 0 (Claude Code is typically pane 0)
    local right_pane=$(wezterm cli get-pane-direction --pane-id 0 Right 2>/dev/null)

    if [ -n "$right_pane" ]; then
        echo "$right_pane"
        return
    fi

    # Strategy 3: Create a new split pane to the right of pane 0
    echo "Creating new split pane to the right of pane 0..." >&2
    wezterm cli split-pane --pane-id 0 --right --percent 45 --cwd "$PROJECT_DIR"
}

# Main logic
main() {
    echo "Finding MCP pane..."
    local mcp_pane=$(get_mcp_pane)
    echo "MCP pane: $mcp_pane"

    # First, try to exit any running Julia REPL gracefully
    echo "Exiting any existing Julia session in pane..."
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste $'\x03'  # Ctrl+C first
    sleep 1
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste $'exit()\r'  # Exit Julia
    sleep 2

    # Now kill any remaining MCP server process by port (belt and suspenders)
    kill_mcp_process

    # Clear the terminal (shell command)
    echo "Clearing terminal..."
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste $'clear\r'
    sleep 1

    # Change to project directory and start Julia
    echo "Starting MCP REPL server..."
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste "cd \"$PROJECT_DIR\""$'\r'
    sleep 1
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste "$JULIA_CMD"$'\r'

    echo "MCP server starting... (wait ~20 seconds for Julia to initialize)"

    # Wait and verify
    sleep 20
    if netstat -aon | grep -q ":$MCP_PORT.*LISTENING"; then
        echo "MCP server is running on port $MCP_PORT"
    else
        echo "Warning: MCP server may not have started yet. Check the pane."
    fi
}

main "$@"
