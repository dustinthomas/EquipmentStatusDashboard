# AuthController
# Handles JSON API endpoints for authentication

module AuthController

using Genie
using Genie.Renderer.Json: json
using Genie.Requests: jsonpayload
using GenieSession
using Logging

# Import authentication functions from parent App module
import ..App: authenticate_user, login!, logout!, current_user, is_authenticated

# Import API helpers for consistent error responses
include(joinpath(@__DIR__, "..", "lib", "api_helpers.jl"))
using .ApiHelpers: api_success, api_error, api_unauthorized, api_bad_request

"""
    api_login()

JSON API endpoint for login.
POST /api/auth/login
Accepts JSON: {username, password}
Returns JSON: user info on success, error on failure
"""
function api_login()
    session = GenieSession.session()

    # Parse JSON payload
    payload = try
        jsonpayload()
    catch e
        @warn "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Handle case where jsonpayload returns nothing
    if payload === nothing
        return api_bad_request("Invalid JSON payload")
    end

    # Get credentials from JSON
    username = get(payload, "username", "")
    password = get(payload, "password", "")

    # Validate input
    if isempty(username) || isempty(password)
        @warn "API login attempt with empty credentials"
        return api_bad_request("Username and password are required")
    end

    # Authenticate user
    user = authenticate_user(username, password)

    if user === nothing
        @warn "API failed login attempt" username=username
        return api_unauthorized("Invalid username or password")
    end

    # Login successful - create session
    if login!(user, session)
        @info "API user logged in successfully" username=user.username user_id=user.id.value
        return api_success(Dict(
            "user" => Dict(
                "id" => user.id.value,
                "username" => user.username,
                "name" => user.name,
                "role" => user.role
            )
        ))
    else
        @error "API failed to create session for user" username=user.username
        return api_error("Login failed. Please try again.")
    end
end

"""
    api_logout()

JSON API endpoint for logout.
POST /api/auth/logout
Clears session and returns success.
"""
function api_logout()
    session = GenieSession.session()

    # Get current user for logging before clearing session
    user = current_user(session)
    if user !== nothing
        @info "API user logging out" username=user.username user_id=user.id.value
    end

    logout!(session)

    return api_success(Dict("success" => true))
end

"""
    api_me()

JSON API endpoint for getting current user info.
GET /api/auth/me
Returns JSON: current user info or 401 if not logged in
"""
function api_me()
    session = GenieSession.session()

    # Check if authenticated
    if !is_authenticated(session)
        return api_unauthorized("Not authenticated")
    end

    user = current_user(session)

    if user === nothing
        return api_unauthorized("Not authenticated")
    end

    return api_success(Dict(
        "user" => Dict(
            "id" => user.id.value,
            "username" => user.username,
            "name" => user.name,
            "role" => user.role
        )
    ))
end

end # module AuthController
