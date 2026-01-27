# CLAUDE.md

This is the rulebook for Claude Code sessions working in this repository.

> **Note:** `CLAUDE-WORKFLOW.md` exists for human onboarding. Claude sessions should NOT read it - all necessary rules are here.

> **Required reading:** `CODE_INDEX.md` - Codebase navigation map. Read this to quickly find functions, files, and patterns.

## Goals

- Manual equipment status dashboard for QCI fab operations
- Internal web app replacing Google Sheets tracker with audit logging
- Built with Claude Code assistance following structured workflow
- Human role: review, define requirements, approve design decisions
- Claude role: plan, implement, test, document

## Hard Rules

- Never commit directly to `main`; always use feature branches
  - Branch naming: `feature/NAME`, `bugfix/NAME`, `refactor/NAME`, or `test/NAME`
  - Only exception: updating this CLAUDE.md file itself (with approval)
- Always run tests before proposing a PR
- Never commit database files (*.sqlite, *.db) to version control
- Never commit sensitive credentials or secrets
- Keep dependencies minimal (avoid bloat)
- Prioritize simplicity over features
- **Keep work units as small as logically possible** - Each unit should represent the smallest coherent change that can be independently tested and merged. Prefer many small PRs over few large ones.

## Coding Style & Stack

- **Language:** Julia (latest stable)
- **Framework:** Genie.jl (web framework)
- **ORM:** SearchLight.jl (supports SQLite, PostgreSQL)
- **Database:** SQLite (v1), migration path to PostgreSQL
- **Authentication:** GenieAuthentication.jl + GenieAuthorisation.jl
- **Frontend:** Server-rendered HTML templates, minimal vanilla JS
- **CSS:** Custom stylesheet with QCI branding, optional Bootstrap utilities
- **Deployment:** Docker with Julia official image
- **Style:**
  - 4-space indentation
  - snake_case for functions and variables
  - PascalCase for types/structs
  - Document public APIs with docstrings

## Development Commands

**IMPORTANT:** Use the Julia REPL MCP server for all Julia operations. See "Julia REPL" section below.

```bash
# Docker build/run (these use bash, not Julia)
docker build -t qci-status:latest .
docker run -d -p 8000:8000 -v qci-data:/data qci-status:latest

# Restart MCP REPL (when struct changes require Julia restart)
bash scripts/restart_mcp.sh
```

## Julia REPL (CRITICAL)

A Julia REPL MCP server is available. **ALWAYS use this instead of `julia` in bash.**

### Why Use the MCP REPL?

1. **No startup latency** - Julia startup takes seconds; the REPL is already running
2. **Project environment ready** - Already configured with `--project=.`
3. **Revise.jl active** - Function changes auto-reload without restart
4. **Persistent state** - Database connections, loaded modules persist

### MCP REPL Tools

| Tool | Purpose |
|------|---------|
| `mcp__julia-repl__exec_repl` | Execute Julia code |
| `mcp__julia-repl__investigate_environment` | Check project/package status |
| `mcp__julia-repl__remove-trailing-whitespace` | Clean up edited files |
| `mcp__julia-repl__usage_instructions` | Get detailed REPL guidance |

### Common Operations

**Starting the App:**
```julia
# In MCP REPL (not bash!):
using Genie; Genie.loadapp()
App.load_app()
App.up(8000; async=true)
```

**Stopping/Restarting Server:**
```julia
App.down()           # Stop server
App.up(8000)         # Restart without reloading
```

**Running Tests:**
```julia
using Pkg; Pkg.test()
```

**Database Migrations:**
```julia
using SearchLight; SearchLight.Migration.up()
```

**Checking Documentation:**
```julia
@doc function_name
```

### Rules

1. **NEVER** use `julia` commands in bash - always use the MCP REPL
2. **Check before assuming** - Use `@doc`, `Pkg.status()`, or read existing code
3. **Use `let` blocks** for temporary computations to avoid namespace pollution
4. **Don't modify environment** - Ask the user if dependencies are missing
5. **Revise.jl limitations** - Struct/const changes require REPL restart

### When to Restart the MCP REPL

Restart is needed when you modify:
- Struct definitions (in model files)
- Const values
- Module structure

To restart:
```bash
bash scripts/restart_mcp.sh
```
Wait ~20 seconds, then reload the app in the new REPL.

## Document Hierarchy

This project uses a three-tier documentation system:

```
SPEC (Human writes)     →  PLAN (Planner creates)    →  FEATURES (Work units)
docs/features/FEATURE.md   plans/FEATURE.md             docs/features/FEATURE-units.md
What we want               How we'll build it           What to do next
```

| Document | Location | Owner | Purpose |
|----------|----------|-------|---------|
| **Spec** | `docs/features/FEATURE.md` | Human | Requirements, user stories, acceptance criteria |
| **Plan** | `plans/FEATURE.md` | Planner | Architecture, approach, milestones (living doc) |
| **Units** | `docs/features/FEATURE-units.md` | Planner → Implementer | Actionable micro-units with status |

**Key rules:**
- Planner creates BOTH plan and units files
- Plan file is updated after each milestone completes
- Units file tracks implementation progress
- Implementer works from units file, references plan file

## Work Units

A **Work Unit** is the smallest coherent, testable chunk of work:
- Results in ONE pull request
- Can be implemented, tested, and merged independently
- Has clear acceptance criteria

**Lifecycle:**
```
PENDING → IN_PROGRESS → IMPLEMENTED → VERIFIED → MERGED
```

