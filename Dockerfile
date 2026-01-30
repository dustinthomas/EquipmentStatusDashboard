# QCI Equipment Status Dashboard - Docker Image
# Multi-stage build for smaller final image and better layer caching

# ============================================================================
# Build stage - install dependencies and precompile
# ============================================================================
FROM julia:1.12 AS builder

WORKDIR /app

# Copy dependency files first (better layer caching)
COPY Project.toml Manifest.toml ./

# Install dependencies
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Copy source code
COPY . .

# Precompile the application (significantly reduces startup time)
RUN julia --project=. -e 'using Pkg; Pkg.precompile()'

# ============================================================================
# Production stage
# ============================================================================
FROM julia:1.12

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the entire app from builder (includes precompiled packages)
COPY --from=builder /root/.julia /root/.julia
COPY --from=builder /app /app

# Create data directory for SQLite database
RUN mkdir -p /data && chmod 755 /data

# Environment variables with defaults
ENV PORT=8000
ENV DATABASE_PATH=/data/qci_status.sqlite
ENV GENIE_ENV=prod
ENV LOG_LEVEL=info
# SECRET_KEY must be provided at runtime for session encryption
ENV SECRET_KEY=""
# Stale status highlighting threshold (hours)
ENV STALE_THRESHOLD_HOURS=8

# Expose the application port
EXPOSE 8000

# Health check - verify server is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Start the application
# Note: Using src/App.jl directly (not app.jl) for proper module loading
# host="0.0.0.0" is required for Docker to accept connections from outside the container
CMD ["julia", "--project=.", "-e", "include(\"src/App.jl\"); using .App; App.up(parse(Int, ENV[\"PORT\"]); host=\"0.0.0.0\")"]
