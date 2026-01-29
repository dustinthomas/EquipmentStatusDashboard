# AdminController
# Handles admin API endpoints for tool and user management

module AdminController

using Genie
using Genie.Renderer.Json: json
using Genie.Requests: getpayload, jsonpayload
using SearchLight
using Logging
using Dates

# Import models from parent App module
import ..App: Tool, User
using ..App.Tools: VALID_STATES, VALID_CRITICALITIES, validate_state, validate_criticality
using ..App.Users: VALID_ROLES, validate_role, find_active_admins, find_by_username

# Import auth core for password hashing
using ..App: hash_password

# Import auth helpers
using ..App.AuthHelpers: current_user

# Import API helpers for consistent error responses
include(joinpath(@__DIR__, "..", "lib", "api_helpers.jl"))
using .ApiHelpers: api_success, api_error, api_bad_request, api_not_found

# Import dashboard helpers for formatting
include(joinpath(@__DIR__, "..", "lib", "dashboard_helpers.jl"))
using .DashboardHelpers: state_css_class, state_display_text, format_timestamp

export api_tools_index, api_tools_show, api_tools_create, api_tools_update, api_tools_toggle_active
export api_users_index, api_users_show, api_users_create, api_users_update, api_users_reset_password, api_users_toggle_active

"""
    get_user_name(user_id::SearchLight.DbId) -> String

Get the display name for a user by their ID.
Returns "Unknown" if user not found.
"""
function get_user_name(user_id::SearchLight.DbId)::String
    if user_id.value === nothing
        return ""
    end
    user = SearchLight.findone(User; id = user_id.value)
    return user === nothing ? "Unknown" : user.name
end

"""
    tool_to_dict(tool::Tool) -> Dict

Convert a Tool to a dictionary for JSON response.
"""
function tool_to_dict(tool::Tool)::Dict
    Dict(
        "id" => tool.id.value,
        "name" => tool.name,
        "area" => tool.area,
        "bay" => tool.bay,
        "criticality" => tool.criticality,
        "is_active" => tool.is_active,
        "state" => tool.current_state,
        "state_display" => state_display_text(tool.current_state),
        "state_class" => state_css_class(tool.current_state),
        "issue_description" => tool.current_issue_description,
        "comment" => tool.current_comment,
        "eta_to_up" => tool.current_eta_to_up,
        "eta_to_up_formatted" => format_timestamp(tool.current_eta_to_up),
        "status_updated_at" => tool.current_status_updated_at,
        "status_updated_at_formatted" => format_timestamp(tool.current_status_updated_at),
        "status_updated_by" => get_user_name(tool.current_status_updated_by_user_id),
        "created_at" => tool.created_at,
        "updated_at" => tool.updated_at
    )
end

"""
    api_tools_index()

JSON API endpoint for listing all tools (including inactive).
GET /api/admin/tools

Returns JSON array of all tool objects with metadata.
"""
function api_tools_index()
    # Get all tools (including inactive)
    all_tools = SearchLight.all(Tool)

    # Sort by name for consistent ordering
    sort!(all_tools, by = t -> lowercase(t.name))

    # Count stats
    active_count = count(t -> t.is_active, all_tools)
    inactive_count = length(all_tools) - active_count

    # Prepare tool data for JSON response
    tool_data = [tool_to_dict(t) for t in all_tools]

    api_success(Dict(
        "tools" => tool_data,
        "meta" => Dict(
            "total" => length(all_tools),
            "active" => active_count,
            "inactive" => inactive_count,
            "criticalities" => VALID_CRITICALITIES,
            "states" => VALID_STATES
        )
    ))
end

"""
    api_tools_show()

JSON API endpoint for fetching a single tool's details (including inactive).
GET /api/admin/tools/:id

Returns JSON object with full tool details.
Returns 404 if tool not found.
"""
function api_tools_show()
    # Get the tool ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid tool ID")
    end

    # Find the tool (including inactive)
    tool = SearchLight.findone(Tool; id = id)

    if tool === nothing
        return api_not_found("Tool not found")
    end

    api_success(Dict("tool" => tool_to_dict(tool)))
