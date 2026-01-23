# AuthController
# Handles login and logout functionality

module AuthController

using Genie
using Genie.Renderer.Html: html
using Genie.Renderer: redirect
using Genie.Renderer.Json: json
using Genie.Requests: postpayload, jsonpayload
using GenieSession
using Logging

# Import authentication functions from the initializer
# These are loaded when the app starts
using Main: authenticate_user, login!, logout!, current_user, is_authenticated

# Import auth helpers for redirect URL handling
# AuthHelpers is loaded by routes.jl before this controller
using Main.AuthHelpers: get_redirect_url

"""
    login_form()

Display the login form.
GET /login
"""
function login_form()
    # If already authenticated, redirect to dashboard
    session = GenieSession.session()
    if is_authenticated(session)
        return redirect("/dashboard")
    end

    html(:auth, :login; layout = :app, error_message = nothing, page_title = "Login")
end

"""
    login()

Process login form submission.
POST /login
"""
function login()
    session = GenieSession.session()

    # Get form data
    username = postpayload(:username, "")
    password = postpayload(:password, "")

    # Validate input
    if isempty(username) || isempty(password)
        @warn "Login attempt with empty credentials"
        return html(:auth, :login; layout = :app,
                   error_message = "Please enter both username and password",
                   page_title = "Login")
    end

    # Authenticate user
    user = authenticate_user(username, password)

    if user === nothing
        # Use generic error message to avoid revealing which field was wrong
        @warn "Failed login attempt" username=username
        return html(:auth, :login; layout = :app,
                   error_message = "Invalid username or password",
                   page_title = "Login")
    end

    # Login successful - create session
    if login!(user, session)
        @info "User logged in successfully" username=user.username user_id=user.id.value
        # Redirect to originally requested page, or dashboard by default
        redirect_url = get_redirect_url("/dashboard")
        return redirect(redirect_url)
    else
        @error "Failed to create session for user" username=user.username
        return html(:auth, :login; layout = :app,
                   error_message = "Login failed. Please try again.",
                   page_title = "Login")
    end
end

"""
    logout()

Log out the current user and redirect to login.
GET /logout
"""
function logout()
    session = GenieSession.session()

    # Get current user for logging before clearing session
    user = current_user(session)
    if user !== nothing
        @info "User logging out" username=user.username user_id=user.id.value
    end

    logout!(session)

    return redirect("/login")
end

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
        return Genie.Renderer.respond(
            json(Dict("error" => "Invalid JSON payload")),
            400,
            Dict("Content-Type" => "application/json")
        )
    end

    # Handle case where jsonpayload returns nothing
    if payload === nothing
        return Genie.Renderer.respond(
            json(Dict("error" => "Invalid JSON payload")),
            400,
            Dict("Content-Type" => "application/json")
        )
    end

    # Get credentials from JSON
    username = get(payload, "username", "")
    password = get(payload, "password", "")

    # Validate input
    if isempty(username) || isempty(password)
        @warn "API login attempt with empty credentials"
        return Genie.Renderer.respond(
            json(Dict("error" => "Username and password are required")),
            400,
            Dict("Content-Type" => "application/json")
        )
    end

    # Authenticate user
    user = authenticate_user(username, password)

    if user === nothing
        @warn "API failed login attempt" username=username
        return Genie.Renderer.respond(
            json(Dict("error" => "Invalid username or password")),
            401,
            Dict("Content-Type" => "application/json")
        )
    end

    # Login successful - create session
    if login!(user, session)
        @info "API user logged in successfully" username=user.username user_id=user.id.value
        return json(Dict(
            "user" => Dict(
                "id" => user.id.value,
                "username" => user.username,
                "name" => user.name,
                "role" => user.role
            )
        ))
    else
        @error "API failed to create session for user" username=user.username
        return Genie.Renderer.respond(
            json(Dict("error" => "Login failed. Please try again.")),
            500,
            Dict("Content-Type" => "application/json")
        )
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

    return json(Dict("success" => true))
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
        return Genie.Renderer.respond(
            json(Dict("error" => "Not authenticated")),
            401,
            Dict("Content-Type" => "application/json")
        )
    end

    user = current_user(session)

    if user === nothing
        return Genie.Renderer.respond(
            json(Dict("error" => "Not authenticated")),
            401,
            Dict("Content-Type" => "application/json")
        )
    end

    return json(Dict(
        "user" => Dict(
            "id" => user.id.value,
            "username" => user.username,
            "name" => user.name,
            "role" => user.role
        )
    ))
end

end # module AuthController
