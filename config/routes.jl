# Route definitions for QCI Equipment Status Dashboard
using Genie.Router
using Genie.Requests
using Genie.Responses
using Genie.Renderer: redirect
using Genie.Renderer.Json: json

# Import modules from App (already loaded by App.jl)
using ..App: AuthHelpers, AuthController, DashboardController

# Health check endpoint - returns JSON status for monitoring
route("/health", method = GET) do
    json(Dict("status" => "ok"))
end

# Root redirect to Vue app
route("/", method = GET) do
    redirect("/vue")
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

# ========================================
# Vue Frontend Routes
# ========================================

# Serve Vue app for /vue routes
# No server-side auth required - Vue handles authentication via API
route("/vue", method = GET) do
    Genie.Renderer.respond(
        read(joinpath(Genie.config.server_document_root, "index.html"), String),
        :html
    )
end

# Catch-all for Vue app sub-routes (e.g., /vue/tools/1)
# Serves same index.html, Vue router handles the path
route("/vue/*", method = GET) do
    Genie.Renderer.respond(
        read(joinpath(Genie.config.server_document_root, "index.html"), String),
        :html
    )
end
