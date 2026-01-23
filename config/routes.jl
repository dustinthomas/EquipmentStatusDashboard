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

# Placeholder dashboard route (to be implemented in Unit 4.1)
# Protected: requires authentication
route("/dashboard", method = GET) do
    auth_result = AuthHelpers.require_authentication()
    if auth_result !== nothing
        return auth_result
    end
    "Dashboard coming soon"
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
