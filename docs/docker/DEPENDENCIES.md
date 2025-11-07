# Dependencies and Runtime Requirements

## Overview

This document details all dependencies required to run the MCP Tree-sitter Server, both in native and containerized environments. Understanding these dependencies is critical for successful Docker implementation.

## Python Version

**Required**: Python 3.10 or higher

**Reasoning**:
- Modern type hints support (PEP 604, PEP 612)
- Pattern matching (PEP 634)
- Better performance
- Active security support

**Tested Versions**:
- Python 3.10 ✅
- Python 3.11 ✅
- Python 3.12 ✅

**Not Supported**:
- Python 3.9 and below

## Core Python Dependencies

### MCP Framework
```toml
mcp[cli] >= 0.12.0
```

**Purpose**: Model Context Protocol implementation
**Components**:
- `mcp.server.fastmcp.FastMCP` - Server framework
- `mcp` CLI tool for development and testing
- Protocol message handling
- Stdio transport

**Why This Version**:
- FastMCP API stability
- CLI integration support
- Bug fixes in 0.12.x series

**Docker Considerations**:
- Pure Python package
- No build dependencies
- Minimal size impact

### Tree-sitter Core
```toml
tree-sitter >= 0.20.0
```

**Purpose**: Core tree-sitter Python bindings
**Components**:
- Parser wrapper
- Tree and node abstractions
- Query language support
- Native C library bindings

**Why This Version**:
- API stability
- Performance improvements
- Bug fixes for cursor operations

**Build Requirements**:
- C compiler (gcc/clang)
- Python development headers
- Make utility

**Docker Considerations**:
- Contains native extensions
- Requires build stage in Dockerfile
- Size: ~5MB compiled

### Tree-sitter Language Pack
```toml
tree-sitter-language-pack >= 0.6.1
```

**Purpose**: Pre-compiled language parsers
**Includes 40+ Languages**:
- Python, JavaScript, TypeScript
- Go, Rust, C, C++, C#
- Java, Kotlin, Swift, Objective-C
- Ruby, PHP, Scala, Clojure
- Bash, Shell, Fish
- HTML, CSS, SCSS
- JSON, YAML, TOML, XML
- And many more...

**Why This Version**:
- Latest parser updates
- Bug fixes
- Additional languages

**Build Requirements**:
- C++ compiler (g++)
- Python development headers
- Make utility
- pkg-config

**Docker Considerations**:
- Large package (100+ MB)
- Contains many native libraries
- Critical for multi-language support
- Takes longest to build/install

### Configuration Management
```toml
pyyaml >= 6.0
types-pyyaml >= 6.0.12.20241230
```

**Purpose**: YAML configuration file parsing
**Components**:
- YAML parser
- Safe loading
- Type stubs for mypy

**Why These Versions**:
- Security fixes in 6.0+
- C library performance benefits
- Type hints compatibility

**Docker Considerations**:
- May require libyaml-dev for C extension
- Falls back to pure Python if unavailable
- Minimal size impact

### Data Validation
```toml
pydantic >= 2.0.0
```

**Purpose**: Configuration and data validation
**Components**:
- Config model validation
- Type coercion
- JSON schema generation
- Error reporting

**Why This Version**:
- Pydantic v2 performance improvements
- Better error messages
- Improved type support

**Docker Considerations**:
- Pure Python (base)
- Optional Rust extensions for performance
- ~5MB with extensions

## Development Dependencies

### Testing Framework
```toml
pytest >= 7.0.0
pytest-cov >= 4.0.0
```

**Purpose**: Unit and integration testing
**Not Required**: For production Docker images

### Code Quality
```toml
ruff >= 0.0.262
mypy >= 1.2.0
```

**Purpose**: Linting and type checking
**Not Required**: For production Docker images

## System Dependencies

### Compilation Tools (Build Time Only)

**For Debian/Ubuntu (slim base)**:
```bash
apt-get install -y \
    gcc \
    g++ \
    make \
    pkg-config \
    python3-dev
```

