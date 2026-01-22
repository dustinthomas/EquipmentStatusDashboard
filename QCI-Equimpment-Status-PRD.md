History
Recent
can you find me a globe mape that the scale is real to geography
wiptrack
Can you help me make a PRD to hand off to claude code. This spread sheet we use as dashbaord. I want
google maps
How does pricing work for teams. It seems like if the license is purchased and I assign basic usage
google sheets
antthropic team pricing
install slack
when coding like Norris Cherny she's he retric his ai to write around 250 lines of code at a time?
Calude team
animae
nano banna
nano banaa
How large is gemini context window?
Give me a random color to represent a category in on todo list, in the form of #00FF00
How do download claude cowork. I have a teams premium so I should be able to use it.
How to install claude cowork
when using yazi what is the key your press that give you optiosn of what to open a folder in?
how many lines of code approximately 200k tokens?
what kind of tree is this.
View All


Account

Upgrade
Can you help me make a PRD to hand off to claude code. This spread sheet we use as dashbaord. I want to brain storm about it to generate ideas. I want to choose the technology stack. I wan to keep this app pretty simple. It does need to have a database for data rention and to interface with other data sources. Let get into brain storming first

Attachment
image.jpg
Perfect! I can see your Equipment Status dashboard. This is a solid foundation to build on. Let me brain storm with you on this PRD and technology stack choices.

Current Dashboard Analysis
What's Working Well:

Clean color-coded status system (Yellow "UP WITH ISSUES", Green "UP", Orange "Maintenance")

Essential columns: Tool, State, Time, Who, Issue Description, Comment

Human-readable data with last-update timestamps

Good for quick visual scanning of equipment health

Current Pain Points I See:

Data Persistence: Google Sheets doesn't have robust historical tracking

Integration: Manual entry or limited API capabilities

Scalability: Google Sheets starts struggling with large datasets

Real-time Updates: Limited webhook/push capabilities

Audit Trail: No built-in version history or change tracking

Querying: Can't easily query historical trends or generate reports

Access Control: Limited granular permissions

Brainstorming: Feature Wishlist
Before we pick tech stack, let's think about what would make this more powerful:

Data & Reporting:

Historical trend analysis (equipment downtime over time)

Predictive alerts ("this pump is degrading, ETA to failure")

Export reports (daily/weekly status summaries)

CSV/JSON data export for analysis

Real-Time Enhancements:

Automated status updates from equipment sensors (MQTT from IoT devices)

Slack/email notifications on state changes

Automatic timestamp capture instead of manual entry

Status update confirmation (avoid stale data)

Operational:

Equipment notes/runbook lookup

Spare parts inventory tracking

Maintenance history per tool

Root cause categorization

SLA tracking (how long down, target resolution time)

Admin/Access:

Multi-site support (if you expand)

Role-based access (techs vs managers vs read-only)

Change audit log

Backup/disaster recovery

Technology Stack Options
Given you're a Julia + Arduino + Linux + CLI person with fab equipment expertise, here are realistic stacks:

Option 1: Julia Full-Stack (My recommendation for you)
text
Frontend:  Genie.jl (Julia web framework) + HTMX
Backend:   Julia + HTTP.jl
Database:  PostgreSQL
Real-time: MQTT.jl for sensor integration
Pros:

Single language (Julia) - faster development for you

Genie.jl has real-time WebSocket support

Julia excels at data analysis for trend generation

Native MQTT support for Arduino sensor integration

Your existing ARM expertise

Cons:

Smaller ecosystem than JS/Python

Steeper learning curve for other maintainers

Effort: Medium, but leverages your existing skills

Option 2: Python/FastAPI (Industry Standard)
text
Frontend:  React or Vue.js
Backend:   Python FastAPI
Database:  PostgreSQL
Real-time: FastAPI WebSockets + Celery for background tasks
Sensors:   Python MQTT.py
Pros:

Industry standard, easy to hand off

Rich ecosystem (pandas for analysis, APScheduler for automation)

Large community, tons of examples

Easy Docker deployment

Cons:

Requires learning React/JS if you want custom UI

Adds complexity vs Julia approach

Effort: High if building custom frontend

Option 3: Lightweight Julia + SQLite (Minimal)
text
Frontend:  Simple HTML dashboard (vanilla JS)
Backend:   Julia HTTP.jl microservice
Database:  SQLite (file-based, zero admin)
Real-time: WebSockets or polling
Pros:

