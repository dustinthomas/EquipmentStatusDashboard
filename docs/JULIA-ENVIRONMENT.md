# Julia Programming Environment Overview

## Julia Basics

Julia is a high-performance language designed for numerical and scientific computing, but also works well for web applications. Key characteristics:

- **JIT Compiled**: Code compiles at runtime, so first execution is slow ("time to first plot" problem), but subsequent runs are fast
- **Dynamic typing** with optional type annotations
- **Multiple dispatch**: Functions can have many methods based on argument types
- **Package manager built-in**: `Pkg` module handles dependencies

## Project Structure

```
EquipmentStatusDashboard/
├── Project.toml          # Dependencies (like package.json)
├── Manifest.toml         # Locked versions (like package-lock.json)
├── app.jl                # Entry point
├── config/
│   ├── routes.jl         # URL routing
│   ├── database.jl       # DB connection logic
│   ├── env/dev.jl        # Environment-specific config
│   └── initializers/     # Auto-loaded at startup
├── src/
│   ├── models/           # SearchLight ORM models
│   ├── controllers/      # Route handlers
│   └── views/            # HTML templates
└── db/
    ├── connection.yml    # Database config
    ├── migrations/       # Schema changes
    └── seeds/            # Initial data
```

## Package Management

```bash
# Project.toml defines dependencies
julia --project=.              # Activate this project's environment
julia -e "using Pkg; Pkg.instantiate()"  # Install from Manifest.toml
julia -e "using Pkg; Pkg.add(\"SomePackage\")"  # Add new dependency
```

The `--project=.` flag is critical - it tells Julia to use *this* project's dependencies, not global ones.

## Key Frameworks

### Genie.jl (Web Framework)

Similar to Ruby on Rails or Django:

```julia
using Genie

# Define routes
route("/") do
    "Hello World"
end

route("/users/:id") do
    user_id = params(:id)
    # ...
end

# Start server
up(8000)
```

### SearchLight.jl (ORM)

Database abstraction layer:

```julia
using SearchLight

# Define model
mutable struct User <: AbstractModel
    id::DbId
    username::String
    role::String
end

# Query
users = SearchLight.find(User)                              # All users
admin = SearchLight.find(User, SQLWhereExpression("role = ?", "admin"))

# Save
user = User(username="john", role="operator")
SearchLight.save!(user)
```

### Migrations

Schema changes in `db/migrations/`:

```julia
module CreateUsers
import SearchLight.Migrations: create_table, column, primary_key

function up()
    create_table(:users) do
        [
            primary_key()
            column(:username, :string)
            column(:role, :string)
        ]
    end
end

function down()
    drop_table(:users)
end
end
```

## Development Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. SETUP                                                   │
│     ./scripts/instantiate.sh    # Install Julia packages    │
│                                                             │
│  2. DATABASE                                                │
│     ./scripts/migrate.sh        # Create tables             │
│     ./scripts/seed.sh           # Add initial data          │
│                                                             │
│  3. RUN                                                     │
│     ./scripts/start.sh          # Start dev server          │
│                                                             │
│  4. TEST                                                    │
│     julia --project=. -e "using Pkg; Pkg.test()"            │
└─────────────────────────────────────────────────────────────┘
```

## How the Scripts Work

### instantiate.sh

```bash
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

Reads `Manifest.toml` and downloads all dependencies.

### migrate.sh

```bash
julia --project=. -e '
using SearchLight
SearchLight.connect()
# Run migration files...
'
```

Executes migration `up()` functions to create database tables.

### seed.sh

```bash
julia --project=. -e '
include("db/seeds/seed_data.jl")
seed!()
'
```

Populates database with initial data (admin user, sample tools).

### start.sh

```bash
julia --project=. -e 'include("app.jl")'
```

Loads app.jl which:

1. Configures logging
2. Loads initializers (database connection, auth)
3. Loads routes
4. Starts HTTP server on port 8000

## Application Boot Sequence

```
app.jl
  │
  ├─→ config/env/dev.jl           # Environment settings
  │
  ├─→ config/initializers/
  │     ├─→ authentication.jl     # Auth functions
  │     └─→ searchlight.jl        # DB connection
  │
  └─→ config/routes.jl            # URL mappings
        └─→ src/controllers/      # Route handlers
              └─→ src/models/     # Database models
```

## Common Julia Patterns in This Codebase

### Module exports

```julia
module Users
export User, find_by_username

struct User
    # ...
end

function find_by_username(name)
    # ...
end
end
```

### Include vs Using

```julia
include("file.jl")      # Execute file in current scope (like copy-paste)
using SomePackage       # Load installed package
using .LocalModule      # Use module defined in current scope
```

### Type annotations (optional but helpful)

```julia
function authenticate(username::String, password::String)::Bool
    # ...
end
```

## Database Connection Flow

```
connection.yml (config)
       │
       ▼
SearchLight.Configuration.load()
       │
       ▼
SearchLight.connect()
       │
       ▼
SQLite database file (db/qci_status_dev.sqlite)
```

The YAML config specifies different databases per environment:

- `dev`: `db/qci_status_dev.sqlite`
- `test`: `db/qci_status_test.sqlite`
- `prod`: `db/qci_status.sqlite`

## Summary

| Concept | Julia/This Project | Equivalent |
|---------|-------------------|------------|
| Package manager | `Pkg` / Project.toml | npm / package.json |
| Web framework | Genie.jl | Express, Rails |
| ORM | SearchLight.jl | Sequelize, ActiveRecord |
| Migrations | db/migrations/*.jl | Rails migrations |
| Entry point | app.jl | index.js, main.py |
