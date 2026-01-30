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

# Run migrations on startup
# NOTE: SearchLight's automatic migration discovery (all_up!!) doesn't work reliably,
# so we manually include and run migration files when tables don't exist.
@info "Running database migrations..."

# Initialize migration tracking table
try
    SearchLight.Migration.init()
catch e
    if !occursin("already exists", lowercase(string(e)))
        @warn "Migration init warning" exception=e
    end
end

# Check which migrations have been applied
applied_migrations = try
    result = SearchLight.query("SELECT version FROM schema_migrations")
    Set(result[!, :version])
catch
    Set{String}()
end

# Define migrations to run (in order)
migrations = [
    ("20260122195602", "db/migrations/20260122195602_create_users.jl", :CreateUsers),
    ("20260122201046", "db/migrations/20260122201046_create_tools.jl", :CreateTools),
    ("20260122203749", "db/migrations/20260122203749_create_status_events.jl", :CreateStatusEvents),
]

for (version, file, mod_name) in migrations
    if version in applied_migrations
        @info "Migration $version already applied"
        continue
    end

    @info "Running migration $version..."
    try
        include(file)
        # Get the module and call up()
        mod = getfield(Main, mod_name)
        mod.up()
        # Record the migration
        SearchLight.query("INSERT INTO schema_migrations (version) VALUES ('$version')")
        @info "Migration $version completed"
    catch e
        error_str = lowercase(string(e))
        if occursin("already exists", error_str) || occursin("duplicate", error_str)
            @info "Migration $version: tables already exist"
            # Still record it as applied
            try
                SearchLight.query("INSERT INTO schema_migrations (version) VALUES ('$version')")
            catch; end
        else
            @error "Migration $version failed" exception=(e, catch_backtrace())
            rethrow(e)
        end
    end
end

@info "Migrations completed successfully"

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
