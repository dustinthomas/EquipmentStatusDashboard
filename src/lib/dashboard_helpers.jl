# Dashboard Helper Functions
# Pure utility functions for the dashboard that have no dependencies on App module
# These can be tested independently without loading the full application

module DashboardHelpers

export state_sort_order, truncate_text, format_timestamp, state_css_class, state_display_text

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

end # module DashboardHelpers
