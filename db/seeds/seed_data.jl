# Seed Data Script
# Creates initial admin user and sample tools for development/testing
#
# Usage:
#   julia --project=. -e 'include("db/seeds/seed_data.jl"); seed!()'
#
# This script is idempotent - it can be run multiple times safely.
# Existing records with matching identifiers will be skipped.

# SHA is a stdlib module, need to import it properly
import SHA: sha256
using Dates

# Include the model modules
include(joinpath(@__DIR__, "..", "..", "src", "models", "User.jl"))
include(joinpath(@__DIR__, "..", "..", "src", "models", "Tool.jl"))
include(joinpath(@__DIR__, "..", "..", "src", "models", "StatusEvent.jl"))

using .Users
using .Tools
using .StatusEvents

using SearchLight

"""
    seed_hash_password(password::String) -> String

Hash a password using SHA256 (compatible with GenieAuthentication).
Used internally by seed functions to avoid naming conflicts with AuthCore.
"""
function seed_hash_password(password::String)::String
    return bytes2hex(sha256(password))
end

"""
    seed_admin_user!() -> Union{User, Nothing}

Create the initial admin user if it doesn't already exist.
Returns the user if created, nothing if already exists.
"""
function seed_admin_user!()::Union{User, Nothing}
    # Check if admin user already exists
    existing = Users.find_by_username("admin")
    if existing !== nothing
        @info "Admin user already exists, skipping"
        return nothing
    end

    timestamp = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    admin = User(
        username = "admin",
        password_hash = seed_hash_password("changeme"),
        name = "System Administrator",
        role = "admin",
        is_active = true,
        created_at = timestamp,
        updated_at = timestamp
    )

    SearchLight.save!(admin)
    @info "Created admin user: $(admin.username)"
    return admin
end

"""
    seed_sample_tools!() -> Vector{Tool}

Create sample fabrication tools with different areas and states.
Returns the list of tools created (skips existing ones).
"""
function seed_sample_tools!()::Vector{Tool}
    # Sample tools representing different fab areas and states
    sample_tools = [
        (
            name = "CVD-01",
            area = "Thin Film",
            bay = "Bay A",
            criticality = "critical",
            state = "UP",
            issue = "",
            comment = "Running optimally"
        ),
        (
            name = "ETCH-01",
            area = "Etch",
            bay = "Bay B",
            criticality = "critical",
            state = "DOWN",
            issue = "RF generator failure",
            comment = "Parts on order, ETA 48 hours"
        ),
        (
            name = "LITH-01",
            area = "Lithography",
            bay = "Bay C",
            criticality = "high",
            state = "UP_WITH_ISSUES",
            issue = "Focus drift observed",
            comment = "Monitoring closely, may need calibration"
        ),
        (
            name = "IMPL-01",
            area = "Implant",
            bay = "Bay D",
            criticality = "high",
            state = "MAINTENANCE",
            issue = "Scheduled PM",
            comment = "Weekly preventive maintenance"
        ),
        (
            name = "CLEAN-01",
            area = "Wet Clean",
            bay = "Bay A",
            criticality = "medium",
            state = "UP",
            issue = "",
            comment = ""
        )
    ]

    created_tools = Tool[]
    timestamp = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS")

    for tool_data in sample_tools
        # Check if tool already exists by name
        existing = SearchLight.find(Tool, SQLWhereExpression("name = ?", tool_data.name))
        if !isempty(existing)
            @info "Tool $(tool_data.name) already exists, skipping"
            continue
        end

        tool = Tool(
            name = tool_data.name,
            area = tool_data.area,
            bay = tool_data.bay,
            criticality = tool_data.criticality,
            is_active = true,
            current_state = tool_data.state,
            current_issue_description = tool_data.issue,
            current_comment = tool_data.comment,
            current_eta_to_up = tool_data.state == "DOWN" ? "2026-01-24T12:00:00" : "",
            current_status_updated_at = timestamp,
            created_at = timestamp,
            updated_at = timestamp
        )

        SearchLight.save!(tool)
        push!(created_tools, tool)
        @info "Created tool: $(tool.name) ($(tool.area), $(tool.current_state))"
    end

    return created_tools
end

"""
    seed!() -> Nothing

Run all seed functions to populate the database with initial data.
This function is idempotent and can be safely run multiple times.
"""
function seed!()
    @info "Starting database seeding..."

    # Seed admin user
    seed_admin_user!()

    # Seed sample tools
    tools = seed_sample_tools!()

    @info "Seeding complete. Created $(length(tools)) new tools."
    nothing
end

# Export the main function
export seed!, seed_admin_user!, seed_sample_tools!, seed_hash_password