end

"""
    api_tools_create()

JSON API endpoint for creating a new tool.
POST /api/admin/tools

Request body (JSON):
- name: Required. Tool name (2-100 characters)
- area: Required. Fab area location
- bay: Optional. Bay or line within area
- criticality: Required. One of: critical, high, medium, low
- is_active: Optional. Whether tool is active (default: true)

Returns created tool JSON on success.
Returns 400 with validation errors on invalid input.
"""
function api_tools_create()
    # Parse JSON request body
    local payload::Dict
    try
        payload = jsonpayload()
        if payload === nothing
            return api_bad_request("Request body is required")
        end
    catch e
        @error "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Extract and validate required fields
    name = string(get(payload, "name", ""))
    area = string(get(payload, "area", ""))
    criticality = string(get(payload, "criticality", "medium"))

    # Validate name
    if isempty(name)
        return api_bad_request("Name is required")
    end
    if length(name) < 2
        return api_bad_request("Name must be at least 2 characters")
    end
    if length(name) > 100
        return api_bad_request("Name must not exceed 100 characters")
    end

    # Validate area
    if isempty(area)
        return api_bad_request("Area is required")
    end
    if length(area) > 50
        return api_bad_request("Area must not exceed 50 characters")
    end

    # Validate criticality
    if !validate_criticality(criticality)
        return api_bad_request("Invalid criticality. Must be one of: $(join(VALID_CRITICALITIES, ", "))")
    end

    # Extract optional fields
    bay = string(get(payload, "bay", ""))
    if length(bay) > 50
        return api_bad_request("Bay must not exceed 50 characters")
    end

    is_active = get(payload, "is_active", true)
    if !(is_active isa Bool)
        is_active = string(is_active) == "true"
    end

    # Create new tool
    timestamp = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    tool = Tool(
        name = name,
        area = area,
        bay = bay,
        criticality = criticality,
        is_active = is_active,
        current_state = "UP",  # New tools start as UP
        current_issue_description = "",
        current_comment = "",
        current_eta_to_up = "",
        current_status_updated_at = "",
        current_status_updated_by_user_id = SearchLight.DbId(),
        created_at = timestamp,
        updated_at = timestamp
    )

    # Save tool
    try
        SearchLight.save!(tool)
        @info "Tool created" tool_id=tool.id.value name=name area=area
    catch e
        @error "Failed to create tool" exception=e
        return api_error("Failed to create tool")
    end

    api_success(Dict("tool" => tool_to_dict(tool)), status=201)
end

"""
    api_tools_update()

JSON API endpoint for updating an existing tool.
PUT /api/admin/tools/:id

Request body (JSON):
- name: Optional. Tool name (2-100 characters)
- area: Optional. Fab area location
- bay: Optional. Bay or line within area
- criticality: Optional. One of: critical, high, medium, low

Note: Use api_tools_toggle_active to change is_active status.

Returns updated tool JSON on success.
Returns 400 with validation errors on invalid input.
Returns 404 if tool not found.
"""
function api_tools_update()
    # Get the tool ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid tool ID")
    end

    # Find the tool
    tool = SearchLight.findone(Tool; id = id)

    if tool === nothing
        return api_not_found("Tool not found")
    end

    # Parse JSON request body
    local payload::Dict
    try
        payload = jsonpayload()
        if payload === nothing
            return api_bad_request("Request body is required")
        end
    catch e
        @error "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Update name if provided
    if haskey(payload, "name")
        name = string(payload["name"])
        if isempty(name)
            return api_bad_request("Name cannot be empty")
        end
        if length(name) < 2
            return api_bad_request("Name must be at least 2 characters")
        end
        if length(name) > 100
            return api_bad_request("Name must not exceed 100 characters")
        end
        tool.name = name
    end

    # Update area if provided
    if haskey(payload, "area")
        area = string(payload["area"])
        if isempty(area)
            return api_bad_request("Area cannot be empty")
        end
        if length(area) > 50
            return api_bad_request("Area must not exceed 50 characters")
        end
        tool.area = area
    end

    # Update bay if provided
    if haskey(payload, "bay")
        bay = string(payload["bay"])
        if length(bay) > 50
            return api_bad_request("Bay must not exceed 50 characters")
        end
        tool.bay = bay
    end

    # Update criticality if provided
    if haskey(payload, "criticality")
        criticality = string(payload["criticality"])
        if !validate_criticality(criticality)
            return api_bad_request("Invalid criticality. Must be one of: $(join(VALID_CRITICALITIES, ", "))")
        end
        tool.criticality = criticality
    end

    # Update timestamp
    tool.updated_at = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    # Save tool
    try
        SearchLight.save!(tool)
        @info "Tool updated" tool_id=tool.id.value name=tool.name
    catch e
        @error "Failed to update tool" exception=e
        return api_error("Failed to update tool")
    end

    api_success(Dict("tool" => tool_to_dict(tool)))
