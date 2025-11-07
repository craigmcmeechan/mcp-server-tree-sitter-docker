# Multi-Project Docker Example

This example shows how to run multiple MCP Tree-sitter servers for different projects simultaneously.

## Use Case

You have multiple projects and want to analyze them separately:
- Backend (Python/Go)
- Frontend (JavaScript/TypeScript)
- Library (Rust)

Each gets its own server instance with:
- Dedicated cache
- Language-specific optimizations
- Independent resource limits

## Setup

1. **Update project paths** in `docker-compose.yml`:
   ```yaml
   volumes:
     - /path/to/your/backend:/workspace:ro
     - /path/to/your/frontend:/workspace:ro
     - /path/to/your/library:/workspace:ro
   ```

2. **Start all servers**:
   ```bash
   docker-compose up -d
   ```

3. **Or start individual servers**:
   ```bash
   docker-compose up -d mcp-server-backend
   docker-compose up -d mcp-server-frontend
   ```

## Using with Claude Desktop

Configure each server separately in `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "tree_sitter_backend": {
      "command": "docker",
      "args": [
        "exec", "-i",
        "mcp-tree-sitter-backend",
        "python", "-m", "mcp_server_tree_sitter.server"
      ]
    },
    "tree_sitter_frontend": {
      "command": "docker",
      "args": [
        "exec", "-i",
        "mcp-tree-sitter-frontend",
        "python", "-m", "mcp_server_tree_sitter.server"
      ]
    },
    "tree_sitter_library": {
      "command": "docker",
      "args": [
        "exec", "-i",
        "mcp-tree-sitter-library",
        "python", "-m", "mcp_server_tree_sitter.server"
      ]
    }
  }
}
```

**Note**: This assumes containers are already running via docker-compose.

## Managing Servers

### Start all
```bash
docker-compose up -d
```

### Stop all
```bash
docker-compose down
```

### Restart specific server
```bash
docker-compose restart mcp-server-backend
```

### View logs for all
```bash
docker-compose logs -f
```

### View logs for specific server
```bash
docker-compose logs -f mcp-server-backend
```

### Check status
```bash
docker-compose ps
```

## Resource Management

Each server has resource limits defined:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

**Adjust based on your needs:**
- Small projects: 0.5 CPU, 512M RAM
- Medium projects: 1-2 CPU, 1G RAM
- Large projects: 2-4 CPU, 2-4G RAM

## Cache Management

Each project has its own cache volume:
- `mcp-cache-backend`
- `mcp-cache-frontend`
- `mcp-cache-library`

### View cache sizes
```bash
docker run --rm -v mcp-cache-backend:/cache alpine du -sh /cache
docker run --rm -v mcp-cache-frontend:/cache alpine du -sh /cache
docker run --rm -v mcp-cache-library:/cache alpine du -sh /cache
```

### Clear specific cache
```bash
docker volume rm mcp-cache-backend
docker-compose up -d mcp-server-backend
```

### Clear all caches
```bash
docker-compose down -v
docker-compose up -d
```

## Customization

### Different configurations per project

1. Create config files:
   ```
   config-backend.yaml
   config-frontend.yaml
   config-library.yaml
   ```

2. Mount them in docker-compose.yml:
   ```yaml
   services:
     mcp-server-backend:
       volumes:
         - ./config-backend.yaml:/config/config.yaml:ro
       environment:
         - MCP_TS_CONFIG_PATH=/config/config.yaml
   ```

### Different log levels

```yaml
services:
  mcp-server-backend:
    environment:
      - MCP_TS_LOG_LEVEL=DEBUG  # More verbose

  mcp-server-frontend:
    environment:
      - MCP_TS_LOG_LEVEL=WARNING  # Less verbose
```

## Troubleshooting

### Container exits immediately
```bash
# Check logs
docker-compose logs mcp-server-backend

# Common causes:
# - Invalid project path
# - Permission issues
# - Missing dependencies
```

### High resource usage
```bash
# Check resource usage
docker stats

# Reduce resource limits or cache size
# Edit docker-compose.yml
```

### Port conflicts
No ports needed! MCP uses stdio. If you see port errors, check for conflicting container names.

## Performance Tips

1. **Pre-load languages** for faster first analysis:
   ```yaml
   environment:
     - MCP_TS_LANGUAGE_PREFERRED_LANGUAGES=python,javascript
   ```

2. **Increase cache** for large projects:
   ```yaml
   environment:
     - MCP_TS_CACHE_MAX_SIZE_MB=500
   ```

3. **Use SSD** for Docker volumes

4. **Allocate adequate resources** based on project size

## Next Steps

- See [DEPLOYMENT.md](../../../docs/docker/DEPLOYMENT.md) for advanced options
- See [CLAUDE_INTEGRATION.md](../../../docs/docker/CLAUDE_INTEGRATION.md) for detailed Claude setup
- Check [basic example](../basic/) for simpler setup