Dead simple, deploy anywhere (single binary with Julia)

Minimal dependencies

Perfect for small fab operations

Zero database maintenance

Cons:

SQLite doesn't scale to massive datasets (but fine for equipment tracking)

Limited concurrent writes

No server clusters

Effort: Low, quickest to MVP

Option 4: Node.js + Express (Fast & Modern)
text
Frontend:  React/SvelteKit
Backend:   Node.js + Express
Database:  PostgreSQL
Real-time: Socket.io
Pros:

JavaScript everywhere (one language)

Extremely fast development

Easy deployment (Vercel, Railway, Fly.io)

Cons:

You'd need to work in JS/TS

Less natural for data analysis features

Effort: Medium

My Recommendation for Your Fab
Given:

You want simple but effective

You have fab-specific equipment knowledge

You're comfortable with Julia + Linux + databases

You want to interface with Arduino/sensors (MQTT)

You're building this for internal fab use (not scaling to 10k users)

I'd suggest: Option 3 (Julia + HTML + SQLite) as MVP, with PostgreSQL upgrade path

Phase 1 (MVP in 2 weeks):

Julia backend with HTTP.jl

Simple HTML dashboard (maybe Bootstrap for styling)

SQLite database

Basic CRUD operations (add/update/delete equipment status)

CSV export

No real-time updates yet

Phase 2 (add sophistication):

PostgreSQL instead of SQLite (drop-in replacement)

MQTT integration for Arduino sensors

WebSocket real-time updates

Historical trend graphs (using Plots.jl or Plotly.jl)

Slack integration

Questions to Guide PRD Development
Before we write the PRD, help me understand:

Data Sources: Will statuses be manual entry, auto-sensor-driven, or both?

Scale: How many equipment items? Expected concurrent users?

Integration Points: What other systems need to read/write this data? (ERP, MES, inventory systems?)

Reporting: What reports matter most? (downtime trends, MTTR, parts tracking?)

Mobile: Desktop-only or mobile-friendly required?

Notifications: Should this alert people proactively? (Slack, email, SMS?)

Maintenance Window: Will this replace Google Sheets or run alongside it?

Skills on Team: Who else would maintain this? Just you or others?

What resonates with you? Want to do Julia full-stack, or safer Python/Node bet?

We still hooking up a equipment network. It will take some time. So just manual update. Maybe only an admin login. We could have users login and have the status when they update things it auto logged. The site will be on an intral never see the outside world.
That setup is perfect for a simple, internal-first MVP: manual-only updates, intranet-only, and basic auth with activity logging.

Core Concept For MVP
Manual updates only for now; future-proof for sensor integration.

Single intranet-hosted web app reachable from fab PCs.

Minimal auth:

Admin users: manage tools, edit any status.

Standard users (optional): update status; all changes auto-logged.

Audit trail:

Every status change stores: user, timestamp, old state, new state, comments.

MVP Features To Capture In PRD
Equipment & Status
Tool list with:

Name, area, category, criticality flag.

Current state (UP, UP WITH ISSUES, MAINTENANCE, DOWN).

Last updated time and by whom.

Status update form:

State dropdown.

Issue description.

Comment / action taken.

Auto-captured timestamp and user identity.

Users & Permissions
Authentication:

Simple username/password or intranet SSO later.

Roles:

Admin: manage equipment list, edit/remove entries, manage users.

User: change status, add comments, cannot delete tools.

Logging:

Each change written to a history table (no hard deletes; only soft-archive tools).

Views & UX
Main dashboard view:

Table very similar to the Google Sheet layout.

Color-coded rows by state (green/yellow/orange/red).

Sort by state, last update time, tool name.

Search/filter by tool name, state, area.

Detail view:

Per-tool page with:

Current status.

History of changes (timeline).

Suggested Tech Stack Given Constraints
Because this is intranet-only, manual-only initially, and you want simplicity:

Backend

Julia + HTTP.jl or Genie.jl

MVC-ish structure but keep endpoints simple REST:

GET /tools, GET /tools/:id, POST /tools/:id/status, GET /history

Database

SQLite for MVP:

Tables: users, tools, status_events.

Later migration path to PostgreSQL if needed.

Frontend