**Purpose**:
- gcc: C compiler for tree-sitter
- g++: C++ compiler for language parsers
- make: Build automation
- pkg-config: Library configuration
- python3-dev: Python headers for native extensions

**Size Impact**: ~200MB
**Retention**: Can be removed after build (multi-stage)

**For Alpine Linux** (if used):
```bash
apk add --no-cache \
    gcc \
    g++ \
    make \
    python3-dev \
    musl-dev \
    linux-headers
```

### Runtime Libraries

**For Debian/Ubuntu**:
```bash
apt-get install -y \
    libgcc-s1 \
    libstdc++6
```

**Purpose**: Runtime support for compiled extensions
**Size Impact**: ~20MB (often pre-installed)
**Retention**: Required in final image

## Optional Dependencies

### Git (For Repository Analysis)
```bash
apt-get install -y git
```

**Purpose**: Clone and analyze Git repositories
**Size Impact**: ~20MB
**Required**: Only if analyzing remote repositories

### Additional Languages (Future)

If users need to add custom tree-sitter languages:
```toml
tree-sitter-<language> >= version
```

**Examples**:
- tree-sitter-python
- tree-sitter-javascript
- etc.

**Note**: Not needed when using tree-sitter-language-pack

## Resource Requirements

### Minimum Requirements

**For Container**:
- CPU: 0.5 cores (500m)
- Memory: 256MB
- Disk: 500MB
- Swap: Not required

**Use Case**: Small projects (<1000 files)

### Recommended Requirements

**For Container**:
- CPU: 1-2 cores (1000m-2000m)
- Memory: 512MB - 1GB
- Disk: 1GB
- Swap: Not required

**Use Case**: Medium projects (1000-10000 files)

### Large Project Requirements

**For Container**:
- CPU: 2-4 cores (2000m-4000m)
- Memory: 2GB - 4GB
- Disk: 2GB
- Swap: Optional

**Use Case**: Large projects (>10000 files), monorepos

### Resource Scaling Factors

**Memory Usage Factors**:
1. **Cache Size**: Configurable (default 100MB)
2. **Number of Open Files**: ~5-10MB per large file
3. **Parse Tree Size**: Varies by language/complexity
4. **Base Overhead**: ~100-150MB

**CPU Usage Factors**:
1. **Initial Parsing**: High CPU during first analysis
2. **Subsequent Operations**: Low CPU with cache hits
3. **Query Complexity**: Complex tree-sitter queries use more CPU
4. **Concurrent Operations**: Not designed for high concurrency

## Network Requirements

**None** - The server does not require network access.

**Reasoning**:
- Uses stdio for communication
- No external API calls
- No telemetry
- All operations local

**Docker Implications**:
- Can use `--network none` for extra security
- No port exposure needed
- Simplified networking

## File System Requirements

### Read Access Required
```
/workspace/       # Source code to analyze (mounted)
/config/          # Optional configuration (mounted)
/app/             # Application code (in container)
```

### Write Access Required
```
/cache/           # Parse tree cache (optional mount)
/tmp/             # Temporary files
/home/mcp/        # User home directory
```

### Excluded Directories (Configurable)
```
.git/
node_modules/
__pycache__/
.venv/
venv/
dist/
build/
```

## Dependency Installation Order

### In Dockerfile

```dockerfile
# 1. System packages (build tools)
RUN apt-get update && apt-get install -y \
    gcc g++ make pkg-config python3-dev

# 2. Upgrade pip and install build tools
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 3. Install Python dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir -e .

# 4. Clean up build dependencies (multi-stage)
# (Move to runtime stage without build tools)
```

### Build Time Estimates

**On Modern Hardware** (4 cores, 8GB RAM):
- System packages: ~30 seconds
- Python core packages: ~10 seconds
- tree-sitter: ~20 seconds
- tree-sitter-language-pack: ~2-3 minutes
- Other packages: ~10 seconds

**Total**: ~3-4 minutes

**On CI/CD** (2 cores, 4GB RAM):
- Total: ~5-8 minutes

**With Docker Layer Caching**:
- Subsequent builds: ~10-30 seconds (if no dependency changes)

