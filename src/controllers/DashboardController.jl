# DashboardController
# Handles the main equipment status dashboard view

module DashboardController

using Genie
using Genie.Renderer.Html: html
using SearchLight
using Logging

# Import models
include(joinpath(@__DIR__, "..", "models", "Tool.jl"))
include(joinpath(@__DIR__, "..", "models", "User.jl"))
using .Tools: Tool, find_active_tools, VALID_STATES
using .Users: User

# Import auth helpers
using Main.AuthHelpers: current_user

export index

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
    index()

Display the main equipment status dashboard.
GET /dashboard
"""
function index()
    user = current_user()

    # Get all active tools
    tools = find_active_tools()

    # Sort: DOWN first, then by state priority, then by ETA (non-empty first), then by name
    sort!(tools, by = t -> (
        state_sort_order(t.current_state),
        isempty(t.current_eta_to_up) ? 1 : 0,  # Tools with ETA first
        t.current_eta_to_up,
        t.name
    ))

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
            :updated_at => format_timestamp(t.current_status_updated_at),
            :updated_by => get_user_name(t.current_status_updated_by_user_id)
        )
        for t in tools
    ]

    html(:dashboard, :index;
         layout = :app,
         page_title = "Dashboard",
         current_user = user,
         tools = tool_data,
         tool_count = length(tools))
end

end # module DashboardController
