# Docker Implementation Plan

## Overview

This document outlines the comprehensive plan for containerizing the MCP Tree-sitter Server. The implementation will enable the server to run in isolated, reproducible Docker containers while maintaining full functionality for code analysis and MCP protocol communication.

## Goals

### Primary Goals
1. **Container-ready Server**: Package the MCP server in a lightweight, production-ready Docker image
2. **Claude Desktop Integration**: Enable seamless integration with Claude Desktop via Docker
3. **Development Workflow**: Support local development with hot-reloading
4. **Multi-platform Support**: Build images for amd64 and arm64 architectures
5. **Security**: Implement least-privilege principles and security best practices

### Secondary Goals
1. **Size Optimization**: Minimize image size through multi-stage builds
2. **Cache Efficiency**: Leverage Docker layer caching for faster builds
3. **Documentation**: Comprehensive guides for deployment and usage
4. **CI/CD Integration**: Automate image builds and publishing

## Architecture Decisions

### Base Image Selection

**Option 1: python:3.10-slim (Recommended)**
- Pros: Small size (~150MB), security updates, official image
- Cons: Requires additional build tools for tree-sitter
- Use Case: Production deployments

**Option 2: python:3.10-alpine**
- Pros: Smallest size (~50MB base)
- Cons: musl libc compatibility issues, longer build times
- Use Case: Size-critical deployments (needs testing)

**Option 3: python:3.10**
- Pros: All build tools included, fastest builds
- Cons: Large size (~900MB)
- Use Case: Development only

**Decision**: Use `python:3.10-slim` for production with multi-stage build

### Communication Model

**Challenge**: MCP protocol uses stdio (stdin/stdout), not HTTP/REST

**Solution**:
```
Host Machine (Claude Desktop)
    │
    ↓ docker run -i (interactive mode)
    │
Container (MCP Server)
    ├─ stdin  ← JSON-RPC requests
    └─ stdout → JSON-RPC responses
```

**Requirements**:
- Container must run with `-i` (interactive) flag
- No TTY allocation needed (`-t` flag not required)
- Container runs in foreground (not detached)
- Logs go to stderr, protocol to stdout

### Volume Mount Strategy

**Required Mounts**:
1. **Source Code**: `/workspace` (read-only)
   - Mount the codebase to be analyzed
   - Read-only for security

2. **Configuration**: `/config` (optional, read-only)
   - Custom YAML configurations
   - Alternative to environment variables

3. **Cache**: `/cache` (read-write, optional)
   - Persistent parse tree cache
   - Improves performance across restarts

**Example**:
```bash
docker run -i \
  -v /path/to/project:/workspace:ro \
  -v /path/to/config:/config:ro \
  -v mcp-cache:/cache \
  mcp-server-tree-sitter
```

### Environment Configuration

**Key Environment Variables**:
```bash
# Logging
MCP_TS_LOG_LEVEL=INFO|DEBUG|WARNING|ERROR

# Cache Configuration
MCP_TS_CACHE_ENABLED=true
MCP_TS_CACHE_MAX_SIZE_MB=100
MCP_TS_CACHE_TTL_SECONDS=300

# Security
MCP_TS_SECURITY_MAX_FILE_SIZE_MB=5

# Language Preferences
MCP_TS_LANGUAGE_PREFERRED_LANGUAGES=python,javascript,typescript

# Config File
MCP_TS_CONFIG_PATH=/config/config.yaml
```

## Implementation Phases

### Phase 1: Basic Dockerfile (Week 1)

**Deliverables**:
- [ ] `Dockerfile` - Multi-stage production build
- [ ] `Dockerfile.dev` - Development variant with hot-reload
- [ ] `.dockerignore` - Optimize build context
- [ ] `docker/` - Directory for Docker-related files

**Tasks**:
1. Create multi-stage Dockerfile
   - Stage 1: Build dependencies
   - Stage 2: Install Python packages
   - Stage 3: Runtime image with minimal layers

2. Implement security best practices
   - Non-root user
   - Minimal base image
   - Only required packages
   - No secrets in layers

3. Optimize image size
   - Multi-stage build
   - Minimize layers
   - Remove build artifacts
   - Use .dockerignore

**Success Criteria**:
- Image size < 400MB
- Server runs successfully
- All tests pass in container
- Build time < 5 minutes

### Phase 2: docker-compose Setup (Week 1)

**Deliverables**:
- [ ] `docker-compose.yml` - Production setup
- [ ] `docker-compose.dev.yml` - Development setup
- [ ] Example configurations
- [ ] Environment templates

**Tasks**:
1. Create docker-compose.yml
   - Service definition
   - Volume mounts
   - Environment variables
   - Network configuration (if needed)

2. Create development variant
   - Source code mount for hot-reload
   - Debug mode enabled
   - Additional development tools

3. Add example projects
   - Sample Python project
   - Sample JavaScript project
   - Configuration examples

