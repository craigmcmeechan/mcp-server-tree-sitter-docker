# Claude Desktop Docker Integration Example

This example shows how to configure Claude Desktop to use the dockerized MCP Tree-sitter Server.

## Configuration File Locations

### macOS
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### Linux
```
~/.config/Claude/claude_desktop_config.json
```

### Windows
```
%APPDATA%\Claude\claude_desktop_config.json
```

## Basic Setup

1. **Copy the example configuration**:
   ```bash
   # macOS/Linux
   cp claude_desktop_config.json ~/Library/Application\ Support/Claude/

   # Or edit existing config
   nano ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

2. **Ensure Docker image is built**:
   ```bash
   docker build -t mcp-server-tree-sitter:latest /path/to/mcp-server-tree-sitter-docker
   ```

3. **Restart Claude Desktop**

4. **Look for the MCP tools icon** (hammer icon) in Claude Desktop

## Configuration Explained

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",                           // Run a new container
        "-i",                            // Interactive (required for MCP)
        "--rm",                          // Remove container when stopped
        "--name", "mcp-tree-sitter",    // Container name
        "-v", "${workspaceFolder}:/workspace:ro",  // Mount project
        "-v", "mcp-cache:/cache",       // Cache volume
        "-e", "MCP_TS_LOG_LEVEL=INFO",  // Environment variable
        "mcp-server-tree-sitter:latest" // Image name
      ]
    }
  }
}
```

### Key Elements

- **`${workspaceFolder}`**: Claude Desktop variable for current directory
- **`:ro`**: Read-only mount (security best practice)
- **`mcp-cache`**: Named volume for persistent cache
- **`-e`**: Environment variables for configuration

## Variations

### Fixed Project Path

Instead of `${workspaceFolder}`, use a specific path:

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/Users/username/Projects/myproject:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Debug Mode

Enable debug logging for troubleshooting:

```json
{
  "mcpServers": {
    "tree_sitter_debug": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--name", "mcp-tree-sitter-debug",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_LOG_LEVEL=DEBUG",
        "mcp-server-tree-sitter:latest",
        "--debug"
      ]
    }
  }
}
```

View logs:
```bash
docker logs mcp-tree-sitter-debug
```

### Multiple Projects

Configure separate servers for different projects:

```json
{
  "mcpServers": {
    "tree_sitter_project1": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--name", "mcp-tree-sitter-project1",
        "-v", "/path/to/project1:/workspace:ro",
        "-v", "mcp-cache-project1:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    },
    "tree_sitter_project2": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--name", "mcp-tree-sitter-project2",
        "-v", "/path/to/project2:/workspace:ro",
        "-v", "mcp-cache-project2:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### With Custom Configuration

Use a YAML config file:

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "/path/to/config.yaml:/config/config.yaml:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_CONFIG_PATH=/config/config.yaml",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Maximum Security

Run with security hardening:

```json
{
  "mcpServers": {
    "tree_sitter_secure": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--read-only",
        "--tmpfs", "/tmp",
        "--tmpfs", "/cache:mode=1777",
        "--security-opt", "no-new-privileges:true",
        "--cap-drop", "ALL",
        "--network", "none",
        "-v", "${workspaceFolder}:/workspace:ro",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

## Testing

### Verify Configuration

1. **Check JSON syntax**:
   ```bash
   # macOS/Linux
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq .
   ```

2. **Restart Claude Desktop**

3. **Check for MCP tools icon** in the interface

### Test Manually

Run the exact command from your config:

```bash
docker run -i --rm \
  -v $(pwd):/workspace:ro \
  -v mcp-cache:/cache \
  -e MCP_TS_LOG_LEVEL=INFO \
  mcp-server-tree-sitter:latest --version
```

## Troubleshooting

### MCP Server Not Appearing

1. **Check Docker is running**:
   ```bash
   docker ps
   ```

2. **Verify image exists**:
   ```bash
   docker images | grep mcp-server-tree-sitter
   ```

3. **Check Claude Desktop logs**:
   - macOS: `~/Library/Logs/Claude/`
   - Look for error messages

4. **Validate JSON**:
   ```bash
   cat claude_desktop_config.json | python -m json.tool
   ```

### Permission Errors

**macOS**: Check Docker Desktop → Settings → Resources → File Sharing
- Ensure your project directory is in the shared list

**Linux**: Check SELinux:
```json
"-v", "${workspaceFolder}:/workspace:ro,z"
```

### Container Conflicts

If you see "container name already in use":

```bash
# Remove old container
docker rm -f mcp-tree-sitter

# Or use unique names in config
"--name", "mcp-tree-sitter-${USER}"
```

### Slow Performance

1. **Increase cache size**:
   ```json
   "-e", "MCP_TS_CACHE_MAX_SIZE_MB=200"
   ```

2. **Pre-load languages**:
   ```json
   "-e", "MCP_TS_LANGUAGE_PREFERRED_LANGUAGES=python,javascript"
   ```

3. **Increase resources** (Docker Desktop → Resources):
   - CPU: 2-4 cores
   - Memory: 4-8GB

## Platform-Specific Notes

### macOS
- Use forward slashes in paths
- `${workspaceFolder}` works correctly
- Check File Sharing settings in Docker Desktop

### Linux
- May need SELinux context (`:z` or `:Z` flag)
- Ensure Docker user can access project directory
- No special configuration needed for `${workspaceFolder}`

### Windows
- Use WSL2 backend in Docker Desktop
- Paths should use forward slashes: `C:/Users/...`
- `${workspaceFolder}` should work with WSL2

## Next Steps

- See [CLAUDE_INTEGRATION.md](../../../docs/docker/CLAUDE_INTEGRATION.md) for complete guide
- See [DEPLOYMENT.md](../../../docs/docker/DEPLOYMENT.md) for advanced options
- Check [basic example](../basic/) for standalone usage
- Check [multi-project example](../multi-project/) for multiple projects

## Additional Resources

- Claude Desktop Documentation: https://claude.ai/docs
- Docker Documentation: https://docs.docker.com
- MCP Documentation: https://modelcontextprotocol.io
