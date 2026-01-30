# Route definitions for QCI Equipment Status Dashboard
using Genie.Router
using Genie.Requests
using Genie.Responses
using Genie.Renderer: redirect
using Genie.Renderer.Json: json

# Import modules from App (already loaded by App.jl)
using ..App: AuthHelpers, AuthController, DashboardController, AdminController

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

# ========================================
# Admin Routes
# ========================================

# Admin: Index - redirect to tools management
# GET /admin - Redirects to /admin/tools
# Protected: requires admin role
route("/admin", method = GET) do
    admin_result = AuthHelpers.require_admin()
    if admin_result !== nothing
        return admin_result
    end
    redirect("/admin/tools")
end

# Admin: Tools list
# GET /admin/tools - List all tools (including inactive)
# Protected: requires admin role (redirects to dashboard if not admin)
# Serves Vue app - Vue handles rendering the admin tools view
route("/admin/tools", method = GET) do
    admin_result = AuthHelpers.require_admin()
    if admin_result !== nothing
        return admin_result
    end
    Genie.Renderer.respond(
        read(joinpath(Genie.config.server_document_root, "index.html"), String),
        :html
    )
end

# Admin: Users list
# GET /admin/users - List all users
# Protected: requires admin role (redirects to dashboard if not admin)
# Serves Vue app - Vue handles rendering the admin users view
route("/admin/users", method = GET) do
    admin_result = AuthHelpers.require_admin()
    if admin_result !== nothing
        return admin_result
    end
    Genie.Renderer.respond(
        read(joinpath(Genie.config.server_document_root, "index.html"), String),
        :html
    )
end

# ========================================
# Admin API Routes
# ========================================

# API: Admin - Get all tools (including inactive)
# GET /api/admin/tools
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/tools", method = GET) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_tools_index()
end

# API: Admin - Get single tool details (including inactive)
# GET /api/admin/tools/:id
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/tools/:id::Int", method = GET) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_tools_show()
end

# API: Admin - Create new tool
# POST /api/admin/tools
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/tools", method = POST) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_tools_create()
end

# API: Admin - Update tool
# PUT /api/admin/tools/:id
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/tools/:id::Int", method = PUT) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_tools_update()
end

# API: Admin - Toggle tool active status (soft delete/restore)
# POST /api/admin/tools/:id/toggle-active
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/tools/:id::Int/toggle-active", method = POST) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_tools_toggle_active()
end

# API: Admin - Get all users
# GET /api/admin/users
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/users", method = GET) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_users_index()
end

# API: Admin - Get single user details
# GET /api/admin/users/:id
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/users/:id::Int", method = GET) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_users_show()
end

# API: Admin - Create new user
# POST /api/admin/users
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/users", method = POST) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_users_create()
end

# API: Admin - Update user
# PUT /api/admin/users/:id
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/users/:id::Int", method = PUT) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_users_update()
end

# API: Admin - Reset user password
# POST /api/admin/users/:id/reset-password
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/users/:id::Int/reset-password", method = POST) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_users_reset_password()
end

# API: Admin - Toggle user active status (soft delete/restore)
# POST /api/admin/users/:id/toggle-active
# Protected: requires admin role (returns 403 if not admin)
route("/api/admin/users/:id::Int/toggle-active", method = POST) do
    admin_result = AuthHelpers.require_admin_api()
    if admin_result !== nothing
        return admin_result
    end
    AdminController.api_users_toggle_active()
end
