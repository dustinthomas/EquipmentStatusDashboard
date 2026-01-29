# QCI Equipment Status Dashboard - Main Application Module
# This module handles proper loading order and namespace isolation

module App

using Genie
using Logging
using SearchLight
using SearchLightSQLite
using Dates

# Re-export Genie server controls for convenience
export up, down

# ============================================================================
# Configuration
# ============================================================================

const LOG_LEVEL = get(ENV, "LOG_LEVEL", "info")
const PORT = parse(Int, get(ENV, "PORT", "8000"))
const DATABASE_PATH = get(ENV, "DATABASE_PATH", "db/qci_status.sqlite")
const GENIE_ENV = get(ENV, "GENIE_ENV", "dev")

# Configure logging
const LOG_LEVEL_MAP = Dict(
    "debug" => Logging.Debug,
    "info" => Logging.Info,
    "warn" => Logging.Warn,
    "error" => Logging.Error
)

function configure_logging()
    global_logger(ConsoleLogger(stderr, get(LOG_LEVEL_MAP, lowercase(LOG_LEVEL), Logging.Info)))
end

# ============================================================================
# Models - loaded as submodules to avoid namespace pollution
# ============================================================================

# Include models within the App module namespace
include("models/User.jl")
include("models/Tool.jl")
include("models/StatusEvent.jl")

# Re-export model types for convenience
using .Users: User
using .Tools: Tool
using .StatusEvents: StatusEvent
export User, Tool, StatusEvent, Users, Tools, StatusEvents

# ============================================================================
# Library modules
# ============================================================================

include("lib/AuthCore.jl")
using .AuthCore
export hash_password, verify_password

# ============================================================================
# Database initialization
# ============================================================================

function init_database()
    @info "Initializing database connection..."

    # Determine database path based on environment
    db_path = if GENIE_ENV == "dev"
        "db/qci_status_dev.sqlite"
    elseif GENIE_ENV == "test"
        "db/qci_status_test.sqlite"
    else
        DATABASE_PATH
    end

    # Configure SearchLight
    SearchLight.Configuration.load(joinpath(@__DIR__, "..", "db", "connection.yml"))

    @info "Connecting to database: $db_path"
    SearchLight.connect()
    @info "Database connection established"
end

# ============================================================================
# Authentication system
# ============================================================================

# Session and authentication state
using GenieSession
using GenieSessionFileSession

const SESSION_TIMEOUT_SECONDS = parse(Int, get(ENV, "SESSION_TIMEOUT", "28800"))
const AUTH_USER_ID_KEY = :__auth_user_id
const AUTH_USER_KEY = :__auth_user

# Track whether load_app() has been called
const _app_loaded = Ref(false)

"""
    authenticate_user(username::String, password::String) -> Union{User, Nothing}

Authenticate a user by username and password.
"""
function authenticate_user(username::String, password::String)::Union{User, Nothing}
    user = Users.find_by_username(username)

    if user === nothing
        @debug "Authentication failed: user not found" username=username
        return nothing
    end

    if !user.is_active
        @debug "Authentication failed: user is inactive" username=username
        return nothing
    end

    if !verify_password(password, user.password_hash)
        @debug "Authentication failed: invalid password" username=username
        return nothing
    end

    @info "User authenticated successfully" username=username user_id=user.id.value
    return user
end

"""
    login!(user::User, session::GenieSession.Session) -> Bool

Log in a user by storing their ID in the session.
"""
function login!(user::User, session::GenieSession.Session)::Bool
    try
        GenieSession.set!(session, AUTH_USER_ID_KEY, user.id.value)
        Users.update_last_login!(user)
        @info "User logged in" username=user.username user_id=user.id.value
        return true
    catch e
        @error "Login failed" exception=(e, catch_backtrace())
        return false
    end
end

"""
    logout!(session::GenieSession.Session) -> Bool

Log out the current user.
"""
function logout!(session::GenieSession.Session)::Bool
    try
        GenieSession.unset!(session, AUTH_USER_ID_KEY)
        GenieSession.unset!(session, AUTH_USER_KEY)
        @info "User logged out"
        return true
    catch e
        @error "Logout failed" exception=(e, catch_backtrace())
        return false
    end
end

"""
    current_user_id(session::GenieSession.Session) -> Union{Int, Nothing}

Get the current user's ID from the session.
"""
function current_user_id(session::GenieSession.Session)::Union{Int, Nothing}
    if GenieSession.isset(session, AUTH_USER_ID_KEY)
        return GenieSession.get(session, AUTH_USER_ID_KEY)
    end
    return nothing
end

"""
    current_user(session::GenieSession.Session) -> Union{User, Nothing}

Get the current authenticated user from the session.
"""
function current_user(session::GenieSession.Session)::Union{User, Nothing}
    if GenieSession.isset(session, AUTH_USER_KEY)
        return GenieSession.get(session, AUTH_USER_KEY)
    end

    user_id = current_user_id(session)
    if user_id === nothing
        return nothing
    end

    try
        user = SearchLight.findone(User; id = user_id)
        if user !== nothing && user.is_active
            GenieSession.set!(session, AUTH_USER_KEY, user)
            return user
        end
    catch e
        @warn "Failed to load user from session" user_id=user_id exception=e
    end

    return nothing
end

"""
    is_authenticated(session::GenieSession.Session) -> Bool

Check if the current session has an authenticated user.
"""
function is_authenticated(session::GenieSession.Session)::Bool
    return current_user(session) !== nothing
end

"""
    is_admin(session::GenieSession.Session) -> Bool

Check if the current authenticated user has admin role.
"""
function is_admin(session::GenieSession.Session)::Bool
    user = current_user(session)
    return user !== nothing && user.role == "admin"
end

export authenticate_user, login!, logout!, current_user_id, current_user
export is_authenticated, is_admin
export AUTH_USER_ID_KEY, AUTH_USER_KEY, SESSION_TIMEOUT_SECONDS

# ============================================================================
# Application initialization
# ============================================================================

function __init__()
    @info "Initializing QCI Equipment Status Dashboard"
    @info "Environment: $GENIE_ENV"
    @info "Port: $PORT"

    # Set Genie environment
    ENV["GENIE_ENV"] = GENIE_ENV

    # Configure logging
    configure_logging()

    # Initialize session system
    GenieSession.__init__()
end

"""
    load_app()

Load the full application (database, routes, etc.)
Call this after `using App` to fully initialize.
"""
function load_app()
    if _app_loaded[]
        @debug "Application already loaded, skipping"
        return
    end

    # Initialize database
    init_database()

    # Load routes (this includes controllers)
    include(joinpath(@__DIR__, "..", "config", "routes.jl"))

    _app_loaded[] = true
    @info "Application loaded successfully"
end

"""
    up(port::Int=$PORT; kwargs...)

Start the web server. Automatically calls load_app() if not already called.
"""
function up(port::Int=PORT; kwargs...)
    if !_app_loaded[]
        @info "Auto-loading application (load_app() was not called)"
        load_app()
    end
    @info "Starting server on port $port"
    Genie.up(port; kwargs...)
end

"""
    down(; kwargs...)

Stop the web server.
"""
function down(; kwargs...)
    @info "Stopping server"
    Genie.down(; kwargs...)
end

# ============================================================================
# Auth Helpers and Controllers - included here to ensure proper module scope
# ============================================================================

include("lib/auth_helpers.jl")
include("controllers/AuthController.jl")
include("controllers/DashboardController.jl")
include("controllers/AdminController.jl")

export load_app

end # module App
