# Vue.js Frontend Conversion - Work Units

## Status Legend
- PENDING: Not started
- IN_PROGRESS: Currently being worked on
- IMPLEMENTED: Code complete, needs verification
- VERIFIED: Tested and working
- MERGED: PR merged to main

---

## Phase 1: Project Setup

### Unit 1.1: Initialize Vite + Vue 3 Project
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] `frontend/` directory created with Vite Vue template
- [x] Dependencies installed: `vue-router@4`, `pinia`
- [x] `vite.config.js` configured with dev proxy to localhost:8000
- [x] Build output configured to `../public/dist/`
- [x] `npm run dev` works

---

### Unit 1.2: Migrate CSS Assets
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] CSS variables from `qci-theme.css` in `src/assets/css/variables.css`
- [x] Component styles from `qci.css` in `src/assets/css/main.css`
- [x] CSS imported in `main.js`
- [x] `qci-logo.svg` copied to `public/img/`

---

## Phase 2: Core Infrastructure

### Unit 2.1: Vue Router Setup
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Router created with routes:
  - `/` → redirect to `/vue`
  - `/vue` → DashboardView (requiresAuth)
  - `/vue/tools/:id` → ToolDetailView (requiresAuth)
  - `/vue/tools/:id/history` → ToolHistoryView (requiresAuth)
  - `/admin/tools` → AdminToolsView (requiresAuth, requiresAdmin)
  - `/admin/users` → AdminUsersView (requiresAuth, requiresAdmin)
- [x] Lazy loading enabled for all views

---

### Unit 2.2: API Composable
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] `useApi.js` composable created
- [x] Centralized fetch with `credentials: 'same-origin'`
- [x] Auto-redirect to login on 401 response
- [x] JSON content-type headers for POST/PUT

---

### Unit 2.3: Auth Store (Pinia)
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Auth store with state: `user`, `isAuthenticated`, `loading`, `error`
- [x] Getters: `isAdmin`, `userName`
- [x] Actions: `checkAuth()`, `login()`, `logout()`
- [x] Logic extracted from app.js lines 215-327

---

### Unit 2.4: Router Navigation Guards
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] `beforeEach` guard checks auth on protected routes
- [x] Unauthenticated users stay on login (no redirect needed - login is inline)
- [x] Non-admins blocked from admin routes

---

## Phase 3: View Components

### Unit 3.1: App.vue + Layout
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Root component with `<router-view>`
- [x] Conditional login form when not authenticated
- [x] NavBar component extracted from app.js

---

### Unit 3.2: Dashboard Store + View
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Pinia store: tools list, meta, filters, sort
- [x] Actions: `fetchTools()`, `applyFilters()`, `setSort()`
- [x] DashboardView component
- [x] FilterBar component
- [x] ToolTable component
- [x] StatusBadge component

---

### Unit 3.3: Tool Detail Store + View
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Pinia store: tool, statusForm state
- [x] Actions: `fetchTool()`, `updateStatus()`
- [x] ToolDetailView component
- [x] StatusUpdateModal component

---

### Unit 3.4: Tool History View
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] History state in toolDetail store
- [x] Date range filters
- [x] CSV export functionality
- [x] ToolHistoryView component

---

### Unit 3.5: Admin Store + Views
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Pinia store: tools list, users list, modal states
- [x] Full CRUD actions for both entities
- [x] AdminToolsView component
- [x] AdminUsersView component
- [x] ToolFormModal component
- [x] UserFormModal component
- [x] PasswordResetModal component

---

## Phase 4: UI/UX Improvements

### Unit 4.1: Enhanced Status Badges
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Icons added (dot, warning triangle, gear)
- [x] Pulse animation for UP status
- [x] Better color contrast for accessibility
- [x] Compact design

---

### Unit 4.2: Compact Data Tables
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Reduced padding for higher data density
- [x] Left border color coding by status
- [x] Improved hover states
- [x] Skeleton loading instead of spinners

---

### Unit 4.3: Inline Filter Bar
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Horizontal layout (not stacked)
- [x] Compact inputs
- [x] Clear visual hierarchy

---

### Unit 4.4: Modal Redesign
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Backdrop blur effect
- [x] Slide-up animation
- [x] Better header/footer separation
- [x] Loading states on buttons

---

### Unit 4.5: Toast Notifications
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] Success/error feedback
- [x] Slide-in animation
- [x] Auto-dismiss

---

## Phase 5: Integration & Cleanup

### Unit 5.1: Backend Route Updates
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] `config/routes.jl` updated to serve from `public/dist/`
- [x] All `/vue/*` routes serve `dist/index.html`

---

### Unit 5.2: Production Build
**Status:** IMPLEMENTED

**Acceptance Criteria:**
- [x] `npm run build` succeeds
- [x] Build output in `public/dist/`
- [ ] All features work with Genie backend (needs verification)

---

### Unit 5.3: Cleanup
**Status:** PENDING

**Acceptance Criteria:**
- [ ] Old `public/js/app.js` removed
- [ ] Old `public/index.html` removed (if applicable)
- [ ] Documentation updated

---

## Verification Checklist

After all units complete:
- [ ] Login/logout works
- [ ] Dashboard loads tools with filters and sorting
- [ ] Tool detail view shows status update modal
- [ ] Status updates persist and show in history
- [ ] History CSV export works
- [ ] Admin tools CRUD works
- [ ] Admin users CRUD works
- [ ] Password reset works
- [ ] Browser back/forward navigation works
- [ ] 401 responses redirect to login
- [ ] Non-admins cannot access admin pages
- [ ] Production build works with Genie
