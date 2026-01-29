# Work Units: QCI Equipment Status Dashboard MVP

**Plan:** `plans/equipment-status-dashboard.md`
**Spec:** `QCI-Equimpment-Status-PRD.md`

## Status Legend
- PENDING: Not started
- IN_PROGRESS: Being worked on
- IMPLEMENTED: Code complete, needs verification
- VERIFIED: Tests pass, ready for merge
- MERGED: Complete
- SKIPPED: Will not implement (see reason)

## Decision Log

**2026-01-23: Pivot to Vue.js frontend**
Units 4.3, 4.4, and 4.5 (Tool Detail, Status Update, Tool History) are skipped in server-rendered form. These features will be implemented directly in the Vue.js frontend. See `docs/features/vue-frontend-units.md` for the Vue implementation units.

---

## Milestone 1: Project Foundation

### Unit 1.1: Genie Project Configuration
**Status:** MERGED
**Branch:** `feature/genie-config`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/1
**Depends on:** None

**Task:**
Set up Genie project structure with proper configuration files. Create `config/` directory with environment configs, `routes.jl` with basic health check route, and update `app.jl` to properly load Genie app.

**Acceptance Criteria:**
- [x] `config/env/dev.jl` and `config/env/prod.jl` exist with appropriate settings
- [x] `routes.jl` exists with `GET /health` route returning `{"status":"ok"}`
- [x] `app.jl` starts Genie server successfully
- [x] `julia --project=. -e "include(\"app.jl\")"` runs without error

**Fix Note (2026-01-22):** Fixed health endpoint by using `Genie.Renderer.Json.json()` instead of non-existent `Genie.Responses.json()` (Genie 5.x API). Added test coverage for the health endpoint response.

**Files to create/modify:**
- `config/env/dev.jl` - Development environment config
- `config/env/prod.jl` - Production environment config
- `config/routes.jl` - Route definitions
- `app.jl` - Update to use Genie.loadapp() properly

---

### Unit 1.2: SearchLight Database Configuration
**Status:** MERGED
**Branch:** `feature/searchlight-config`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/2
**Depends on:** 1.1

**Task:**
Configure SearchLight ORM with SQLite adapter. Create database configuration file and connection setup.

**Acceptance Criteria:**
- [x] `db/connection.yml` or `config/database.jl` exists with SQLite config
- [x] SearchLight can connect to SQLite database
- [x] Database file created at configurable path (env var `DATABASE_PATH`)
- [x] Connection tested successfully in REPL

**Files to create/modify:**
- `config/database.jl` - SearchLight configuration
- `config/initializers/searchlight.jl` - SearchLight initialization

---

### Unit 1.3: Base Layout Template
**Status:** MERGED
**Branch:** `feature/base-layout`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/3
**Depends on:** 1.1

**Task:**
Create the base HTML layout template with QCI branding placeholder. Include Raleway font, basic navigation structure, and footer.

**Acceptance Criteria:**
- [x] `src/views/layouts/app.jl.html` exists with valid HTML5 structure
- [x] Includes `<head>` with Raleway font from Google Fonts
- [x] Has placeholder nav bar and footer with QCI copyright
- [x] Renders without errors

**Files to create/modify:**
- `src/views/layouts/app.jl.html` - Main layout template
- `public/css/qci.css` - Basic CSS with QCI colors (skeleton)

---

## Milestone 2: Data Models

### Unit 2.1: User Model and Migration
**Status:** MERGED
**Branch:** `feature/user-model`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/4
**Depends on:** 1.2

**Task:**
Create the User model with SearchLight, including migration for the `users` table. Fields: id, username, password_hash, name, role, is_active, last_login_at, created_at, updated_at.

**Acceptance Criteria:**
- [x] `src/models/User.jl` exists with all required fields ✓
- [x] Migration creates `users` table with correct schema ✓
- [x] Migration runs successfully: `SearchLight.Migration.up()` ✓
- [x] Can create/read User records in REPL ✓
- [x] Role validation (only "admin" or "operator" allowed) ✓

**Files to create/modify:**
- `src/models/User.jl` - User model definition
- `db/migrations/TIMESTAMP_create_users.jl` - Migration file

---