Server-rendered HTML with a light JS sprinkle:

Bootstrap or Pico.css for quick styling.

No SPA needed; keep it submit/redirect for reliability.

View pages:

/login, /dashboard, /tools/:id, /admin/tools, /admin/users.

Auth

Cookie-based sessions stored in DB.

Passwords hashed with a standard library (Argon2/bcrypt).

Next Step: Draft PRD Sections
If this direction looks right, next step is to draft the PRD sections like:

Goals & Non-Goals

User Roles & Permissions

User Flows

Data Model

Pages & Endpoints

Security & Deployment

Reply with:

Whether you want users + admin, or admin-only for v1.

Any must-have fields beyond what’s in the sheet (area, bay, uptime target, etc.).

Once you answer those, the PRD can be written in a Claude-friendly structure for implementation.

ok which is better for the light wieght app Genie or Http? Maybe Genie has btter feature for database and user login? Also we need to theme is with Qci colors and fonts I can provide those. It will be deployed and developed in docker.
For what you described, Genie is the better fit than bare HTTP.jl.

Genie vs HTTP.jl for your use case
Genie.jl advantages

Has first-class support for routing, templating, and sessions out of the box, so you are not hand-rolling auth and HTML rendering.

Integrates directly with SearchLight.jl, a native ORM that supports SQLite, Postgres, and MySQL, which gives you migrations and a clean data model for tools, users, and status history.

Provides GenieAuthentication.jl, a plugin that scaffolds DB‑backed user authentication (users table, migrations, login routes), exactly what you want for admin + user logins.

Has built-in documentation and tutorials aimed at CRUD/MVC apps, which fits this dashboard well.

HTTP.jl alone

Super lightweight but very low-level; you’d need to build routing, session management, authentication, and DB integration yourself or stitch several libraries together.
​

Best when you want a tiny API or very custom stack, not when you need standard web-app features fast.

For an internal CRUD dashboard with auth, history, and DB, Genie + SearchLight + GenieAuthentication will get you productive much faster with less boilerplate.

Database, Auth, and Theming in Genie
Database

Genie pairs with SearchLight; you can choose SQLite for MVP and later swap to Postgres with configuration changes and migrations.

User login

GenieAuthentication installs models, controllers, and migrations for a users table, then you run a migration command to create it and get DB‑backed auth.

You can restrict routes to authenticated users and later add role-based authorization via GenieAuthorisation if you want admin vs user separation.

Theming (QCI colors/fonts)

Genie uses standard HTML templating; you can drop in a custom CSS file (with your QCI color palette and fonts) or integrate Bootstrap/Tailwind with your own variables.

This makes it straightforward to match corporate branding once you provide colors and font stack.

Docker Deployment
Genie has specific tooling for Docker via GenieDeployDocker, which can generate an optimized Dockerfile and even build/run the container for you.

Typical pattern: place the generated Dockerfile at the app root and use standard docker build / docker run or Fly.io-style deployment if you ever expose it beyond the intranet.

If you’re good with this, next step is:

Lock in Genie + SearchLight + GenieAuthentication + SQLite,

You send the QCI color and font specs,

Then draft the PRD sections assuming this stack (routes, models, templates, and Docker deployment requirements).

oh yeah add column for ETA to UP
Perfect. I'll add that to the data model and dashboard.

Updated Data Model
StatusEvent now includes:

id, tool_id, state, issue_description, comment, created_at, created_by_user_id

eta_to_up (datetime, nullable) — when the equipment is expected to be back online

Dashboard Changes
Add "ETA to UP" column to the main equipment status table.

Display as:

Empty/blank if state is already "UP"

ISO datetime (or relative time like "in 4 hours") if state is "UP WITH ISSUES", "MAINTENANCE", or "DOWN"

Visual highlight (e.g., red text) if ETA has passed

Sort/filter by ETA so you can see which tools are coming back soonest.

Status Update Form
When updating status to anything other than "UP", prompt for optional eta_to_up field.

If user clears the ETA field, it nulls out (no ETA set).

When status changes back to "UP", the ETA is cleared automatically.

This way:

Operators know at a glance when gear will be back.

You can plan shift hand-offs around ETAs.

If a tool comes back early or late, someone updates the status and ETA accordingly.

Ready to write the full PRD now?

