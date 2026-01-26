#!/usr/bin/env julia

# Start the MCPRepl server for Claude Code
# Run with: julia --project=. -i scripts/start_mcp_repl.jl

using MCPRepl

# Work around parser issue with function names ending in !
start_fn = getfield(MCPRepl, Symbol("start!"))
start_fn(verbose=true)

println("\n📡 MCP REPL server is running on http://localhost:3000")
println("   Keep this terminal open for Claude Code to connect.")
println("   Press Ctrl+C to stop the server.\n")
