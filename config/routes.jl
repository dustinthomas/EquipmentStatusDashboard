# Route definitions for QCI Equipment Status Dashboard
using Genie.Router
using Genie.Requests
using Genie.Responses
using Genie.Renderer.Json: json

# Health check endpoint - returns JSON status for monitoring
route("/health", method = GET) do
    json(Dict("status" => "ok"))
end

# Root redirect to dashboard (will be protected by auth later)
route("/", method = GET) do
    Genie.Responses.redirect("/dashboard")
end

# Placeholder dashboard route (to be implemented in Unit 4.1)
route("/dashboard", method = GET) do
    "Dashboard coming soon"
end
