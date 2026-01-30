# QCI Equipment Status Dashboard - Deployment

## Production Server

**Host:** n8n (via Tailscale/SSH)
**Port:** 8000
**URL:** http://n8n:8000 (internal network)

## Architecture

- **Container:** qci-status-dashboard
- **Image:** qci-status:latest (tagged by commit SHA)
- **Port:** 8000 (internal) -> 8000 (host)
- **Data:** Docker volume `qci-data` at `/data` (SQLite database)

## Coexisting Services on n8n

| Service | Port | Container |
|---------|------|-----------|
| SOP-System | 80 | sop-system |
| Gitea | 3000 | gitea |
| n8n | 5678 | (port-forwarded) |
| **QCI Status** | **8000** | qci-status-dashboard |

## Quick Commands

### View Logs
```bash
ssh n8n "sudo docker logs qci-status-dashboard --tail 100 -f"
```

### Restart Container
```bash
ssh n8n "sudo docker restart qci-status-dashboard"
```

### Check Health
```bash
ssh n8n "sudo docker inspect --format='{{.State.Health.Status}}' qci-status-dashboard"
```

### Deploy Latest
```bash
ssh n8n "sudo -u git /home/git/qci-deploy-docker.sh"
```

## Initial Setup

1. Clone repo on server:
   ```bash
   sudo mkdir -p /var/www/qci-status
   sudo chown git:git /var/www/qci-status
   sudo -u git git clone <repo-url> /var/www/qci-status
   ```

2. Set up environment (create `/home/git/.qci-env`):
   ```bash
   export SECRET_KEY="$(openssl rand -hex 32)"
   export QCI_PORT=8000
   export STALE_THRESHOLD_HOURS=8
   ```

3. Copy deploy script:
   ```bash
   sudo cp /var/www/qci-status/deploy/deploy-docker.sh /home/git/qci-deploy-docker.sh
   sudo chmod +x /home/git/qci-deploy-docker.sh
   sudo chown git:git /home/git/qci-deploy-docker.sh
   ```

4. Run initial deployment:
   ```bash
   source /home/git/.qci-env
   sudo -u git /home/git/qci-deploy-docker.sh
   ```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | (required) | Session encryption key |
| `QCI_PORT` | 8000 | Host port to expose |
| `STALE_THRESHOLD_HOURS` | 8 | Hours before status shown as stale |

## Default Admin Credentials

On first run, the app creates a default admin user:
- **Username:** admin
- **Password:** changeme123

**Change this immediately after first login!**
