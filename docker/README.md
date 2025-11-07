# Docker Support Files

This directory contains supporting files for the Docker containerization of the MCP Tree-sitter Server.

## Files

### entrypoint.sh

The container entrypoint script that:
- Validates the environment
- Checks workspace, cache, and config directories
- Verifies dependencies are loaded correctly
- Displays startup information
- Handles signals gracefully (SIGTERM, SIGINT)
- Executes the MCP server or custom command

**Usage:**
The entrypoint is automatically called by Docker. You can override commands:

```bash
# Default (runs MCP server)
docker run -i --rm mcp-server-tree-sitter:latest

# Run with debug flag
docker run -i --rm mcp-server-tree-sitter:latest --debug

# Run bash shell (dev image)
docker run -it --rm mcp-server-tree-sitter:dev /bin/bash

# Run tests
docker run --rm mcp-server-tree-sitter:dev pytest
```

## Building Images

### Production Image

```bash
# Build from project root
docker build -t mcp-server-tree-sitter:latest .

# Build with specific tag
docker build -t mcp-server-tree-sitter:0.5.1 .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 \
  -t mcp-server-tree-sitter:latest .
```

### Development Image

```bash
# Build dev image
docker build -f Dockerfile.dev -t mcp-server-tree-sitter:dev .
```

## Testing the Build

### Quick Test

```bash
# Check version
docker run --rm mcp-server-tree-sitter:latest --version

# Check help
docker run --rm mcp-server-tree-sitter:latest --help

# Verify dependencies
docker run --rm mcp-server-tree-sitter:latest \
  python -c "import mcp_server_tree_sitter; print('OK')"
```

### Run with Project

```bash
# Analyze a project
docker run -i --rm \
  -v $(pwd):/workspace:ro \
  -v mcp-cache:/cache \
  mcp-server-tree-sitter:latest
```

### Development Testing

```bash
# Run tests
docker run --rm mcp-server-tree-sitter:dev pytest

# Run with coverage
docker run --rm mcp-server-tree-sitter:dev pytest --cov

# Interactive shell
docker run -it --rm mcp-server-tree-sitter:dev /bin/bash
```

## Image Details

### Production Image (Dockerfile)

**Base**: python:3.10-slim

**Features**:
- Multi-stage build for minimal size
- Non-root user (mcp:mcp, UID/GID 1000)
- Only runtime dependencies
- Health check included
- ~300-400MB size (estimated)

**Layers**:
1. Builder stage: Installs build deps and compiles packages
2. Runtime stage: Copies compiled packages, adds application code

**Volumes**:
- `/workspace` - Source code to analyze (mount read-only)
- `/cache` - Parse tree cache (writable)
- `/config` - Optional configuration files (read-only)

**User**: mcp (UID 1000, GID 1000)

**Entrypoint**: `/entrypoint.sh`

**Default CMD**: `python -m mcp_server_tree_sitter.server`

### Development Image (Dockerfile.dev)

**Base**: python:3.10-slim

**Features**:
- All build tools included
- Development dependencies (pytest, mypy, ruff)
- Additional tools (git, vim, curl)
- Source code volume mounts
- Debug logging by default

**Additional Volumes**:
- `/app/src` - Application source (for hot-reload)
- `/app/tests` - Test files

**Default CMD**: `python -m mcp_server_tree_sitter.server --debug`

## Environment Variables

All MCP_TS_* environment variables are supported:

```bash
docker run -i --rm \
  -e MCP_TS_LOG_LEVEL=DEBUG \
  -e MCP_TS_CACHE_ENABLED=true \
  -e MCP_TS_CACHE_MAX_SIZE_MB=200 \
  -v $(pwd):/workspace:ro \
  mcp-server-tree-sitter:latest
```

See [../docs/docker/CLAUDE_INTEGRATION.md](../docs/docker/CLAUDE_INTEGRATION.md) for complete list.

## Build Optimization

### Layer Caching

The Dockerfile is optimized for layer caching:
1. System dependencies (rarely change)
2. pyproject.toml (dependency changes)
3. Application code (frequent changes)

### .dockerignore

The `.dockerignore` file excludes:
- Git files and history
- Python cache files
- Test files and coverage reports
- Documentation (except README.md)
- Development tools
- IDE configurations

This reduces build context from ~50MB to ~5MB.

## Troubleshooting

### Build Fails During Dependency Installation

**Issue**: tree-sitter-language-pack compilation fails

**Solution**:
```bash
# Ensure enough memory
docker build --memory=4g -t mcp-server-tree-sitter:latest .

# Check build logs
docker build --progress=plain -t mcp-server-tree-sitter:latest .
```

### Permission Errors

**Issue**: Container can't access mounted volumes

**Solution**:
```bash
# Linux: Ensure correct ownership
chown -R 1000:1000 /path/to/project

# Or use :z flag for SELinux
docker run -i --rm -v $(pwd):/workspace:ro,z mcp-server-tree-sitter:latest
```

### Large Image Size

**Issue**: Image larger than expected

**Solution**:
```bash
# Check layer sizes
docker history mcp-server-tree-sitter:latest

# Ensure multi-stage build is working
docker build --target runtime -t mcp-server-tree-sitter:latest .

# Clean build cache
docker builder prune
```

## Maintenance

### Updating Base Image

```bash
# Pull latest base
docker pull python:3.10-slim

# Rebuild
docker build --no-cache -t mcp-server-tree-sitter:latest .
```

### Cleaning Up

```bash
# Remove old images
docker rmi mcp-server-tree-sitter:old-tag

# Remove all untagged images
docker image prune

# Remove build cache
docker builder prune -a
```

## Security

### Running with Minimal Privileges

```bash
docker run -i --rm \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /cache:mode=1777 \
  --security-opt=no-new-privileges:true \
  --cap-drop=ALL \
  --network=none \
  -v $(pwd):/workspace:ro \
  mcp-server-tree-sitter:latest
```

### Scanning for Vulnerabilities

```bash
# Using Trivy
trivy image mcp-server-tree-sitter:latest

# Using Docker Scout (if available)
docker scout cves mcp-server-tree-sitter:latest
```

## CI/CD Integration

See [../.github/workflows/](../.github/workflows/) for example GitHub Actions workflows.

## Additional Resources

- [Deployment Guide](../docs/docker/DEPLOYMENT.md)
- [Claude Integration Guide](../docs/docker/CLAUDE_INTEGRATION.md)
- [Dependencies Documentation](../docs/docker/DEPENDENCIES.md)
- [Implementation Checklist](../docs/docker/IMPLEMENTATION_CHECKLIST.md)

---

**Last Updated**: 2025-11-07