### Unit 2.2: Tool Model and Migration
**Status:** MERGED
**Branch:** `feature/tool-model`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/5
**Depends on:** 1.2

**Task:**
Create the Tool model with denormalized current status fields. Fields: id, name, area, bay, criticality, is_active, current_state, current_issue_description, current_comment, current_eta_to_up, current_status_updated_at, current_status_updated_by_user_id, created_at, updated_at.

**Acceptance Criteria:**
- [x] `src/models/Tool.jl` exists with all required fields
- [x] Migration creates `tools` table with correct schema
- [x] Migration runs successfully
- [x] Can create/read Tool records in REPL
- [x] State validation (only valid states allowed)
- [x] Criticality validation (low/medium/high)

**Files to create/modify:**
- `src/models/Tool.jl` - Tool model definition
- `db/migrations/20260122201046_create_tools.jl` - Migration file

---

### Unit 2.3: StatusEvent Model and Migration
**Status:** MERGED
**Branch:** `feature/status-event-model`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/6
**Depends on:** 2.1, 2.2

**Task:**
Create the StatusEvent model for audit trail. Fields: id, tool_id (FK), state, issue_description, comment, eta_to_up, created_by_user_id (FK), created_at. Add index on (tool_id, created_at).

**Acceptance Criteria:**
- [x] `src/models/StatusEvent.jl` exists with all required fields
- [x] Migration creates `statusevents` table with FKs
- [x] Index exists on tool_id and created_at (separate indexes)
- [x] Migration runs successfully
- [x] Can create/read StatusEvent records in REPL

**Files to create/modify:**
- `src/models/StatusEvent.jl` - StatusEvent model definition
- `db/migrations/20260122203749_create_status_events.jl` - Migration file

---

### Unit 2.4: Seed Data
**Status:** MERGED
**Branch:** `feature/seed-data`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/7
**Depends on:** 2.1, 2.2, 2.3

**Task:**
Create seed script with initial admin user and sample tools. Admin user: username="admin", password="changeme" (hashed). Sample tools: 3-5 fabrication tools with different areas and states.

**Acceptance Criteria:**
- [x] `db/seeds/seed_data.jl` exists
- [x] Running seed creates admin user with hashed password
- [x] Running seed creates sample tools
- [x] Seed is idempotent (can run multiple times safely)
- [x] Seed script documented in README

**Files to create/modify:**
- `db/seeds/seed_data.jl` - Seed script

---

## Milestone 3: Authentication

### Unit 3.1: GenieAuthentication Setup
**Status:** MERGED
**Branch:** `feature/auth-setup`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/8
**Depends on:** 2.1

**Task:**
Integrate GenieAuthentication with the User model. Configure session handling, password hashing, and authentication checks.

**Acceptance Criteria:**
- [x] GenieAuthentication configured in `config/initializers/`
- [x] User model integrates with auth system
- [x] Password hashing works (SHA256 - compatible with existing seed data)
- [x] Session storage configured (file-based via GenieSessionFileSession)
- [x] `authenticate(username, password)` function works

**Files to create/modify:**
- `config/initializers/authentication.jl` - Auth configuration
- `src/models/User.jl` - Add auth integration methods

---

### Unit 3.2: Login/Logout Routes and Views
**Status:** MERGED
**Branch:** `feature/login-views`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/9
**Depends on:** 3.1, 1.3

**Task:**
Create login page with username/password form, and logout functionality. Style with QCI branding.

**Acceptance Criteria:**
- [x] `GET /login` renders login form
- [x] `POST /login` authenticates and redirects to dashboard
- [x] `GET /logout` clears session and redirects to login
- [x] Invalid credentials show error message (generic, not specific)
- [x] Login page styled with QCI branding

**Files to create/modify:**
- `src/controllers/AuthController.jl` - Login/logout handlers
- `src/views/auth/login.jl.html` - Login form template
- `config/routes.jl` - Add auth routes

---

### Unit 3.3: Route Protection Middleware
**Status:** MERGED
**Branch:** `feature/route-protection`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/10
**Depends on:** 3.2

**Task:**
Add middleware to protect routes requiring authentication. Redirect unauthenticated users to login. Create helper functions for checking auth/roles.

