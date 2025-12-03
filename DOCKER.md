# 🐳 Docker Deployment Guide

## Quick Start

```bash
# Start everything
./docker-start.sh start

# Access at: http://localhost:8501
```

## What Gets Deployed

The Docker setup includes:

1. **Ollama Service** (`private-gpt-ollama`)
   - Runs on port 11434
   - Stores models in persistent volume
   - Automatically pulls `deepseek-r1:8b` model

2. **Streamlit App** (`private-gpt-app`)
   - Runs on port 8501
   - Connects to Ollama service
   - Includes RAG functionality

## Architecture

```
┌─────────────────────────────────────────┐
│         Docker Network                   │
│  (private-gpt-network)                  │
│                                          │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Ollama     │◄───┤  Streamlit   │  │
│  │  Container   │    │  App         │  │
│  │  :11434      │    │  :8501       │  │
│  └──────────────┘    └──────────────┘  │
│         ▲                    ▲          │
│         │                    │          │
└─────────┼────────────────────┼──────────┘
          │                    │
     Port 11434            Port 8501
          │                    │
     (Host Access)       (Web Browser)
```

## Docker Commands

### Using the Launch Script (Recommended)

```bash
# Start services
./docker-start.sh start

# View logs
./docker-start.sh logs

# Check status
./docker-start.sh status

# Restart services
./docker-start.sh restart

# Stop services
./docker-start.sh stop

# Rebuild images
./docker-start.sh build

# Open shell in container
./docker-start.sh exec app    # App container
./docker-start.sh exec ollama # Ollama container

# Clean up everything
./docker-start.sh clean

# Show help
./docker-start.sh help
```

### Using Docker Compose Directly

```bash
# Start in background
docker-compose up -d

# Start with logs
docker-compose up

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart app

# Rebuild
docker-compose build --no-cache

# Pull latest images
docker-compose pull
```

### Useful Docker Commands

```bash
# Check running containers
docker ps

# View app logs
docker logs -f private-gpt-app

# View Ollama logs
docker logs -f private-gpt-ollama

# Execute command in container
docker exec -it private-gpt-app bash
docker exec -it private-gpt-ollama bash

# Pull a different model
docker exec private-gpt-ollama ollama pull llama3

# List available models
docker exec private-gpt-ollama ollama list

# Check resource usage
docker stats private-gpt-app private-gpt-ollama

# Remove container
docker rm -f private-gpt-app

# Remove image
docker rmi private_gpt-app

# Prune unused resources
docker system prune -a
```

## Configuration

### Environment Variables

Edit `docker-compose.yml` to change:

```yaml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434  # Ollama connection URL
```

### Port Mapping

Change ports in `docker-compose.yml`:

```yaml
ports:
  - "8080:8501"  # Change 8080 to your preferred port
```

### GPU Support

Uncomment GPU section in `docker-compose.yml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

**Requirements:**
- NVIDIA GPU
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

### Volume Management

Data persistence:

```bash
# Backup Ollama models
docker run --rm -v private-gpt-ollama-data:/data -v $(pwd):/backup ubuntu tar czf /backup/ollama-backup.tar.gz -C /data .

# Restore Ollama models
docker run --rm -v private-gpt-ollama-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/ollama-backup.tar.gz -C /data

# List volumes
docker volume ls

# Inspect volume
docker volume inspect private-gpt-ollama-data

# Remove volume (careful!)
docker volume rm private-gpt-ollama-data
```

## Troubleshooting

### Container Won't Start

```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs app
docker-compose logs ollama

# Restart services
docker-compose restart
```

### Ollama Connection Issues

```bash
# Check if Ollama is healthy
docker exec private-gpt-ollama curl http://localhost:11434/api/tags

# Restart Ollama
docker-compose restart ollama

# Check network connectivity
docker exec private-gpt-app ping ollama
```

### Model Not Found

```bash
# List models
docker exec private-gpt-ollama ollama list

# Pull model
docker exec private-gpt-ollama ollama pull deepseek-r1:8b

# Check Ollama logs
docker logs private-gpt-ollama
```

### Out of Memory

```bash
# Check resource usage
docker stats

# Increase Docker memory limit in Docker Desktop settings
# Or edit /etc/docker/daemon.json (Linux):
{
  "default-runtime": "runc",
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "storage-driver": "overlay2"
}
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :8501
sudo lsof -i :11434

# Change port in docker-compose.yml
ports:
  - "8502:8501"  # Use 8502 instead
```

### Rebuild from Scratch

```bash
# Stop and remove everything
docker-compose down -v --rmi all

# Rebuild
docker-compose build --no-cache

# Start fresh
docker-compose up -d
```

## Performance Optimization

### CPU-Only Mode

Already configured by default. Uses `faiss-cpu` for vector search.

### GPU Mode

1. Enable GPU in `docker-compose.yml`
2. Install NVIDIA Container Toolkit
3. Restart Docker daemon
4. Start services

### Memory Optimization

For smaller models or limited RAM:

```bash
# Use smaller model
docker exec private-gpt-ollama ollama pull phi3:mini

# Update app to use smaller model (change in sidebar settings)
```

## Production Considerations

### Security

```dockerfile
# App runs as non-root user (already configured)
USER appuser
```

### Logging

```yaml
# Add to docker-compose.yml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Health Checks

Already configured for both services with:
- Interval: 30s
- Timeout: 10s
- Retries: 3
- Start period: 30s

### Reverse Proxy

Example Nginx configuration:

```nginx
server {
    listen 80;
    server_name private-gpt.example.com;

    location / {
        proxy_pass http://localhost:8501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Updating

```bash
# Pull latest code
git pull

# Rebuild and restart
./docker-start.sh stop
./docker-start.sh build
./docker-start.sh start
```

## Uninstalling

```bash
# Complete cleanup
./docker-start.sh clean

# Remove everything including source
cd ..
rm -rf Private_GPT
```

---

**Need help?** Check the [main README](README.md) or open an issue.

