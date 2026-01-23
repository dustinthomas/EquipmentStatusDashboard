# SearchLight Initializer
# Automatically connects to database when application loads

using Logging

# Include database configuration
include(joinpath(@__DIR__, "..", "database.jl"))

@info "Initializing SearchLight..."

# Connect to database
if connect_database()
    @info "SearchLight initialized successfully"

    # Run pending migrations in production mode
    if get(ENV, "GENIE_ENV", "dev") == "prod"
        @info "Running database migrations..."
        try
            SearchLight.Migrations.up()
            @info "Migrations completed"
        catch e
            @warn "Migration error (may already be up to date)" exception=e
        end
    end
else
    @error "Failed to initialize SearchLight - database connection failed"
end
