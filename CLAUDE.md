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

- **Language:** Julia 1.9+
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

```bash
# Setup (install Julia dependencies)
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Run development server
julia --project=. -e "include(\"app.jl\")"

# Run database migrations
julia --project=. -e "using SearchLight; SearchLight.Migration.up()"

# Run tests
julia --project=. -e "using Pkg; Pkg.test()"

# Build Docker image
docker build -t qci-status:latest .

# Run Docker container
docker run -d -p 8000:8000 -v qci-data:/data qci-status:latest
```

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
├── app.jl                 # Application entry point
│
├── src/                   # Source code
│   ├── models/            # SearchLight models (User, Tool, StatusEvent)
│   ├── controllers/       # Route handlers
│   ├── views/             # HTML templates
│   └── lib/               # Shared utilities
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