**Acceptance Criteria:**
- [x] Unauthenticated requests to `/dashboard` redirect to `/login`
- [x] After login, user redirected to originally requested page
- [x] `current_user()` helper returns logged-in user
- [x] `is_admin()` helper checks user role
- [x] Session timeout works (configurable, default 8 hours)

**Files to create/modify:**
- `src/lib/auth_helpers.jl` - Authentication helper functions
- `config/routes.jl` - Add middleware to protected routes

---

## Milestone 4: Dashboard & Tool Views

### Unit 4.1: Dashboard Controller and View
**Status:** MERGED
**Branch:** `feature/dashboard-view`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/11
**Depends on:** 3.3, 2.2

**Task:**
Create main dashboard showing all active tools with current status. Display as table with color-coded rows by state.

**Acceptance Criteria:**
- [x] `GET /dashboard` renders tool list
- [x] Table shows: name, area, state, last updated, updated by, issue (truncated), ETA
- [x] Rows colored by state (green/yellow/orange/red)
- [x] Only active tools shown
- [x] Clicking row navigates to tool detail

**Files to create/modify:**
- `src/controllers/DashboardController.jl` - Dashboard handler
- `src/views/dashboard/index.jl.html` - Dashboard template
- `config/routes.jl` - Add dashboard route
- `public/css/qci.css` - Add status color styles

---

### Unit 4.2: Dashboard Sorting and Filtering
**Status:** MERGED
**Branch:** `feature/dashboard-view` (included in Unit 4.1 PR)
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/11
**Depends on:** 4.1

**Task:**
Add sorting and filtering to dashboard. Sortable columns: name, state, area, last updated, ETA. Filters: state dropdown, area dropdown, text search.

**Acceptance Criteria:**
- [x] Clicking column header sorts by that column
- [x] Sort direction toggles (asc/desc)
- [x] State filter dropdown works
- [x] Area filter dropdown works
- [x] Text search filters by tool name
- [x] Filters persist in URL query params