end

"""
    api_tools_toggle_active()

JSON API endpoint for toggling tool active status.
POST /api/admin/tools/:id/toggle-active

Toggles the is_active flag on the tool (soft delete/restore).

Returns updated tool JSON on success.
Returns 404 if tool not found.
"""
function api_tools_toggle_active()
    # Get the tool ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid tool ID")
    end

    # Find the tool
    tool = SearchLight.findone(Tool; id = id)

    if tool === nothing
        return api_not_found("Tool not found")
    end

    # Toggle is_active
    old_status = tool.is_active
    tool.is_active = !tool.is_active
    tool.updated_at = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    # Save tool
    try
        SearchLight.save!(tool)
        action = tool.is_active ? "activated" : "deactivated"
        @info "Tool $action" tool_id=tool.id.value name=tool.name was_active=old_status is_active=tool.is_active
    catch e
        @error "Failed to toggle tool active status" exception=e
        return api_error("Failed to toggle tool active status")
    end

    api_success(Dict(
        "tool" => tool_to_dict(tool),
        "message" => tool.is_active ? "Tool activated" : "Tool deactivated"
    ))
end

# ============================================================================
# User Management API Endpoints
# ============================================================================

"""
    user_to_dict(user::User) -> Dict

Convert a User to a dictionary for JSON response.
Excludes password_hash for security.
"""
function user_to_dict(user::User)::Dict
    Dict(
        "id" => user.id.value,
        "username" => user.username,
        "name" => user.name,
        "role" => user.role,
        "is_active" => user.is_active,
        "last_login_at" => user.last_login_at,
        "last_login_at_formatted" => format_timestamp(user.last_login_at),
        "created_at" => user.created_at,
        "created_at_formatted" => format_timestamp(user.created_at),
        "updated_at" => user.updated_at,
        "updated_at_formatted" => format_timestamp(user.updated_at)
    )
end

"""
    api_users_index()

JSON API endpoint for listing all users (including inactive).
GET /api/admin/users

Returns JSON array of all user objects with metadata.
"""
function api_users_index()
    # Get all users (including inactive)
    all_users = SearchLight.all(User)

    # Sort by name for consistent ordering
    sort!(all_users, by = u -> lowercase(u.name))

    # Count stats
    active_count = count(u -> u.is_active, all_users)
    inactive_count = length(all_users) - active_count
    admin_count = count(u -> u.role == "admin" && u.is_active, all_users)
    operator_count = count(u -> u.role == "operator" && u.is_active, all_users)

    # Prepare user data for JSON response
    user_data = [user_to_dict(u) for u in all_users]

    api_success(Dict(
        "users" => user_data,
        "meta" => Dict(
            "total" => length(all_users),
            "active" => active_count,
            "inactive" => inactive_count,
            "admins" => admin_count,
            "operators" => operator_count,
            "roles" => VALID_ROLES
        )
    ))
end

"""
    api_users_show()

JSON API endpoint for fetching a single user's details.
GET /api/admin/users/:id

Returns JSON object with full user details (excluding password).
Returns 404 if user not found.
"""
function api_users_show()
    # Get the user ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid user ID")
    end

    # Find the user
    user = SearchLight.findone(User; id = id)

    if user === nothing
        return api_not_found("User not found")
    end

    api_success(Dict("user" => user_to_dict(user)))
