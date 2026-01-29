# DashboardController
# Handles JSON API endpoints for the equipment status dashboard

module DashboardController

using Genie
using Genie.Renderer.Json: json
using Genie.Requests: getpayload
using SearchLight
using Logging

# Import models from parent App module
import ..App: Tool, User, StatusEvent
using ..App.Tools: find_active_tools, VALID_STATES, validate_state, update_current_status!
using ..App.StatusEvents: create_status_event!, find_by_tool_id, find_by_tool_id_in_range

# Import auth helpers (also part of App module)
using ..App.AuthHelpers: current_user

# Import API helpers for consistent error responses
include(joinpath(@__DIR__, "..", "lib", "api_helpers.jl"))
using .ApiHelpers: api_success, api_error, api_bad_request, api_not_found

# Import dashboard helpers (pure utility functions)
include(joinpath(@__DIR__, "..", "lib", "dashboard_helpers.jl"))
using .DashboardHelpers: state_sort_order, truncate_text, format_timestamp, state_css_class, state_display_text

export state_display_text, api_index, api_show, api_update_status, api_history, api_history_csv

# Valid sort columns and their field mappings
const SORT_COLUMNS = Dict(
    "name" => :name,
    "area" => :area,
    "state" => :current_state,
    "updated" => :current_status_updated_at,
    "eta" => :current_eta_to_up
)

# Default sort settings
const DEFAULT_SORT_COLUMN = "state"
const DEFAULT_SORT_DIR = "asc"

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
    get_unique_areas(tools::Vector{Tool}) -> Vector{String}

Extract unique area values from tools, sorted alphabetically.
"""
function get_unique_areas(tools::Vector{Tool})::Vector{String}
    areas = unique([t.area for t in tools])
    sort!(areas)
    return areas
end

"""
    filter_tools(tools::Vector{Tool}, state_filter::String, area_filter::String, search::String) -> Vector{Tool}

Filter tools by state, area, and name search text.
"""
function filter_tools(tools::Vector{Tool}, state_filter::String, area_filter::String, search::String)::Vector{Tool}
    filtered = tools

    # Filter by state
    if !isempty(state_filter) && state_filter != "all"
        filtered = filter(t -> t.current_state == state_filter, filtered)
    end

    # Filter by area
    if !isempty(area_filter) && area_filter != "all"
        filtered = filter(t -> t.area == area_filter, filtered)
    end

    # Filter by name search (case-insensitive)
    if !isempty(search)
        search_lower = lowercase(search)
        filtered = filter(t -> occursin(search_lower, lowercase(t.name)), filtered)
    end

    return collect(filtered)
end

"""
    sort_tools(tools::Vector{Tool}, sort_col::String, sort_dir::String) -> Vector{Tool}

Sort tools by the specified column and direction.
"""
function sort_tools(tools::Vector{Tool}, sort_col::String, sort_dir::String)::Vector{Tool}
    # Validate sort column
    if !haskey(SORT_COLUMNS, sort_col)
        sort_col = DEFAULT_SORT_COLUMN
    end

    # Validate sort direction
    if sort_dir != "asc" && sort_dir != "desc"
        sort_dir = DEFAULT_SORT_DIR
    end

    # Get the field symbol
    field = SORT_COLUMNS[sort_col]

    # Create sort key function based on column
    if sort_col == "state"
        # Special sorting for state: DOWN first, UP last
        key_fn = t -> state_sort_order(t.current_state)
    elseif sort_col == "eta"
        # Special sorting for ETA: empty values last
        key_fn = t -> (isempty(t.current_eta_to_up) ? 1 : 0, t.current_eta_to_up)
    elseif sort_col == "updated"
        # Sort by timestamp, empty values last
        key_fn = t -> (isempty(t.current_status_updated_at) ? 1 : 0, t.current_status_updated_at)
    else
        # Default: sort by the field value
        key_fn = t -> lowercase(getfield(t, field))
    end

    # Sort the tools
    sorted = sort(tools, by = key_fn, rev = (sort_dir == "desc"))

    return sorted
end

"""
    api_index()

