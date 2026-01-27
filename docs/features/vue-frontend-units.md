# Work Units: Vue.js Frontend Migration

**Plan:** `plans/vue-frontend.md`
**Spec:** `docs/features/vue-frontend.md`

## Status Legend
- PENDING: Not started
- IN_PROGRESS: Being worked on
- IMPLEMENTED: Code complete, needs verification
- VERIFIED: Tests pass, ready for merge
- MERGED: Complete

---

## Milestone 1: JSON API Layer

### Unit 1.1: Tools API Endpoint
**Status:** MERGED
**Branch:** `feature/vue-api-tools`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/12
**Depends on:** None

**Task:**
Create JSON API endpoint for listing tools with filter/sort support.

**Acceptance Criteria:**
- [x] `GET /api/tools` returns JSON array of tools
- [x] Supports query params: `state`, `area`, `search`, `sort`, `dir`
- [x] Returns tool data matching current dashboard fields
- [x] Protected by authentication (401 if not logged in)

**Files to modify:**
- `src/controllers/DashboardController.jl` - Add `api_index()` function
- `config/routes.jl` - Add `/api/tools` route

---

### Unit 1.2: Auth API Endpoints
**Status:** MERGED
**Branch:** `feature/vue-api-auth`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/13
**Depends on:** None

**Task:**
Create JSON API endpoints for authentication.

**Acceptance Criteria:**
- [x] `POST /api/auth/login` accepts JSON `{username, password}`, returns user or error
- [x] `POST /api/auth/logout` clears session, returns success
- [x] `GET /api/auth/me` returns current user info or 401

**Files to modify:**
- `src/controllers/AuthController.jl` - Add `api_login()`, `api_logout()`, `api_me()`
- `config/routes.jl` - Add `/api/auth/*` routes

---

### Unit 1.3: API Error Handling
**Status:** MERGED
**Branch:** `feature/vue-api-errors`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/14
**Depends on:** 1.1, 1.2

**Task:**
Standardize API error responses and add CORS headers if needed.

**Acceptance Criteria:**
- [x] All API errors return consistent JSON format `{error: "message"}`
- [x] 401 for unauthenticated, 403 for unauthorized, 400 for bad input
- [x] Content-Type is application/json for all API responses

**Files to modify:**
- `src/lib/api_helpers.jl` - Create helper functions
- `src/controllers/DashboardController.jl` - Use helpers
- `src/controllers/AuthController.jl` - Use helpers

---

### Unit 1.4: Tool Detail API
**Status:** MERGED
**Branch:** `feature/vue-api-tool-detail`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/15
**Depends on:** 1.3

**Task:**
Create JSON API endpoint for fetching a single tool's details.

**Acceptance Criteria:**
- [x] `GET /api/tools/:id` returns JSON with full tool details
- [x] Includes: name, area, bay, criticality, current state, issue, comment, ETA
- [x] Includes last updated timestamp and user name
- [x] Returns 404 JSON error for invalid tool ID
- [x] Protected by authentication (401 if not logged in)

**Files to modify:**
- `src/controllers/DashboardController.jl` - Add `api_show()` function
- `config/routes.jl` - Add `/api/tools/:id` route

---

### Unit 1.5: Status Update API
**Status:** MERGED
**Branch:** `feature/vue-api-status-update`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/16
**Depends on:** 1.3

**Task:**
Create JSON API endpoint for updating tool status.

**Acceptance Criteria:**
- [x] `POST /api/tools/:id/status` accepts JSON `{state, issue_description, comment, eta_to_up}`
- [x] Creates StatusEvent record
- [x] Updates Tool's current_* fields
- [x] Sets current_status_updated_by_user_id to logged-in user
- [x] If state is UP, clears ETA
- [x] Returns updated tool JSON on success
- [x] Returns 400 with validation errors on invalid input
- [x] Protected by authentication (401 if not logged in)

