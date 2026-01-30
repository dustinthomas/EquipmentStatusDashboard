# Work Units: Admin UI

**Plan:** `plans/admin-ui.md`
**Spec:** `docs/features/admin-ui.md`

## Status Legend
- PENDING: Not started
- IN_PROGRESS: Being worked on
- IMPLEMENTED: Code complete, needs verification
- VERIFIED: Tests pass, ready for merge
- MERGED: Complete

---

## Milestone 1: Admin Navigation & Shell

### Unit 1.1: Admin View Routing and Navigation
**Status:** IMPLEMENTED
**Branch:** `feature/admin-ui-shell`
**Depends on:** None

**Task:**
Set up admin view routing in Vue app and update server routes to serve the Vue app instead of placeholder HTML. Add tab navigation for switching between Tools and Users views.

**Acceptance Criteria:**
- [x] `currentView` supports `'admin-tools'` and `'admin-users'` values
- [x] `/admin/tools` and `/admin/users` routes serve Vue app (update `routes.jl`)
- [x] Admin navbar link navigates to admin tools view
- [x] Tab navigation component shows "Tools" and "Users" tabs
- [x] Clicking tabs switches between admin views
- [x] Browser back/forward works with admin views
- [x] Admin views only accessible to admin role users (server-side via `require_admin()`)

**Files to modify:**
- `public/js/app.js` - Add admin state, currentView handling, tab navigation template
- `config/routes.jl` - Update `/admin/tools` and `/admin/users` to serve Vue app
- `public/css/qci.css` - Add tab navigation styles

---

## Milestone 2: Tool Management UI

### Unit 2.1: Tool List Table
**Status:** PENDING
**Branch:** `feature/admin-tools-list`
**Depends on:** 1.1

**Task:**
Implement admin tool list table showing all tools (including inactive). Include search/filter, sorting, and visual distinction for inactive tools.

**Acceptance Criteria:**
- [ ] Admin tools view fetches from `GET /api/admin/tools` on mount
- [ ] Table displays: name, area, bay, criticality, current state, active/inactive badge
- [ ] Inactive tools show faded row style and "Inactive" badge
- [ ] Search input filters by tool name
- [ ] Column headers clickable for sorting (name, area, criticality)
- [ ] Loading spinner shown during fetch
- [ ] Error message displayed if fetch fails
- [ ] "Add Tool" button visible (opens modal in next unit)

**Files to modify:**
- `public/js/app.js` - Add admin.tools state, fetchAdminTools(), tool list template
- `public/css/qci.css` - Add inactive row styles, admin badges

---

### Unit 2.2: Tool Create/Edit/Toggle Modals
**Status:** PENDING
**Branch:** `feature/admin-tools-crud`
**Depends on:** 2.1

**Task:**
Implement modal forms for creating and editing tools, plus toggle active functionality with confirmation.

**Acceptance Criteria:**
- [ ] "Add Tool" button opens create modal
- [ ] Create form has: name (required), area (required), bay (optional), criticality (dropdown)
- [ ] Criticality dropdown shows: critical, high, medium, low
- [ ] Create form submits to `POST /api/admin/tools`
- [ ] Clicking edit button/icon on row opens edit modal
- [ ] Edit form pre-populated with tool's current values
- [ ] Edit form submits to `PUT /api/admin/tools/:id`
- [ ] Toggle active button calls `POST /api/admin/tools/:id/toggle-active`
- [ ] Confirmation prompt before toggling active status
- [ ] Success message shown after create/edit/toggle
- [ ] Form validation errors displayed from API response
- [ ] Tool list refreshes after successful operation
- [ ] Modal closes on success or cancel

**Files to modify:**
- `public/js/app.js` - Add toolModal state, create/edit/toggle methods, modal templates

---

## Milestone 3: User Management UI

### Unit 3.1: User List Table
**Status:** PENDING
**Branch:** `feature/admin-users-list`
**Depends on:** 1.1

**Task:**
Implement admin user list table showing all users (including inactive). Include search and visual distinction for inactive users.

**Acceptance Criteria:**
- [ ] Admin users view fetches from `GET /api/admin/users` on mount
- [ ] Table displays: username, name, role, last login (formatted), active/inactive badge
- [ ] Inactive users show faded row style and "Inactive" badge
- [ ] Role shown as badge (admin = primary color, operator = secondary)
- [ ] Search input filters by username or name
- [ ] Column headers clickable for sorting (username, name, role, last login)
- [ ] Loading spinner shown during fetch
- [ ] Error message displayed if fetch fails
- [ ] "Add User" button visible (opens modal in next unit)

**Files to modify:**
- `public/js/app.js` - Add admin.users state, fetchAdminUsers(), user list template
- `public/css/qci.css` - Add role badge styles

---

### Unit 3.2: User Create/Edit/Password/Toggle Modals
**Status:** PENDING
**Branch:** `feature/admin-users-crud`
**Depends on:** 3.1

**Task:**
Implement modal forms for creating users, editing users (without password), resetting passwords, and toggling active status with protection for last admin.

**Acceptance Criteria:**
- [ ] "Add User" button opens create modal
- [ ] Create form has: username (required), name (required), password (required), role (dropdown)
- [ ] Role dropdown shows: admin, operator
- [ ] Create form submits to `POST /api/admin/users`
- [ ] Clicking edit button/icon on row opens edit modal
- [ ] Edit form has: username, name, role (NO password field)
- [ ] Edit form pre-populated with user's current values
- [ ] Edit form submits to `PUT /api/admin/users/:id`
- [ ] "Reset Password" button opens password modal
- [ ] Password modal has single password field
- [ ] Password modal submits to `POST /api/admin/users/:id/reset-password`
- [ ] Toggle active button calls `POST /api/admin/users/:id/toggle-active`
- [ ] Confirmation prompt before toggling active status
- [ ] Error message shown if trying to deactivate/demote last admin (from API)
- [ ] Success message shown after create/edit/reset/toggle
- [ ] Form validation errors displayed from API response
- [ ] User list refreshes after successful operation
- [ ] Modal closes on success or cancel

**Files to modify:**
- `public/js/app.js` - Add userModal, passwordModal state, CRUD methods, modal templates

---

## Summary

| Milestone | Units | Description |
|-----------|-------|-------------|
| 1. Navigation | 1 | Admin routing, tabs |
| 2. Tool Management | 2 | Tool list + CRUD modals |
| 3. User Management | 2 | User list + CRUD modals |

**Total: 5 work units**
