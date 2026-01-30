# QCI Equipment Status Dashboard

Internal web application for tracking equipment status at QCI fab operations.

## Overview

This application replaces the Google Sheets equipment status tracker with a dedicated web app featuring:

- Real-time manual status updates
- Role-based access control (Admin/Operator)
- Complete audit trail for all changes
- ETA tracking for equipment returning to service
- CSV export for reporting

## Tech Stack

- **Backend:** Julia + Genie.jl
- **Database:** SQLite (via SearchLight.jl)
- **Authentication:** GenieAuthentication.jl
- **Deployment:** Docker

## Quick Start

### Prerequisites

- Julia (latest stable)
- Docker (for deployment)

### Development Setup

```bash
# Install dependencies
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Run database migrations
julia --project=. -e "using SearchLight; SearchLight.Migration.up()"

# Seed database with initial data (admin user + sample tools)
julia --project=. -e 'include("db/seeds/seed_data.jl"); seed!()'

# Start development server
julia --project=. -e "include(\"app.jl\")"
```

#### Seed Data

The seed script (`db/seeds/seed_data.jl`) creates:
- **Admin user:** username=`admin`, password=`changeme` (change immediately!)
- **Sample tools:** 5 fabrication tools with different states for testing

The seed is idempotent - running it multiple times is safe.

The app will be available at `http://localhost:8000`

### Docker Deployment

#### Using Docker Compose (Recommended)

```bash
# Start the application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the application
docker-compose down

# Stop and remove all data (WARNING: deletes database!)
docker-compose down -v
```

#### Using Docker Directly

```bash
# Build image
docker build -t qci-status:latest .

# Run container with volume for data persistence
docker run -d \
  --name qci-status-dashboard \
  -p 8000:8000 \
  -v qci-data:/data \
  -e SECRET_KEY=your-secret-key-here \
  -e STALE_THRESHOLD_HOURS=8 \
  qci-status:latest

# Check health
curl http://localhost:8000/health

# View logs
docker logs -f qci-status-dashboard

# Stop container
docker stop qci-status-dashboard
```

#### First-Time Setup (Database Migration & Seed)

After starting the container for the first time, run migrations and seed the database:

```bash
# Run migrations
docker exec qci-status-dashboard julia --project=. -e \
  'include("src/App.jl"); using .App; App.load_app(); using SearchLight; SearchLight.Migration.up()'

# Seed initial data (admin user + sample tools)
docker exec qci-status-dashboard julia --project=. -e \
  'include("src/App.jl"); using .App; App.load_app(); include("db/seeds/seed_data.jl"); seed!()'
```

**Default admin credentials:** username=`admin`, password=`changeme` (change immediately!)

## User Roles

| Role | Capabilities |
|------|-------------|
| **Admin** | Manage tools, manage users, update any status, view audit trail, export data |
| **Operator** | Update tool status, add comments, view history, export tool-specific data |

## Equipment States

| State | Color | Description |
|-------|-------|-------------|
| UP | Green | Equipment operational |
| UP WITH ISSUES | Yellow | Operational but has problems |
| MAINTENANCE | Orange | Scheduled maintenance |
| DOWN | Red | Not operational |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8000` | HTTP server port |
| `DATABASE_PATH` | `/data/qci_status.sqlite` | SQLite database location |
| `LOG_LEVEL` | `info` | Logging verbosity (`debug`, `info`, `warn`, `error`) |
| `SECRET_KEY` | (required) | Session encryption key. Generate with: `openssl rand -hex 32` |
| `GENIE_ENV` | `dev` | Environment mode (`dev`, `test`, `prod`) |
| `STALE_THRESHOLD_HOURS` | `8` | Hours before a tool status is marked as stale |
| `SESSION_TIMEOUT` | `28800` | Session timeout in seconds (default: 8 hours) |

### Security Notes

- **Always set `SECRET_KEY`** in production. Never use the default dev key.
- The database file contains password hashes and session data. Protect the volume mount.
- For production, consider using a reverse proxy (nginx) with TLS.

## Project Structure

```
├── app.jl              # Application entry point
├── src/
│   ├── models/         # Data models (User, Tool, StatusEvent)
│   ├── controllers/    # Route handlers
│   └── views/          # HTML templates
├── db/
│   ├── migrations/     # Database schema migrations
│   └── seeds/          # Initial data
├── public/             # Static assets (CSS, JS, images)
└── test/               # Test suite
```

## License

Internal use only - Quantum Computing Inc (QCI)
