# Vue.js + Tailwind CSS Migration Plan

## Executive Summary

This document outlines the plan to migrate the QCI Equipment Status Dashboard frontend from a single-file Vue 3 CDN setup to a modern Vite + Vue 3 + Tailwind CSS build system.

## Current Architecture

| Aspect | Current State |
|--------|---------------|
| Frontend | Vue 3 CDN (1,660 lines in single `app.js`) |
| Styling | Custom CSS (800+ lines `qci.css` + `qci-theme.css`) |
| Backend | Genie.jl with complete JSON REST API |
| API Coverage | Login, logout, tools CRUD, history, CSV export |
| Build System | None - direct browser execution |

## Target Architecture

| Aspect | Target State |
|--------|---------------|
| Frontend | Vue 3 + Vite + TypeScript |
| Styling | Tailwind CSS with QCI theme |
| Components | Single File Components (SFCs) |
| Build | Docker-based Node.js (keeps Node off host) |

## Migration Phases

### Phase 0: Debug Current Issue (COMPLETED)
- API returns correct `state_display` and `state_class` values
- Backend is working correctly
- Issue is in frontend rendering (CSS or Vue binding)

### Phase 1: Project Setup (2-4 hours)
- Create `frontend/` directory with Vite + Vue 3 + TypeScript
- Setup Tailwind CSS with QCI brand colors as theme
- Docker dev environment (keeps Node off your system)
- Vite proxy config for API calls to Genie backend

### Phase 2: Component Migration (8-12 hours)
Convert `app.js` into Vue Single File Components:
```
frontend/src/
├── components/
│   ├── StatusBadge.vue      # Reusable badge component
│   ├── ToolTable.vue        # Dashboard table
│   ├── ToolDetail.vue       # Tool detail view
│   ├── ToolHistory.vue      # History view
│   ├── StatusUpdateForm.vue # Status update modal
│   └── ui/                  # shadcn-vue components
├── views/
│   ├── DashboardView.vue
│   ├── LoginView.vue
│   └── ToolView.vue
├── composables/
│   ├── useAuth.ts           # Authentication logic
│   └── useTools.ts          # Tool API calls
└── App.vue
```

### Phase 3: Tailwind Styling (4-8 hours)
- Install shadcn-vue for pre-built components
- Convert QCI color scheme to Tailwind config
- Replace custom CSS with utility classes

### Phase 4: Production Build (2-4 hours)
- Build output goes to `public/` or dedicated static folder
- Genie serves built assets
- Docker production config

## Docker Development Setup

### Dockerfile.dev
```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
```

### docker-compose.dev.yml
```yaml
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    volumes:
      - ./frontend:/app
      - /app/node_modules  # Anonymous volume for node_modules
    ports:
      - "5173:5173"
    environment:
      - VITE_API_URL=http://host.docker.internal:8000

  backend:
    # Your existing Genie container
    ports:
      - "8000:8000"
```

## QCI Theme Colors (Tailwind)

```typescript
// tailwind.config.ts
colors: {
  qci: {
    'dark-navy': '#1E204B',
    'light-navy': '#222354',
    'light-grey': '#F4F5F9',
    'white': '#FFFFFF',
    'body-text': '#3A3D4A',
  },
  status: {
    up: '#2ecc71',
    'up-with-issues': '#f39c12',
    maintenance: '#e67e22',
    down: '#e74c3c',
  },
}
```

## Benefits of Migration

1. **Component architecture** - Reusable `.vue` files instead of one massive template string
2. **Tailwind utility classes** - No custom CSS maintenance, consistent spacing/colors
3. **Build-time optimization** - Tree-shaking, minification, code splitting
4. **TypeScript option** - Type safety for larger codebase
5. **Dev experience** - Hot Module Replacement, better tooling
6. **shadcn/ui components** - Pre-built Tailwind components via shadcn-vue

## Estimated Effort

| Phase | Hours |
|-------|-------|
| Phase 1: Setup | 2-4 |
| Phase 2: Components | 8-12 |
| Phase 3: Styling | 4-8 |
| Phase 4: Build | 2-4 |
| **Total** | **16-28** |

## Files Already Created

- `frontend/package.json` - Dependencies
- `frontend/tsconfig.json` - TypeScript config
- `frontend/vite.config.ts` - Vite config with API proxy
- `frontend/tailwind.config.ts` - Tailwind with QCI colors
- `frontend/postcss.config.js` - PostCSS for Tailwind
- `frontend/index.html` - Entry HTML

## Next Steps

1. Debug the current badge issue in the existing app
2. Once resolved, continue with Phase 1 setup
3. Incrementally migrate components while keeping old app functional