JSON API endpoint for listing tools with filter/sort support.
GET /api/tools

Query Parameters:
- state: Filter by state (UP, UP_WITH_ISSUES, MAINTENANCE, DOWN)
- area: Filter by area
- search: Search by name (case-insensitive)
- sort: Sort column (name, area, state, updated, eta)
- dir: Sort direction (asc, desc)

Returns JSON array of tool objects.
"""
function api_index()
    # Get query parameters
    params = getpayload()
    state_filter = string(get(params, :state, ""))
    area_filter = string(get(params, :area, ""))
    search = string(get(params, :search, ""))
    sort_col = string(get(params, :sort, DEFAULT_SORT_COLUMN))
    sort_dir = string(get(params, :dir, DEFAULT_SORT_DIR))

    # Get all active tools
    all_tools = find_active_tools()

    # Get unique areas for filter dropdown (before filtering)
    areas = get_unique_areas(all_tools)

    # Apply filters
    filtered_tools = filter_tools(all_tools, state_filter, area_filter, search)

    # Apply sorting
    sorted_tools = sort_tools(filtered_tools, sort_col, sort_dir)

    # Prepare tool data for JSON response
    tool_data = [
        Dict(
            "id" => t.id.value,
            "name" => t.name,
            "area" => t.area,
            "bay" => t.bay,
            "criticality" => t.criticality,
            "state" => t.current_state,
            "state_display" => state_display_text(t.current_state),
            "state_class" => state_css_class(t.current_state),
            "issue_description" => t.current_issue_description,
            "comment" => t.current_comment,
            "eta_to_up" => t.current_eta_to_up,
            "eta_to_up_formatted" => format_timestamp(t.current_eta_to_up),
            "status_updated_at" => t.current_status_updated_at,
            "status_updated_at_formatted" => format_timestamp(t.current_status_updated_at),
            "status_updated_by" => get_user_name(t.current_status_updated_by_user_id)
        )
        for t in sorted_tools
    ]

    # Return JSON response with metadata
    api_success(Dict(
        "tools" => tool_data,
        "meta" => Dict(
            "total" => length(all_tools),
            "filtered" => length(sorted_tools),
            "areas" => areas,
            "states" => VALID_STATES
        )
    ))
end

"""
    api_show(id::Int)

JSON API endpoint for fetching a single tool's details.
GET /api/tools/:id

Returns JSON object with full tool details including:
- name, area, bay, criticality
- current state, issue description, comment, ETA
- last updated timestamp and user name

Returns 404 if tool not found or inactive.
"""
function api_show()
    # Get the tool ID from the route parameters
    params = Genie.Router.params()
    id_str = get(params, :id, "")

    # Validate ID parameter
    local id::Int
    try
        id = parse(Int, string(id_str))
    catch
        return api_error("Invalid tool ID", status=400)
    end

    # Find the tool
    tool = SearchLight.findone(Tool; id = id)

    # Check if tool exists and is active
    if tool === nothing
        return api_error("Tool not found", status=404)
    end

    if !tool.is_active
        return api_error("Tool not found", status=404)
    end

    # Prepare tool data for JSON response
    tool_data = Dict(
        "id" => tool.id.value,
        "name" => tool.name,
        "area" => tool.area,
        "bay" => tool.bay,
        "criticality" => tool.criticality,
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
        "is_active" => tool.is_active,
        "created_at" => tool.created_at,
        "updated_at" => tool.updated_at
    )

    api_success(Dict("tool" => tool_data))
end

"""
    api_update_status()

JSON API endpoint for updating tool status.
POST /api/tools/:id/status

Request body (JSON):
- state: Required. One of: UP, UP_WITH_ISSUES, MAINTENANCE, DOWN
- issue_description: Optional. Description of the issue
- comment: Optional. Additional comment
- eta_to_up: Optional. Estimated time to UP (ISO 8601 datetime). Cleared if state is UP.

