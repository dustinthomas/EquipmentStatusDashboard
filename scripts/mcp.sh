#!/bin/bash
# MCP REPL Pane Manager for WezTerm
# Cross-platform: works on Linux, macOS, and Windows (Git Bash/MSYS2)
#
# Usage: ./scripts/mcp.sh <command>
#
# Commands:
#   status   - Check if pane exists and if MCP REPL is running
#   open     - Open a vertical pane (if one doesn't exist)
#   start    - Start the MCP REPL (opens pane if needed)
#   stop     - Stop the MCP REPL session
#   restart  - Restart the MCP REPL
#   close    - Close the MCP pane entirely
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

JULIA_CMD="julia --project=. -i scripts/start_mcp_repl.jl"
MCP_PORT=3000
PANE_WIDTH_PERCENT=40

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

# Check for required dependencies
check_dependencies() {
    local missing=()

    if ! command -v wezterm &> /dev/null; then
        missing+=("wezterm")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Installation instructions:"
        for dep in "${missing[@]}"; do
            case "$dep" in
                jq)
                    case "$OS_TYPE" in
                        windows)
                            echo "  jq: winget install jqlang.jq"
                            echo "      or: pacman -S jq (MSYS2)"
                            ;;
                        macos)
                            echo "  jq: brew install jq"
                            ;;
                        linux)
                            echo "  jq: sudo apt install jq (Debian/Ubuntu)"
                            echo "      or: sudo dnf install jq (Fedora)"
                            ;;
                    esac
                    ;;
                wezterm)
                    echo "  wezterm: https://wezfurlong.org/wezterm/installation.html"
                    ;;
            esac
        done
        exit 1
    fi
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

# Get the current pane ID (where Claude Code is running)
get_current_pane() {
    # WezTerm sets WEZTERM_PANE environment variable
    if [ -n "$WEZTERM_PANE" ]; then
        echo "$WEZTERM_PANE"
        return
    fi

    # Fallback: find the active pane with "Claude" in the title
    local claude_pane
    claude_pane=$(wezterm cli list --format json 2>/dev/null | \
        jq -r '[.[] | select(.is_active == true and (.title | test("Claude"; "i")))] | .[0].pane_id // empty' 2>/dev/null)

    if [ -n "$claude_pane" ]; then
        echo "$claude_pane"
        return
    fi

    # Last fallback: first active pane
    local active_pane
    active_pane=$(wezterm cli list --format json 2>/dev/null | \
        jq -r '[.[] | select(.is_active == true)] | .[0].pane_id // "0"' 2>/dev/null)

    echo "${active_pane:-0}"
}

# Get the tab ID for a given pane
get_tab_for_pane() {
    local pane_id=$1
    wezterm cli list --format json 2>/dev/null | \
        jq -r ".[] | select(.pane_id == $pane_id) | .tab_id" 2>/dev/null
}

# Find existing MCP pane (pane to the right of current, or with julia/mcp in title)
find_mcp_pane() {
    local current_pane=$1
    local current_tab
    current_tab=$(get_tab_for_pane "$current_pane")

    # Strategy 1: Look for pane with "julia" or "mcp" in title within same tab
    local julia_pane
    julia_pane=$(wezterm cli list --format json 2>/dev/null | \
        jq -r "[.[] | select(.tab_id == $current_tab and .pane_id != $current_pane and ((.title | test(\"julia|mcp\"; \"i\")) or (.title | test(\"start_mcp\"; \"i\"))))] | .[0].pane_id // empty" 2>/dev/null)

    if [ -n "$julia_pane" ]; then
        echo "$julia_pane"
        return 0
    fi

    # Strategy 2: Look for pane to the right
    local right_pane
    right_pane=$(wezterm cli get-pane-direction --pane-id "$current_pane" Right 2>/dev/null)

    if [ -n "$right_pane" ]; then
        echo "$right_pane"
        return 0
    fi

    # No pane found
    return 1
}

# Create a new pane to the right
create_right_pane() {
    local current_pane=$1

    log_info "Creating new pane to the right..."
    local new_pane
    new_pane=$(wezterm cli split-pane --pane-id "$current_pane" --right --percent "$PANE_WIDTH_PERCENT" --cwd "$PROJECT_DIR" 2>/dev/null)

    if [ -n "$new_pane" ]; then
        echo "$new_pane"
        # Activate the original Claude pane
        sleep 0.5
        wezterm cli activate-pane --pane-id "$current_pane" 2>/dev/null || true
        return 0
    fi

    log_error "Failed to create pane"
    return 1
}

