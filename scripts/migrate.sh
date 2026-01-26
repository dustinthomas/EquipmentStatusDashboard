#!/bin/bash
# Run database migrations

set -e

cd "$(dirname "$0")/.."

echo "Running database migrations..."
julia --project=. -e '
using SearchLight
using SearchLightSQLite

# Load database configuration
config_file = joinpath(@__DIR__, "db", "connection.yml")
SearchLight.Configuration.load(config_file)
SearchLight.connect()

migrations_path = joinpath(pwd(), "db", "migrations")

# Migration files in order
migrations = [
    ("20260122195602_create_users.jl", :CreateUsers),
    ("20260122201046_create_tools.jl", :CreateTools),
    ("20260122203749_create_status_events.jl", :CreateStatusEvents)
]

for (file, mod_name) in migrations
    migration_file = joinpath(migrations_path, file)
    version = split(file, "_")[1]

    # Check if already run
    try
        result = SearchLight.query("SELECT version FROM schema_migrations WHERE version = '\''$version'\''")
        if !isempty(result)
            println("Skipping $file (already run)")
            continue
        end
    catch
        # schema_migrations table might not exist yet
    end

    println("Running migration: $file")
    include(migration_file)
    mod = getfield(Main, mod_name)
    mod.up()

    # Record migration as run
    SearchLight.query("INSERT INTO schema_migrations (version) VALUES ('\''$version'\'')")
    println("  ✓ Completed")
end

println("\nAll migrations completed successfully.")
'
echo "Done."
