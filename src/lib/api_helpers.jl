# API Helper Functions
# Standardized JSON API response helpers for consistent error handling

module ApiHelpers

using Genie
using Genie.Renderer.Json: JSONParser

export api_success, api_error, api_unauthorized, api_forbidden, api_not_found, api_bad_request

"""
    api_success(data::Dict; status::Int=200) -> HTTP.Messages.Response

Return a successful JSON API response.

# Arguments
- `data::Dict`: The data to return in the response body
- `status::Int`: HTTP status code (default: 200)

# Returns
JSON response with Content-Type: application/json
"""
function api_success(data::Dict; status::Int=200)
    return Genie.Renderer.respond(
        JSONParser.json(data),
        status,
        Dict("Content-Type" => "application/json; charset=utf-8")
    )
end

"""
    api_error(message::String; status::Int=500) -> HTTP.Messages.Response

Return a JSON API error response with consistent format.

# Arguments
- `message::String`: Error message to return
- `status::Int`: HTTP status code (default: 500)

# Returns
JSON response: {"error": "message"}
"""
function api_error(message::String; status::Int=500)
    return Genie.Renderer.respond(
        JSONParser.json(Dict("error" => message)),
        status,
        Dict("Content-Type" => "application/json; charset=utf-8")
    )
end

"""
    api_unauthorized(message::String="Unauthorized") -> HTTP.Messages.Response

Return a 401 Unauthorized JSON API response.

# Arguments
- `message::String`: Error message (default: "Unauthorized")

# Returns
JSON response: {"error": "message"} with 401 status
"""
function api_unauthorized(message::String="Unauthorized")
    return api_error(message, status=401)
end

"""
    api_forbidden(message::String="Forbidden") -> HTTP.Messages.Response

Return a 403 Forbidden JSON API response.

# Arguments
- `message::String`: Error message (default: "Forbidden")

# Returns
JSON response: {"error": "message"} with 403 status
"""
function api_forbidden(message::String="Forbidden")
    return api_error(message, status=403)
end

"""
    api_not_found(message::String="Not found") -> HTTP.Messages.Response

Return a 404 Not Found JSON API response.

# Arguments
- `message::String`: Error message (default: "Not found")

# Returns
JSON response: {"error": "message"} with 404 status
"""
function api_not_found(message::String="Not found")
    return api_error(message, status=404)
end

"""
    api_bad_request(message::String="Bad request") -> HTTP.Messages.Response

Return a 400 Bad Request JSON API response.

# Arguments
- `message::String`: Error message (default: "Bad request")

# Returns
JSON response: {"error": "message"} with 400 status
"""
function api_bad_request(message::String="Bad request")
    return api_error(message, status=400)
end

end # module ApiHelpers
