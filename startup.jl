# Docker startup script for QCI Equipment Status Dashboard
#
# Note: Julia 1.12 world age warnings appear during startup. These are harmless
# in production - they only affect Revise.jl hot-reloading (not used in Docker).
# The warnings will be fixed in a future Julia release.

include("src/App.jl")
using .App
using SearchLight
using Genie

# Initialize database connection first
App.load_app()

# Run migrations on startup (idempotent - safe to run multiple times)
@info "Running database migrations..."
try
    # Initialize migration tracking table if it doesn't exist
    SearchLight.Migration.init()
catch e
    # Table may already exist, which is fine
    if !occursin("already exists", lowercase(string(e)))
        @warn "Migration init warning" exception=e
    end
end

try
    # Run all pending migrations (all_up!! runs all migrations that are :down)
    SearchLight.Migration.all_up!!()
    @info "Migrations completed successfully"
catch e
    error_str = lowercase(string(e))
    if occursin("already exists", error_str) || occursin("duplicate", error_str)
        @info "Migrations already applied"
    else
        @error "Migration failed" exception=(e, catch_backtrace())
        rethrow(e)
    end
end

# Seed admin user if no users exist
try
    users = SearchLight.all(App.User)
    if isempty(users)
        @info "No users found, creating default admin user..."
        admin = App.User(
            username = "admin",
            password_hash = App.hash_password("admin"),
            name = "Administrator",
            role = "admin",
            is_active = true
        )
        SearchLight.save!(admin)
        @info "Default admin user created (username: admin, password: admin)"
        @warn "SECURITY: Change the default admin password immediately!"
    end
catch e
    @error "Failed to check/create admin user" exception=(e, catch_backtrace())
end

# Start the server
# Note: Can't use invokelatest with kwargs easily, so call up() directly
# The world age warning for load_app() is harmless
port = parse(Int, ENV["PORT"])
@info "Starting server on port $port"
Genie.up(port, "0.0.0.0")

# Keep the process alive (Genie.up runs in async mode by default)
wait()
