# Docker Helper Scripts

This directory contains helper scripts for building, running, testing, and managing the MCP Tree-sitter Server Docker containers.

## Available Scripts

### build.sh - Build Docker Images

Build production or development Docker images.

**Usage:**
```bash
./build.sh [TARGET] [OPTIONS]
```

**Targets:**
- `production` - Build production image (default)
- `dev` - Build development image
- `all` - Build both images

**Options:**
- `-t, --tag TAG` - Image tag (default: latest)
- `-p, --platform PLAT` - Build for specific platform(s)
- `--no-cache` - Build without using cache
- `--push` - Push image after building
- `-h, --help` - Show help

**Examples:**
```bash
# Build production image
./build.sh production

# Build dev image with tag
./build.sh dev -t v0.5.1

# Multi-platform build
./build.sh production -p linux/amd64,linux/arm64

# Build and push
./build.sh production --push
```

---

### run.sh - Run Container

Run the MCP Tree-sitter Server in a Docker container.

**Usage:**
```bash
./run.sh [PROJECT_PATH] [OPTIONS]
```

**Options:**
- `-c, --config PATH` - Path to config.yaml
- `-t, --tag TAG` - Image tag to use
- `-n, --name NAME` - Container name
- `-l, --log-level LEVEL` - Log level (DEBUG, INFO, WARNING, ERROR)
- `--cache-size SIZE` - Cache size in MB
- `--no-cache` - Disable caching
- `-d, --detach` - Run in background
- `--debug` - Enable debug mode
- `-h, --help` - Show help

**Examples:**
```bash
# Run with current directory
./run.sh

# Run with specific project
./run.sh /path/to/project

# Run with custom config
./run.sh . -c /path/to/config.yaml

# Run with debug logging
./run.sh . --debug

# Run in background
./run.sh /path/to/project -d
```

---

### test.sh - Run Tests

Test Docker images with various test suites.

**Usage:**
```bash
./test.sh [OPTIONS]
```

**Options:**
- `-t, --tag TAG` - Image tag to test
- `--type TYPE` - Test type: quick, unit, integration, all (default: all)
- `--coverage` - Run with coverage report
- `-v, --verbose` - Verbose output
- `-h, --help` - Show help

**Test Types:**
- `quick` - Quick smoke tests (version, imports, etc.)
- `unit` - Run pytest unit tests
- `integration` - Run integration tests
- `all` - Run all test suites

**Examples:**
```bash
# Run all tests
./test.sh

# Quick tests only
./test.sh --type quick

# Unit tests with coverage
./test.sh --type unit --coverage

# Verbose output
./test.sh -v
```

---

### clean.sh - Cleanup Resources

Clean up Docker containers, images, and volumes.

**Usage:**
```bash
./clean.sh [OPTIONS]
```

**Options:**
- `-c, --containers` - Clean stopped containers
- `-i, --images` - Clean dangling images
- `-v, --volumes` - Clean unused volumes (removes cache!)
- `-a, --all` - Clean everything
- `-f, --force` - Don't ask for confirmation
- `--dry-run` - Show what would be cleaned
- `-h, --help` - Show help

**Examples:**
```bash
# Clean containers only
./clean.sh -c

# Clean images and containers
./clean.sh -c -i

# Clean everything (with confirmation)
./clean.sh -a

# See what would be cleaned
./clean.sh -a --dry-run

# Clean everything without confirmation
./clean.sh -a -f
```

**Warning:** Cleaning volumes will delete all cached parse trees!

---

### install-claude-desktop.sh - Claude Desktop Setup

Automatically configure Claude Desktop to use the Docker MCP server.

**Usage:**
```bash
./install-claude-desktop.sh [OPTIONS]
```

**Options:**
- `-n, --name NAME` - Server name in config (default: tree_sitter)
- `-t, --tag TAG` - Docker image tag (default: latest)
- `-w, --workspace PATH` - Workspace path (default: ${workspaceFolder})
- `--no-backup` - Don't backup existing config
- `--dry-run` - Preview changes
- `-h, --help` - Show help

**Examples:**
```bash
# Basic installation
./install-claude-desktop.sh

# Custom server name
./install-claude-desktop.sh -n tree_sitter_main

# Fixed workspace path
./install-claude-desktop.sh -w /Users/me/Projects/myproject

# Preview changes
./install-claude-desktop.sh --dry-run
```

**Config Locations:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Requirements:**
- `jq` (optional but recommended for automatic config updates)
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq`

---

## Common Workflows

### Complete Setup

```bash
# 1. Build the image
./build.sh production

# 2. Test it works
./test.sh --type quick

# 3. Install in Claude Desktop
./install-claude-desktop.sh

# 4. Restart Claude Desktop
```

### Development Workflow

```bash
# 1. Build dev image
./build.sh dev

# 2. Run tests
./test.sh --type unit --coverage

# 3. Run with debug logging
./run.sh /path/to/project --debug
```

### Testing a New Version

```bash
# 1. Build with version tag
./build.sh production -t v0.6.0

# 2. Test it
./test.sh -t v0.6.0

# 3. Run it
./run.sh . -t v0.6.0
```

### Cleanup Before Rebuild

```bash
# 1. Stop any running containers
docker stop mcp-tree-sitter

# 2. Clean everything except volumes (keep cache)
./clean.sh -c -i -f