end

"""
    api_users_create()

JSON API endpoint for creating a new user.
POST /api/admin/users

Request body (JSON):
- username: Required. Unique username (3-50 characters)
- password: Required. Password (minimum 6 characters)
- name: Required. Display name (1-100 characters)
- role: Required. One of: admin, operator
- is_active: Optional. Whether user is active (default: true)

Returns created user JSON on success.
Returns 400 with validation errors on invalid input.
"""
function api_users_create()
    # Parse JSON request body
    local payload::Dict
    try
        payload = jsonpayload()
        if payload === nothing
            return api_bad_request("Request body is required")
        end
    catch e
        @error "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Extract and validate required fields
    username = string(get(payload, "username", ""))
    password = string(get(payload, "password", ""))
    name = string(get(payload, "name", ""))
    role = string(get(payload, "role", "operator"))

    # Validate username
    if isempty(username)
        return api_bad_request("Username is required")
    end
    if length(username) < 3
        return api_bad_request("Username must be at least 3 characters")
    end
    if length(username) > 50
        return api_bad_request("Username must not exceed 50 characters")
    end
    # Check username format (alphanumeric and underscores only)
    if !occursin(r"^[a-zA-Z0-9_]+$", username)
        return api_bad_request("Username can only contain letters, numbers, and underscores")
    end

    # Check for duplicate username
    existing_user = find_by_username(username)
    if existing_user !== nothing
        return api_bad_request("Username already exists")
    end

    # Validate password
    if isempty(password)
        return api_bad_request("Password is required")
    end
    if length(password) < 6
        return api_bad_request("Password must be at least 6 characters")
    end

    # Validate name
    if isempty(name)
        return api_bad_request("Name is required")
    end
    if length(name) > 100
        return api_bad_request("Name must not exceed 100 characters")
    end

    # Validate role
    if !validate_role(role)
        return api_bad_request("Invalid role. Must be one of: $(join(VALID_ROLES, ", "))")
    end

    # Extract optional fields
    is_active = get(payload, "is_active", true)
    if !(is_active isa Bool)
        is_active = string(is_active) == "true"
    end

    # Create new user
    timestamp = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    user = User(
        username = username,
        password_hash = hash_password(password),
        name = name,
        role = role,
        is_active = is_active,
        last_login_at = "",
        created_at = timestamp,
        updated_at = timestamp
    )

    # Save user
    try
        SearchLight.save!(user)
        @info "User created" user_id=user.id.value username=username role=role
    catch e
        @error "Failed to create user" exception=e
        return api_error("Failed to create user")
    end

    api_success(Dict("user" => user_to_dict(user)), status=201)
end

