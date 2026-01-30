# Admin UI Feature Specification

## Overview

The Admin UI provides a web interface for administrators to manage tools and users in the QCI Equipment Status Dashboard. The backend API is fully implemented (Units 5.1-5.3); this feature adds the Vue.js frontend to consume those APIs.

## Reference

- **Admin API Implementation:** `docs/features/equipment-status-dashboard-units.md` (Units 5.1-5.3)
- **Vue Frontend Patterns:** `docs/features/vue-frontend-units.md`
- **API Controller:** `src/controllers/AdminController.jl`

## Existing API Endpoints

### Tool Management (`/api/admin/tools`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/tools` | List all tools (including inactive) with metadata |
| GET | `/api/admin/tools/:id` | Get single tool details |
| POST | `/api/admin/tools` | Create new tool |
| PUT | `/api/admin/tools/:id` | Update tool details |
| POST | `/api/admin/tools/:id/toggle-active` | Toggle tool active status |

### User Management (`/api/admin/users`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/users` | List all users (including inactive) with metadata |
| GET | `/api/admin/users/:id` | Get single user details |
| POST | `/api/admin/users` | Create new user |
| PUT | `/api/admin/users/:id` | Update user details (not password) |
| POST | `/api/admin/users/:id/reset-password` | Reset user password |
| POST | `/api/admin/users/:id/toggle-active` | Toggle user active status |

## User Stories

### Tool Management
1. **As an admin, I want to view all tools** (including inactive ones) so I can manage the equipment inventory
2. **As an admin, I want to create a new tool** so I can add equipment to the system
3. **As an admin, I want to edit tool details** (name, area, bay, criticality) so I can keep equipment information current
4. **As an admin, I want to deactivate/reactivate tools** so I can soft-delete equipment without losing history

### User Management
1. **As an admin, I want to view all users** (including inactive ones) so I can manage system access
2. **As an admin, I want to create a new user** so I can grant system access to operators
3. **As an admin, I want to edit user details** (username, name, role) so I can update user information
4. **As an admin, I want to reset a user's password** so I can help users who forgot their credentials
5. **As an admin, I want to deactivate/reactivate users** so I can control system access without losing audit history

## Acceptance Criteria

### General
- [ ] Admin UI accessible only to users with `admin` role
- [ ] Non-admins redirected to dashboard with error message (existing behavior)
- [ ] Admin link visible in navbar only for admin users (already implemented)
- [ ] Loading states shown during API calls
- [ ] Error messages displayed for failed operations
- [ ] Success feedback shown after create/update/toggle operations

### Tool Management UI
- [ ] `/admin/tools` displays table of all tools (active and inactive)
- [ ] Table shows: name, area, bay, criticality, status, active/inactive badge
- [ ] Inactive tools visually distinguished (e.g., faded row, badge)
- [ ] "Add Tool" button opens create form modal
- [ ] Create form fields: name (required), area (required), bay (optional), criticality (dropdown)
- [ ] Clicking a tool row or edit button opens edit form modal
- [ ] Edit form pre-populated with current values
- [ ] Toggle active button changes tool status with confirmation
- [ ] Search/filter by name, area, or status
- [ ] Form validation with error messages

### User Management UI
- [ ] `/admin/users` displays table of all users (active and inactive)
- [ ] Table shows: username, name, role, last login, active/inactive badge
- [ ] Inactive users visually distinguished
- [ ] "Add User" button opens create form modal
- [ ] Create form fields: username (required), name (required), password (required), role (dropdown)
- [ ] Clicking a user row or edit button opens edit form modal
- [ ] Edit form excludes password field (use separate reset)
- [ ] "Reset Password" button opens password reset modal
- [ ] Toggle active button with protection for last admin
- [ ] Cannot deactivate or demote the last active admin (API enforced, UI should show message)
- [ ] Form validation with error messages

## UI/UX Requirements

### Navigation
- Extend existing Vue app with admin views
- Internal navigation: Dashboard <-> Admin Tools <-> Admin Users
- Use same `currentView` pattern as existing tool detail/history views
- Tab navigation within admin section (Tools | Users)

### Styling
- Follow existing QCI branding (see `CLAUDE.md` and `public/css/qci.css`)
- Use existing card, table, button, and form styles
- Use modal pattern consistent with status update form
- Status badges for role (admin = primary, operator = secondary)
- Active/inactive badges with distinct colors

### Forms
- Modal-based create/edit forms (consistent with status update modal)
- Required field indicators
- Real-time validation feedback
- Cancel button to close without saving
- Disabled state during submission

### Tables
- Consistent with dashboard table styling
- Clickable rows for edit action
- Action buttons in last column (edit, toggle active)
- Sort by columns (name, role, last login)
- Search/filter capability

## Technical Approach

- Extend `public/js/app.js` with admin state and methods
- Add new `currentView` options: `'admin-tools'`, `'admin-users'`
- Route handling for `/admin/tools` and `/admin/users` in Vue
- Reuse existing modal, table, and form CSS
- No build step required (CDN Vue 3)

## Out of Scope

- Bulk operations (delete multiple tools/users)
- CSV import/export for tools/users
- Advanced filtering (date ranges, multiple criteria)
- Password complexity requirements beyond minimum length
- Two-factor authentication
- User activity audit log view
