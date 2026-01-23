# Code Index

Quick reference for navigating this codebase.

## Entry Points

| File | Purpose |
|------|---------|
| `app.jl` | Application entry point, starts Genie server |
| `test/runtests.jl` | Test suite entry |

## Key Modules

| Module | Location | Responsibility |
|--------|----------|----------------|
| User | `src/models/User.jl` | User authentication and roles |
| Tool | `src/models/Tool.jl` | Equipment/tool data |
| StatusEvent | `src/models/StatusEvent.jl` | Status change history and audit trail |
| DashboardController | `src/controllers/DashboardController.jl` | Main dashboard routes |
| AuthController | `src/controllers/AuthController.jl` | Login/logout handling |
| AdminController | `src/controllers/AdminController.jl` | Admin routes for tools/users |

## Common Patterns

### Adding a new route
```julia
# In routes.jl
route("/path", YourController.action_name, method=GET)
```

### Creating a model
```julia
# In src/models/YourModel.jl
using SearchLight

@kwdef mutable struct YourModel <: AbstractModel
    id::DbId = DbId()
    field::String = ""
end
```

### Status state enum values
```julia
# Valid states for StatusEvent
const STATES = ["UP", "UP_WITH_ISSUES", "MAINTENANCE", "DOWN"]
```

### User roles
```julia
# Valid user roles (defined in src/models/User.jl)
const VALID_ROLES = ["admin", "operator"]
```

### Database migrations
Migrations are in `db/migrations/` with timestamp prefixes:
```
20260122195602_create_users.jl  # User table
20260122201046_create_tools.jl  # Tool table
```

## Where to Find Things

| If you need... | Look in... |
|----------------|------------|
| Database models | `src/models/` |
| Route handlers | `src/controllers/` |
| HTML templates | `src/views/` |
| CSS styles | `public/css/` |
| Database migrations | `db/migrations/` |
| Seed data | `db/seeds/` |
| Tests | `test/` |

## Status Colors (CSS)

| State | Color | Hex |
|-------|-------|-----|
| UP | Green | `#2ecc71` |
| UP_WITH_ISSUES | Yellow | `#f39c12` |
| MAINTENANCE | Orange | `#e67e22` |
| DOWN | Red | `#e74c3c` |

## QCI Brand Colors

| Name | Hex | Usage |
|------|-----|-------|
| Dark Navy | `#1E204B` | Headers, nav |
| Light Navy | `#222354` | Logo, accents |
| Light Grey | `#F4F5F9` | Page background |
| Body Text | `#3A3D4A` | Text on light bg |
