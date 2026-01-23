# Tool Model
# Represents equipment/tools tracked in the QCI Equipment Status Dashboard

module Tools

using SearchLight
using SearchLight.Validation
using SearchLight.Validation.Validators
using Dates

export Tool, VALID_STATES, VALID_CRITICALITIES, validate_state, validate_criticality,
       find_active_tools, find_by_area, update_current_status!

"""Valid equipment states."""
const VALID_STATES = ["UP", "UP_WITH_ISSUES", "MAINTENANCE", "DOWN"]

"""Valid criticality levels."""
const VALID_CRITICALITIES = ["critical", "high", "medium", "low"]

"""
    Tool

Represents an equipment/tool in the fab.

# Fields
- `id::DbId`: Primary key
- `name::String`: Tool name/identifier
- `area::String`: Fab area location
- `bay::String`: Bay or line within area
- `criticality::String`: Criticality level (critical/high/medium/low)
- `is_active::Bool`: Whether tool is tracked (soft delete)
- `current_state::String`: Current status (UP/UP_WITH_ISSUES/MAINTENANCE/DOWN)
- `current_issue_description::String`: Current issue description (if any)
- `current_comment::String`: Current status comment
- `current_eta_to_up::String`: Estimated time to UP status (ISO 8601 datetime)
- `current_status_updated_at::String`: When current status was set (ISO 8601)
- `current_status_updated_by_user_id::DbId`: User who set current status
- `created_at::String`: Record creation timestamp (ISO 8601)
- `updated_at::String`: Last modification timestamp (ISO 8601)
"""
@kwdef mutable struct Tool <: AbstractModel
    id::DbId = DbId()
    name::String = ""
    area::String = ""
    bay::String = ""
    criticality::String = "medium"
    is_active::Bool = true
    current_state::String = "UP"
    current_issue_description::String = ""
    current_comment::String = ""
    current_eta_to_up::String = ""
    current_status_updated_at::String = ""
    current_status_updated_by_user_id::DbId = DbId()
    created_at::String = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    updated_at::String = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
end

"""
    validate_state(state::String) -> Bool

Check if a state is valid.
"""
function validate_state(state::String)::Bool
    return state in VALID_STATES
end

"""
    validate_criticality(criticality::String) -> Bool

Check if a criticality level is valid.
"""
function validate_criticality(criticality::String)::Bool
    return criticality in VALID_CRITICALITIES
end

"""
    is_down(tool::Tool) -> Bool

Check if tool is in DOWN state.
"""
function is_down(tool::Tool)::Bool
    return tool.current_state == "DOWN"
end

"""
    has_issues(tool::Tool) -> Bool

Check if tool has any issues (not fully UP).
"""
function has_issues(tool::Tool)::Bool
    return tool.current_state != "UP"
end

# Custom validators

"""Validator: check that state is valid"""
function is_valid_state(field::Symbol, m::Tool)::ValidationResult
    state = getfield(m, field)
    if state in VALID_STATES
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :is_valid_state, "must be one of: $(join(VALID_STATES, ", "))")
    end
end

"""Validator: check that criticality is valid"""
function is_valid_criticality(field::Symbol, m::Tool)::ValidationResult
    criticality = getfield(m, field)
    if criticality in VALID_CRITICALITIES
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :is_valid_criticality, "must be one of: $(join(VALID_CRITICALITIES, ", "))")
    end
end

"""Validator: check minimum string length"""
function has_min_length(field::Symbol, m::Tool, min_len::Int)::ValidationResult
    val = getfield(m, field)
    if length(val) >= min_len
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_min_length, "must be at least $min_len characters")
    end
end

"""Validator: check maximum string length"""
function has_max_length(field::Symbol, m::Tool, max_len::Int)::ValidationResult
    val = getfield(m, field)
    if length(val) <= max_len
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_max_length, "must not exceed $max_len characters")
    end
end

# Validation rules
function SearchLight.Validation.validator(::Tool)
    ModelValidator([
        # Name validations
        ValidationRule(:name, is_not_empty),
        ValidationRule(:name, has_min_length, (2,)),
        ValidationRule(:name, has_max_length, (100,)),

        # Area validations
        ValidationRule(:area, is_not_empty),
        ValidationRule(:area, has_max_length, (50,)),

        # Bay validations (can be empty)
        ValidationRule(:bay, has_max_length, (50,)),

        # State validation
        ValidationRule(:current_state, is_valid_state),

        # Criticality validation
        ValidationRule(:criticality, is_valid_criticality),
    ])
end

"""
    find_active_tools() -> Vector{Tool}

Find all active tools.
"""
function find_active_tools()::Vector{Tool}
    return SearchLight.find(Tool, SQLWhereExpression("is_active = ?", true))
end

"""
    find_by_area(area::String) -> Vector{Tool}

Find all active tools in a specific area.
"""
function find_by_area(area::String)::Vector{Tool}
    return SearchLight.find(Tool, SQLWhereExpression("area = ? AND is_active = ?", area, true))
end

"""
    find_down_tools() -> Vector{Tool}

Find all active tools that are DOWN.
"""
function find_down_tools()::Vector{Tool}
    return SearchLight.find(Tool, SQLWhereExpression("current_state = ? AND is_active = ?", "DOWN", true))
end

"""
    update_current_status!(tool::Tool, state::String, user_id::DbId;
                           issue_description::String="", comment::String="", eta_to_up::String="") -> Tool

Update the current status fields on a tool.
"""
function update_current_status!(tool::Tool, state::String, user_id::DbId;
                                issue_description::String="", comment::String="", eta_to_up::String="")::Tool
    if !validate_state(state)
        error("Invalid state: $state. Must be one of: $(join(VALID_STATES, ", "))")
    end

    timestamp = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    tool.current_state = state
    tool.current_issue_description = issue_description
    tool.current_comment = comment
    tool.current_eta_to_up = state == "UP" ? "" : eta_to_up  # Clear ETA if UP
    tool.current_status_updated_at = timestamp
    tool.current_status_updated_by_user_id = user_id
    tool.updated_at = timestamp

    SearchLight.save!(tool)
    return tool
end

end # module Tools