Stretch goal would produce a graph that shows the relations ships for utiliztion meaning up time down time, up with issues.
That’s a great stretch goal and fits naturally with the data you’re already logging.

Stretch Goal: Utilization & State Graphs
Objective: Visualize, per tool (and optionally per area), how much time is spent in each state: UP, UP WITH ISSUES, MAINTENANCE, DOWN, over a selected period.

Data Needed (already covered by model)
From StatusEvent history:

tool_id

state

created_at

Next event time (derived in query) to get a time interval per state

The app can derive state intervals by pairing each event with the next event’s timestamp, or “now” if it is the latest.

Graph Types in PRD
Per-tool stacked bar chart

X-axis: time window (day/week/month)

Y-axis: hours

Bars: stacked segments for each state (UP, UP WITH ISSUES, MAINTENANCE, DOWN) showing total hours in that period.

Per-area utilization summary

For a given date range, show one bar per tool or per area with percentage of time in each state.

UI Placement
“Analytics” tab or button from dashboard:

Filters: date range, area, specific tool(s).

Default: last 30 days, all tools.

Implementation Notes for Claude
Compute state intervals in backend (Genie controller):

Query StatusEvent by tool and date range.

Sort by created_at, pair adjacent events.

Aggregate durations (in hours) by state.

Serve JSON to a small JS chart library:

e.g., Chart.js or Plotly embedded via CDN.

Use QCI palette:

UP: green

UP WITH ISSUES: yellow

MAINTENANCE: orange

DOWN: red

Backgrounds and fonts from QCI theme.

This can be clearly marked in the PRD as “Phase 2 / Stretch: Utilization Analytics” so Claude knows it’s optional but desirable.

Ok I think we can produce the PRD now
QCI Equipment Status PRD
Document

Created a comprehensive Product Requirements Document for the QCI Equipment Status Dashboard. The PRD covers all key sections: executive summary, goals/non-goals, user roles and permissions, core user flows, data model, routes, branding guidelines (QCI colors, Raleway font, logo), technical stack (Genie.jl + SearchLight.jl + SQLite), Docker deployment, Phase 1 MVP features, Phase 2 stretch goals (utilization analytics), and success criteria. Includes handoff notes for Claude Code implementation and a visual reference appendix with colors and font stack. Ready for direct implementation.






QCI Equipment Status PRD


# QCI Equipment Status Dashboard – Product Requirements Document

**Product Owner:** Dustin (Facilities/Process Engineering)  
**Company:** Quantum Computing Inc (QCI)  
**Status:** PRD for handoff to Claude Code  
**Date:** January 22, 2026  

---

## 1. Executive Summary

Replace the current Google Sheets equipment status tracker with an internal web application that provides real-time manual status updates, audit logging, and role-based access control. The app will run on intranet only, deployed via Docker, and built with Genie.jl + SearchLight.jl + SQLite.

**MVP Target:** 2–3 weeks for core functionality.  
**Stretch Goal:** Utilization analytics with state-duration graphs.

---

## 2. Goals

- ✅ **Replace Google Sheets** with a dedicated, internally-hosted web app.
- ✅ **Track equipment state** (UP, UP WITH ISSUES, MAINTENANCE, DOWN) with automatic audit trail.
- ✅ **Role-based access**: Admin (manage tools & users) and Operator (update status & comments).
- ✅ **Track ETA to UP** for tools not yet operational.
- ✅ **Audit trail**: Every status change is immutable and tied to a user and timestamp.
- ✅ **Export & reporting**: CSV export of tool history; optional analytics dashboard (stretch).
- ✅ **Intranet-only deployment** via Docker with SQLite database.
- ✅ **QCI branding**: Use Raleway font, QCI color palette, and company logo.

---

## 3. Non-Goals / Out of Scope (v1)

- ❌ No equipment sensor/MQTT integration; all updates are manual.
- ❌ No external internet access; **intranet only**.
- ❌ No advanced real-time alerting or Slack integration in v1.
- ❌ No multi-site or federation; single QCI fab instance.
- ❌ No predictive maintenance or ML-based analytics in v1.
- ❌ Analytics/utilization graphs (marked as Phase 2 stretch goal).

---

## 4. User Roles & Permissions

### Admin
- Create, edit, and delete tools.
- Manage user accounts (create, deactivate, reset roles).
- Edit any tool's status, issue description, and ETA.
- View full audit trail and history for all tools.
- Export data to CSV.