# 3. Rebuild
./build.sh production --no-cache
```

### Complete Cleanup

```bash
# Remove everything including cache
./clean.sh -a

# This will ask for confirmation
# Add -f to skip confirmation
```

## Script Features

### All Scripts Include

- ✅ Colored output for better readability
- ✅ Detailed help messages (`--help`)
- ✅ Error handling and validation
- ✅ Dry-run mode where applicable
- ✅ Informative progress messages
- ✅ Exit codes for CI/CD integration

### Exit Codes

- `0` - Success
- `1` - Error or test failure
- Standard Unix conventions

## Platform Support

### Supported Platforms

- ✅ macOS (Intel and Apple Silicon)
- ✅ Linux (x86_64 and arm64)
- ✅ Windows (Use direct docker commands or WSL/Git Bash)

### Requirements

**macOS/Linux:**
- Docker Engine 20.10+
- Bash 4.0+

**Windows:**
- Docker Desktop 20.10+
- PowerShell 5.1+ (for direct docker commands)
- OR WSL/Git Bash (to run bash helper scripts)

**Optional (for better experience):**
- `jq` - JSON processing (for install-claude-desktop.sh)
- `docker buildx` - Multi-platform builds

### Windows Users

The bash helper scripts (`.sh` files) require a bash environment. Windows users have three options:

**Option 1: Direct Docker Commands (Recommended)**

Use PowerShell with direct docker commands:

```powershell
# Build development image
docker build -f Dockerfile.dev -t mcp-server-tree-sitter:dev .

# Build production image
docker build -t mcp-server-tree-sitter:latest .

# Run container
docker run -i --rm `
  -v ${PWD}:/workspace:ro `
  -v mcp-cache:/cache `
  mcp-server-tree-sitter:dev
```

**Option 2: Windows Subsystem for Linux (WSL)**

Install WSL and run scripts normally:

```powershell
wsl ./scripts/docker/build.sh dev
wsl ./scripts/docker/run.sh /path/to/project
```

**Option 3: Git Bash**

If you have Git for Windows installed, use Git Bash:

```bash
./scripts/docker/build.sh dev
./scripts/docker/run.sh /path/to/project
```

**Common Windows Issues:**

1. **`build.sh: not found`** - Use direct docker commands or WSL/Git Bash
2. **`docker buildx build' requires 1 argument`** - Variable expansion issue in PowerShell, use direct commands
3. **Path issues** - Use absolute Windows paths (e.g., `C:\Users\...`) or `${PWD}` for current directory

## Tips and Tricks

### Faster Builds

```bash
# Use cache from previous build
./build.sh production --cache-from mcp-server-tree-sitter:latest

# Multi-platform build with cache
./build.sh production \
  -p linux/amd64,linux/arm64 \
  --cache-from mcp-server-tree-sitter:latest
```

### Debugging Build Issues

```bash
# Build without cache
./build.sh production --no-cache

# Build and run tests immediately
./build.sh production && ./test.sh --type quick
```

### Automating in Scripts

```bash
#!/bin/bash
# Your custom automation script

cd /path/to/mcp-server-tree-sitter-docker

# Build
./scripts/docker/build.sh production -t latest || exit 1

# Test
./scripts/docker/test.sh --type all || exit 1

# Install
./scripts/docker/install-claude-desktop.sh --dry-run

echo "Ready to deploy!"
```

### CI/CD Integration

```bash
# Example GitHub Actions / GitLab CI script
./scripts/docker/build.sh production -t $VERSION
./scripts/docker/test.sh --type all
./scripts/docker/build.sh production -t $VERSION --push
```

## Troubleshooting

### Build Script Issues

**Problem:** `docker buildx` not found

**Solution:**
```bash
# Install buildx
docker buildx install

# Or use standard build (single platform)
./build.sh production  # without -p flag
```

### Run Script Issues

**Problem:** Container name already in use

**Solution:**
```bash
# Remove old container
docker rm -f mcp-tree-sitter

# Or use different name
./run.sh . -n mcp-tree-sitter-2
```

### Test Script Issues

**Problem:** Dev image not found

**Solution:**
```bash
# Build dev image first
./build.sh dev
```

### Install Script Issues

**Problem:** jq not found

**Solution:**
```bash
# Install jq
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

**Problem:** Permission denied on config file

**Solution:**
```bash
# Check permissions
ls -la "~/Library/Application Support/Claude/"

# Fix if needed
chmod 755 "~/Library/Application Support/Claude/"
```

## Additional Resources

- [Main Docker Documentation](../../docs/docker/README.md)
- [Deployment Guide](../../docs/docker/DEPLOYMENT.md)
- [Claude Integration Guide](../../docs/docker/CLAUDE_INTEGRATION.md)
- [Examples](../../examples/docker/)

## Contributing

When adding new scripts:

1. Follow existing naming conventions
2. Include comprehensive help text
3. Add error handling
4. Support `--help` and `--dry-run`
5. Use colored output for clarity
6. Update this README

## Support

For issues with scripts:

1. Run with `--help` to see all options
2. Try `--dry-run` to preview actions
3. Check [Troubleshooting](#troubleshooting) section
4. Report issues on GitHub

---

**Last Updated**: 2025-11-07
**Script Version**: 1.0