**Success Criteria**:
- One-command startup
- Volume mounts working
- Environment vars applied
- Easy to customize

### Phase 3: Claude Desktop Integration (Week 2)

**Deliverables**:
- [ ] Claude Desktop configuration guide
- [ ] Helper scripts for Docker integration
- [ ] Troubleshooting documentation
- [ ] Example workflows

**Tasks**:
1. Document Claude Desktop setup
   - Configuration file format
   - Docker command structure
   - Volume mount configuration

2. Create helper scripts
   - `scripts/run-docker.sh` - Wrapper for docker run
   - `scripts/install-claude.sh` - Setup automation
   - Cross-platform support (bash, PowerShell)

3. Test integration scenarios
   - Single project analysis
   - Multiple projects
   - Configuration variants

**Claude Desktop Config Example**:
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
        "-e", "MCP_TS_LOG_LEVEL=INFO",
        "mcp-server-tree-sitter:latest"
      ]
    }
  }
}
```

**Success Criteria**:
- Claude Desktop can communicate with container
- File analysis works correctly
- Performance acceptable (< 2s latency)
- Error handling robust

### Phase 4: Documentation & Examples (Week 2)

**Deliverables**:
- [ ] `docs/docker/DEPLOYMENT.md` - Deployment guide
- [ ] `docs/docker/DEVELOPMENT.md` - Development guide
- [ ] `docs/docker/TROUBLESHOOTING.md` - Common issues
- [ ] `examples/docker/` - Example configurations

**Tasks**:
1. Write comprehensive guides
   - Installation instructions
   - Configuration options
   - Use case examples
   - Best practices

2. Create example configurations
   - Different base images
   - Various volume mount scenarios
   - Multi-project setups
   - CI/CD integration examples

3. Document troubleshooting
   - Common errors
   - Debugging techniques
   - Performance tuning
   - Security considerations

**Success Criteria**:
- Documentation complete and accurate
- Examples tested and working
- Common questions answered
- Clear troubleshooting steps

### Phase 5: CI/CD & Publishing (Week 3)

**Deliverables**:
- [ ] GitHub Actions workflow for image builds
- [ ] Multi-platform build support
- [ ] Docker Hub publishing
- [ ] Automated testing in containers

**Tasks**:
1. Create GitHub Actions workflow
   - Build on push to main
   - Tag-based releases
   - Multi-arch builds (amd64, arm64)
   - Security scanning

2. Set up Docker Hub
   - Repository creation
   - Automated pushes
   - README sync
   - Tag management

3. Add container tests
   - Integration tests in containers
   - Performance benchmarks
   - Security scans
   - Smoke tests

**Success Criteria**:
- Automated builds working
- Multi-platform images published
- Tests pass in CI
- Images properly tagged

### Phase 6: Advanced Features (Week 4)

**Deliverables**:
- [ ] Health check endpoints
- [ ] Metrics collection
- [ ] Resource limits documentation
- [ ] Production hardening

**Tasks**:
1. Add health checks
   - Liveness check
   - Readiness check
   - Startup check

2. Implement monitoring
   - Prometheus metrics (optional)
   - Resource usage tracking
   - Performance metrics

3. Production hardening
   - Resource limits (CPU, memory)
   - Security scanning results
   - Compliance documentation
   - Best practices guide

**Success Criteria**:
- Health checks functional
- Resource limits documented
- Security audit passed
- Production-ready status

## Technical Specifications

### Dockerfile Structure

```dockerfile
# Stage 1: Builder
FROM python:3.10-slim AS builder
# Install build dependencies
# Copy and install Python packages
# Compile native extensions

# Stage 2: Runtime
FROM python:3.10-slim
# Copy from builder
# Create non-root user
# Set up directories
# Configure entrypoint
```

### Directory Structure in Container

```
/app/
├── mcp_server_tree_sitter/  # Application code
├── entrypoint.sh            # Startup script
└── README.md                # Basic info

