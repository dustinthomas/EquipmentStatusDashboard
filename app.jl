# QCI Equipment Status Dashboard
# Legacy entry point - redirects to new App module structure
#
# RECOMMENDED: Use Genie.loadapp() instead:
#   using Genie
#   Genie.loadapp()
#   App.load_app()
#   up()
#
# This file provides backwards compatibility for direct include("app.jl")

@warn "app.jl is deprecated. Use Genie.loadapp() instead for proper hot-reloading support."

# Load the new App module
include("bootstrap.jl")

# Load routes and start server
App.load_app()
App.up(; async = false)
