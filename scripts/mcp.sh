#!/bin/bash
# MCP REPL Manager
# Cross-platform: works on Linux, macOS, and Windows (Git Bash/MSYS2)
#
# The MCP REPL runs in a separate terminal window and communicates via HTTP.
# Any Claude session can connect to it as long as it's running on port 3000.
#
# Usage: ./scripts/mcp.sh <command>
#
# Commands:
#   status   - Check if MCP REPL is running
#   start    - Start the MCP REPL in a new terminal window
#   stop     - Stop the MCP REPL
#   restart  - Restart the MCP REPL
#
# Exit codes:
#   0 - Success
#   1 - Error
#   2 - Already in desired state (e.g., REPL already running)

set -e

# ============================================================================
# Platform Detection and Configuration
# ============================================================================

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

OS_TYPE=$(detect_os)

# Auto-detect project directory (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Convert to Windows path if needed (for cmd.exe)
if [ "$OS_TYPE" = "windows" ]; then
    PROJECT_DIR_WIN=$(cygpath -w "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")
fi

JULIA_CMD="julia --project=. -i scripts/start_mcp_repl.jl"
MCP_PORT=3000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if MCP server is listening on the port (cross-platform)
is_mcp_running() {
    case "$OS_TYPE" in
        windows)
            netstat -an 2>/dev/null | grep -qE "[:.]$MCP_PORT[[:space:]].*LISTENING" && return 0
            ;;
        *)
            ss -tlnp 2>/dev/null | grep -q ":$MCP_PORT " && return 0
            ;;
    esac
    return 1
}

# Get PID of process on MCP port (cross-platform)
get_mcp_pid() {
    case "$OS_TYPE" in
        windows)
            # On Windows, netstat -ano shows PID in last column
            netstat -ano 2>/dev/null | grep -E "[:.]$MCP_PORT[[:space:]].*LISTENING" | awk '{print $NF}' | head -1
            ;;
        *)
            ss -tlnp 2>/dev/null | grep ":$MCP_PORT " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | head -1
            ;;
    esac
}

# Kill process by PID (cross-platform)
kill_process() {
    local pid=$1
    case "$OS_TYPE" in
        windows)
            taskkill //F //PID "$pid" 2>/dev/null || true
            ;;
        *)
            kill -9 "$pid" 2>/dev/null || true
            ;;
    esac
}

# Open a new terminal window with the given command
open_terminal() {
    local title="$1"
    local working_dir="$2"
    local command="$3"

    case "$OS_TYPE" in
        windows)
            # Use PowerShell to start Julia in a new window
            powershell.exe -NoProfile -Command "Start-Process -FilePath 'julia' -ArgumentList '--project=.', '-i', 'scripts/start_mcp_repl.jl' -WorkingDirectory '$PROJECT_DIR_WIN'"
            ;;
        macos)
            if command -v wezterm &> /dev/null; then
                wezterm start --cwd "$working_dir" -- bash -c "$command; exec bash"
            else
                osascript -e "tell app \"Terminal\" to do script \"cd '$working_dir' && $command\""
            fi
            ;;
        linux)
            if command -v wezterm &> /dev/null; then
                wezterm start --cwd "$working_dir" -- bash -c "$command; exec bash"
            elif command -v gnome-terminal &> /dev/null; then
                gnome-terminal --working-directory="$working_dir" -- bash -c "$command; exec bash"
            elif command -v xterm &> /dev/null; then
                xterm -e "cd '$working_dir' && $command; exec bash" &
            else
                log_error "No supported terminal emulator found"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported platform: $OS_TYPE"
            return 1
            ;;
    esac
}

# ============================================================================
# Command Implementations
# ============================================================================

cmd_status() {
    echo "=== MCP REPL Status ==="
    echo ""
    echo "Platform: $OS_TYPE"
    echo "Project:  $PROJECT_DIR"
    echo "Port:     $MCP_PORT"
    echo ""

    if is_mcp_running; then
        local pid
        pid=$(get_mcp_pid)
        log_success "MCP server is RUNNING on port $MCP_PORT (PID: $pid)"
        echo ""
        echo "Any Claude session can connect to this REPL via MCP tools."
    else
        log_warn "MCP server is NOT running on port $MCP_PORT"
        echo ""
        echo "Run './scripts/mcp.sh start' to start the REPL in a new terminal."
    fi
}

cmd_start() {
    # Check if already running
    if is_mcp_running; then
        local pid
        pid=$(get_mcp_pid)
        log_warn "MCP server is already running on port $MCP_PORT (PID: $pid)"
        echo "Use './scripts/mcp.sh restart' to restart the server."
        exit 2
    fi

    log_info "Starting MCP REPL in a new terminal window..."

    # Try to open terminal
    local open_success=true
    open_terminal "Julia MCP REPL" "$PROJECT_DIR" "$JULIA_CMD" || open_success=false

    if [ "$open_success" = "false" ]; then
        log_warn "Could not auto-start terminal. Please start manually:"
        echo ""
        echo "  Open a new terminal and run:"
        echo "    cd $PROJECT_DIR"
        echo "    $JULIA_CMD"
        echo ""
        return 1
    fi

    log_info "Julia starting... (takes ~15-20 seconds)"

    # Wait and verify
    local attempts=0
    local max_attempts=30

    while [ $attempts -lt $max_attempts ]; do
        sleep 1
        if is_mcp_running; then
            log_success "MCP server is running on port $MCP_PORT"
            echo ""
            echo "The REPL is ready. Any Claude session can now use MCP tools."
            return 0
        fi
        attempts=$((attempts + 1))
        if [ $((attempts % 5)) -eq 0 ]; then
            echo "  Still waiting... ($attempts seconds)"
        fi
    done

    log_warn "Auto-start timed out. Please start manually in a new terminal:"
    echo ""
    echo "    cd $PROJECT_DIR_WIN"
    echo "    $JULIA_CMD"
    echo ""
    echo "Then run './scripts/mcp.sh status' to verify."
    return 1
}

cmd_stop() {
    if ! is_mcp_running; then
        log_warn "MCP server is not running"
        exit 2
    fi

    local pid
    pid=$(get_mcp_pid)
    log_info "Stopping MCP server (PID: $pid)..."

    kill_process "$pid"
    sleep 2

    if ! is_mcp_running; then
        log_success "MCP server stopped"
        echo ""
        echo "Note: The terminal window may still be open. You can close it manually."
    else
        log_error "Failed to stop MCP server"
        return 1
    fi
}

cmd_restart() {
    log_info "Restarting MCP REPL..."

    # Stop if running
    if is_mcp_running; then
        cmd_stop
        sleep 1
    fi

    # Start fresh
    cmd_start
}

# ============================================================================
# Main
# ============================================================================

show_usage() {
    echo "MCP REPL Manager (Cross-platform)"
    echo ""
    echo "The MCP REPL runs in a separate terminal and communicates via HTTP."
    echo "Any Claude session can connect to it on port $MCP_PORT."
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  status   Check if MCP REPL is running"
    echo "  start    Start the MCP REPL in a new terminal window"
    echo "  stop     Stop the MCP REPL"
    echo "  restart  Restart the MCP REPL"
    echo ""
    echo "Detected platform: $OS_TYPE"
}

main() {
    local command="${1:-}"

    if [ -z "$command" ]; then
        show_usage
        exit 1
    fi

    case "$command" in
        status)
            cmd_status
            ;;
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        restart)
            cmd_restart
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
