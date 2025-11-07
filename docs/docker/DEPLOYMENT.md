# Docker Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying and using the MCP Tree-sitter Server in Docker containers. It covers various deployment scenarios from local development to production use with Claude Desktop.

## Quick Start

### Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 2.0+ (optional)
- 1GB free disk space
- 512MB available RAM

### Pull the Image (Once Available)

```bash
# Pull latest version
docker pull mcp-server-tree-sitter:latest

# Or specific version
docker pull mcp-server-tree-sitter:0.5.1
```

### Basic Usage

```bash
# Analyze a project
docker run -i --rm \
  -v /path/to/your/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

**Note**: The `-i` (interactive) flag is **required** for MCP protocol communication via stdin/stdout.

## Building from Source

### Build the Image

```bash
# Clone the repository
git clone https://github.com/wrale/mcp-server-tree-sitter.git
cd mcp-server-tree-sitter

# Build production image
docker build -t mcp-server-tree-sitter:local .

# Build with specific target
docker build --target runtime -t mcp-server-tree-sitter:local .

# Build development image
docker build -f Dockerfile.dev -t mcp-server-tree-sitter:dev .
```

### Build Options

```bash
# Multi-platform build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t mcp-server-tree-sitter:latest \
  .

# Build with BuildKit cache
DOCKER_BUILDKIT=1 docker build \
  --cache-from mcp-server-tree-sitter:latest \
  -t mcp-server-tree-sitter:local .

# Build with build arguments
docker build \
  --build-arg PYTHON_VERSION=3.11 \
  -t mcp-server-tree-sitter:py311 .
