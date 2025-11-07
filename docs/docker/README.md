# Docker Documentation

Welcome to the Docker documentation for the MCP Tree-sitter Server. This directory contains comprehensive documentation for containerizing and deploying the server using Docker.

## Quick Navigation

### For Users

**Getting Started:**
- 🚀 [Deployment Guide](DEPLOYMENT.md) - How to run the Docker container
- 📦 [Dependencies](DEPENDENCIES.md) - Required dependencies and system requirements

**Understanding the Project:**
- 📖 [Project Overview](PROJECT_OVERVIEW.md) - High-level architecture and features

### For Developers

**Implementation:**
- 📋 [Implementation Checklist](IMPLEMENTATION_CHECKLIST.md) - Step-by-step implementation guide
- 🗺️ [Docker Plan](DOCKER_PLAN.md) - Detailed implementation plan and architecture decisions

## Document Summaries

### [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
**Purpose**: Comprehensive overview of the MCP Tree-sitter Server project
**Audience**: All users and developers
**Contents**:
- What is MCP and tree-sitter
- Core capabilities and features
- Architecture overview
- Use cases and applications
- Configuration system
- Current status and roadmap

**When to read**: Start here if you're new to the project or want a high-level understanding.

---

### [DOCKER_PLAN.md](DOCKER_PLAN.md)
**Purpose**: Detailed Docker implementation strategy and planning
**Audience**: Developers implementing Docker support
**Contents**:
- Implementation goals and decisions
- Architecture decisions (base images, communication, volumes)
- 6-phase implementation roadmap
- Technical specifications
- Security considerations
- Testing strategy
- Risk assessment

**When to read**: Before starting Docker implementation or when making architectural decisions.

---

### [DEPENDENCIES.md](DEPENDENCIES.md)
**Purpose**: Complete dependency documentation
**Audience**: Developers and system administrators
**Contents**:
- Python version requirements
- Core Python dependencies with rationale
- System dependencies (build and runtime)
- Resource requirements
- Compatibility matrix
- Installation order and timing
- Troubleshooting common dependency issues

**When to read**: When building Docker images, troubleshooting build issues, or optimizing resource usage.

---

### [DEPLOYMENT.md](DEPLOYMENT.md)
**Purpose**: Comprehensive deployment guide
**Audience**: Users deploying the containerized server
**Contents**:
- Quick start guide
- Building from source
- Multiple deployment scenarios:
  - Claude Desktop integration
  - Local development
  - CI/CD integration
  - Production deployment
- Configuration options
- Volume management
- Troubleshooting guide
- Best practices

**When to read**: When deploying or running the Docker container in any environment.

---

### [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)
**Purpose**: Step-by-step implementation checklist
**Audience**: Developers implementing Docker support
**Contents**:
- 8 phases of implementation
- Detailed task lists for each phase
- Testing requirements
- Success criteria
- Sign-off checklist

**When to read**: During active Docker implementation work to track progress.

---

## Docker Files Structure (Planned)

Once implemented, the Docker-related files will be organized as follows:

```
/
├── Dockerfile                          # Production Dockerfile
├── Dockerfile.dev                      # Development Dockerfile
├── .dockerignore                       # Docker build context exclusions
├── docker-compose.yml                  # Production compose file
├── docker-compose.dev.yml              # Development compose file
├── .env.example                        # Environment variables template
│
├── docker/
│   ├── entrypoint.sh                  # Container entrypoint script
│   ├── healthcheck.sh                 # Health check script (optional)
│   └── README.md                      # Docker files reference
│
├── scripts/docker/
│   ├── build.sh                       # Build images
│   ├── run.sh                         # Run container wrapper
│   ├── test.sh                        # Run tests in container
│   ├── clean.sh                       # Cleanup Docker resources
│   ├── install-claude-desktop.sh      # Claude Desktop setup (macOS/Linux)
│   ├── build.ps1                      # Build images (Windows)
│   ├── run.ps1                        # Run container (Windows)
│   └── install-claude-desktop.ps1     # Claude Desktop setup (Windows)
│
├── examples/docker/
│   ├── basic/
│   │   ├── docker-compose.yml
│   │   ├── config.yaml
│   │   └── README.md
│   ├── multi-project/
│   │   ├── docker-compose.yml
│   │   └── README.md
│   └── claude-desktop/
│       ├── claude_desktop_config.json
│       └── README.md
│
└── docs/docker/
    ├── README.md                       # This file
    ├── PROJECT_OVERVIEW.md
    ├── DOCKER_PLAN.md
    ├── DEPENDENCIES.md
    ├── DEPLOYMENT.md
    └── IMPLEMENTATION_CHECKLIST.md
```

## Quick Reference

### Building the Image
```bash
docker build -t mcp-server-tree-sitter:latest .
```

