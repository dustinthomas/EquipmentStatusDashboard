# StatusEvent Model
# Represents immutable audit trail of equipment status changes

module StatusEvents

using SearchLight
using SearchLight.Validation
using SearchLight.Validation.Validators
using Dates

export StatusEvent, VALID_STATES, validate_state, find_by_tool_id, find_by_tool_id_in_range,
       create_status_event!

"""Valid equipment states (same as Tool model)."""
const VALID_STATES = ["UP", "UP_WITH_ISSUES", "MAINTENANCE", "DOWN"]

"""
    StatusEvent

Represents a single status change event for a tool (audit trail).
StatusEvents are immutable - they are never modified or deleted.

# Fields
- `id::DbId`: Primary key
- `tool_id::DbId`: Foreign key to Tool
- `state::String`: Status at time of event (UP/UP_WITH_ISSUES/MAINTENANCE/DOWN)
- `issue_description::String`: Description of issue (if any)
- `comment::String`: Additional comment from operator
- `eta_to_up::String`: Estimated time to UP status (ISO 8601 datetime)
- `created_by_user_id::DbId`: Foreign key to User who created this event
- `created_at::String`: When this event was recorded (ISO 8601)
"""
@kwdef mutable struct StatusEvent <: AbstractModel
    id::DbId = DbId()
    tool_id::DbId = DbId()
    state::String = "UP"
    issue_description::String = ""
    comment::String = ""
    eta_to_up::String = ""
    created_by_user_id::DbId = DbId()
    created_at::String = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
end

"""
    validate_state(state::String) -> Bool

Check if a state is valid.
"""
function validate_state(state::String)::Bool
    return state in VALID_STATES
end

# Custom validators

"""Validator: check that state is valid"""
function is_valid_state(field::Symbol, m::StatusEvent)::ValidationResult
    state = getfield(m, field)
    if state in VALID_STATES
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :is_valid_state, "must be one of: $(join(VALID_STATES, ", "))")
    end
end

"""Validator: check that tool_id is set"""
function has_tool_id(field::Symbol, m::StatusEvent)::ValidationResult
    tool_id = getfield(m, field)
    if tool_id.value !== nothing
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_tool_id, "must be set")
    end
end

"""Validator: check that created_by_user_id is set"""
function has_user_id(field::Symbol, m::StatusEvent)::ValidationResult
    user_id = getfield(m, field)
    if user_id.value !== nothing
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_user_id, "must be set")
    end
end

"""Validator: check maximum string length"""
function has_max_length(field::Symbol, m::StatusEvent, max_len::Int)::ValidationResult
    val = getfield(m, field)
    if length(val) <= max_len
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_max_length, "must not exceed $max_len characters")
    end
end

# Validation rules
function SearchLight.Validation.validator(::StatusEvent)
    ModelValidator([
        # State validation
        ValidationRule(:state, is_valid_state),

        # Foreign key validations
        ValidationRule(:tool_id, has_tool_id),
        ValidationRule(:created_by_user_id, has_user_id),

        # Text field length limits
        ValidationRule(:issue_description, has_max_length, (2000,)),
        ValidationRule(:comment, has_max_length, (2000,)),
    ])
end

"""
    find_by_tool_id(tool_id::DbId) -> Vector{StatusEvent}

Find all status events for a tool, ordered by created_at descending (newest first).
Note: Results are sorted in Julia after retrieval since SearchLight doesn't directly
support ordered queries with SQLWhereExpression.
"""
function find_by_tool_id(tool_id::DbId)::Vector{StatusEvent}
    events = SearchLight.find(StatusEvent, SQLWhereExpression("tool_id = ?", tool_id.value))
    # Sort by created_at descending (newest first)
    return sort(events, by = e -> e.created_at, rev = true)
end

"""
    find_by_tool_id_in_range(tool_id::DbId, from_date::String, to_date::String) -> Vector{StatusEvent}

Find status events for a tool within a date range, ordered by created_at descending.
Dates should be in ISO 8601 format (YYYY-MM-DDTHH:MM:SS).
"""
function find_by_tool_id_in_range(tool_id::DbId, from_date::String, to_date::String)::Vector{StatusEvent}
    events = SearchLight.find(StatusEvent,
        SQLWhereExpression("tool_id = ? AND created_at >= ? AND created_at <= ?",
            tool_id.value, from_date, to_date))
    # Sort by created_at descending (newest first)
    return sort(events, by = e -> e.created_at, rev = true)
end

"""
    find_latest_by_tool_id(tool_id::DbId) -> Union{StatusEvent, Nothing}

Find the most recent status event for a tool.
"""
function find_latest_by_tool_id(tool_id::DbId)::Union{StatusEvent, Nothing}
    events = find_by_tool_id(tool_id)  # Already sorted newest first
    return isempty(events) ? nothing : first(events)
end

"""
    find_by_user_id(user_id::DbId) -> Vector{StatusEvent}

Find all status events created by a specific user.
"""
function find_by_user_id(user_id::DbId)::Vector{StatusEvent}
    events = SearchLight.find(StatusEvent,
        SQLWhereExpression("created_by_user_id = ?", user_id.value))
    # Sort by created_at descending (newest first)
    return sort(events, by = e -> e.created_at, rev = true)
end

"""
    create_status_event!(tool_id::DbId, user_id::DbId, state::String;
                         issue_description::String="", comment::String="", eta_to_up::String="") -> StatusEvent

Create and save a new status event.
"""
function create_status_event!(tool_id::DbId, user_id::DbId, state::String;
                              issue_description::String="", comment::String="", eta_to_up::String="")::StatusEvent
    if !validate_state(state)
        error("Invalid state: $state. Must be one of: $(join(VALID_STATES, ", "))")
    end

    # If state is UP, clear ETA
    actual_eta = state == "UP" ? "" : eta_to_up

    event = StatusEvent(
        tool_id = tool_id,
        state = state,
        issue_description = issue_description,
        comment = comment,
        eta_to_up = actual_eta,
        created_by_user_id = user_id,
        created_at = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    )

    SearchLight.save!(event)
    return event
end

end # module StatusEvents