# Check if a pane appears to have Julia/MCP running (by checking pane text)
pane_has_julia() {
    local pane_id=$1
    local pane_text
    pane_text=$(wezterm cli get-text --pane-id "$pane_id" 2>/dev/null | head -50)

    if echo "$pane_text" | grep -qiE "(julia>|MCP REPL|MCPRepl|localhost:$MCP_PORT)"; then
        return 0
    fi
    return 1
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

# ============================================================================
# Command Implementations
# ============================================================================

cmd_status() {
    echo "=== MCP REPL Status ==="
    echo ""
    echo "Platform: $OS_TYPE"
    echo "Project:  $PROJECT_DIR"
    echo ""

    local current_pane
    current_pane=$(get_current_pane)
    local current_tab
    current_tab=$(get_tab_for_pane "$current_pane")

    echo "Current pane: $current_pane (tab: $current_tab)"

    # Check for MCP pane
    local mcp_pane
    if mcp_pane=$(find_mcp_pane "$current_pane"); then
        log_success "MCP pane found: $mcp_pane"

        # Check if Julia is running in that pane
        if pane_has_julia "$mcp_pane"; then
            log_success "Julia session detected in pane"
        else
            log_warn "No Julia session detected in pane"
        fi
    else
        log_warn "No MCP pane found (no split pane to the right)"
    fi

    # Check if MCP server is listening
    if is_mcp_running; then
        local pid
        pid=$(get_mcp_pid)
        log_success "MCP server is RUNNING on port $MCP_PORT (PID: $pid)"
    else
        log_warn "MCP server is NOT running on port $MCP_PORT"
    fi
}

cmd_open() {
    local current_pane
    current_pane=$(get_current_pane)

    log_info "Checking for existing MCP pane..."

    local mcp_pane
    if mcp_pane=$(find_mcp_pane "$current_pane"); then
        log_success "Pane already exists: $mcp_pane"
        echo "PANE_ID=$mcp_pane"
        exit 2
    fi

    mcp_pane=$(create_right_pane "$current_pane")
    log_success "Created new pane: $mcp_pane"
    echo "PANE_ID=$mcp_pane"
}

cmd_start() {
    local current_pane
    current_pane=$(get_current_pane)

    # Check if already running
    if is_mcp_running; then
        local pid
        pid=$(get_mcp_pid)
        log_warn "MCP server is already running on port $MCP_PORT (PID: $pid)"
        echo "Use 'mcp.sh restart' to restart the server."
        exit 2
    fi

    # Find or create pane
    local mcp_pane
    if ! mcp_pane=$(find_mcp_pane "$current_pane"); then
        mcp_pane=$(create_right_pane "$current_pane")
    fi

    log_info "Starting MCP REPL in pane $mcp_pane..."

    # Clear and start Julia
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste $'clear\r'
    sleep 0.5
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste "cd \"$PROJECT_DIR\""$'\r'
    sleep 0.5
    wezterm cli send-text --pane-id "$mcp_pane" --no-paste "$JULIA_CMD"$'\r'

    log_info "Julia starting... (takes ~15-20 seconds)"

    # Wait and verify
    local attempts=0
    local max_attempts=30

    while [ $attempts -lt $max_attempts ]; do
        sleep 1
        if is_mcp_running; then
            log_success "MCP server is running on port $MCP_PORT"
            return 0
        fi
        attempts=$((attempts + 1))
        if [ $((attempts % 5)) -eq 0 ]; then
            echo "  Still waiting... ($attempts seconds)"
        fi
    done

    log_warn "Timeout waiting for MCP server. Check pane $mcp_pane for errors."
    return 1
}

cmd_stop() {
    local current_pane
    current_pane=$(get_current_pane)

    if ! is_mcp_running; then
        log_warn "MCP server is not running"
        exit 2
    fi

    # Find the MCP pane
    local mcp_pane
    if mcp_pane=$(find_mcp_pane "$current_pane"); then
        log_info "Stopping Julia session in pane $mcp_pane..."

        # Send Ctrl+C then exit()
        wezterm cli send-text --pane-id "$mcp_pane" --no-paste $'\x03'
        sleep 1
        wezterm cli send-text --pane-id "$mcp_pane" --no-paste $'exit()\r'
        sleep 2
    fi

    # Force kill if still running
    if is_mcp_running; then
        local pid
        pid=$(get_mcp_pid)
        log_info "Force killing process $pid..."
        kill_process "$pid"
        sleep 1
    fi

    if ! is_mcp_running; then
        log_success "MCP server stopped"
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
    fi

    # Start fresh
    cmd_start
}

cmd_close() {
    local current_pane
    current_pane=$(get_current_pane)

    # Find the MCP pane
    local mcp_pane
    if ! mcp_pane=$(find_mcp_pane "$current_pane"); then
        log_warn "No MCP pane found to close"
        exit 2
    fi

    # Stop Julia if running
    if is_mcp_running; then
        log_info "Stopping MCP server first..."
        cmd_stop
    fi

    # Close the pane
    log_info "Closing pane $mcp_pane..."
    wezterm cli kill-pane --pane-id "$mcp_pane" 2>/dev/null

    log_success "Pane closed"
}

# ============================================================================
# Main
# ============================================================================

show_usage() {
    echo "MCP REPL Pane Manager for WezTerm (Cross-platform)"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  status   Check if pane exists and if MCP REPL is running"
    echo "  open     Open a vertical pane (if one doesn't exist)"
    echo "  start    Start the MCP REPL (opens pane if needed)"
    echo "  stop     Stop the MCP REPL session"
    echo "  restart  Restart the MCP REPL"
    echo "  close    Close the MCP pane entirely"
    echo ""
    echo "Detected platform: $OS_TYPE"
}

main() {
    local command="${1:-}"

    # Check dependencies for all commands except help
    if [ -n "$command" ] && [ "$command" != "-h" ] && [ "$command" != "--help" ] && [ "$command" != "help" ]; then
        check_dependencies
    fi

    if [ -z "$command" ]; then
        show_usage
        exit 1
    fi

    case "$command" in
        status)
            cmd_status
            ;;
        open)
            cmd_open
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
        close)
            cmd_close
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
