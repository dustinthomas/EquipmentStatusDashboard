#!/bin/bash
# Restart MCP REPL server in WezTerm pane to the right of Claude Code
# Usage: ./scripts/restart_mcp.sh [--force]
#
# Options:
#   --force    Restart the MCP server even if it's already running
#
# Exit codes:
#   0 - Success (server started or already running)
#   1 - Error
#   2 - Server already running (use --force to restart)

set -e

PROJECT_DIR="C:/Git/Projects/EqupimentStatusDashboard"
JULIA_CMD="julia --project=. -i scripts/start_mcp_repl.jl"
MCP_PORT=3000
FORCE_RESTART=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_RESTART=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if MCP server is already running
is_mcp_running() {
    netstat -aon 2>/dev/null | grep -q ":$MCP_PORT.*LISTENING"
}

# Get PID of process on MCP port
get_mcp_pid() {
    netstat -aon 2>/dev/null | grep ":$MCP_PORT.*LISTENING" | awk '{print $5}' | head -1
}

# Kill any process listening on the MCP port
kill_mcp_process() {
    local pid=$(get_mcp_pid)

    if [ -n "$pid" ] && [ "$pid" != "0" ]; then
        echo "Killing MCP server process $pid..."
        cmd //c "taskkill /F /PID $pid" 2>/dev/null || true
        sleep 2
        echo "Process killed."
        return 0
    fi
    return 1
}

# Get the current pane ID (where this script is running)
get_current_pane() {
    # WezTerm sets WEZTERM_PANE environment variable
    if [ -n "$WEZTERM_PANE" ]; then
        echo "$WEZTERM_PANE"
        return
    fi

    # Fallback: try to find pane by looking at active pane
    local active_pane=$(wezterm cli list --format json 2>/dev/null | \
        python -c "import sys, json; panes = json.load(sys.stdin); \
        active = [p['pane_id'] for p in panes if p.get('is_active', False)]; \
        print(active[0] if active else '0')" 2>/dev/null)

    echo "${active_pane:-0}"
}

# Find or create pane to the right of the current pane
get_or_create_right_pane() {
    local current_pane=$1

    # Strategy 1: Look for existing pane with "julia" or "mcp" in title
    local julia_pane=$(wezterm cli list --format json 2>/dev/null | \
        python -c "import sys, json; panes = json.load(sys.stdin); \
        matches = [p['pane_id'] for p in panes if 'julia' in p.get('title','').lower() or 'mcp' in p.get('title','').lower()]; \
        print(matches[0] if matches else '')" 2>/dev/null)

    if [ -n "$julia_pane" ]; then
        echo "$julia_pane"
        return 0  # Pane exists
    fi

    # Strategy 2: Check if there's a pane to the right of current pane
    local right_pane=$(wezterm cli get-pane-direction --pane-id "$current_pane" Right 2>/dev/null)

    if [ -n "$right_pane" ]; then
        echo "$right_pane"
        return 0  # Pane exists
    fi

    # Strategy 3: Create a new split pane to the right
    echo "Creating new pane to the right of pane $current_pane..." >&2
    local new_pane=$(wezterm cli split-pane --pane-id "$current_pane" --right --percent 40 --cwd "$PROJECT_DIR" 2>/dev/null)

    if [ -n "$new_pane" ]; then
        echo "$new_pane"
        return 1  # Pane was created
    fi

    echo "Failed to create pane" >&2
    exit 1
}

# Start MCP server in the specified pane
start_mcp_in_pane() {
    local pane_id=$1

    # Clear the terminal
    wezterm cli send-text --pane-id "$pane_id" --no-paste $'clear\r'
    sleep 1

    # Change to project directory and start Julia
    echo "Starting MCP REPL server in pane $pane_id..."
    wezterm cli send-text --pane-id "$pane_id" --no-paste "cd \"$PROJECT_DIR\""$'\r'
    sleep 1
    wezterm cli send-text --pane-id "$pane_id" --no-paste "$JULIA_CMD"$'\r'

    echo "MCP server starting... (wait ~20 seconds for Julia to initialize)"

    # Wait and verify
    sleep 20
    if is_mcp_running; then
        echo "SUCCESS: MCP server is running on port $MCP_PORT"
        return 0
    else
        echo "WARNING: MCP server may not have started yet. Check pane $pane_id."
        return 1
    fi
}

# Stop existing Julia session in pane
stop_julia_in_pane() {
    local pane_id=$1

    echo "Stopping existing Julia session in pane $pane_id..."
    wezterm cli send-text --pane-id "$pane_id" --no-paste $'\x03'  # Ctrl+C
    sleep 1
    wezterm cli send-text --pane-id "$pane_id" --no-paste $'exit()\r'
    sleep 2
}

# Main logic
main() {
    echo "=== MCP REPL Server Manager ==="
    echo ""

    # Step 1: Detect current pane
    local current_pane=$(get_current_pane)
    echo "Current Claude pane: $current_pane"

    # Step 2: Check if MCP server is already running
    if is_mcp_running; then
        local pid=$(get_mcp_pid)
        echo ""
        echo "MCP server is ALREADY RUNNING on port $MCP_PORT (PID: $pid)"

        if [ "$FORCE_RESTART" = true ]; then
            echo "Force restart requested..."
        else
            echo ""
            echo "ALREADY_RUNNING"
            echo "Use --force to restart, or the server is ready to use."
            exit 2
        fi
    fi

    # Step 3: Find or create pane to the right
    echo ""
    echo "Looking for MCP pane..."
    local mcp_pane
    local pane_existed=true

    mcp_pane=$(get_or_create_right_pane "$current_pane")
    pane_existed=$?

    echo "MCP pane: $mcp_pane"

    # Step 4: If force restart or server not running, start it
    if [ "$FORCE_RESTART" = true ] || ! is_mcp_running; then
        # Stop existing session if pane existed
        if [ $pane_existed -eq 0 ]; then
            stop_julia_in_pane "$mcp_pane"
            kill_mcp_process || true
        fi

        # Start fresh
        start_mcp_in_pane "$mcp_pane"
    fi
}

main "$@"
