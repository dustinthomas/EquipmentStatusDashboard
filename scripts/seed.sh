#!/bin/bash
# Seed the database with initial data (admin user, sample tools)

set -e

cd "$(dirname "$0")/.."

echo "Seeding database..."
julia --project=. -e '
using SearchLight
using SearchLightSQLite

# Load database configuration
config_file = joinpath(@__DIR__, "db", "connection.yml")
SearchLight.Configuration.load(config_file)
SearchLight.connect()

# Load models and seed data
include(joinpath(@__DIR__, "src", "models", "User.jl"))
include(joinpath(@__DIR__, "db", "seeds", "seed_data.jl"))

# Run seeds
seed!()

println("\nSeeding completed successfully.")
'
echo "Done."