```

## Deployment Scenarios

### Scenario 1: Claude Desktop Integration

**Configuration File**: `claude_desktop_config.json`

#### macOS/Linux
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

#### Windows (PowerShell)
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
        "-v", "${env:PWD}:/workspace:ro",
        "-v", "mcp-cache:/cache",
        "-e", "MCP_TS_LOG_LEVEL=INFO",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

#### Multiple Projects
```json
{
  "mcpServers": {
    "tree_sitter_project1": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/path/to/project1:/workspace:ro",
        "-v", "mcp-cache-project1:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    },
    "tree_sitter_project2": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/path/to/project2:/workspace:ro",
        "-v", "mcp-cache-project2:/cache",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

### Scenario 2: Local Development

#### Using docker-compose

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  mcp-server:
    build:
      context: .
      dockerfile: Dockerfile.dev
    stdin_open: true  # Required for MCP protocol
    tty: false        # TTY not needed
    volumes:
      - ./src:/app/src:ro  # Source code (hot-reload in dev)
      - ./tests:/app/tests:ro
      - ${PROJECT_PATH:-./example_project}:/workspace:ro
      - ${CONFIG_PATH:-./config}:/config:ro
      - mcp-cache:/cache
    environment:
      - MCP_TS_LOG_LEVEL=${LOG_LEVEL:-DEBUG}
      - MCP_TS_CACHE_ENABLED=true
      - MCP_TS_CACHE_MAX_SIZE_MB=200
      - PYTHONUNBUFFERED=1
    command: ["--debug"]

volumes:
  mcp-cache:
```

**Start the service**:
```bash
# Set environment variables
export PROJECT_PATH=/path/to/your/project
export LOG_LEVEL=DEBUG

# Start with compose
docker-compose up

# Or in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

#### Using Helper Scripts

**scripts/run-docker.sh**:
```bash
#!/bin/bash

PROJECT_PATH="${1:-.}"
CONFIG_PATH="${2:-}"
LOG_LEVEL="${3:-INFO}"

DOCKER_ARGS="-i --rm"
DOCKER_ARGS="$DOCKER_ARGS -v ${PROJECT_PATH}:/workspace:ro"
DOCKER_ARGS="$DOCKER_ARGS -v mcp-cache:/cache"
DOCKER_ARGS="$DOCKER_ARGS -e MCP_TS_LOG_LEVEL=${LOG_LEVEL}"

if [ -n "$CONFIG_PATH" ]; then
  DOCKER_ARGS="$DOCKER_ARGS -v ${CONFIG_PATH}:/config:ro"
  DOCKER_ARGS="$DOCKER_ARGS -e MCP_TS_CONFIG_PATH=/config/config.yaml"
fi

docker run $DOCKER_ARGS mcp-server-tree-sitter:latest
```

**Usage**:
```bash
# Analyze current directory
./scripts/run-docker.sh .

# With custom config
./scripts/run-docker.sh /path/to/project /path/to/config

# With debug logging
./scripts/run-docker.sh /path/to/project "" DEBUG
```

### Scenario 3: CI/CD Integration

#### GitHub Actions

**.github/workflows/code-analysis.yml**:
```yaml
name: Code Analysis

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Pull MCP Server Image
        run: docker pull mcp-server-tree-sitter:latest

      - name: Run Code Analysis
        run: |
          docker run -i --rm \
            -v ${{ github.workspace }}:/workspace:ro \
            -e MCP_TS_LOG_LEVEL=INFO \
            mcp-server-tree-sitter:latest \
            analyze_project --project /workspace --format json > analysis.json

      - name: Upload Analysis Results
        uses: actions/upload-artifact@v3
        with:
          name: analysis-results
          path: analysis.json
```

#### GitLab CI

**.gitlab-ci.yml**:
```yaml
code_analysis:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker pull mcp-server-tree-sitter:latest
    - docker run -i --rm
        -v $CI_PROJECT_DIR:/workspace:ro
        mcp-server-tree-sitter:latest
        analyze_project --project /workspace
  artifacts:
    paths:
      - analysis-results/
```

### Scenario 4: Production Deployment

#### With Resource Limits

```bash
docker run -i --rm \
  --name mcp-tree-sitter \
  --cpus="2" \
  --memory="1g" \
  --memory-swap="1g" \
  --pids-limit=100 \
  -v /data/projects:/workspace:ro \
  -v mcp-cache:/cache \
  -e MCP_TS_LOG_LEVEL=WARNING \
  mcp-server-tree-sitter:latest
```

#### With Security Hardening

```bash
docker run -i --rm \
  --name mcp-tree-sitter \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /cache:mode=1777 \
  --security-opt=no-new-privileges:true \
  --cap-drop=ALL \
  --network none \
  -v /data/projects:/workspace:ro \
  -e MCP_TS_LOG_LEVEL=WARNING \
  mcp-server-tree-sitter:latest
```

#### With Health Checks (If Implemented)

```bash
docker run -i -d \
  --name mcp-tree-sitter \
  --health-cmd="python -c 'import mcp_server_tree_sitter; print(\"OK\")'" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  -v /data/projects:/workspace:ro \
  mcp-server-tree-sitter:latest
```

## Configuration

### Environment Variables

```bash
# Logging
MCP_TS_LOG_LEVEL=INFO              # DEBUG|INFO|WARNING|ERROR

# Cache Settings
MCP_TS_CACHE_ENABLED=true          # Enable/disable caching
MCP_TS_CACHE_MAX_SIZE_MB=100       # Maximum cache size
MCP_TS_CACHE_TTL_SECONDS=300       # Cache TTL

# Security
MCP_TS_SECURITY_MAX_FILE_SIZE_MB=5 # Max file size to parse

# Language Preferences
MCP_TS_LANGUAGE_PREFERRED_LANGUAGES=python,javascript,typescript

# Config File
MCP_TS_CONFIG_PATH=/config/config.yaml  # Path to YAML config
```

### Configuration File

**config/config.yaml**:
```yaml
cache:
  enabled: true
  max_size_mb: 100
  ttl_seconds: 300

security:
  max_file_size_mb: 5
  excluded_dirs:
    - .git
    - node_modules
    - __pycache__
    - .venv
    - dist
    - build

language:
  default_max_depth: 5
  preferred_languages:
    - python
    - javascript
    - typescript
    - go

log_level: INFO
```

**Mount the config**:
```bash
docker run -i --rm \
  -v /path/to/config.yaml:/config/config.yaml:ro \
  -e MCP_TS_CONFIG_PATH=/config/config.yaml \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

### Volume Mounts

#### Source Code (Required)
```bash
-v /path/to/project:/workspace:ro
```
- **Purpose**: Code to analyze
- **Mode**: Read-only (`:ro`)
- **Required**: Yes

#### Configuration (Optional)
```bash
-v /path/to/config:/config:ro
```
- **Purpose**: Custom YAML configuration
- **Mode**: Read-only (`:ro`)
- **Required**: No

#### Cache (Recommended)
```bash
-v mcp-cache:/cache
```
- **Purpose**: Parse tree cache for performance
- **Mode**: Read-write
- **Required**: No (but improves performance)

#### Types of Volume Mounts

**Named Volume** (Recommended for cache):
```bash
docker volume create mcp-cache
docker run -i --rm -v mcp-cache:/cache ...
```

**Bind Mount** (For source code):
```bash
docker run -i --rm -v /host/path:/workspace:ro ...
```

**Tmpfs** (For temporary data):
```bash
docker run -i --rm --tmpfs /tmp:rw,noexec,nosuid,size=100m ...
```

## Networking

### No Network Required

The MCP server uses stdio and doesn't require network access:

```bash
# Disable networking for extra security
docker run -i --rm \
  --network none \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

### Bridge Network (If Future Features Need It)

```bash
# Create custom bridge network
docker network create mcp-network

# Run with custom network
docker run -i --rm \
  --network mcp-network \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

## Data Management

### Managing Cache

```bash
# Create named volume
docker volume create mcp-cache

# Inspect volume
docker volume inspect mcp-cache

# Check cache size
docker run --rm -v mcp-cache:/cache alpine du -sh /cache

# Clear cache
docker volume rm mcp-cache
docker volume create mcp-cache

# Backup cache
docker run --rm -v mcp-cache:/cache -v $(pwd):/backup alpine \
  tar czf /backup/mcp-cache-backup.tar.gz -C /cache .

# Restore cache
docker run --rm -v mcp-cache:/cache -v $(pwd):/backup alpine \
  tar xzf /backup/mcp-cache-backup.tar.gz -C /cache
```

### Log Management

```bash
# View logs from running container
docker logs mcp-tree-sitter

# Follow logs
docker logs -f mcp-tree-sitter

# Limit log size
docker run -i --rm \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

## Monitoring

### Resource Usage

```bash
# View real-time stats
docker stats mcp-tree-sitter

# View stats for all containers
docker stats

# One-time stats
docker stats --no-stream mcp-tree-sitter
```

### Health Checks (If Implemented)

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' mcp-tree-sitter

# View health check logs
docker inspect --format='{{json .State.Health}}' mcp-tree-sitter | jq
```

## Troubleshooting

### Common Issues

#### Issue 1: Container Starts but No Response

**Symptom**:
```bash
docker run -i --rm -v ./project:/workspace:ro mcp-server-tree-sitter:latest
# No output
```

**Cause**: Missing `-i` flag or container not in interactive mode

**Solution**:
```bash
# Ensure -i flag is present
docker run -i --rm -v ./project:/workspace:ro mcp-server-tree-sitter:latest
```

#### Issue 2: Permission Denied on Volume Mount

**Symptom**:
```
Error: Permission denied: '/workspace/file.py'
```

**Cause**: Volume mount permissions or SELinux

**Solution**:
```bash
# Linux: Check SELinux
ls -Z /path/to/project

# Add SELinux label if needed
docker run -i --rm \
  -v /path/to/project:/workspace:ro,z \
  mcp-server-tree-sitter:latest

# Or disable SELinux for mount (less secure)
-v /path/to/project:/workspace:ro,Z
```

#### Issue 3: Out of Memory

**Symptom**:
```
Container killed by OOM killer
```

**Cause**: Insufficient memory allocated

**Solution**:
```bash
# Increase memory limit
docker run -i --rm \
  --memory="2g" \
  --memory-swap="2g" \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest

# Or disable cache
docker run -i --rm \
  -e MCP_TS_CACHE_ENABLED=false \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

#### Issue 4: Slow Performance

**Cause**: No cache volume or bind mount performance

**Solution**:
```bash
# Use named volume for cache
docker volume create mcp-cache
docker run -i --rm \
  -v mcp-cache:/cache \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest

# On macOS: Use delegated mode
docker run -i --rm \
  -v /path/to/project:/workspace:ro,delegated \
  -v mcp-cache:/cache \
  mcp-server-tree-sitter:latest
```

#### Issue 5: Language Parser Not Found

**Symptom**:
```
Error: Language 'xyz' not available
```

**Cause**: Language not included in tree-sitter-language-pack

**Solution**:
```bash
# Check supported languages
docker run --rm mcp-server-tree-sitter:latest \
  python -c "from tree_sitter_language_pack import get_languages; print(get_languages())"

# Use a supported language or build custom image with additional parsers
```

### Debug Mode

```bash
# Run with debug logging
docker run -i --rm \
  -e MCP_TS_LOG_LEVEL=DEBUG \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest

# Run with shell access (dev image)
docker run -it --rm \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:dev \
  /bin/bash

# Inside container, manually test
python -m mcp_server_tree_sitter --debug
```

### Getting Help

```bash
# View help
docker run --rm mcp-server-tree-sitter:latest --help

# View version
docker run --rm mcp-server-tree-sitter:latest --version

# Test basic functionality
docker run --rm mcp-server-tree-sitter:latest \
  python -c "from mcp_server_tree_sitter import __version__; print(__version__)"
```

## Best Practices

### Security
1. ✅ Always use read-only mounts for source code (`:ro`)
2. ✅ Run with `--network none` when possible
3. ✅ Use `--read-only` filesystem with tmpfs for /tmp and /cache
4. ✅ Drop all capabilities with `--cap-drop=ALL`
5. ✅ Set resource limits (`--memory`, `--cpus`)
6. ✅ Use `--security-opt=no-new-privileges:true`
7. ❌ Don't run as root (image already uses non-root user)
8. ❌ Don't mount sensitive directories

### Performance
1. ✅ Use named volumes for cache (faster than bind mounts)
2. ✅ Pre-load frequently used languages via config
3. ✅ Set appropriate cache size for your projects
4. ✅ Use SSD storage for volume mounts
5. ✅ Allocate sufficient memory (512MB minimum)

### Operations
1. ✅ Use `--rm` flag to auto-cleanup containers
2. ✅ Name containers with `--name` for easier management
3. ✅ Tag images with versions, not just `latest`
4. ✅ Implement health checks in production
5. ✅ Monitor resource usage with `docker stats`
6. ✅ Backup cache volumes periodically

## Advanced Topics

### Multi-Stage Build Customization

```dockerfile
# Build with different Python version
FROM python:3.11-slim AS builder
# ... rest of Dockerfile

# Build with custom base
FROM custom-python-base:3.10 AS builder
# ... rest of Dockerfile
```

### Custom Entrypoint

```bash
# Override entrypoint for debugging
docker run -it --rm \
  --entrypoint /bin/bash \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

### Resource Constraints

```bash
# Advanced resource controls
docker run -i --rm \
  --cpus="2" \
  --cpu-shares=1024 \
  --memory="1g" \
  --memory-reservation="512m" \
  --memory-swap="1g" \
  --kernel-memory="512m" \
  --pids-limit=100 \
  --ulimit nofile=1024:2048 \
  -v /path/to/project:/workspace:ro \
  mcp-server-tree-sitter:latest
```

## Migration Guide

### From Native Installation to Docker

**Before** (Native):
```bash
pip install mcp-server-tree-sitter
python -m mcp_server_tree_sitter
```

**After** (Docker):
```bash
docker run -i --rm \
  -v $(pwd):/workspace:ro \
  mcp-server-tree-sitter:latest
```

**Claude Desktop Config Change**:

Before:
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

After:
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "${workspaceFolder}:/workspace:ro",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

## Support

For issues, questions, or contributions:

- GitHub Issues: https://github.com/wrale/mcp-server-tree-sitter/issues
- Documentation: https://github.com/wrale/mcp-server-tree-sitter/docs
- Discussions: https://github.com/wrale/mcp-server-tree-sitter/discussions
