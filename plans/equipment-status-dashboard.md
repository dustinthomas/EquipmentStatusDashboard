# Plan: QCI Equipment Status Dashboard MVP

**Spec:** `QCI-Equimpment-Status-PRD.md`
**Units:** `docs/features/equipment-status-dashboard-units.md`
**Vue Units:** `docs/features/vue-frontend-units.md`
**Status:** In Progress

## Overview

Build an internal web application for tracking fabrication equipment status, replacing Google Sheets with a database-backed system featuring user authentication, role-based access, and complete audit trail.

The implementation follows a bottom-up approach:
1. Database layer (models, migrations)
2. Authentication layer
3. Core views and controllers (server-rendered for initial MVP)
4. Admin functionality
5. Polish and deployment
6. **Vue.js frontend migration** (progressive enhancement)

## Architecture

### Current: Hybrid (Server-rendered + JSON API)

The dashboard currently uses server-rendered templates with sorting/filtering. A Vue.js frontend migration is in progress to provide a more responsive user experience.

### Data Flow (Server-rendered)
```
User → Login → Session Cookie → Controller → Model → SQLite
                                    ↓
                            HTML Template → User
```

### Data Flow (Vue.js - Target Architecture)
```
User → Vue App → JSON API → Controller → Model → SQLite
                    ↓
            JSON Response → Vue App → User
```

### Key Design Decisions

1. **Hybrid rendering**: Server-rendered templates for initial MVP, migrating to Vue.js SPA
2. **JSON API layer**: RESTful endpoints at `/api/*` for Vue frontend consumption
3. **Cookie-based sessions**: Using GenieAuthentication.jl (works for both HTML and API)
4. **Soft deletes**: `is_active` flag on Users and Tools (preserve audit trail)
5. **Immutable status events**: StatusEvent records never modified or deleted
6. **Current state on Tool**: Denormalized `current_*` fields for fast dashboard queries
7. **CDN-loaded Vue**: No build step; Vue 3 loaded from CDN for simplicity

### Files to Create

| Category | Files |
|----------|-------|
| Models | `User.jl`, `Tool.jl`, `StatusEvent.jl` |
| Migrations | `CreateUsers`, `CreateTools`, `CreateStatusEvents` |
| Controllers | `AuthController.jl`, `DashboardController.jl`, `ToolsController.jl`, `AdminController.jl` |
| Views (legacy) | Layout, login, dashboard templates (to be replaced by Vue) |
| API Helpers | `api_helpers.jl` - JSON response utilities |
| Config | `routes.jl`, `database.jl`, SearchLight config |
| Static | `qci.css` (branding), `public/js/app.js` (Vue app) |
| Frontend | `public/index.html` (Vue shell) |

## Milestones

### Milestone 1: Project Foundation
- **Status:** Complete
- **Units:** 1.1, 1.2, 1.3
- Genie project configuration, SearchLight setup, base layout template

### Milestone 2: Data Models
- **Status:** Complete
- **Units:** 2.1, 2.2, 2.3, 2.4
- User, Tool, StatusEvent models with migrations, validators, and seed data

### Milestone 3: Authentication
- **Status:** Complete
- **Units:** 3.1, 3.2, 3.3
- Login/logout, session management, route protection middleware

### Milestone 4: Dashboard & Tool Views
- **Status:** In Progress
- **Units:** 4.1 (Complete), 4.2 (Implemented), 4.3-4.5 (Pending)
- Main dashboard with sorting/filtering, tool detail, status update, history view

### Milestone 5: Admin Features
- **Status:** Not Started
- **Units:** 5.1, 5.2, 5.3
- Tool management, user management, admin authorization

### Milestone 6: UI Polish & Deployment
- **Status:** Not Started
- **Units:** 6.1, 6.2, 6.3, 6.4
- QCI branding CSS, stale highlighting, Dockerfile, health/logging

### Milestone 7: Vue.js Frontend Migration
- **Status:** Complete
- **Units:** See `docs/features/vue-frontend-units.md`
- Progressive migration from server-rendered templates to Vue.js SPA
- Sub-milestones:
  - 7.1: JSON API Layer (Complete)
  - 7.2: Vue App Shell (Complete)
  - 7.3: Dashboard Implementation (Complete)
  - 7.4: Tool Management Views (Complete)
  - 7.5: Cleanup & Testing (Complete)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| GenieAuthentication integration complexity | Follow official docs, test auth flow early |
| SearchLight migration quirks | Test migrations with clean DB; add rollback procedures |
| Session persistence across restarts | Store sessions in database, not memory |
| SQLite file permissions in Docker | Use explicit volume mount, document permissions |
| Stale status display | Add last-updated highlighting, optional auto-refresh |
| Vue migration scope creep | Keep server-rendered fallback; migrate incrementally |
| API/HTML session sharing | Use same cookie-based auth for both |

## Dependencies

External Julia packages (already in Project.toml):
- Genie.jl - Web framework
- SearchLight.jl - ORM
- SearchLightSQLite.jl - SQLite adapter
- GenieAuthentication.jl - Auth plugin
- GenieAuthorisation.jl - Role-based access

Frontend (CDN):
- Vue.js 3.x - Reactive UI framework

## Testing Strategy

- Unit tests for model validations
- Integration tests for authentication flow
- Controller tests for CRUD operations
- API endpoint tests for JSON responses
- In-memory SQLite for test isolation

## Updates

- 2026-01-22: Initial plan created from PRD
- 2026-01-23: Updated plan to reflect Vue.js frontend migration decision; added Milestone 7; updated milestone statuses to reflect actual progress
- 2026-01-28: Milestone 7 (Vue.js Frontend Migration) complete - all units verified/merged
