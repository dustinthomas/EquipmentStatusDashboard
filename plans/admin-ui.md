# Plan: Admin UI

**Spec:** `docs/features/admin-ui.md`
**Units:** `docs/features/admin-ui-units.md`
**Status:** Complete

## Overview

Add Vue.js frontend components for admin tool and user management. The backend API is fully implemented (`AdminController.jl`); this plan covers the frontend Vue components that consume those APIs.

The implementation follows existing Vue patterns in `public/js/app.js`:
- Reactive state management with `reactive()` and `ref()`
- Modal-based forms (like status update)
- Table components with sorting/filtering
- `currentView` routing pattern

## Architecture

### Key Design Decisions

1. **Extend existing app.js** - No new files, add admin state/methods to existing Vue app
2. **Modal-based forms** - Create/edit forms as modals (consistent with status update)
3. **Tab navigation** - Tools and Users as tabs within admin section
4. **Reuse existing CSS** - Use QCI table, card, modal, and form styles

### State Structure

```javascript
const admin = reactive({
    currentTab: 'tools',  // 'tools' | 'users'
    tools: {
        items: [],
        meta: {},
        loading: false,
        error: null
    },
    users: {
        items: [],
        meta: {},
        loading: false,
        error: null
    },
    // Modal state
    toolModal: { visible: false, mode: 'create', tool: null, ... },
    userModal: { visible: false, mode: 'create', user: null, ... },
    passwordModal: { visible: false, userId: null, ... }
});
```

### New `currentView` Values

- `'admin-tools'` - Tool management view
- `'admin-users'` - User management view

### Files to Modify

| File | Changes |
|------|---------|
| `public/js/app.js` | Add admin state, methods, computed properties, templates |
| `public/css/qci.css` | Add admin-specific styles (badges, tabs) |
| `config/routes.jl` | Update placeholder routes to serve Vue app |

## Milestones

### Milestone 1: Admin Navigation & Shell
- **Status:** Complete
- **Units:** 1.1
- Set up admin view routing and basic navigation with tabs

### Milestone 2: Tool Management UI
- **Status:** Complete
- **Units:** 2.1, 2.2
- Tool list table with CRUD modals

### Milestone 3: User Management UI
- **Status:** Complete
- **Units:** 3.1, 3.2
- User list table with CRUD modals and password reset

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Large app.js file | Keep admin code well-organized with clear section comments |
| CSS conflicts | Use admin-specific class prefixes where needed |
| Form validation | Leverage existing API validation, show returned errors |

## Updates

- 2026-01-30: Initial plan created
- 2026-01-30: Milestone 1 complete (Unit 1.1 verified, PR #36)
- 2026-01-30: Milestone 2 complete (Units 2.1, 2.2 merged, PRs #37, #38)
- 2026-01-30: Milestone 3 complete (Units 3.1, 3.2 implemented)
