# Dashboard Helper Functions
# Pure utility functions for the dashboard that have no dependencies on App module
# These can be tested independently without loading the full application

module DashboardHelpers

using Dates

export state_sort_order, truncate_text, format_timestamp, state_css_class, state_display_text
export is_status_stale, get_stale_threshold_hours

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
    get_stale_threshold_hours() -> Int

Get the stale status threshold in hours from environment variable.
Default is 8 hours if not set.
"""
function get_stale_threshold_hours()::Int
    threshold_str = get(ENV, "STALE_THRESHOLD_HOURS", "8")
    try
        threshold = parse(Int, threshold_str)
        return max(1, threshold)  # Ensure at least 1 hour
    catch
        return 8  # Default to 8 hours on parse error
    end
end

"""
    is_status_stale(timestamp::String) -> Bool

Check if a status timestamp is stale (older than threshold hours).
Returns false if timestamp is empty or invalid.

The threshold is configured via STALE_THRESHOLD_HOURS environment variable (default: 8).
"""
function is_status_stale(timestamp::String)::Bool
    if isempty(timestamp)
        return false
    end

    try
        # Parse ISO 8601 timestamp (yyyy-mm-ddTHH:MM:SS format)
        # Handle timestamps with or without fractional seconds
        ts_str = timestamp
        if contains(ts_str, ".")
            ts_str = split(ts_str, ".")[1]  # Remove fractional seconds
        end
        if length(ts_str) == 19
            ts = DateTime(ts_str, "yyyy-mm-ddTHH:MM:SS")
        elseif length(ts_str) == 16
            ts = DateTime(ts_str, "yyyy-mm-ddTHH:MM")
        else
            return false
        end

        threshold_hours = get_stale_threshold_hours()
        cutoff = now() - Hour(threshold_hours)
        return ts < cutoff
    catch e
        # Invalid timestamp format - not stale
        return false
    end
end

end # module DashboardHelpers
