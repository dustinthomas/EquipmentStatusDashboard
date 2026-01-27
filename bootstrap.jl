# Bootstrap file for Genie.loadapp()
# This is the entry point that Genie looks for when loading the application

# Ensure we're using the project environment
using Pkg
if !isfile("Project.toml")
    error("bootstrap.jl must be run from the project root directory")
end

# Load the main application module
include("src/App.jl")
using .App

# Export commonly used functions for REPL convenience
export up, down
