# Claude Integration Guide for Docker MCP Server

## Overview

This guide provides detailed instructions for integrating the dockerized MCP Tree-sitter Server with Claude Desktop and Claude Code CLI. Both platforms use JSON configuration files to connect to MCP servers.

## Table of Contents

- [Claude Desktop Configuration](#claude-desktop-configuration)
- [Claude Code CLI Configuration](#claude-code-cli-configuration)
- [Configuration Options](#configuration-options)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)
- [Testing Your Configuration](#testing-your-configuration)

---

## Claude Desktop Configuration

### Configuration File Locations

The Claude Desktop configuration file is located at:

**macOS:**
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Linux:**
```
~/.config/Claude/claude_desktop_config.json
```

**Windows:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

### Basic Configuration

#### 1. Single Project with Docker

**macOS/Linux:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--name", "mcp-tree-sitter",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_LOG_LEVEL=INFO",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

**Windows (PowerShell):**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--name", "mcp-tree-sitter",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_LOG_LEVEL=INFO",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

**Important Notes:**
- `${workspaceFolder}` is a Claude Desktop variable that resolves to your current working directory
- The `-i` flag is **required** for MCP protocol communication
- `--rm` automatically removes the container when stopped
- Volume syntax: `source:destination:mode` where mode is `ro` (read-only) or `rw` (read-write)

#### 2. Fixed Project Path

If you want to analyze a specific project regardless of Claude Desktop's current directory:

**macOS/Linux:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "/absolute/path/to/your/project:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

**Windows:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "C:\\Users\\YourName\\Projects\\MyProject:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

#### 3. Multiple Projects

Configure separate MCP servers for different projects:

```json
{
  "mcpServers": {
    "tree_sitter_project1": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--name", "mcp-tree-sitter-project1",
        "-v", "/path/to/project1:/workspace:ro",
        "-v", "mcp-cache-project1:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    },
    "tree_sitter_project2": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--name", "mcp-tree-sitter-project2",
        "-v", "/path/to/project2:/workspace:ro",
        "-v", "mcp-cache-project2:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

**Key Points:**
- Each server needs a unique name in `mcpServers`
- Each container needs a unique `--name`
- Use separate cache volumes for each project
- Claude Desktop will show both servers in the MCP tools menu

#### 4. With Custom Configuration

To use a custom YAML configuration file:

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "/path/to/your/config.yaml:/config/config.yaml:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_CONFIG_PATH=/config/config.yaml",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

#### 5. Debug Mode

Enable debug logging for troubleshooting:

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
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

View logs with:
```bash
docker logs mcp-tree-sitter
```

---

## Claude Code CLI Configuration

### Configuration File Location

Claude Code CLI uses MCP configuration at:

**All Platforms:**
```
~/.config/claude-code/mcp_servers.json
```

Or within a project's `.claude/` directory:
```
<project-root>/.claude/mcp_servers.json
```

### Basic Configuration

#### 1. Global Configuration

**~/.config/claude-code/mcp_servers.json:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--name", "mcp-tree-sitter",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_LOG_LEVEL=INFO",
        "mcp-server-tree-sitter:latest"
      ],
      "env": {}
    }
  }
}
```

**Key Differences from Claude Desktop:**
- Claude Code may require the `"env": {}` field
- `${workspaceFolder}` resolves to the current working directory where `claude` command is run

#### 2. Project-Specific Configuration

**<project>/.claude/mcp_servers.json:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "${projectRoot}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "mcp-server-tree-sitter:latest"
      ],
      "env": {
        "MCP_TS_LOG_LEVEL": "INFO"
      }
    }
  }
}
```

**Variables available:**
- `${projectRoot}` - The root directory of the current project
- `${workspaceFolder}` - The current working directory
- `${env:VARIABLE_NAME}` - Environment variable from your shell

#### 3. Using Shell Script Wrapper

For more complex setups, use a wrapper script:

**~/.config/claude-code/mcp_servers.json:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "/home/user/bin/run-mcp-tree-sitter.sh",
      "args": [],
      "env": {
        "PROJECT_PATH": "${workspaceFolder}"
      }
    }
  }
}
```

**~/bin/run-mcp-tree-sitter.sh:**
```bash
#!/bin/bash
docker run -i --rm \
  -v "${PROJECT_PATH}:/workspace:ro" \
  -v mcp-cache:/cache \
  -e "MCP_TS_LOG_LEVEL=INFO" \
  mcp-server-tree-sitter:latest
```

