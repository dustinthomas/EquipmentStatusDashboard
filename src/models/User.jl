# User Model
# Represents authenticated users of the QCI Equipment Status Dashboard

module Users

using SearchLight
using SearchLight.Validation
using SearchLight.Validation.Validators
using Dates

export User, VALID_ROLES, validate_role, is_admin, is_active_user
export find_by_username, find_active_admins, find_all_users, update_last_login!

"""Valid user roles for the system."""
const VALID_ROLES = ["admin", "operator"]

"""
    User

Represents a user account in the system.

# Fields
- `id::DbId`: Primary key
- `username::String`: Unique login identifier
- `password_hash::String`: SHA256 hashed password (hex-encoded)
- `name::String`: Display name
- `role::String`: User role ("admin" or "operator")
- `is_active::Bool`: Whether the user can log in
- `last_login_at::String`: Last successful login timestamp (ISO 8601 format)
- `created_at::String`: Account creation timestamp (ISO 8601 format)
- `updated_at::String`: Last modification timestamp (ISO 8601 format)
"""
@kwdef mutable struct User <: AbstractModel
    id::DbId = DbId()
    username::String = ""
    password_hash::String = ""
    name::String = ""
    role::String = "operator"
    is_active::Bool = true
    last_login_at::String = ""
    created_at::String = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    updated_at::String = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
end

# Note: SearchLight auto-generates table name as "users" (pluralized, lowercase)
# and uses "id" as default primary key, so no need to override

"""
    validate_role(role::String) -> Bool

Check if a role is valid.
"""
function validate_role(role::String)::Bool
    return role in VALID_ROLES
end

"""
    is_admin(user::User) -> Bool

Check if user has admin role.
"""
function is_admin(user::User)::Bool
    return user.role == "admin"
end

"""
    is_active_user(user::User) -> Bool

Check if user account is active.
"""
function is_active_user(user::User)::Bool
    return user.is_active
end

# Custom validators

"""Validator: check that role is valid (admin or operator)"""
function is_valid_role(field::Symbol, m::User)::ValidationResult
    role = getfield(m, field)
    if role in VALID_ROLES
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :is_valid_role, "must be 'admin' or 'operator'")
    end
end

"""Validator: check minimum string length"""
function has_min_length(field::Symbol, m::User, min_len::Int)::ValidationResult
    val = getfield(m, field)
    if length(val) >= min_len
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_min_length, "must be at least $min_len characters")
    end
end

"""Validator: check maximum string length"""
function has_max_length(field::Symbol, m::User, max_len::Int)::ValidationResult
    val = getfield(m, field)
    if length(val) <= max_len
        return ValidationResult(valid)
    else
        return ValidationResult(invalid, :has_max_length, "must not exceed $max_len characters")
    end
end

# Validation rules
function SearchLight.Validation.validator(::User)
    ModelValidator([
        # Username validations
        ValidationRule(:username, is_not_empty),
        ValidationRule(:username, has_min_length, (3,)),
        ValidationRule(:username, has_max_length, (50,)),

        # Name validations
        ValidationRule(:name, is_not_empty),
        ValidationRule(:name, has_max_length, (100,)),

        # Password hash validation (should be set)
        ValidationRule(:password_hash, is_not_empty),

        # Role validation
        ValidationRule(:role, is_valid_role),
    ])
end

"""
    find_by_username(username::String) -> Union{User, Nothing}

Find a user by their username.
"""
function find_by_username(username::String)::Union{User, Nothing}
    users = SearchLight.find(User, SQLWhereExpression("username = ?", username))
    return isempty(users) ? nothing : first(users)
end

"""
    find_active_admins() -> Vector{User}

Find all active admin users.
"""
function find_active_admins()::Vector{User}
    return SearchLight.find(User, SQLWhereExpression("role = ? AND is_active = ?", "admin", true))
end

"""
    update_last_login!(user::User) -> User

Update the last_login_at timestamp for a user.
"""
function update_last_login!(user::User)::User
    timestamp = Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS")
    user.last_login_at = timestamp
    user.updated_at = timestamp
    SearchLight.save!(user)
    return user
end

"""
    find_all_users() -> Vector{User}

Find all users (active and inactive).
"""
function find_all_users()::Vector{User}
    return SearchLight.all(User)
end

end # module Users