**Note:** This functionality was implemented as part of Unit 4.1 (PR #11) rather than as a separate unit.

**Files modified:**
- `src/controllers/DashboardController.jl` - Filter/sort logic
- `app/resources/dashboard/views/index.jl.html` - Filter UI with HTMX
- `app/resources/dashboard/views/table.jl.html` - Table partial for HTMX updates

---

### Unit 4.3: Tool Detail View
**Status:** SKIPPED
**Reason:** Implementing directly in Vue frontend (see `docs/features/vue-frontend-units.md`)
**Branch:** `feature/tool-detail`
**Depends on:** 4.1

**Task:**
~~Create tool detail page showing full current status and actions. Include "Update Status" button and "View History" link.~~

**Note:** This feature will be implemented as part of the Vue.js frontend migration instead of server-rendered templates.

**Acceptance Criteria:**
- [ ] ~~`GET /tools/:id` renders tool detail~~
- [ ] ~~Shows: name, area, bay, criticality, current state, issue, comment, ETA~~
- [ ] ~~Shows last updated timestamp and user name~~
- [ ] ~~"Update Status" button links to update form~~
- [ ] ~~"View History" links to history page~~
- [ ] ~~404 for invalid tool ID~~

**Files to create/modify:**
- ~~`src/controllers/ToolsController.jl` - Detail handler~~
- ~~`src/views/tools/show.jl.html` - Detail template~~
- ~~`config/routes.jl` - Add tool routes~~

---

### Unit 4.4: Status Update Form
**Status:** SKIPPED
**Reason:** Implementing directly in Vue frontend (see `docs/features/vue-frontend-units.md`)
**Branch:** `feature/status-update`
**Depends on:** 4.3, 2.3

**Task:**
~~Create form to update tool status. On submit: create StatusEvent, update Tool's current_* fields, redirect to tool detail.~~

**Note:** This feature will be implemented as part of the Vue.js frontend migration. JSON API endpoints for status updates will be added to support the Vue frontend.

**Acceptance Criteria:**
- [ ] ~~`GET /tools/:id/status/new` renders update form~~
- [ ] ~~Form has: state dropdown (required), issue (optional), comment (optional), ETA (optional)~~
- [ ] ~~`POST /tools/:id/status` creates StatusEvent~~
- [ ] ~~Tool's current_* fields updated~~
- [ ] ~~current_status_updated_by_user_id set to logged-in user~~
- [ ] ~~If state is UP, ETA cleared~~
- [ ] ~~Redirects to tool detail on success~~

**Files to create/modify:**
- ~~`src/controllers/ToolsController.jl` - Status update handlers~~
- ~~`src/views/tools/status_new.jl.html` - Update form template~~
- ~~`config/routes.jl` - Add status routes~~

---

### Unit 4.5: Tool History View
**Status:** SKIPPED
**Reason:** Implementing directly in Vue frontend (see `docs/features/vue-frontend-units.md`)
**Branch:** `feature/tool-history`
**Depends on:** 4.3, 2.3

**Task:**
~~Create history page showing chronological status events for a tool. Include date range filter and CSV export.~~

**Note:** This feature will be implemented as part of the Vue.js frontend migration. JSON API endpoints for history data will be added to support the Vue frontend.

**Acceptance Criteria:**
- [ ] ~~`GET /tools/:id/history` renders history list~~
- [ ] ~~Shows: timestamp, user, state, issue, comment, ETA~~
- [ ] ~~Ordered by created_at descending (newest first)~~
- [ ] ~~Date range filter (from, to) works~~
- [ ] ~~"Export CSV" button downloads filtered history~~
- [ ] ~~CSV includes all history fields~~

**Files to create/modify:**
- ~~`src/controllers/ToolsController.jl` - History handler~~
- ~~`src/views/tools/history.jl.html` - History template~~
- ~~`config/routes.jl` - Add history route~~

---

## Milestone 5: Admin Features

### Unit 5.1: Admin Authorization Middleware
**Status:** MERGED
**Branch:** `feature/admin-auth`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/30
**Depends on:** 3.3

**Task:**
Add middleware to protect admin routes. Only users with role="admin" can access `/admin/*` routes.

**Acceptance Criteria:**
- [x] Non-admin users get 403 on `/admin/*` routes
- [x] Admin users can access `/admin/*` routes
- [x] 403 page shows friendly message
- [x] Redirect to dashboard for non-admins

**Implementation Notes:**
- `require_admin()` middleware redirects non-admins to `/vue?error=forbidden`
- `require_admin_api()` middleware returns JSON 403 for API routes
- Vue app displays friendly "Admin access required" message when error param is present
- Admin link in navbar only shown to users with admin role

**Files to create/modify:**
- `src/lib/auth_helpers.jl` - Add admin check middleware
- `src/views/errors/403.jl.html` - Forbidden error page (handled via Vue redirect instead)
- `config/routes.jl` - Add admin middleware

---

### Unit 5.2: Tool Management (Admin)
**Status:** MERGED
**Branch:** `feature/admin-tools`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/31
**Depends on:** 5.1, 2.2

**Task:**
Admin API endpoints to create, edit, and deactivate tools. List all tools (including inactive).

**Note:** Per project decision (see Units 4.3-4.5), admin features are implemented as JSON APIs for the Vue frontend instead of server-rendered HTML pages.

**Acceptance Criteria:**
- [x] `GET /api/admin/tools` lists all tools with status (including inactive)
- [x] `GET /api/admin/tools/:id` shows single tool details
- [x] `POST /api/admin/tools` creates new tool
- [x] `PUT /api/admin/tools/:id` updates tool
- [x] `POST /api/admin/tools/:id/toggle-active` toggles is_active (soft delete)
- [x] Validation errors returned as JSON with 400 status
- [x] All routes protected with admin middleware (403 for non-admins)

**Files created/modified:**
- `src/controllers/AdminController.jl` - Tool management API handlers
- `src/App.jl` - Include AdminController
- `config/routes.jl` - Add admin tool API routes
- `test/runtests.jl` - Add tests for admin tool management

---

### Unit 5.3: User Management (Admin)
**Status:** MERGED
**Branch:** `feature/admin-users`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/32
**Depends on:** 5.1, 2.1

**Task:**
Admin API endpoints to create, edit, and deactivate users. Include password reset functionality.

**Note:** Per project decision (see Units 4.3-4.5), admin features are implemented as JSON APIs for the Vue frontend instead of server-rendered HTML pages.

**Acceptance Criteria:**
- [x] `GET /api/admin/users` lists all users (including inactive)
- [x] `GET /api/admin/users/:id` shows single user details
- [x] `POST /api/admin/users` creates new user with hashed password
- [x] `PUT /api/admin/users/:id` updates user (not password)
- [x] `POST /api/admin/users/:id/reset-password` resets password
- [x] `POST /api/admin/users/:id/toggle-active` toggles is_active (soft delete)
- [x] Cannot deactivate last admin
- [x] Cannot change role of last admin
- [x] Validation errors returned as JSON with 400 status
- [x] All routes protected with admin middleware (403 for non-admins)

**Files created/modified:**
- `src/controllers/AdminController.jl` - User management API handlers
- `config/routes.jl` - Add admin user API routes
- `test/runtests.jl` - Add tests for admin user management

---

## Milestone 6: UI Polish & Deployment

### Unit 6.1: QCI Branding CSS
**Status:** PENDING
**Branch:** `feature/qci-css`
**Depends on:** 4.1

**Task:**
Complete CSS styling with QCI branding. Navy headers, status colors, Raleway font, card layouts, responsive basics.

**Acceptance Criteria:**
- [ ] Nav bar uses QCI dark navy (#1E204B)
- [ ] Raleway font applied throughout
- [ ] Status colors match spec (green/yellow/orange/red)
- [ ] Dashboard uses white cards with subtle shadow
- [ ] Footer styled with QCI copyright
- [ ] Forms and buttons styled consistently

**Files to create/modify:**
- `public/css/qci.css` - Complete QCI styles
- `public/img/qci-logo.png` - QCI logo placeholder

---

### Unit 6.2: Stale Status Highlighting
**Status:** PENDING
**Branch:** `feature/stale-highlight`
**Depends on:** 4.1

**Task:**
Highlight tools whose status hasn't been updated in configurable time (default 8 hours). Add visual indicator (faded row or icon).

**Acceptance Criteria:**
- [ ] Tools not updated in 8+ hours have visual indicator
- [ ] Threshold configurable via environment variable
- [ ] Indicator is subtle but noticeable (faded or icon)
- [ ] Tooltip explains "Status may be stale"

**Files to create/modify:**
- `src/controllers/DashboardController.jl` - Add stale check
- `src/views/dashboard/index.jl.html` - Add stale indicator
- `public/css/qci.css` - Stale styling

---

### Unit 6.3: Dockerfile and Docker Compose
**Status:** PENDING
**Branch:** `feature/docker`
**Depends on:** All previous units

**Task:**
Create Dockerfile for production deployment. Include Docker Compose for easy local testing.

**Acceptance Criteria:**
- [ ] `Dockerfile` builds successfully
- [ ] Uses official Julia image
- [ ] Runs Pkg.instantiate() and precompiles
- [ ] Exposes port 8000
- [ ] `docker-compose.yml` for local testing
- [ ] Volume mount for SQLite persistence
- [ ] Environment variables documented

**Files to create/modify:**
- `Dockerfile` - Production image
- `docker-compose.yml` - Local testing
- `README.md` - Docker instructions

---

### Unit 6.4: Health Check and Logging
**Status:** PENDING
**Branch:** `feature/health-logging`
**Depends on:** 1.1

**Task:**
Ensure health check endpoint works and add structured logging for key events (login, status changes).

**Acceptance Criteria:**
- [ ] `GET /health` returns `{"status":"ok"}`
- [ ] Login attempts logged (success/failure, no passwords)
- [ ] Status changes logged (tool_id, user_id, new_state)
- [ ] Logs go to stdout/stderr for Docker
- [ ] Log level configurable via `LOG_LEVEL` env var

**Files to create/modify:**
- `src/controllers/HealthController.jl` - Health endpoint
- `src/lib/logging.jl` - Logging utilities
- `config/routes.jl` - Ensure health route exists

---

## Summary

| Milestone | Units | Description |
|-----------|-------|-------------|
| 1. Foundation | 3 | Project setup, config, base layout |
| 2. Data Models | 4 | User, Tool, StatusEvent models + seeds |
| 3. Authentication | 3 | Login, sessions, route protection |
| 4. Dashboard & Tools | 5 | Main views and status updates |
| 5. Admin Features | 3 | Tool and user management |
| 6. Polish & Deploy | 4 | CSS, Docker, health checks |

**Total: 22 work units**
