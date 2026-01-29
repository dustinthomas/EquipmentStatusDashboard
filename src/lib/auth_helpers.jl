# Authentication Helper Functions
# Route protection middleware and convenience functions for controllers

module AuthHelpers

using Genie
using Genie.Renderer: redirect
using Genie.Renderer.Json: json
using Genie.Requests: getrequest
using GenieSession
using Logging

# Import API helpers for consistent error responses
include(joinpath(@__DIR__, "api_helpers.jl"))
using .ApiHelpers: api_unauthorized, api_forbidden

# Session keys for redirect URL storage
const REDIRECT_URL_KEY = :__redirect_url
const LAST_ACTIVITY_KEY = :__last_activity

# Import parent App module for authentication functions
# Use qualified calls (App.xxx) to avoid naming conflicts with wrapper functions
import ..App

"""
    get_session() -> GenieSession.Session

Get the current session. Convenience wrapper.
"""
function get_session()::GenieSession.Session
    return GenieSession.session()
end

"""
    store_redirect_url(url::String) -> Nothing

Store a URL to redirect to after login.
"""
function store_redirect_url(url::String)
    session = get_session()
    GenieSession.set!(session, REDIRECT_URL_KEY, url)
    return nothing
end

"""
    get_redirect_url(default::String = "/dashboard") -> String

Retrieve and clear the stored redirect URL.
Returns the default if no URL was stored.
"""
function get_redirect_url(default::String = "/dashboard")::String
    session = get_session()
    if GenieSession.isset(session, REDIRECT_URL_KEY)
        url = GenieSession.get(session, REDIRECT_URL_KEY)
        GenieSession.unset!(session, REDIRECT_URL_KEY)
        # Don't redirect to login or logout pages
        if url in ["/login", "/logout", ""]
            return default
        end
        return url
    end
    return default
end

"""
    get_current_path() -> String

Get the current request path for storing as redirect URL.
"""
function get_current_path()::String
    try
        req = getrequest()
        path = req.target
        # Strip query string for cleaner redirect
        if occursin("?", path)
            path = split(path, "?")[1]
        end
        return path
    catch
        return "/dashboard"
    end
end

"""
    check_session_timeout(session::GenieSession.Session, timeout_seconds::Int) -> Bool

Check if the session has expired based on last activity.
Returns true if session is valid, false if expired.
"""
function check_session_timeout(session::GenieSession.Session, timeout_seconds::Int)::Bool
    current_time = time()

    if GenieSession.isset(session, LAST_ACTIVITY_KEY)
        last_activity = GenieSession.get(session, LAST_ACTIVITY_KEY)
        if (current_time - last_activity) > timeout_seconds
            @debug "Session expired" elapsed=(current_time - last_activity) timeout=timeout_seconds
            return false
        end
    end

    # Update last activity time
    GenieSession.set!(session, LAST_ACTIVITY_KEY, current_time)
    return true
end

"""
    require_authentication() -> Union{Nothing, HTTP.Messages.Response}

Check if the user is authenticated. If not, redirect to login page.
Stores the current URL for redirect after login.

Returns nothing if authenticated, or a redirect response if not.

Usage in route:
```julia
route("/dashboard", method = GET) do
    auth_result = require_authentication()
    if auth_result !== nothing
        return auth_result
    end
    # ... rest of route handler
end
```
"""
function require_authentication()
    session = get_session()

    # Check session timeout first
    timeout_seconds = get(ENV, "SESSION_TIMEOUT", "28800") |> x -> parse(Int, x)
    if !check_session_timeout(session, timeout_seconds)
        @info "Session expired, clearing authentication"
        # Clear auth data on timeout
        App.logout!(session)
        store_redirect_url(get_current_path())
        return redirect("/login")
    end

    # Check if authenticated
    if !App.is_authenticated(session)
        @debug "Unauthenticated access attempt" path=get_current_path()
        store_redirect_url(get_current_path())
        return redirect("/login")
    end

    return nothing
end

"""
    require_authentication_api() -> Union{Nothing, HTTP.Messages.Response}

Check if the user is authenticated for API requests.
Returns JSON 401 Unauthorized if not authenticated.

Returns nothing if authenticated, or a JSON error response if not.

Usage in route:
```julia
route("/api/tools", method = GET) do
    auth_result = require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end
    # ... rest of route handler
end
```
"""
function require_authentication_api()
    session = get_session()

    # Check session timeout first
    timeout_seconds = get(ENV, "SESSION_TIMEOUT", "28800") |> x -> parse(Int, x)
    if !check_session_timeout(session, timeout_seconds)
        @info "Session expired, clearing authentication"
        App.logout!(session)
        return api_unauthorized("Session expired")
    end

    # Check if authenticated
    if !App.is_authenticated(session)
        @debug "Unauthenticated API access attempt" path=get_current_path()
        return api_unauthorized()
    end

    return nothing
end

"""
    require_admin() -> Union{Nothing, HTTP.Messages.Response}

Check if the user is an admin. If not authenticated, redirect to login.
If authenticated but not admin, redirect to dashboard with 403 status.

Returns nothing if admin, or a redirect/error response if not.

Usage in route:
```julia
route("/admin/tools", method = GET) do
    admin_result = require_admin()
    if admin_result !== nothing
        return admin_result
    end
    # ... rest of route handler
end
```
"""
function require_admin()
    # First check authentication
    auth_result = require_authentication()
    if auth_result !== nothing
        return auth_result
    end

    # Then check admin role
    session = get_session()
    if !App.is_admin(session)
        user = App.current_user(session)
        username = user !== nothing ? user.username : "unknown"
        @warn "Non-admin access attempt to admin route" path=get_current_path() username=username
        # Redirect to dashboard - non-admins shouldn't access admin routes
        return redirect("/vue?error=forbidden")
    end

    return nothing
end

"""
    require_admin_api() -> Union{Nothing, HTTP.Messages.Response}

Check if the user is an admin for API requests.
Returns JSON 401 Unauthorized if not authenticated.
Returns JSON 403 Forbidden if authenticated but not admin.

Returns nothing if admin, or a JSON error response if not.

Usage in route:
```julia
route("/api/admin/tools", method = GET) do
    admin_result = require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    # ... rest of route handler
end
```
"""
function require_admin_api()
    # First check authentication
    auth_result = require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end

    # Then check admin role
    session = get_session()
    if !App.is_admin(session)
        user = App.current_user(session)
        username = user !== nothing ? user.username : "unknown"
        @warn "Non-admin API access attempt" path=get_current_path() username=username
        return api_forbidden("Admin access required")
    end

    return nothing
end

"""
    current_user()

Get the current authenticated user.
Convenience wrapper that doesn't require passing the session.
"""
function current_user()
    session = get_session()
    return App.current_user(session)
end

"""
    is_authenticated() -> Bool

Check if there is an authenticated user.
Convenience wrapper that doesn't require passing the session.
"""
function is_authenticated()::Bool
    session = get_session()
    return App.is_authenticated(session)
end

"""
    is_admin() -> Bool

Check if the current user is an admin.
Convenience wrapper that doesn't require passing the session.
"""
function is_admin()::Bool
    session = get_session()
    return App.is_admin(session)
end

export get_session, store_redirect_url, get_redirect_url, get_current_path
export check_session_timeout, require_authentication, require_authentication_api
export require_admin, require_admin_api
export current_user, is_authenticated, is_admin
export REDIRECT_URL_KEY

end # module AuthHelpers