**Skills update files automatically:**
- `/implement-step` updates units file status + plan milestones
- `/verify-ship` updates units file + plan on milestone complete

## Session Rules

**Each session = One role, One work unit**

| Role | Reads | Outputs |
|------|-------|---------|
| Planner | CLAUDE.md, CODE_INDEX.md, Spec | Plan + Units files |
| Implementer | CLAUDE.md, CODE_INDEX.md, Units file, Plan | Code + tests |
| Verifier | CLAUDE.md, Units file | PASS/FAIL report |
| Bug Fixer | CLAUDE.md, CODE_INDEX.md, Bug doc | Fixed code |

**At session end:**
1. Update units file with status
2. Update plan file if milestone complete
3. Tell user: "CLEAR CONTEXT, then run [next command]"

**TodoWrite:** Use for session-internal tracking only. Units file is the cross-session source of truth.

## Project Structure

```
EquipmentStatusDashboard/
├── CLAUDE.md              # This file (rulebook for Claude)
├── CLAUDE-WORKFLOW.md     # Human onboarding guide (Claude: do not read)
├── CODE_INDEX.md          # Codebase navigation map
├── README.md              # User documentation
├── Project.toml           # Julia dependencies
├── Manifest.toml          # Julia dependency lock
├── Dockerfile             # Docker deployment
├── bootstrap.jl           # Entry point for Genie.loadapp()
├── app.jl                 # Legacy entry point (deprecated, use bootstrap.jl)
│
├── bin/                   # Startup scripts
│   ├── repl.bat           # Start interactive REPL (Windows)
│   └── server.bat         # Start server (Windows)
│
├── scripts/               # Development scripts
│   └── restart_mcp.sh     # Restart MCP REPL in WezTerm
│
├── src/                   # Source code
│   ├── App.jl             # Main application module
│   ├── models/            # SearchLight models (User, Tool, StatusEvent)
│   ├── controllers/       # Route handlers
│   ├── views/             # HTML templates
│   └── lib/               # Shared utilities (AuthCore, auth_helpers)
│
├── db/
│   ├── migrations/        # Database migrations
│   └── seeds/             # Seed data (initial admin user, sample tools)
│
├── public/                # Static assets
│   ├── css/               # Stylesheets (QCI branding)
│   ├── js/                # Client-side JavaScript
│   └── img/               # Images (QCI logo)
│
├── test/                  # Tests
│
├── plans/                 # Implementation plans (living docs)
│
└── docs/
    ├── features/          # Specs and units files
    └── bugs/              # Bug tracking
```

## Branching Strategy

| Role | Branch Prefix | Example |
|------|---------------|---------|
| Implementer | `feature/` | `feature/add-dashboard` |
| Bug Fixer | `bugfix/` | `bugfix/login-redirect` |
| Refactor | `refactor/` | `refactor/simplify-auth` |

**Exceptions (direct commits to main):**
- Updating `CLAUDE.md` with explicit approval
- Updating units file status to MERGED after PR merge

## Testing Requirements

- Test all CRUD operations for models
- Test authentication and authorization flows
- Test role-based access control (admin vs operator)
- Use in-memory SQLite for tests (isolate from production data)
- Run full test suite before any PR
- Never commit test databases

## Data Model

**User:** id, username, password_hash, name, role, last_login_at, created_at, updated_at, is_active
- Roles: `admin`, `operator`

**Tool:** id, name, area, bay_or_line, criticality, created_at, updated_at, is_active
- Criticality: `critical`, `high`, `medium`, `low`

**StatusEvent:** id, tool_id, state, issue_description, comment, eta_to_up, created_by_user_id, created_at
- States: `UP`, `UP_WITH_ISSUES`, `MAINTENANCE`, `DOWN`
- Timestamps: ISO 8601 format

## UI/UX Guidelines

### QCI Branding
- **Dark Navy:** `#1E204B` (headers, nav, primary buttons)
- **Light Navy:** `#222354` (logo, accents)
- **Light Grey:** `#F4F5F9` (page background)
- **White:** `#FFFFFF` (cards, content areas)
- **Body Text:** `#3A3D4A` (text on light backgrounds)

### Status Colors
- **UP:** `#2ecc71` (green)
- **UP WITH ISSUES:** `#f39c12` (yellow/amber)
- **MAINTENANCE:** `#e67e22` (orange)
- **DOWN:** `#e74c3c` (red)

### Typography
```css
font-family: "Raleway", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
```

### Layout
- Server-rendered HTML, no SPA
- Dashboard shows color-coded equipment table
- Sort by state (down tools first), then by ETA
- Mobile-responsive is stretch goal; focus on desktop intranet use

## Implementation Notes

- **Intranet only:** No TLS required; HTTP is acceptable internally
- **Docker deployment:** SQLite database persisted via volume mount at `/data`
- **Sessions:** Cookie-based, stored in database
- **Passwords:** Hashed with Argon2 or bcrypt
- **Soft deletes:** Tools and users are deactivated, not deleted (preserve audit trail)
- **Audit trail:** StatusEvent records are immutable; never delete or modify

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_PATH` | `/data/qci_status.sqlite` | SQLite database file location |
| `PORT` | `8000` | HTTP server port |
| `LOG_LEVEL` | `info` | Logging verbosity |
| `SECRET_KEY` | (required) | Session encryption key |

## Lessons Learned

(Start empty - add entries as discovered)

### Template
```
### [DATE] - [Brief description]
**What happened:** [describe]
**Rule:** [new rule]
```