/workspace/                   # Mounted source code (read-only)
/config/                      # Mounted config (read-only)
/cache/                       # Parse tree cache (read-write)
/tmp/                        # Temporary files
```

### User & Permissions

```
User: mcp (UID 1000, GID 1000)
Home: /home/mcp
Working Directory: /app
Read Access: /app, /workspace, /config
Write Access: /cache, /tmp, /home/mcp
```

### Resource Recommendations

**Minimum**:
- CPU: 0.5 cores
- Memory: 256MB
- Disk: 500MB

**Recommended**:
- CPU: 1-2 cores
- Memory: 512MB - 1GB
- Disk: 1GB

**Large Projects**:
- CPU: 2-4 cores
- Memory: 2GB - 4GB
- Disk: 2GB

### Network Requirements

**None** - Server uses stdio, no network ports required.

Optional:
- Metrics endpoint (if implemented): Port 9090
- Health check endpoint (if implemented): Port 8080

## Security Considerations

### Container Security

1. **Non-root User**: Run as UID 1000
2. **Read-only Root**: `--read-only` flag with tmpfs
3. **No Capabilities**: Drop all capabilities
4. **Resource Limits**: CPU and memory constraints
5. **No Network**: `--network none` if not needed

### Security Scanning

Tools to integrate:
- Trivy: Vulnerability scanning
- Hadolint: Dockerfile linting
- Docker Bench: Runtime security

### Secrets Management

**Never include**:
- API keys
- Credentials
- Private keys
- Sensitive configuration

**Use instead**:
- Environment variables
- Docker secrets
- External secret managers

## Testing Strategy

### Test Levels

1. **Build Tests**: Dockerfile builds successfully
2. **Unit Tests**: Tests pass inside container
3. **Integration Tests**: MCP protocol communication works
4. **Performance Tests**: Acceptable latency and throughput
5. **Security Tests**: No vulnerabilities, proper isolation

### Test Commands

```bash
# Build test
docker build -t mcp-server-tree-sitter:test .

# Unit tests
docker run --rm mcp-server-tree-sitter:test pytest

# Integration test
./scripts/test-docker-integration.sh

# Security scan
trivy image mcp-server-tree-sitter:latest

# Performance benchmark
./scripts/benchmark-docker.sh
```

## Rollout Plan

### Development Environment (Immediate)
- Build and test locally
- Iterate on Dockerfile
- Validate functionality

### Internal Testing (Week 2)
- Share with team
- Gather feedback
- Fix issues

### Beta Release (Week 3)
- Limited public release
- Documentation review
- Community feedback

### General Availability (Week 4)
- Public Docker Hub images
- Full documentation
- Announcement

## Success Metrics

### Performance
- [ ] Container startup time < 3 seconds
- [ ] First analysis latency < 2 seconds
- [ ] Memory usage < 500MB (typical)
- [ ] Image size < 400MB

### Reliability
- [ ] All tests pass in container
- [ ] No crashes during 24h test
- [ ] Error handling robust
- [ ] Resource leaks eliminated

### Usability
- [ ] Setup time < 5 minutes
- [ ] Documentation clear
- [ ] Examples work out-of-box
- [ ] Troubleshooting effective

### Security
- [ ] No high/critical vulnerabilities
- [ ] Non-root user
- [ ] Minimal attack surface
- [ ] Security best practices followed

## Open Questions

1. **Alpine Linux**: Should we provide an Alpine variant?
   - Pros: Smaller size
   - Cons: Compatibility concerns

2. **Metrics**: Should we add a metrics endpoint?
   - Pros: Better monitoring
   - Cons: Additional complexity

3. **Health Checks**: HTTP endpoint or exec-based?
   - Stdio makes HTTP endpoint optional

4. **Multi-container**: Any benefit to splitting components?
   - Current: Single container
   - Alternative: Sidecar pattern

5. **Registry**: Docker Hub vs. GitHub Container Registry?
   - Docker Hub: Better discovery
   - GHCR: Integrated with GitHub

## Dependencies

### External Dependencies
- Docker Engine 20.10+
- docker-compose 2.0+ (optional)
- Claude Desktop (for integration)

### Python Dependencies
See `pyproject.toml` - all dependencies must work in container:
- mcp[cli] >= 0.12.0
- tree-sitter >= 0.20.0
- tree-sitter-language-pack >= 0.6.1
- pyyaml >= 6.0
- pydantic >= 2.0.0

### Build Dependencies
- gcc, g++, make (for tree-sitter native extensions)
- pkg-config
- Python development headers

## Risk Assessment

### High Risk
- **Stdio Communication**: Non-standard Docker usage
  - Mitigation: Thorough testing, clear documentation

- **Volume Mount Performance**: Potential I/O bottlenecks
  - Mitigation: Benchmark, document limitations

### Medium Risk
- **Image Size**: Could exceed target
  - Mitigation: Multi-stage build, optimization

- **Cross-platform**: arm64 compatibility
  - Mitigation: CI builds for both architectures

### Low Risk
- **Documentation**: Learning curve for users
  - Mitigation: Comprehensive guides, examples

## Next Steps

1. **Review Plan**: Team review and approval
2. **Create Branch**: `feature/docker-implementation`
3. **Phase 1 Start**: Begin Dockerfile implementation
4. **Iterative Development**: Test and refine each phase
5. **Documentation**: Parallel documentation effort

## References

- MCP Specification: https://modelcontextprotocol.io/
- Docker Best Practices: https://docs.docker.com/develop/dev-best-practices/
- Python Docker Guide: https://docs.docker.com/language/python/
- Tree-sitter Documentation: https://tree-sitter.github.io/tree-sitter/

## Approval

- [ ] Technical Lead Review
- [ ] Security Review
- [ ] Documentation Review
- [ ] Ready to Implement
