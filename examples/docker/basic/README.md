# Basic Docker Example

This is a minimal setup for running the MCP Tree-sitter Server with Docker Compose.

## Quick Start

1. **Update the project path** in `docker-compose.yml`:
   ```yaml
   volumes:
     - /path/to/your/project:/workspace:ro
   ```

2. **Start the server**:
   ```bash
   docker-compose up
   ```

3. **Test it's working**:
   In another terminal:
   ```bash
   docker logs mcp-tree-sitter-basic
   ```

## Using with Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "compose",
        "-f", "/path/to/this/docker-compose.yml",
        "run", "--rm", "mcp-server"
      ]
    }
  }
}
```

Or use `docker run` directly - see [CLAUDE_INTEGRATION.md](../../../docs/docker/CLAUDE_INTEGRATION.md).

## Custom Configuration

To use the provided `config.yaml`:

1. **Update docker-compose.yml**:
   ```yaml
   volumes:
     - /path/to/your/project:/workspace:ro
     - ./config.yaml:/config/config.yaml:ro

   environment:
     - MCP_TS_CONFIG_PATH=/config/config.yaml
   ```

2. **Edit config.yaml** to match your needs

3. **Restart**:
   ```bash
   docker-compose restart
   ```

## Stopping

```bash
# Stop the server
docker-compose down

# Stop and remove volumes (clears cache)
docker-compose down -v
```

## Logs

```bash
# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

## Troubleshooting

### Server won't start
```bash
# Check if port is in use or container exists
docker ps -a | grep mcp-tree-sitter

# Remove old container
docker rm mcp-tree-sitter-basic

# Try again
docker-compose up
```

### Can't access project files
```bash
# Check volume mount
docker-compose exec mcp-server ls -la /workspace

# Verify permissions
ls -la /path/to/your/project
```

### Slow performance
```bash
# Increase cache size in docker-compose.yml
environment:
  - MCP_TS_CACHE_MAX_SIZE_MB=200
```

## Next Steps

- See [DEPLOYMENT.md](../../../docs/docker/DEPLOYMENT.md) for more deployment options
- See [CLAUDE_INTEGRATION.md](../../../docs/docker/CLAUDE_INTEGRATION.md) for Claude setup
- Check [multi-project example](../multi-project/) for analyzing multiple projects