### Operator (Standard User)
- View all tools and their current status.
- Update tool status, issue description, and ETA on assigned or any tool (permission TBD).
- Add comments to status events.
- View tool history (own updates and those by others).
- Export tool-specific history to CSV.

### Guest/Unauthenticated
- No access; redirect to login page.

---

## 5. Core User Flows

### 5.1 Login Flow
1. User navigates to intranet URL (e.g., `http://qci-status.internal`).
2. If not authenticated, redirect to `/login`.
3. Enter username/password (managed by GenieAuthentication).
4. On success, redirect to `/dashboard`.
5. Session stored as cookie; logout clears session.

### 5.2 Dashboard View (Main)
1. User lands on `/dashboard` showing a table of all equipment.
2. Table displays:
   - **Tool Name** (clickable to detail view)
   - **Area** (e.g., Litho, Etch, Deposition)
   - **Current State** (color-coded: green=UP, yellow=UP WITH ISSUES, orange=MAINTENANCE, red=DOWN)
   - **Last Updated** (timestamp and by whom)
   - **ETA to UP** (if applicable, or blank if UP)
   - **Issue Description** (first 50 chars; full text in detail view)
   - **Comment** (preview; full text in detail view)
3. Rows sorted by state (down tools first), then by ETA.
4. Filter/search by tool name, area, state.
5. Button: **"Update Status"** (leads to form or inline edit).
6. Admin users see additional **"Manage Tools"** and **"Manage Users"** buttons.

### 5.3 Update Status Flow
1. From dashboard, click **"Update Status"** on a tool row.
2. Navigate to `/tools/:id/update` form with fields:
   - **Current State** (dropdown: UP, UP WITH ISSUES, MAINTENANCE, DOWN)
   - **Issue Description** (textarea; required if state != UP)
   - **ETA to UP** (datetime picker; optional; only shown if state != UP)
   - **Comment** (textarea; optional; auto-appended with user name and timestamp)
   - **Submit** button
3. On submit:
   - Validate required fields.
   - Create new `StatusEvent` record with `user_id`, timestamp, old/new state.
   - If state changes to UP, clear `eta_to_up`.
   - Redirect to `/tools/:id` (detail view) with confirmation message.

### 5.4 Tool Detail View
1. Navigate to `/tools/:id` showing:
   - **Tool info**: name, area, bay/line, criticality.
   - **Current status**: state, ETA, issue, comment.
   - **History timeline**: list of last 20 status events with date, user, state change, and comment.
   - **Button**: "Update Status" → redirects to form.
   - **Admin only**: "Edit Tool" and "Delete Tool" buttons.
2. Collapse/expand history for readability.

### 5.5 Manage Tools (Admin)
1. Navigate to `/admin/tools` showing a table of all tools.
2. Columns: name, area, bay, criticality, current state, last updated, actions.
3. Buttons:
   - **"Add Tool"** → modal/form to create new tool (auto-creates "UP" initial state).
   - **"Edit"** (per row) → edit name, area, bay, criticality; state changes via dashboard.
   - **"Deactivate"** (per row) → soft-delete; hide from main dashboard but keep in history.

### 5.6 Manage Users (Admin)
1. Navigate to `/admin/users` showing a table of all users.
2. Columns: username, name, role, last login, actions.
3. Buttons:
   - **"Add User"** → form with username, password, name, role.
   - **"Edit"** (per row) → update name or role.
   - **"Deactivate"** (per row) → soft-delete; prevent login but keep audit trail.

### 5.7 Export History
1. From tool detail `/tools/:id`, button **"Export History to CSV"**.
2. Downloads CSV with columns: date, user, state, issue description, comment, eta_to_up.
3. Date range filter (default: last 30 days, configurable).

---

## 6. Data Model

### User
id (primary key)
username (unique, string)
password_hash (bcrypt/argon2)
name (string)
role (enum: admin, operator)
last_login_at (datetime, nullable)
created_at (datetime)
updated_at (datetime)
is_active (boolean, default: true)

### Tool
id (primary key)
name (string, unique)
area (string, e.g., "Litho", "Etch", "Deposition")
bay_or_line (string, e.g., "Bay A", "Line 2")
criticality (enum: critical, high, medium, low; default: high)
created_at (datetime)
updated_at (datetime)
is_active (boolean, default: true)