## Compatibility Matrix

### Operating Systems

| OS | Native Support | Docker Support | Notes |
|----|---------------|----------------|-------|
| Linux (x86_64) | ✅ | ✅ | Primary platform |
| Linux (arm64) | ✅ | ✅ | Apple Silicon, RPi |
| macOS (x86_64) | ✅ | ✅ | Intel Macs |
| macOS (arm64) | ✅ | ✅ | Apple Silicon |
| Windows | ✅ | ✅ | WSL2 recommended |

### Docker Platforms

| Platform | Support | Image Available | Notes |
|----------|---------|----------------|-------|
| linux/amd64 | ✅ | Planned | x86_64 systems |
| linux/arm64 | ✅ | Planned | ARM systems |
| linux/arm/v7 | ⚠️ | Not planned | Limited resources |
| windows/amd64 | ⚠️ | Not planned | Use WSL2 instead |

### Python Implementations

| Implementation | Support | Notes |
|---------------|---------|-------|
| CPython | ✅ | Primary implementation |
| PyPy | ❌ | Native extensions incompatible |
| Jython | ❌ | Python 2 only |
| IronPython | ❌ | Windows-specific |

## Dependency Security

### Known Vulnerabilities

**Current Status**: None known in production dependencies

**Monitoring**:
- Dependabot enabled
- Regular security audits
- CVE monitoring

### Update Policy

**Major Updates**: Manual review required
**Minor Updates**: Automated via Dependabot
**Security Patches**: Immediate update and release

### Pinning Strategy

**Production**:
```toml
package >= minimum.version
```

**Reasoning**: Allow security patches, prevent breaking changes

**Development/Testing**:
```
# uv.lock file pins exact versions
```

**Reasoning**: Reproducible builds

## Troubleshooting Dependencies

### Common Issues

**1. tree-sitter-language-pack fails to build**
```
Error: error: command 'gcc' failed
```

**Solution**:
```bash
apt-get install gcc g++ make python3-dev
```

**2. ImportError: No module named 'tree_sitter'**

**Solution**:
```bash
pip install tree-sitter>=0.20.0
```

**3. Parse tree cache permission denied**

**Solution**:
```bash
# Ensure cache directory writable
chmod 755 /cache
chown mcp:mcp /cache
```

**4. Out of memory during build**

**Solution**:
```bash
# Increase Docker memory limit
docker build --memory=4g ...
```

### Verification Commands

**Check Python version**:
```bash
python --version  # Should be 3.10+
```

**Verify tree-sitter**:
```python
import tree_sitter
print(tree_sitter.__version__)
```

**Verify language pack**:
```python
from tree_sitter_language_pack import get_language
lang = get_language('python')
print(f"Python parser loaded: {lang is not None}")
```

**Test MCP import**:
```python
from mcp.server.fastmcp import FastMCP
print("MCP imported successfully")
```

## Future Dependency Considerations

### Potential Additions

1. **HTTP Server** (if needed)
   - uvicorn or hypercorn
   - For REST API variant

2. **Database** (if persistence needed)
   - SQLite for local storage
   - Redis for distributed cache

3. **Monitoring**
   - Prometheus client
   - OpenTelemetry

4. **Compression**
   - zstandard for cache compression
   - Reduce memory footprint

### Deprecation Watch

- **Python 3.10**: End of life 2026-10
- **Pydantic v1**: Already deprecated
- **tree-sitter 0.20**: Monitor for 1.0 release

## Summary

### Critical Dependencies
1. Python 3.10+
2. tree-sitter >= 0.20.0
3. tree-sitter-language-pack >= 0.6.1
4. mcp[cli] >= 0.12.0

### Build-Time Only
1. gcc, g++, make
2. Python development headers
3. pkg-config

### Runtime Only
1. libgcc-s1, libstdc++6
2. Application code
3. Python runtime

### Optional
1. Git (for repo analysis)
2. Custom configurations
3. Additional languages

### Docker-Specific
1. Multi-stage build to minimize size
2. Non-root user for security
3. Read-only mounts for source code
4. Writable cache volume