**Files to modify:**
- `src/controllers/DashboardController.jl` - Add `api_update_status()` function
- `config/routes.jl` - Add `/api/tools/:id/status` route

---

### Unit 1.6: Tool History API
**Status:** MERGED
**Branch:** `feature/vue-api-history`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/17
**Depends on:** 1.3

**Task:**
Create JSON API endpoint for fetching tool status history.

**Acceptance Criteria:**
- [x] `GET /api/tools/:id/history` returns JSON array of status events
- [x] Supports query params: `from`, `to` (date range filter)
- [x] Returns: timestamp, user name, state, issue, comment, ETA for each event
- [x] Ordered by created_at descending (newest first)
- [x] `GET /api/tools/:id/history.csv` returns CSV download
- [x] Protected by authentication (401 if not logged in)

**Files to modify:**
- `src/controllers/DashboardController.jl` - Add `api_history()` function
- `config/routes.jl` - Add `/api/tools/:id/history` route

---

## Milestone 2: Vue App Shell

### Unit 2.1: HTML Shell & Vue Setup
**Status:** MERGED
**Branch:** `feature/vue-shell`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/19
**Depends on:** None

**Task:**
Create the HTML shell that loads Vue and the app.

**Acceptance Criteria:**
- [x] `public/index.html` loads Vue 3 from CDN
- [x] Includes existing CSS files
- [x] Has mount point for Vue app
- [x] Shows loading state while Vue initializes
- [x] Has `<noscript>` message for no-JS browsers

**Files to create:**
- `public/index.html` - HTML shell
- `public/js/app.js` - Empty Vue app scaffold

**Files to modify:**
- `config/routes.jl` - Serve index.html for frontend routes

---

### Unit 2.2: Authentication UI
**Status:** MERGED
**Branch:** `feature/vue-auth-ui`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/20
**Depends on:** 1.2, 2.1

**Task:**
Implement login form and auth state management in Vue.

**Acceptance Criteria:**
- [x] Login form with username/password fields
- [x] Submit calls `/api/auth/login`
- [x] Shows error messages on failed login
- [x] Successful login redirects to dashboard
- [x] Logout button calls `/api/auth/logout`
- [x] App checks `/api/auth/me` on load to restore session

**Files to modify:**
- `public/js/app.js` - Add auth state, login component, methods

---

## Milestone 3: Dashboard Implementation

### Unit 3.1: Tool Table Component
**Status:** MERGED
**Branch:** `feature/vue-dashboard-table`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/21
**Depends on:** 1.1, 2.1

**Task:**
Implement the main tools table with data fetching.

**Acceptance Criteria:**
- [x] Fetches tools from `/api/tools` on mount
- [x] Displays table with all columns (Name, Area, Status, Issue, ETA, Updated, Updated By)
- [x] Status badges with correct CSS classes
- [x] Clickable rows (prepare for tool detail view)
- [x] Shows "No tools found" when empty
- [x] Shows loading spinner during fetch

**Files to modify:**
- `public/js/app.js` - Add dashboard state and table rendering

---

### Unit 3.2: Filtering
**Status:** MERGED
**Branch:** `feature/vue-dashboard-filter`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/23
**Depends on:** 3.1

**Task:**
Implement filter controls (state, area, search).

**Acceptance Criteria:**
- [x] State dropdown with all states
- [x] Area dropdown populated from tools data
- [x] Search input for name filtering
- [x] Apply button triggers API call with filters
- [x] Clear button resets all filters
- [x] Filters reflected in URL query string

**Files to modify:**
- `public/js/app.js` - Add filter state and handlers

---

### Unit 3.3: Sorting
**Status:** PENDING
**Branch:** `feature/vue-dashboard-sort`
**Depends on:** 3.1

**Task:**
Implement column sorting.

