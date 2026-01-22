# QCI Equipment Status Dashboard
# Application entry point

using Genie
using Logging

# Configure logging based on environment
const LOG_LEVEL = get(ENV, "LOG_LEVEL", "info")
const log_level_map = Dict(
    "debug" => Logging.Debug,
    "info" => Logging.Info,
    "warn" => Logging.Warn,
    "error" => Logging.Error
)
global_logger(ConsoleLogger(stderr, get(log_level_map, lowercase(LOG_LEVEL), Logging.Info)))

# Environment configuration
const PORT = parse(Int, get(ENV, "PORT", "8000"))
const DATABASE_PATH = get(ENV, "DATABASE_PATH", "db/qci_status.sqlite")
const GENIE_ENV = get(ENV, "GENIE_ENV", "dev")

@info "Starting QCI Equipment Status Dashboard"
@info "Environment: $GENIE_ENV"
@info "Port: $PORT"
@info "Database: $DATABASE_PATH"

# Set Genie environment
ENV["GENIE_ENV"] = GENIE_ENV

# Load environment-specific configuration
const env_file = joinpath(@__DIR__, "config", "env", "$GENIE_ENV.jl")
if isfile(env_file)
    @info "Loading environment config: $env_file"
    include(env_file)
else
    @warn "Environment config not found: $env_file, using defaults"
end

# Load routes
const routes_file = joinpath(@__DIR__, "config", "routes.jl")
if isfile(routes_file)
    @info "Loading routes: $routes_file"
    include(routes_file)
else
    @error "Routes file not found: $routes_file"
end

# Start server
@info "Starting server on port $PORT"
up(PORT; async = false)