"""
    api_users_update()

JSON API endpoint for updating an existing user (excluding password).
PUT /api/admin/users/:id

Request body (JSON):
- username: Optional. Unique username (3-50 characters)
- name: Optional. Display name (1-100 characters)
- role: Optional. One of: admin, operator

Note: Use api_users_reset_password to change password.
Note: Use api_users_toggle_active to change is_active status.

Returns updated user JSON on success.
Returns 400 with validation errors on invalid input.
Returns 404 if user not found.
"""
function api_users_update()
    # Get the user ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid user ID")
    end

    # Find the user
    user = SearchLight.findone(User; id = id)

    if user === nothing
        return api_not_found("User not found")
    end

    # Parse JSON request body
    local payload::Dict
    try
        payload = jsonpayload()
        if payload === nothing
            return api_bad_request("Request body is required")
        end
    catch e
        @error "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Update username if provided
    if haskey(payload, "username")
        username = string(payload["username"])
        if isempty(username)
            return api_bad_request("Username cannot be empty")
        end
        if length(username) < 3
            return api_bad_request("Username must be at least 3 characters")
        end
        if length(username) > 50
            return api_bad_request("Username must not exceed 50 characters")
        end
        if !occursin(r"^[a-zA-Z0-9_]+$", username)
            return api_bad_request("Username can only contain letters, numbers, and underscores")
        end
        # Check for duplicate username (excluding current user)
        if username != user.username
            existing_user = find_by_username(username)
            if existing_user !== nothing
                return api_bad_request("Username already exists")
            end
        end
        user.username = username
    end

    # Update name if provided
    if haskey(payload, "name")
        name = string(payload["name"])
        if isempty(name)
            return api_bad_request("Name cannot be empty")
        end
        if length(name) > 100
            return api_bad_request("Name must not exceed 100 characters")
        end
        user.name = name
    end

    # Update role if provided
    if haskey(payload, "role")
        role = string(payload["role"])
        if !validate_role(role)
            return api_bad_request("Invalid role. Must be one of: $(join(VALID_ROLES, ", "))")
        end
        # Prevent demoting the last admin
        if user.role == "admin" && role != "admin" && user.is_active
            active_admins = find_active_admins()
            if length(active_admins) <= 1
                return api_bad_request("Cannot change role of the last active admin")
            end
        end
        user.role = role
    end

    # Update timestamp
    user.updated_at = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    # Save user
    try
        SearchLight.save!(user)
        @info "User updated" user_id=user.id.value username=user.username
    catch e
        @error "Failed to update user" exception=e
        return api_error("Failed to update user")
    end

    api_success(Dict("user" => user_to_dict(user)))
end

"""
    api_users_reset_password()

JSON API endpoint for resetting a user's password.
POST /api/admin/users/:id/reset-password

Request body (JSON):
- password: Required. New password (minimum 6 characters)

Returns updated user JSON on success.
Returns 400 with validation errors on invalid input.
Returns 404 if user not found.
"""
function api_users_reset_password()
    # Get the user ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid user ID")
    end

    # Find the user
    user = SearchLight.findone(User; id = id)

    if user === nothing
        return api_not_found("User not found")
    end

    # Parse JSON request body
    local payload::Dict
    try
        payload = jsonpayload()
        if payload === nothing
            return api_bad_request("Request body is required")
        end
    catch e
        @error "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Validate password
    password = string(get(payload, "password", ""))
    if isempty(password)
        return api_bad_request("Password is required")
    end
    if length(password) < 6
        return api_bad_request("Password must be at least 6 characters")
    end

    # Update password hash and timestamp
    user.password_hash = hash_password(password)
    user.updated_at = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    # Save user
    try
        SearchLight.save!(user)
        @info "User password reset" user_id=user.id.value username=user.username
    catch e
        @error "Failed to reset user password" exception=e
        return api_error("Failed to reset user password")
    end

    api_success(Dict(
        "user" => user_to_dict(user),
        "message" => "Password reset successfully"
    ))
end

"""
    api_users_toggle_active()

JSON API endpoint for toggling user active status.
POST /api/admin/users/:id/toggle-active

Toggles the is_active flag on the user (soft delete/restore).
Cannot deactivate the last active admin.

Returns updated user JSON on success.
Returns 400 if attempting to deactivate last admin.
Returns 404 if user not found.
"""
function api_users_toggle_active()
    # Get the user ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_bad_request("Invalid user ID")
    end

    # Find the user
    user = SearchLight.findone(User; id = id)

    if user === nothing
        return api_not_found("User not found")
    end

    # Prevent deactivating the last active admin
    if user.is_active && user.role == "admin"
        active_admins = find_active_admins()
        if length(active_admins) <= 1
            return api_bad_request("Cannot deactivate the last active admin")
        end
    end

    # Toggle is_active
    old_status = user.is_active
    user.is_active = !user.is_active
    user.updated_at = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    # Save user
    try
        SearchLight.save!(user)
        action = user.is_active ? "activated" : "deactivated"
        @info "User $action" user_id=user.id.value username=user.username was_active=old_status is_active=user.is_active
    catch e
        @error "Failed to toggle user active status" exception=e
        return api_error("Failed to toggle user active status")
    end

    api_success(Dict(
        "user" => user_to_dict(user),
        "message" => user.is_active ? "User activated" : "User deactivated"
    ))
end

end # module AdminController
