# Authentication Initializer
# Configures authentication with the User model and session handling
# This file is loaded when the application starts

using Logging
using GenieSession
using GenieSessionFileSession
using SearchLight

# Include the authentication core module
include(joinpath(@__DIR__, "..", "..", "src", "lib", "AuthCore.jl"))
using .AuthCore

# Include the User model
include(joinpath(@__DIR__, "..", "..", "src", "models", "User.jl"))
using .Users

@info "Initializing authentication system..."

# Initialize session system - this registers hooks for session handling
# GenieSessionFileSession provides file-based session storage
GenieSession.__init__()

# Session timeout in seconds (8 hours = 28800 seconds)
const SESSION_TIMEOUT_SECONDS = parse(Int, get(ENV, "SESSION_TIMEOUT", "28800"))

# Authentication constants
const AUTH_USER_ID_KEY = :__auth_user_id
const AUTH_USER_KEY = :__auth_user

# Re-export core functions
export hash_password, verify_password

"""
    authenticate_user(username::String, password::String) -> Union{User, Nothing}

Authenticate a user by username and password.
Returns the User if credentials are valid, nothing otherwise.
Does NOT update session - use login! for that.
"""
function authenticate_user(username::String, password::String)::Union{User, Nothing}
    # Find user by username
    user = Users.find_by_username(username)

    if user === nothing
        @debug "Authentication failed: user not found" username=username
        return nothing
    end

    # Check if user is active
    if !user.is_active
        @debug "Authentication failed: user is inactive" username=username
        return nothing
    end

    # Verify password
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
Updates the user's last_login_at timestamp.
Returns true on success.
"""
function login!(user::User, session::GenieSession.Session)::Bool
    try
        # Store user ID in session
        GenieSession.set!(session, AUTH_USER_ID_KEY, user.id.value)

        # Update last login timestamp
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

Log out the current user by clearing their session.
Returns true on success.
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
Returns nothing if not authenticated.
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
Returns nothing if not authenticated or user not found.
Caches the user in the session for subsequent calls.
"""
function current_user(session::GenieSession.Session)::Union{User, Nothing}
    # Check if we have a cached user
    if GenieSession.isset(session, AUTH_USER_KEY)
        return GenieSession.get(session, AUTH_USER_KEY)
    end

    # Get user ID from session
    user_id = current_user_id(session)
    if user_id === nothing
        return nothing
    end

    # Load user from database
    try
        user = SearchLight.findone(User; id = user_id)
        if user !== nothing && user.is_active
            # Cache user in session
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
Returns false if not authenticated.
"""
function is_admin(session::GenieSession.Session)::Bool
    user = current_user(session)
    if user === nothing
        return false
    end
    return user.role == "admin"
end

# Export functions for use in controllers
export authenticate_user
export login!, logout!, current_user_id, current_user
export is_authenticated, is_admin
export AUTH_USER_ID_KEY, AUTH_USER_KEY, SESSION_TIMEOUT_SECONDS

@info "Authentication system initialized"