Creates a StatusEvent record for audit trail and updates Tool's current_* fields.
Sets current_status_updated_by_user_id to the logged-in user.

Returns updated tool JSON on success.
Returns 400 with validation errors on invalid input.
Returns 404 if tool not found or inactive.
"""
function api_update_status()
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

    # Check if tool exists and is active
    if tool === nothing
        return api_not_found("Tool not found")
    end

    if !tool.is_active
        return api_not_found("Tool not found")
    end

    # Parse JSON request body
    local payload::Dict
    try
        payload = Genie.Requests.jsonpayload()
        if payload === nothing
            return api_bad_request("Request body is required")
        end
    catch e
        @error "Failed to parse JSON payload" exception=e
        return api_bad_request("Invalid JSON payload")
    end

    # Extract and validate state (required)
    state = get(payload, "state", nothing)
    if state === nothing || isempty(string(state))
        return api_bad_request("State is required")
    end

    state = string(state)
    if !validate_state(state)
        return api_bad_request("Invalid state. Must be one of: $(join(VALID_STATES, ", "))")
    end

    # Extract optional fields
    issue_description = string(get(payload, "issue_description", ""))
    comment = string(get(payload, "comment", ""))
    eta_to_up = string(get(payload, "eta_to_up", ""))

    # Get current user
    user = current_user()
    if user === nothing
        return api_error("User session invalid", status=500)
    end

    # Create StatusEvent for audit trail
    try
        create_status_event!(
            tool.id,
            user.id,
            state;
            issue_description = issue_description,
            comment = comment,
            eta_to_up = eta_to_up
        )
    catch e
        @error "Failed to create status event" exception=e
        return api_error("Failed to create status event")
    end

    # Update tool's current status fields
    try
        update_current_status!(
            tool,
            state,
            user.id;
            issue_description = issue_description,
            comment = comment,
            eta_to_up = eta_to_up
        )
    catch e
        @error "Failed to update tool status" exception=e
        return api_error("Failed to update tool status")
    end

    # Prepare updated tool data for JSON response
    tool_data = Dict(
        "id" => tool.id.value,
        "name" => tool.name,
        "area" => tool.area,
        "bay" => tool.bay,
        "criticality" => tool.criticality,
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
        "is_active" => tool.is_active,
        "created_at" => tool.created_at,
        "updated_at" => tool.updated_at
    )

    api_success(Dict("tool" => tool_data))
end

"""
    api_history()

JSON API endpoint for fetching tool status history.
GET /api/tools/:id/history

Query Parameters:
- from: Optional. Start date for filtering (ISO 8601 format)
- to: Optional. End date for filtering (ISO 8601 format)

Returns JSON array of status events ordered by created_at descending (newest first).
Each event includes: timestamp, user name, state, issue, comment, ETA.