### StatusEvent
id (primary key)
tool_id (foreign key → Tool)
state (enum: UP, UP_WITH_ISSUES, MAINTENANCE, DOWN)
issue_description (text, nullable)
comment (text, nullable)
eta_to_up (datetime, nullable)
created_by_user_id (foreign key → User)
created_at (datetime)

---

## 7. Pages & Routes

| Route | Method | Page | Auth Required | Role |
|-------|--------|------|---------------|------|
| `/` | GET | Redirect to dashboard or login | No | Any |
| `/login` | GET | Login form | No | Any |
| `/login` | POST | Process login | No | Any |
| `/logout` | POST | Clear session | Yes | Any |
| `/dashboard` | GET | Main equipment status table | Yes | Any |
| `/tools/:id` | GET | Tool detail + history | Yes | Any |
| `/tools/:id/update` | GET | Update status form | Yes | Any |
| `/tools/:id/update` | POST | Process status update | Yes | Any |
| `/tools/:id/export` | GET | Export history CSV | Yes | Any |
| `/admin/tools` | GET | Manage tools table | Yes | Admin |
| `/admin/tools/create` | POST | Create new tool | Yes | Admin |
| `/admin/tools/:id/edit` | POST | Update tool | Yes | Admin |
| `/admin/tools/:id/delete` | POST | Soft-delete tool | Yes | Admin |
| `/admin/users` | GET | Manage users table | Yes | Admin |
| `/admin/users/create` | POST | Create new user | Yes | Admin |
| `/admin/users/:id/edit` | POST | Update user | Yes | Admin |
| `/admin/users/:id/deactivate` | POST | Soft-deactivate user | Yes | Admin |
| `/health` | GET | Health check (JSON) | No | Any |

---

## 8. Branding & Styling

### Colors (QCI Palette)
- **Dark Navy**: `#1E204B` (header, nav, primary elements)
- **Light Navy/Logo**: `#222354` (accents, logo)
- **Light Grey Background**: `#F4F5F9` (page background)
- **White**: `#FFFFFF` (cards, content areas)
- **Body Text**: `#3A3D4A` (dark grey; main text on light backgrounds)
- **Primary Text**: `#FFFFFF` (white; text on dark navy)

### Status Colors
- **UP**: `#2ecc71` (green)
- **UP WITH ISSUES**: `#f39c12` (yellow/amber)
- **MAINTENANCE**: `#e67e22` (orange)
- **DOWN**: `#e74c3c` (red)

### Font
- **Primary**: Raleway (sans-serif)
- **Fallback**: system sans-serif stack

### Logo
- QCI wordmark (provided image) placed in top-left header.
- Small copyright "© Quantum Computing Inc" in footer.

---

## 9. Technical Stack

### Backend
- **Framework**: Genie.jl (Julia web framework)
- **Database**: SearchLight.jl ORM + SQLite (v1); migration path to PostgreSQL
- **Authentication**: GenieAuthentication.jl + GenieAuthorisation.jl
- **Templating**: Genie's built-in HTML templating (Julia templates)

### Frontend
- **HTML**: Server-rendered via Genie templates
- **CSS**: Custom stylesheet using QCI palette; optional Bootstrap utility classes for responsive layout
- **JavaScript**: Minimal; vanilla JS for form validation and simple interactions (optional HTMX for progressive enhancement)

### Deployment
- **Container**: Docker
- **Base Image**: Julia official image (latest LTS)
- **Volume**: Mount for SQLite database persistence
- **Environment**: Intranet only; no external reverse proxy or TLS required initially (HTTP OK internally)
- **Health Check**: Simple `/health` endpoint returning `{"status": "ok"}`

---

## 10. Deployment & Operations

### Docker Setup
FROM julia:latest

WORKDIR /app
COPY . .

RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.resolve()"

CMD ["julia", "--project=.", "-e", "include(\"app.jl\")"]

### Environment Variables
- `DATABASE_PATH` (default: `/data/qci_status.sqlite`)
- `LOG_LEVEL` (default: `info`)
- `PORT` (default: `8000`)
- `SECRET_KEY` (session secret; generate on first run or pass via env)

### Volume Mounts
- `/data` → for SQLite database file persistence