**Acceptance Criteria:**
- [ ] Clickable column headers for sortable columns
- [ ] Toggle asc/desc on repeated clicks
- [ ] Sort indicator (arrow) on active column
- [ ] State column sorts by priority (DOWN first)
- [ ] Sort params included in API call
- [ ] Sort state reflected in URL query string

**Files to modify:**
- `public/js/app.js` - Add sort state and handlers

---

## Milestone 4: Tool Management Views

### Unit 4.1: Tool Detail View
**Status:** PENDING
**Branch:** `feature/vue-tool-detail`
**Depends on:** 1.4, 2.1

**Task:**
Implement tool detail view showing full status and actions.

**Acceptance Criteria:**
- [ ] Clicking a tool row navigates to detail view
- [ ] Shows: name, area, bay, criticality, current state, issue, comment, ETA
- [ ] Shows last updated timestamp and user name
- [ ] "Update Status" button opens status update form
- [ ] "View History" button navigates to history view
- [ ] "Back to Dashboard" link
- [ ] Loading state while fetching
- [ ] Error handling for 404

**Files to modify:**
- `public/js/app.js` - Add tool detail component and routing

---

### Unit 4.2: Status Update Form
**Status:** PENDING
**Branch:** `feature/vue-status-update`
**Depends on:** 1.5, 4.1

**Task:**
Implement status update form as modal or inline component.

**Acceptance Criteria:**
- [ ] Form with: state dropdown (required), issue (optional), comment (optional), ETA (optional)
- [ ] State dropdown shows all valid states with color indicators
- [ ] ETA field hidden/cleared when state is UP
- [ ] Submit calls `/api/tools/:id/status`
- [ ] Shows validation errors from API
- [ ] Success updates tool detail view
- [ ] Cancel button closes form without saving

**Files to modify:**
- `public/js/app.js` - Add status update component

---

### Unit 4.3: Tool History View
**Status:** PENDING
**Branch:** `feature/vue-history`
**Depends on:** 1.6, 4.1

**Task:**
Implement tool history view with filtering and export.

**Acceptance Criteria:**
- [ ] Lists all status events for the tool
- [ ] Shows: timestamp, user, state, issue, comment, ETA
- [ ] Ordered newest first
- [ ] Date range filter (from/to date pickers)
- [ ] "Export CSV" button triggers download
- [ ] "Back to Tool" link
- [ ] Loading state while fetching

**Files to modify:**
- `public/js/app.js` - Add history component

---

## Milestone 5: Cleanup & Testing

### Unit 5.1: Navigation & Polish
**Status:** PENDING
**Branch:** `feature/vue-nav-polish`
**Depends on:** 2.2, 4.3

**Task:**
Complete navigation and polish the UI.

**Acceptance Criteria:**
- [ ] Navbar with Dashboard link
- [ ] Admin link visible only for admin role
- [ ] Login/Logout link based on auth state
- [ ] Tool count display (X of Y tools shown)
- [ ] Loading states for all async operations
- [ ] Error handling with user-friendly messages

**Files to modify:**
- `public/js/app.js` - Add navbar component, polish UI
- `public/css/qci.css` - Add any Vue-specific styles

---

### Unit 5.2: Remove Old Templates & Final Testing
**Status:** PENDING
**Branch:** `feature/vue-cleanup`
**Depends on:** 5.1

**Task:**
Remove old Genie templates and ensure all tests pass.

**Acceptance Criteria:**
- [ ] Remove `app/resources/dashboard/views/`
- [ ] Remove `app/resources/layouts/views/`
- [ ] Remove `src/views/`
- [ ] Update any remaining HTML route references
- [ ] All existing tests pass
- [ ] Manual testing of all features complete

**Files to delete:**
- `app/resources/dashboard/views/*.jl.html`
- `app/resources/layouts/views/*.jl.html`
- `src/views/**/*`

**Files to modify:**
- `config/routes.jl` - Remove old HTML routes
- `src/controllers/DashboardController.jl` - Remove HTML rendering methods
