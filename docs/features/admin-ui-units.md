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
**Status:** MERGED
**Branch:** `feature/admin-ui-shell`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/36
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
**Status:** MERGED
**Branch:** `feature/admin-tools-list`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/37
**Depends on:** 1.1

**Task:**
Implement admin tool list table showing all tools (including inactive). Include search/filter, sorting, and visual distinction for inactive tools.

**Acceptance Criteria:**
- [x] Admin tools view fetches from `GET /api/admin/tools` on mount
- [x] Table displays: name, area, bay, criticality, current state, active/inactive badge
- [x] Inactive tools show faded row style and "Inactive" badge
- [x] Search input filters by tool name
- [x] Column headers clickable for sorting (name, area, criticality)
- [x] Loading spinner shown during fetch
- [x] Error message displayed if fetch fails
- [x] "Add Tool" button visible (opens modal in next unit)

**Files to modify:**
- `public/js/app.js` - Add admin.tools state, fetchAdminTools(), tool list template
- `public/css/qci.css` - Add inactive row styles, admin badges

---

### Unit 2.2: Tool Create/Edit/Toggle Modals
**Status:** MERGED
**Branch:** `feature/admin-tools-crud`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/38
**Depends on:** 2.1

**Task:**
Implement modal forms for creating and editing tools, plus toggle active functionality with confirmation.

**Acceptance Criteria:**
- [x] "Add Tool" button opens create modal
- [x] Create form has: name (required), area (required), bay (optional), criticality (dropdown)
- [x] Criticality dropdown shows: critical, high, medium, low
- [x] Create form submits to `POST /api/admin/tools`
- [x] Clicking edit button/icon on row opens edit modal
- [x] Edit form pre-populated with tool's current values
- [x] Edit form submits to `PUT /api/admin/tools/:id`
- [x] Toggle active button calls `POST /api/admin/tools/:id/toggle-active`
- [x] Confirmation prompt before toggling active status
- [x] Success message shown after create/edit/toggle
- [x] Form validation errors displayed from API response
- [x] Tool list refreshes after successful operation
- [x] Modal closes on success or cancel

**Files to modify:**
- `public/js/app.js` - Add toolModal state, create/edit/toggle methods, modal templates

---

## Milestone 3: User Management UI

### Unit 3.1: User List Table
**Status:** MERGED
**Branch:** `feature/admin-users-list`
**PR:** https://github.com/dustinthomas/EquipmentStatusDashboard/pull/39
**Depends on:** 1.1

**Task:**
Implement admin user list table showing all users (including inactive). Include search and visual distinction for inactive users.

**Acceptance Criteria:**
- [x] Admin users view fetches from `GET /api/admin/users` on mount
- [x] Table displays: username, name, role, last login (formatted), active/inactive badge
- [x] Inactive users show faded row style and "Inactive" badge
- [x] Role shown as badge (admin = primary color, operator = secondary)
- [x] Search input filters by username or name
- [x] Column headers clickable for sorting (username, name, role, last login)
- [x] Loading spinner shown during fetch
- [x] Error message displayed if fetch fails
- [x] "Add User" button visible (opens modal in next unit)

**Files to modify:**
- `public/js/app.js` - Add admin.users state, fetchAdminUsers(), user list template
- `public/css/qci.css` - Add role badge styles

---

### Unit 3.2: User Create/Edit/Password/Toggle Modals
**Status:** IMPLEMENTED
**Branch:** `feature/admin-users-crud`
**Depends on:** 3.1

**Task:**
Implement modal forms for creating users, editing users (without password), resetting passwords, and toggling active status with protection for last admin.

**Acceptance Criteria:**
- [x] "Add User" button opens create modal
- [x] Create form has: username (required), name (required), password (required), role (dropdown)
- [x] Role dropdown shows: admin, operator
- [x] Create form submits to `POST /api/admin/users`
- [x] Clicking edit button/icon on row opens edit modal
- [x] Edit form has: username, name, role (NO password field)
- [x] Edit form pre-populated with user's current values
- [x] Edit form submits to `PUT /api/admin/users/:id`
- [x] "Reset Password" button opens password modal
- [x] Password modal has single password field
- [x] Password modal submits to `POST /api/admin/users/:id/reset-password`
- [x] Toggle active button calls `POST /api/admin/users/:id/toggle-active`
- [x] Confirmation prompt before toggling active status
- [x] Error message shown if trying to deactivate/demote last admin (from API)
- [x] Success message shown after create/edit/reset/toggle
- [x] Form validation errors displayed from API response
- [x] User list refreshes after successful operation
- [x] Modal closes on success or cancel

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