### Running the Container
```bash
docker run -i --rm \
  -v /path/to/project:/workspace:ro \
  -v mcp-cache:/cache \
  mcp-server-tree-sitter:latest
```

### Using with docker-compose
```bash
docker-compose up
```

### Claude Desktop Configuration
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

## Common Tasks

### For First-Time Users

1. Read [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) to understand the project
2. Follow [DEPLOYMENT.md](DEPLOYMENT.md) Quick Start section
3. Configure Claude Desktop using examples in DEPLOYMENT.md
4. Refer to Troubleshooting section if issues arise

### For Developers Implementing Docker

1. Review [DOCKER_PLAN.md](DOCKER_PLAN.md) for architecture decisions
2. Check [DEPENDENCIES.md](DEPENDENCIES.md) for build requirements
3. Follow [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) step-by-step
4. Test using guidelines in each phase of the checklist
5. Update documentation as implementation progresses

### For DevOps/SRE

1. Review [DEPENDENCIES.md](DEPENDENCIES.md) for resource requirements
2. Study [DEPLOYMENT.md](DEPLOYMENT.md) Production Deployment section
3. Implement security hardening from DEPLOYMENT.md
4. Set up monitoring and health checks
5. Configure CI/CD using examples in DEPLOYMENT.md

## Implementation Status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | 📝 Planned | Basic Dockerfile |
| Phase 2 | 📝 Planned | docker-compose Setup |
| Phase 3 | 📝 Planned | Helper Scripts & Automation |
| Phase 4 | 📝 Planned | CI/CD Integration |
| Phase 5 | ✅ Complete | Documentation |
| Phase 6 | 📝 Planned | Testing & Validation |
| Phase 7 | 📝 Planned | Release Preparation |
| Phase 8 | 📝 Planned | Post-Release |

Status Legend:
- ✅ Complete
- 🚧 In Progress
- 📝 Planned
- ❌ Blocked

## Key Design Decisions

### Why stdio instead of HTTP?
The MCP protocol is designed for desktop integration using stdin/stdout. This simplifies deployment and reduces attack surface by eliminating network requirements.

### Why Multi-Stage Build?
Reduces final image size by ~200MB by removing build tools and intermediate artifacts. Critical for distribution and fast pulls.

### Why Non-Root User?
Security best practice. The container runs as user `mcp` (UID 1000) with minimal privileges.

### Why Read-Only Source Mounts?
The server only reads source code, never modifies it. Read-only mounts prevent accidental changes and improve security.

### Why Named Volumes for Cache?
Named volumes are faster than bind mounts and properly handled by Docker. Critical for parse tree cache performance.

## Frequently Asked Questions

**Q: Can I use this with Docker Desktop?**
A: Yes, Docker Desktop on macOS, Windows (WSL2), and Linux all work.

**Q: What about Podman?**
A: Podman should work as a drop-in Docker replacement. Replace `docker` with `podman` in commands.

**Q: Do I need docker-compose?**
A: No, it's optional. You can use `docker run` directly. Compose simplifies complex setups.

**Q: Can I run multiple instances?**
A: Yes, each Claude Desktop MCP server config can run a separate container instance.

**Q: What about Windows without WSL2?**
A: Windows containers are not currently planned. WSL2 is recommended.

**Q: How do I update the image?**
A: Pull the latest image with `docker pull mcp-server-tree-sitter:latest` and restart.

**Q: Where are logs stored?**
A: Logs go to stderr and are available via `docker logs <container-name>`.

**Q: Can I customize the base image?**
A: Yes, modify the Dockerfile. See DOCKER_PLAN.md for alternative base images.

## Getting Help

### Documentation Issues
- Found an error in docs? Open an issue on GitHub
- Want to improve docs? Submit a pull request
- Have a question? Start a GitHub Discussion

### Docker Implementation Issues
- Check [DEPLOYMENT.md](DEPLOYMENT.md) Troubleshooting section first
- Review [DEPENDENCIES.md](DEPENDENCIES.md) for compatibility issues
- Search existing GitHub issues
- Open a new issue with details about your environment

### General Support
- GitHub Issues: https://github.com/wrale/mcp-server-tree-sitter/issues
- Discussions: https://github.com/wrale/mcp-server-tree-sitter/discussions
- Main README: [../../README.md](../../README.md)

## Contributing

Contributions to Docker implementation and documentation are welcome!

**Areas needing help**:
- Testing on different platforms
- Performance optimization
- Additional examples
- Documentation improvements
- Troubleshooting guides

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

Same as the main project: MIT License

See [LICENSE](../../LICENSE) for details.

---

**Last Updated**: 2025-11-07
**Documentation Version**: 1.0
**Status**: Pre-implementation (Documentation Phase)