Returns 404 if tool not found or inactive.
"""
function api_history()
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

    # Check if tool exists and is active
    if tool === nothing
        return api_not_found("Tool not found")
    end

    if !tool.is_active
        return api_not_found("Tool not found")
    end

    # Get query parameters for date range filtering
    query_params = getpayload()
    from_date = string(get(query_params, :from, ""))
    to_date = string(get(query_params, :to, ""))

    # Fetch status events
    local events::Vector{StatusEvent}
    if !isempty(from_date) && !isempty(to_date)
        events = find_by_tool_id_in_range(tool.id, from_date, to_date)
    elseif !isempty(from_date)
        # Only from date specified - use high end date
        events = find_by_tool_id_in_range(tool.id, from_date, "9999-12-31T23:59:59")
    elseif !isempty(to_date)
        # Only to date specified - use low start date
        events = find_by_tool_id_in_range(tool.id, "0000-01-01T00:00:00", to_date)
    else
        # No date range - get all events
        events = find_by_tool_id(tool.id)
    end

    # Prepare event data for JSON response
    event_data = [
        Dict(
            "id" => e.id.value,
            "created_at" => e.created_at,
            "created_at_formatted" => format_timestamp(e.created_at),
            "state" => e.state,
            "state_display" => state_display_text(e.state),
            "state_class" => state_css_class(e.state),
            "issue_description" => e.issue_description,
            "comment" => e.comment,
            "eta_to_up" => e.eta_to_up,
            "eta_to_up_formatted" => format_timestamp(e.eta_to_up),
            "created_by_user_id" => e.created_by_user_id.value,
            "created_by_user_name" => get_user_name(e.created_by_user_id)
        )
        for e in events
    ]

    # Return JSON response with metadata
    api_success(Dict(
        "tool_id" => tool.id.value,
        "tool_name" => tool.name,
        "events" => event_data,
        "meta" => Dict(
            "count" => length(events),
            "from" => from_date,
            "to" => to_date
        )
    ))
end

"""
    api_history_csv()

CSV download endpoint for tool status history.
GET /api/tools/:id/history.csv

Query Parameters:
- from: Optional. Start date for filtering (ISO 8601 format)
- to: Optional. End date for filtering (ISO 8601 format)

Returns CSV file with headers: Timestamp,User,State,Issue,Comment,ETA
Events ordered by created_at descending (newest first).

Returns 404 if tool not found or inactive.
"""
function api_history_csv()
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

    # Check if tool exists and is active
    if tool === nothing
        return api_not_found("Tool not found")
    end

    if !tool.is_active
        return api_not_found("Tool not found")
    end

    # Get query parameters for date range filtering
    query_params = getpayload()
    from_date = string(get(query_params, :from, ""))
    to_date = string(get(query_params, :to, ""))

    # Fetch status events
    local events::Vector{StatusEvent}
    if !isempty(from_date) && !isempty(to_date)
        events = find_by_tool_id_in_range(tool.id, from_date, to_date)
    elseif !isempty(from_date)
        events = find_by_tool_id_in_range(tool.id, from_date, "9999-12-31T23:59:59")
    elseif !isempty(to_date)
        events = find_by_tool_id_in_range(tool.id, "0000-01-01T00:00:00", to_date)
    else
        events = find_by_tool_id(tool.id)
    end

    # Build CSV content
    csv_lines = String[]

    # Header row
    push!(csv_lines, "Timestamp,User,State,Issue,Comment,ETA")

    # Data rows
    for e in events
        # Escape CSV fields (double quotes and wrap in quotes if needed)
        timestamp = e.created_at
        user_name = escape_csv_field(get_user_name(e.created_by_user_id))
        state = e.state
        issue = escape_csv_field(e.issue_description)
        comment = escape_csv_field(e.comment)
        eta = e.eta_to_up

        push!(csv_lines, "$timestamp,$user_name,$state,$issue,$comment,$eta")
    end

    csv_content = join(csv_lines, "\n")

    # Generate filename with tool name and date
    safe_tool_name = replace(tool.name, r"[^a-zA-Z0-9_-]" => "_")
    filename = "$(safe_tool_name)_history.csv"

    # Return CSV response with download headers
    return Genie.Renderer.respond(
        csv_content,
        200,
        Dict(
            "Content-Type" => "text/csv",
            "Content-Disposition" => "attachment; filename=\"$filename\""
        )
    )
end

"""
    escape_csv_field(value::String) -> String

Escape a CSV field value by wrapping in quotes and escaping internal quotes.
"""
function escape_csv_field(value::String)::String
    if isempty(value)
        return ""
    end
    # If contains comma, newline, or quote, wrap in quotes and escape internal quotes
    if occursin(',', value) || occursin('\n', value) || occursin('"', value)
        escaped = replace(value, "\"" => "\"\"")
        return "\"$escaped\""
    end
    return value
end

end # module DashboardController
