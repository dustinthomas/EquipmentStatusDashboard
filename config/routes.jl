# Route definitions for QCI Equipment Status Dashboard
using Genie.Router
using Genie.Requests
using Genie.Responses
using Genie.Renderer: redirect
using Genie.Renderer.Json: json

# Load auth helpers
include(joinpath(@__DIR__, "..", "src", "lib", "auth_helpers.jl"))
using .AuthHelpers

# Load controllers
include(joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl"))
using .AuthController

include(joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl"))
using .DashboardController

# Health check endpoint - returns JSON status for monitoring
route("/health", method = GET) do
    json(Dict("status" => "ok"))
end

# Root redirect to dashboard (protected by auth)
route("/", method = GET) do
    auth_result = AuthHelpers.require_authentication()
    if auth_result !== nothing
        return auth_result
    end
    redirect("/dashboard")
end

# Main dashboard route
# Protected: requires authentication
route("/dashboard", method = GET) do
    auth_result = AuthHelpers.require_authentication()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.index()
end

# Dashboard filter endpoint for HTMX partial updates
# Returns just the table HTML without the full page layout
route("/dashboard/filter", method = GET) do
    auth_result = AuthHelpers.require_authentication()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.filter_table()
end

# ========================================
# Authentication Routes
# ========================================

# Login page
route("/login", method = GET) do
    AuthController.login_form()
end

# Login form submission
route("/login", method = POST) do
    AuthController.login()
end

# Logout
route("/logout", method = GET) do
    AuthController.logout()
end

# ========================================
# JSON API Routes
# ========================================

# API: Get tools list with filter/sort support
# Protected: requires authentication (returns 401 if not logged in)
route("/api/tools", method = GET) do
    auth_result = AuthHelpers.require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.api_index()
end

# API: Get single tool details
# GET /api/tools/:id
# Protected: requires authentication (returns 401 if not logged in)
route("/api/tools/:id::Int", method = GET) do
    auth_result = AuthHelpers.require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.api_show()
end

# API: Update tool status
# POST /api/tools/:id/status
# Accepts JSON: {state, issue_description, comment, eta_to_up}
# Protected: requires authentication (returns 401 if not logged in)
route("/api/tools/:id::Int/status", method = POST) do
    auth_result = AuthHelpers.require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.api_update_status()
end

# API: Get tool status history
# GET /api/tools/:id/history
# Query params: from, to (date range filter)
# Protected: requires authentication (returns 401 if not logged in)
route("/api/tools/:id::Int/history", method = GET) do
    auth_result = AuthHelpers.require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.api_history()
end

# API: Download tool status history as CSV
# GET /api/tools/:id/history.csv
# Query params: from, to (date range filter)
# Protected: requires authentication (returns 401 if not logged in)
route("/api/tools/:id::Int/history.csv", method = GET) do
    auth_result = AuthHelpers.require_authentication_api()
    if auth_result !== nothing
        return auth_result
    end
    DashboardController.api_history_csv()
end

# ========================================
# Auth API Routes
# ========================================

# API: Login
# POST /api/auth/login
# Accepts JSON: {username, password}
# Returns JSON: user info on success, error on failure
route("/api/auth/login", method = POST) do
    AuthController.api_login()
end

# API: Logout
# POST /api/auth/logout
# Clears session and returns success
route("/api/auth/logout", method = POST) do
    AuthController.api_logout()
end

# API: Get current user info
# GET /api/auth/me
# Returns JSON: current user info or 401 if not logged in
route("/api/auth/me", method = GET) do
    AuthController.api_me()
end