Don't forget to make it executable:
```bash
chmod +x ~/bin/run-mcp-tree-sitter.sh
```

---

## Configuration Options

### Environment Variables

All environment variables can be passed with `-e` flag:

```json
"args": [
  "run", "-i", "--rm",
  "-e", "MCP_TS_LOG_LEVEL=DEBUG",
  "-e", "MCP_TS_CACHE_ENABLED=true",
  "-e", "MCP_TS_CACHE_MAX_SIZE_MB=200",
  "-e", "MCP_TS_CACHE_TTL_SECONDS=600",
  "-e", "MCP_TS_SECURITY_MAX_FILE_SIZE_MB=10",
  "-v", "${workspaceFolder}:/workspace:ro",
  "mcp-server-tree-sitter:latest"
]
```

### Available Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_TS_LOG_LEVEL` | `INFO` | Logging level: DEBUG, INFO, WARNING, ERROR |
| `MCP_TS_CACHE_ENABLED` | `true` | Enable/disable parse tree caching |
| `MCP_TS_CACHE_MAX_SIZE_MB` | `100` | Maximum cache size in MB |
| `MCP_TS_CACHE_TTL_SECONDS` | `300` | Cache entry TTL in seconds |
| `MCP_TS_SECURITY_MAX_FILE_SIZE_MB` | `5` | Maximum file size to parse |
| `MCP_TS_CONFIG_PATH` | - | Path to YAML config file |
| `MCP_TS_LANGUAGE_PREFERRED_LANGUAGES` | - | Comma-separated language list |

### Docker Run Options

#### Resource Limits

```json
"args": [
  "run", "-i", "--rm",
  "--memory", "1g",
  "--cpus", "2",
  "-v", "${workspaceFolder}:/workspace:ro",
  "mcp-server-tree-sitter:latest"
]
```

#### Security Options

```json
"args": [
  "run", "-i", "--rm",
  "--read-only",
  "--tmpfs", "/tmp",
  "--tmpfs", "/cache:mode=1777",
  "--security-opt", "no-new-privileges:true",
  "--cap-drop", "ALL",
  "-v", "${workspaceFolder}:/workspace:ro",
  "mcp-server-tree-sitter:latest"
]
```

#### Network Isolation

```json
"args": [
  "run", "-i", "--rm",
  "--network", "none",
  "-v", "${workspaceFolder}:/workspace:ro",
  "mcp-server-tree-sitter:latest"
]
```

---

## Common Scenarios

### Scenario 1: Development Workflow

Analyze code in your active development directory:

