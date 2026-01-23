# DashboardController
# Handles the main equipment status dashboard view

module DashboardController

using Genie
using Genie.Renderer.Html: html
using Genie.Requests: getpayload
using SearchLight
using Logging

# Import models
include(joinpath(@__DIR__, "..", "models", "Tool.jl"))
include(joinpath(@__DIR__, "..", "models", "User.jl"))
using .Tools: Tool, find_active_tools, VALID_STATES
using .Users: User

# Import auth helpers
using Main.AuthHelpers: current_user

export index, state_display_text

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
    state_sort_order(state::String) -> Int

Return sort priority for states (DOWN first, then MAINTENANCE, UP_WITH_ISSUES, UP).
Lower numbers sort first.
"""
function state_sort_order(state::String)::Int
    order = Dict(
        "DOWN" => 1,
        "MAINTENANCE" => 2,
        "UP_WITH_ISSUES" => 3,
        "UP" => 4
    )
    return get(order, state, 5)
end

"""
    truncate_text(text::String, max_length::Int = 50) -> String

Truncate text to max_length characters, adding ellipsis if truncated.
"""
function truncate_text(text::String, max_length::Int = 50)::String
    if length(text) <= max_length
        return text
    end
    return text[1:max_length-3] * "..."
end

"""
    format_timestamp(timestamp::String) -> String

Format an ISO 8601 timestamp for display (yyyy-mm-dd HH:MM).
Returns empty string if timestamp is empty.
"""
function format_timestamp(timestamp::String)::String
    if isempty(timestamp)
        return ""
    end
    # ISO format: yyyy-mm-ddTHH:MM:SS
    # Display: yyyy-mm-dd HH:MM
    try
        if length(timestamp) >= 16
            return timestamp[1:10] * " " * timestamp[12:16]
        else
            return timestamp
        end
    catch
        return timestamp
    end
end

"""
    state_css_class(state::String) -> String

Return the CSS class for a given state.
"""
function state_css_class(state::String)::String
    classes = Dict(
        "UP" => "status-up",
        "UP_WITH_ISSUES" => "status-up-with-issues",
        "MAINTENANCE" => "status-maintenance",
        "DOWN" => "status-down"
    )
    return get(classes, state, "")
end

"""
    state_display_text(state::String) -> String

Return display-friendly text for a state.
"""
function state_display_text(state::String)::String
    display = Dict(
        "UP" => "Up",
        "UP_WITH_ISSUES" => "Up with Issues",
        "MAINTENANCE" => "Maintenance",
        "DOWN" => "Down"
    )
    return get(display, state, state)
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
    build_query_string(params::Dict; exclude::Vector{String}=String[]) -> String

Build a URL query string from parameters, optionally excluding certain keys.
"""
function build_query_string(params::Dict; exclude::Vector{String}=String[])::String
    filtered = filter(kv -> !(string(kv[1]) in exclude) && !isempty(string(kv[2])), params)
    if isempty(filtered)
        return ""
    end
    return "?" * join(["$(k)=$(v)" for (k, v) in filtered], "&")
end

"""
    get_sort_url(current_params::Dict, column::String, current_sort::String, current_dir::String) -> String

Generate URL for column sort link. Toggles direction if clicking same column.
"""
function get_sort_url(current_params::Dict, column::String, current_sort::String, current_dir::String)::String
    new_params = copy(current_params)
    new_params["sort"] = column

    # Toggle direction if clicking same column
    if column == current_sort
        new_params["dir"] = (current_dir == "asc") ? "desc" : "asc"
    else
        # Default direction for new column
        new_params["dir"] = "asc"
    end

    return "/dashboard" * build_query_string(new_params)
end

"""
    index()

Display the main equipment status dashboard.
GET /dashboard
"""
function index()
    user = current_user()

    # Get query parameters
    params = getpayload()
    state_filter = get(params, :state, "")
    area_filter = get(params, :area, "")
    search = get(params, :search, "")
    sort_col = get(params, :sort, DEFAULT_SORT_COLUMN)
    sort_dir = get(params, :dir, DEFAULT_SORT_DIR)

    # Get all active tools
    all_tools = find_active_tools()

    # Get unique areas for filter dropdown (before filtering)
    areas = get_unique_areas(all_tools)

    # Apply filters
    filtered_tools = filter_tools(all_tools, string(state_filter), string(area_filter), string(search))

    # Apply sorting
    sorted_tools = sort_tools(filtered_tools, string(sort_col), string(sort_dir))

    # Build current params dict for URL building
    current_params = Dict{String, String}()
    if !isempty(string(state_filter))
        current_params["state"] = string(state_filter)
    end
    if !isempty(string(area_filter))
        current_params["area"] = string(area_filter)
    end
    if !isempty(string(search))
        current_params["search"] = string(search)
    end
    if !isempty(string(sort_col)) && string(sort_col) != DEFAULT_SORT_COLUMN
        current_params["sort"] = string(sort_col)
    end
    if !isempty(string(sort_dir)) && string(sort_dir) != DEFAULT_SORT_DIR
        current_params["dir"] = string(sort_dir)
    end

    # Generate sort URLs for column headers
    sort_urls = Dict(
        "name" => get_sort_url(current_params, "name", string(sort_col), string(sort_dir)),
        "area" => get_sort_url(current_params, "area", string(sort_col), string(sort_dir)),
        "state" => get_sort_url(current_params, "state", string(sort_col), string(sort_dir)),
        "updated" => get_sort_url(current_params, "updated", string(sort_col), string(sort_dir)),
        "eta" => get_sort_url(current_params, "eta", string(sort_col), string(sort_dir))
    )

    # Prepare tool data for the view
    tool_data = [
        Dict(
            :id => t.id.value,
            :name => t.name,
            :area => t.area,
            :state => t.current_state,
            :state_display => state_display_text(t.current_state),
            :state_class => state_css_class(t.current_state),
            :issue => truncate_text(t.current_issue_description),
            :full_issue => t.current_issue_description,
            :eta => format_timestamp(t.current_eta_to_up),
            :eta_raw => t.current_eta_to_up,
            :updated_at => format_timestamp(t.current_status_updated_at),
            :updated_by => get_user_name(t.current_status_updated_by_user_id)
        )
        for t in sorted_tools
    ]

    # State display labels for dropdown
    state_labels = Dict(
        "UP" => "Up",
        "UP_WITH_ISSUES" => "Up with Issues",
        "MAINTENANCE" => "Maintenance",
        "DOWN" => "Down"
    )

    html(:dashboard, :index;
         layout = :app,
         page_title = "Dashboard",
         current_user = user,
         tools = tool_data,
         tool_count = length(sorted_tools),
         total_count = length(all_tools),
         states = VALID_STATES,
         state_labels = state_labels,
         areas = areas,
         state_filter = string(state_filter),
         area_filter = string(area_filter),
         search = string(search),
         sort_col = string(sort_col),
         sort_dir = string(sort_dir),
         sort_urls = sort_urls)
end

end # module DashboardController
