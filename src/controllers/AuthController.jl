# AuthController
# Handles login and logout functionality

module AuthController

using Genie
using Genie.Renderer.Html: html
using Genie.Renderer: redirect
using Genie.Requests: postpayload
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

end # module AuthController