**Claude Desktop:**
```json
{
  "mcpServers": {
    "tree_sitter_dev": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache-dev:/cache",
        "-e", "MCP_TS_LOG_LEVEL=DEBUG",
        "-e", "MCP_TS_CACHE_ENABLED=true",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Scenario 2: Large Monorepo

Optimize for large codebases:

```json
{
  "mcpServers": {
    "tree_sitter_monorepo": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--memory", "4g",
        "--cpus", "4",
        "-v", "/path/to/monorepo:/workspace:ro",
        "-v", "mcp-cache-monorepo:/cache",
        "-e", "MCP_TS_CACHE_ENABLED=true",
        "-e", "MCP_TS_CACHE_MAX_SIZE_MB=500",
        "-e", "MCP_TS_CACHE_TTL_SECONDS=3600",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Scenario 3: CI/CD Analysis

Analyze code in CI pipelines (via Claude Code):

**.claude/mcp_servers.json:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${projectRoot}:/workspace:ro",
        "-e", "MCP_TS_LOG_LEVEL=WARNING",
        "-e", "MCP_TS_CACHE_ENABLED=false",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Scenario 4: Security-Focused Setup

Maximum security with minimal privileges:

```json
{
  "mcpServers": {
    "tree_sitter_secure": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--read-only",
        "--tmpfs", "/tmp:rw,noexec,nosuid,size=50m",
        "--tmpfs", "/cache:rw,noexec,nosuid,size=100m",
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

### Scenario 5: Multi-Language Projects

Pre-load specific languages for better performance:

```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_LANGUAGE_PREFERRED_LANGUAGES=python,javascript,typescript,go,rust",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

---

## Troubleshooting

### Issue 1: MCP Server Not Appearing

**Symptoms:**
- No MCP tools icon in Claude Desktop
- Server not listed in available tools

**Solutions:**

1. **Verify JSON syntax:**
   ```bash
   # macOS/Linux
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq .

   # Or use Python
   python -m json.tool ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

2. **Check file location:**
   ```bash
   # macOS
   ls -la ~/Library/Application\ Support/Claude/

   # Linux
   ls -la ~/.config/Claude/

   # Windows
   dir %APPDATA%\Claude\
   ```

3. **Restart Claude Desktop** after configuration changes

4. **Check Claude Desktop logs:**
   - macOS: `~/Library/Logs/Claude/`
   - Windows: `%APPDATA%\Claude\logs\`

### Issue 2: Docker Container Fails to Start

**Symptoms:**
- Error messages in Claude
- MCP server connection failed

**Solutions:**

1. **Test Docker command manually:**
   ```bash
   docker run -i --rm \
     -v $(pwd):/workspace:ro \
     -v mcp-cache:/cache \
     mcp-server-tree-sitter:latest --version
   ```

2. **Check Docker is running:**
   ```bash
   docker ps
   ```

3. **Verify image exists:**
   ```bash
   docker images | grep mcp-server-tree-sitter
   ```

4. **Check volume mounts exist:**
   ```bash
   docker volume ls | grep mcp-cache
   ```

### Issue 3: Permission Denied Errors

**Symptoms:**
```
Error: Permission denied: '/workspace/file.py'
```

**Solutions:**

1. **Linux SELinux - Add `:z` or `:Z` flag:**
   ```json
   "-v", "${workspaceFolder}:/workspace:ro,z"
   ```

2. **Check file permissions:**
   ```bash
   ls -la /path/to/project
   ```

3. **Ensure Docker has file access:**
   - macOS: Check Docker Desktop → Settings → Resources → File Sharing
   - Windows: Check Docker Desktop → Settings → Resources → File Sharing

### Issue 4: Container Name Conflict

**Symptoms:**
```
Error: Conflict. The container name "/mcp-tree-sitter" is already in use
```

**Solutions:**

1. **Remove the `--name` flag** to let Docker generate names
2. **Stop existing container:**
   ```bash
   docker stop mcp-tree-sitter
   docker rm mcp-tree-sitter
   ```
3. **Use unique names** for multiple instances

### Issue 5: Volume Mount Not Working

**Symptoms:**
- Server can't find files
- Empty workspace directory

**Solutions:**

1. **Use absolute paths** (not relative):
   ```json
   "-v", "/absolute/path/to/project:/workspace:ro"
   ```

2. **Check path syntax:**
   - macOS/Linux: `/Users/name/project` or `/home/user/project`
   - Windows: `C:\\Users\\Name\\Project` (escape backslashes)

3. **Verify workspace variable:**
   ```bash
   echo ${workspaceFolder}  # Should show current directory
   ```

### Issue 6: Slow Performance

**Symptoms:**
- Long delays when analyzing code
- Timeouts

**Solutions:**

1. **Enable and increase cache:**
   ```json
   "-e", "MCP_TS_CACHE_ENABLED=true",
   "-e", "MCP_TS_CACHE_MAX_SIZE_MB=500"
   ```

2. **Use named volume for cache** (not bind mount):
   ```json
   "-v", "mcp-cache:/cache"
   ```

3. **Increase resources:**
   ```json
   "--memory", "2g",
   "--cpus", "2"
   ```

4. **Pre-load languages:**
   ```json
   "-e", "MCP_TS_LANGUAGE_PREFERRED_LANGUAGES=python,javascript"
   ```

### Issue 7: Claude Code CLI Not Finding Server

**Symptoms:**
- `claude` command doesn't see MCP server
- Tools not available

**Solutions:**

1. **Check config file location:**
   ```bash
   cat ~/.config/claude-code/mcp_servers.json
   ```

2. **Verify environment variables:**
   ```bash
   env | grep CLAUDE
   ```

3. **Use project-specific config:**
   ```bash
   mkdir -p .claude
   # Add mcp_servers.json there
   ```

4. **Test with verbose mode:**
   ```bash
   claude --verbose
   ```

---

## Testing Your Configuration

### Quick Test for Claude Desktop

1. **Open Claude Desktop**

2. **Look for MCP tools icon** (hammer icon) in the interface

3. **Click the tools icon** - you should see "tree_sitter" (or your server name)

4. **Try a simple command:**
   ```
   Can you list the files in my project?
   ```

5. **Check if it works:**
   - Claude should use the `list_files` tool
   - You should see file listings from your project

### Quick Test for Claude Code CLI

1. **Navigate to your project:**
   ```bash
   cd /path/to/your/project
   ```

2. **Run Claude Code:**
   ```bash
   claude
   ```

3. **Check available tools:**
   ```bash
   # In Claude Code session, ask:
   What MCP tools are available?
   ```

4. **Test the server:**
   ```bash
   # Ask Claude to analyze something:
   Can you analyze the structure of this project?
   ```

### Manual Docker Test

Test the Docker container directly:

```bash
# Start container interactively
docker run -i --rm \
  -v $(pwd):/workspace:ro \
  -v mcp-cache:/cache \
  -e MCP_TS_LOG_LEVEL=DEBUG \
  mcp-server-tree-sitter:latest

# In another terminal, check logs
docker logs mcp-tree-sitter

# Check if container is running
docker ps | grep mcp-tree-sitter
```

### Verify Cache is Working

```bash
# Check cache volume
docker volume inspect mcp-cache

# Check cache size
docker run --rm -v mcp-cache:/cache alpine du -sh /cache
```

### Debug Mode Testing

Enable debug mode and check logs:

```json
{
  "mcpServers": {
    "tree_sitter": {
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

Then view logs:
```bash
docker logs -f mcp-tree-sitter-debug
```

---

## Best Practices

### 1. Configuration Management

✅ **Do:**
- Keep a backup of your configuration files
- Use version control for project-specific configs
- Document any custom settings
- Test changes in a separate server entry first

❌ **Don't:**
- Edit configuration while Claude is running
- Share configurations with hardcoded paths
- Skip JSON validation

### 2. Security

✅ **Do:**
- Use read-only mounts for source code (`:ro`)
- Run with `--network none` when possible
- Use `--security-opt=no-new-privileges:true`
- Limit resources with `--memory` and `--cpus`

❌ **Don't:**
- Mount sensitive directories (like ~/.ssh)
- Run without `--rm` flag (leaves containers behind)
- Share cache volumes between untrusted projects

### 3. Performance

✅ **Do:**
- Use named volumes for cache (faster than bind mounts)
- Pre-load frequently used languages
- Set appropriate cache size for your projects
- Use SSD storage for Docker volumes

❌ **Don't:**
- Disable cache without reason
- Use tiny resource limits
- Mount over network shares (slow)

### 4. Maintenance

✅ **Do:**
- Update Docker image regularly
- Clear old cache volumes periodically
- Monitor resource usage
- Keep documentation of your setup

❌ **Don't:**
- Let cache grow unbounded
- Forget to clean up stopped containers
- Ignore Docker updates

---

## Advanced Configuration

### Using docker-compose with Claude Desktop

Create a wrapper script that uses docker-compose:

**~/bin/mcp-tree-sitter-compose.sh:**
```bash
#!/bin/bash
cd /path/to/docker-compose/directory
docker-compose run --rm mcp-server
```

**Claude Desktop config:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "/home/user/bin/mcp-tree-sitter-compose.sh",
      "args": []
    }
  }
}
```

### Dynamic Path Resolution

Use environment variables for flexible paths:

**~/.bashrc or ~/.zshrc:**
```bash
export MY_PROJECT_PATH=/path/to/project
```

**Claude Desktop config:**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${env:MY_PROJECT_PATH}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Multiple Configurations with Profiles

Create different configurations for different purposes:

```json
{
  "mcpServers": {
    "tree_sitter_dev": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-e", "MCP_TS_LOG_LEVEL=DEBUG",
        "mcp-server-tree-sitter:latest"
      ]
    },
    "tree_sitter_prod": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--read-only",
        "--network", "none",
        "-v", "${workspaceFolder}:/workspace:ro",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

---

## Migration Guide

### From Native Installation to Docker

**Before (Native):**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "python",
      "args": ["-m", "mcp_server_tree_sitter.server"]
    }
  }
}
```

**After (Docker):**
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

**Benefits:**
- No Python environment conflicts
- Consistent across machines
- Easier updates
- Better isolation

---

## Additional Resources

- [Main README](../../README.md) - Project overview
- [Deployment Guide](DEPLOYMENT.md) - Detailed deployment instructions
- [Docker Plan](DOCKER_PLAN.md) - Implementation details
- [Troubleshooting](DEPLOYMENT.md#troubleshooting) - Common issues

---

## Support

For issues with Claude integration:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Review [DEPLOYMENT.md](DEPLOYMENT.md) for Docker-specific issues
3. Check [GitHub Issues](https://github.com/wrale/mcp-server-tree-sitter/issues)
4. Start a [Discussion](https://github.com/wrale/mcp-server-tree-sitter/discussions)

---

**Last Updated**: 2025-11-07
**Version**: 1.0
