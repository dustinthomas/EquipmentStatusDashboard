# SearchLight Database Configuration
# Configures SQLite database connection using SearchLight's standard YAML-based config
# with support for DATABASE_PATH environment variable override

using SearchLight
using SearchLightSQLite
using Logging

"""
    connect_database()

Establishes connection to the SQLite database using SearchLight.
Loads configuration from db/connection.yml and allows DATABASE_PATH env var to override.
Returns true if connection successful, false otherwise.
"""
function connect_database()
    # Load SearchLight configuration from YAML file
    config_file = joinpath(@__DIR__, "..", "db", "connection.yml")

    @info "Loading database configuration from: $config_file"

    try
        # Load configuration
        db_settings = SearchLight.Configuration.load(config_file; context = @__MODULE__)

        # Allow DATABASE_PATH env var to override the database path
        if haskey(ENV, "DATABASE_PATH") && !isempty(ENV["DATABASE_PATH"])
            db_settings["database"] = ENV["DATABASE_PATH"]
            @info "Database path overridden by DATABASE_PATH env var: $(db_settings["database"])"
        end

        # Ensure parent directory exists for the database file
        db_path = db_settings["database"]
        db_dir = dirname(db_path)
        if !isempty(db_dir) && !isdir(db_dir)
            mkpath(db_dir)
            @info "Created database directory: $db_dir"
        end

        # Update the config with the potentially modified path
        SearchLight.config.db_config_settings = db_settings

        @info "Connecting to database: $(db_settings["database"])"

        # Establish the actual database connection
        SearchLight.connect()

        @info "Database connection established successfully"
        return true
    catch e
        @error "Failed to connect to database" exception=(e, catch_backtrace())
        return false
    end
end

"""
    disconnect_database()

Closes the database connection.
"""
function disconnect_database()
    try
        SearchLight.disconnect()
        @info "Database connection closed"
    catch e
        @warn "Error closing database connection" exception=e
    end
end

"""
    is_connected()

Check if database is connected by attempting a simple query.
"""
function is_connected()
    try
        SearchLight.query("SELECT 1")
        return true
    catch
        return false
    end
end

"""
    database_path()

Returns the current database path from configuration.
"""
function database_path()
    if haskey(ENV, "DATABASE_PATH") && !isempty(ENV["DATABASE_PATH"])
        return ENV["DATABASE_PATH"]
    end

    env = get(ENV, "GENIE_ENV", get(ENV, "SEARCHLIGHT_ENV", "dev"))
    if env == "prod"
        return "/data/qci_status.sqlite"
    elseif env == "test"
        return joinpath("db", "qci_status_test.sqlite")
    else
        return joinpath("db", "qci_status_dev.sqlite")
    end
end

"""
    cleanup_test_database(db_path::String)

Safely clean up a test database file, handling Windows-specific SQLite file locking.
Disconnects the database, forces garbage collection, and retries deletion on Windows.
"""
function cleanup_test_database(db_path::String)
    # Disconnect first
    disconnect_database()

    # Force garbage collection to release any lingering file handles
    GC.gc()

    # On Windows, SQLite may hold file locks briefly after disconnect
    # Retry deletion with small delays
    if Sys.iswindows() && isfile(db_path)
        max_retries = 5
        for attempt in 1:max_retries
            try
                rm(db_path; force=true)
                return  # Success
            catch e
                if attempt < max_retries
                    sleep(0.1 * attempt)  # Increasing delay
                    GC.gc()  # Try GC again
                else
                    @warn "Could not delete test database after $max_retries attempts: $db_path" exception=e
                end
            end
        end
    else
        # Non-Windows: simple deletion
        isfile(db_path) && rm(db_path; force=true)
    end
end
