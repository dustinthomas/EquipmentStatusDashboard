#!/bin/bash
set -e

# QCI Equipment Status Dashboard - Docker Deployment Script
# Similar pattern to SOP-System deployment

# Clear git hook environment variables
unset GIT_DIR
unset GIT_WORK_TREE
unset GIT_INDEX_FILE

# Configuration
REPO_PATH="/var/www/qci-status"
IMAGE_NAME="qci-status"
CONTAINER_NAME="qci-status-dashboard"
DEPLOY_PORT="${QCI_PORT:-8000}"
VOLUME_NAME="qci-data"
LOG_FILE="/home/git/logs/qci-deploy-$(date +%Y%m%d-%H%M%S).log"

# Required: Generate with `openssl rand -hex 32`
SECRET_KEY="${SECRET_KEY:-}"

mkdir -p /home/git/logs

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting QCI Status Dashboard Docker deployment ==="

# Check for required environment
if [ -z "$SECRET_KEY" ]; then
    log "WARNING: SECRET_KEY not set. Using default (not secure for production!)"
    SECRET_KEY="change-me-in-production-$(date +%s)"
fi

cd "$REPO_PATH" || exit 1

# Pull latest code
log "Pulling latest code from origin..."
git fetch origin 2>&1 | tee -a "$LOG_FILE"
git reset --hard origin/master 2>&1 | tee -a "$LOG_FILE"

COMMIT_SHA=$(git rev-parse --short HEAD)
log "Building image for commit: $COMMIT_SHA"

# Build image (Julia build takes longer than Node)
log "Building Docker image (this may take a few minutes for Julia)..."
docker build -t "${IMAGE_NAME}:${COMMIT_SHA}" -t "${IMAGE_NAME}:latest" . 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log "ERROR: Docker build failed"
    exit 1
fi

# Ensure volume exists
if ! docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    log "Creating data volume: ${VOLUME_NAME}"
    docker volume create "${VOLUME_NAME}"
fi

# Stop old container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Stopping existing container..."
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
fi

# Start new container
log "Starting new container on port ${DEPLOY_PORT}..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "${DEPLOY_PORT}:8000" \
    -v "${VOLUME_NAME}:/data" \
    -e PORT=8000 \
    -e GENIE_ENV=prod \
    -e GENIE_HOST=0.0.0.0 \
    -e DATABASE_PATH=/data/qci_status.sqlite \
    -e SECRET_KEY="${SECRET_KEY}" \
    -e STALE_THRESHOLD_HOURS="${STALE_THRESHOLD_HOURS:-8}" \
    "${IMAGE_NAME}:${COMMIT_SHA}" 2>&1 | tee -a "$LOG_FILE"

# Health check (Julia needs more time to start)
log "Waiting for container to be healthy (Julia startup takes ~60-90 seconds)..."
sleep 30

for i in {1..20}; do
    if curl -f -s "http://localhost:${DEPLOY_PORT}/health" > /dev/null; then
        log "Health check passed"
        log "=== Deployment successful ==="
        docker ps --filter "name=$CONTAINER_NAME"
        exit 0
    fi
    log "Health check attempt $i/20 failed, retrying in 5s..."
    sleep 5
done

# Rollback on failure
log "ERROR: Health check failed after 20 attempts, rolling back..."
docker logs "$CONTAINER_NAME" --tail 50 2>&1 | tee -a "$LOG_FILE"
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

# Try to restart previous version
PREVIOUS_VERSION=$(docker images "${IMAGE_NAME}" --format "{{.Tag}}" | grep -v "${COMMIT_SHA}" | grep -v "latest" | head -n1)
if [ -n "$PREVIOUS_VERSION" ]; then
    log "Rolling back to: $PREVIOUS_VERSION"
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p "${DEPLOY_PORT}:8000" \
        -v "${VOLUME_NAME}:/data" \
        -e PORT=8000 \
        -e GENIE_ENV=prod \
        -e GENIE_HOST=0.0.0.0 \
        -e DATABASE_PATH=/data/qci_status.sqlite \
        -e SECRET_KEY="${SECRET_KEY}" \
        "${IMAGE_NAME}:${PREVIOUS_VERSION}"
fi

exit 1