### Starting the App
docker build -t qci-status:latest .
docker run -d -p 8000:8000 -v qci-data:/data qci-status:latest

### Access
- Internal URL: `http://qci-status.internal:8000` (assumes internal DNS resolution)
- Intranet only; firewall blocks external access

### Backup
- SQLite file backed up periodically to file share (external to container).
- Recommend daily snapshots via cron or backup service.

---

## 11. Phase 1: MVP (Core Features)

**Delivered in initial release:**

1. ✅ User authentication (login/logout, GenieAuthentication)
2. ✅ Dashboard with equipment table (all tools, current state, last update, ETA)
3. ✅ Update status form (state, issue, comment, ETA)
4. ✅ Tool detail view + history timeline
5. ✅ Admin: manage tools (create, edit, deactivate)
6. ✅ Admin: manage users (create, edit, deactivate)
7. ✅ CSV export per-tool history
8. ✅ QCI branding (colors, fonts, logo)
9. ✅ Docker deployment with SQLite
10. ✅ Role-based access control (admin vs operator)
11. ✅ Audit trail (immutable StatusEvent records)
12. ✅ Health check endpoint

---

## 12. Phase 2: Stretch Goals

**Optional enhancements post-MVP:**

- 📊 **Utilization Analytics**:
  - Graph showing % time in each state (UP, UP WITH ISSUES, MAINTENANCE, DOWN) per tool over a date range.
  - Time window selector (day, week, month).
  - Stacked bar chart using Chart.js or Plotly.
  - Accessible via `/analytics` page.
  - Filters: tool name, area, date range.

- 🔔 **Future enhancements** (not in scope yet):
  - Email/Slack notifications on status changes.
  - Equipment sensor/MQTT auto-update (when network is ready).
  - Predictive maintenance alerts.
  - Multi-site/area-level dashboards.
  - Mobile-responsive design (current target: desktop, intranet-facing).

---

## 13. Success Criteria

- ✅ App loads in under 2 seconds on intranet.
- ✅ All status updates reflected in dashboard within 1 second.
- ✅ Audit trail never loses data; all changes are traceable to a user.
- ✅ Admin can add a new tool in < 30 seconds.
- ✅ Operators can update status in < 15 seconds.
- ✅ CSV export completes in < 5 seconds.
- ✅ Docker container restarts without data loss (SQLite file persisted).
- ✅ QCI branding applied (logo, colors, Raleway font) consistently across all pages.
- ✅ Role-based access enforced; non-admin users cannot access `/admin/*` routes.

---

## 14. Handoff Notes for Claude Code

### Before Starting
1. Confirm Genie.jl, SearchLight.jl, and GenieAuthentication.jl versions.
2. Use Julia 1.9+ for best compatibility.
3. Set up `Project.toml` with dependencies and migrations.

### Key Assumptions
- Single-user sessions (no concurrent logins per user for now).
- SQLite auto-vacuumed; no manual maintenance needed.
- Intranet deployment assumes no TLS; HTTP OK internally.
- No rate-limiting or DDoS protection needed for internal fab use.

### Testing Recommendations
- Manual smoke tests: login, create tool, update status, export CSV.
- Admin tests: user creation, tool creation, role enforcement.
- Data persistence: restart container; verify SQLite data survives.

### Post-Deployment
1. Set initial admin user credentials via bootstrap script or UI.
2. Import existing tools from Google Sheets (CSV import script, optional).
3. Train operators and admins on login, status updates, and history view.
4. Monitor logs for errors; adjust `LOG_LEVEL` if needed.

---

## 15. Appendix: Visual Reference

### Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Dark Navy | `#1E204B` | Headers, nav, primary buttons |
| Light Navy | `#222354` | Logo, accents |
| Light Grey | `#F4F5F9` | Page background |
| White | `#FFFFFF` | Cards, text areas |
| Body Text | `#3A3D4A` | Primary text on light bg |
| UP | `#2ecc71` | Green status |
| UP WITH ISSUES | `#f39c12` | Yellow status |
| MAINTENANCE | `#e67e22` | Orange status |
| DOWN | `#e74c3c` | Red status |

### Font Stack
font-family: "Raleway", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;

### QCI Assets
- Logo: `Logo-wordmark-webinar.jpg` (provided)
- Brand guidelines: Raleway, dark navy primary, light grey secondary

---

**End of PRD**
