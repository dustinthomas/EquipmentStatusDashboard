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
**Status:** IMPLEMENTED
**Branch:** `feature/vue-api-tools`
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
**Status:** PENDING
**Branch:** `feature/vue-api-auth`
**Depends on:** None

**Task:**
Create JSON API endpoints for authentication.

**Acceptance Criteria:**
- [ ] `POST /api/auth/login` accepts JSON `{username, password}`, returns user or error
- [ ] `POST /api/auth/logout` clears session, returns success
- [ ] `GET /api/auth/me` returns current user info or 401

**Files to modify:**
- `src/controllers/AuthController.jl` - Add `api_login()`, `api_logout()`, `api_me()`
- `config/routes.jl` - Add `/api/auth/*` routes

---

### Unit 1.3: API Error Handling
**Status:** PENDING
**Branch:** `feature/vue-api-errors`
**Depends on:** 1.1, 1.2

**Task:**
Standardize API error responses and add CORS headers if needed.

**Acceptance Criteria:**
- [ ] All API errors return consistent JSON format `{error: "message"}`
- [ ] 401 for unauthenticated, 403 for unauthorized, 400 for bad input
- [ ] Content-Type is application/json for all API responses

**Files to modify:**
- `src/lib/api_helpers.jl` - Create helper functions
- `src/controllers/DashboardController.jl` - Use helpers
- `src/controllers/AuthController.jl` - Use helpers

---

## Milestone 2: Vue App Shell

### Unit 2.1: HTML Shell & Vue Setup
**Status:** PENDING
**Branch:** `feature/vue-shell`
**Depends on:** None

**Task:**
Create the HTML shell that loads Vue and the app.

**Acceptance Criteria:**
- [ ] `public/index.html` loads Vue 3 from CDN
- [ ] Includes existing CSS files
- [ ] Has mount point for Vue app
- [ ] Shows loading state while Vue initializes
- [ ] Has `<noscript>` message for no-JS browsers

**Files to create:**
- `public/index.html` - HTML shell
- `public/js/app.js` - Empty Vue app scaffold

**Files to modify:**
- `config/routes.jl` - Serve index.html for frontend routes

---

### Unit 2.2: Authentication UI
**Status:** PENDING
**Branch:** `feature/vue-auth-ui`
**Depends on:** 1.2, 2.1

**Task:**
Implement login form and auth state management in Vue.

**Acceptance Criteria:**
- [ ] Login form with username/password fields
- [ ] Submit calls `/api/auth/login`
- [ ] Shows error messages on failed login
- [ ] Successful login redirects to dashboard
- [ ] Logout button calls `/api/auth/logout`
- [ ] App checks `/api/auth/me` on load to restore session

**Files to modify:**
- `public/js/app.js` - Add auth state, login component, methods

---

## Milestone 3: Dashboard Implementation

### Unit 3.1: Tool Table Component
**Status:** PENDING
**Branch:** `feature/vue-dashboard-table`
**Depends on:** 1.1, 2.1

**Task:**
Implement the main tools table with data fetching.

**Acceptance Criteria:**
- [ ] Fetches tools from `/api/tools` on mount
- [ ] Displays table with all columns (Name, Area, Status, Issue, ETA, Updated, Updated By)
- [ ] Status badges with correct CSS classes
- [ ] Clickable rows (prepare for tool detail view)
- [ ] Shows "No tools found" when empty
- [ ] Shows loading spinner during fetch

**Files to modify:**
- `public/js/app.js` - Add dashboard state and table rendering

---

### Unit 3.2: Filtering
**Status:** PENDING
**Branch:** `feature/vue-dashboard-filter`
**Depends on:** 3.1

**Task:**
Implement filter controls (state, area, search).

**Acceptance Criteria:**
- [ ] State dropdown with all states
- [ ] Area dropdown populated from tools data
- [ ] Search input for name filtering
- [ ] Apply button triggers API call with filters
- [ ] Clear button resets all filters
- [ ] Filters reflected in URL query string

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

## Milestone 4: Cleanup & Testing

### Unit 4.1: Navigation & Polish
**Status:** PENDING
**Branch:** `feature/vue-nav-polish`
**Depends on:** 2.2, 3.3

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

### Unit 4.2: Remove Old Templates & Final Testing
**Status:** PENDING
**Branch:** `feature/vue-cleanup`
**Depends on:** 4.1

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
