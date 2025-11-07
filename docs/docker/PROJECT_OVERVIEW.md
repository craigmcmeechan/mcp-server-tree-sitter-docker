# MCP Tree-sitter Server - Project Overview

## Executive Summary

The MCP Tree-sitter Server is a Model Context Protocol (MCP) server that provides intelligent code analysis capabilities using tree-sitter. It's designed to give AI assistants like Claude structured access to codebases with context-aware analysis, supporting 12+ programming languages with AST parsing, symbol extraction, and advanced query capabilities.

**Version**: 0.5.1
**License**: MIT
**Language**: Python 3.10+
**Protocol**: Model Context Protocol (MCP)

## What is MCP?

The Model Context Protocol (MCP) is a standardized protocol that enables AI assistants to interact with external tools and data sources. MCP servers expose capabilities through:
- **Resources**: Data and content that can be read
- **Tools**: Functions that can be executed
- **Prompts**: Templates for common operations

## Core Capabilities

### 1. Multi-Language Support
Supports 12+ languages out-of-the-box with tree-sitter-language-pack:
- Python, JavaScript, TypeScript
- Go, Rust, C, C++
- Swift, Java, Kotlin
- Julia, APL
- Plus 15+ additional languages (Bash, C#, Ruby, etc.)

### 2. Project Management
- Register multiple projects simultaneously
- Persistent project state during server lifetime
- Project-scoped analysis operations
- File pattern matching and filtering

### 3. Code Analysis Features

**AST Analysis**:
- Parse source code into Abstract Syntax Trees
- Configurable depth traversal
- Cursor-based efficient tree walking
- Node-level code inspection

**Symbol Extraction**:
- Functions, classes, methods
- Variables and constants
- Import/export statements
- Language-specific constructs

**Search & Query**:
- Text-based search across projects
- Tree-sitter query language support
- Pattern matching with regex
- Cross-file dependency analysis

**Complexity Analysis**:
- Cyclomatic complexity metrics
- Code structure analysis
- Nesting depth calculation
- Line-of-code statistics

### 4. Performance Features
- **Parse tree caching**: Configurable TTL-based cache
- **Lazy loading**: On-demand language parser loading
- **Memory management**: Configurable cache size limits
- **Efficient traversal**: Cursor-based AST navigation

## Architecture Highlights

### Design Patterns
1. **Dependency Injection**: Centralized `DependencyContainer` manages all components
2. **Singleton Pattern**: Core services (registries, caches) use singleton pattern
3. **Bootstrap Pattern**: Critical initialization happens before main application logic
4. **Protocol-First**: Built on FastMCP framework for MCP compliance

### Key Components

```
┌─────────────────────────────────────────────────┐
│           MCP Protocol Layer (stdio)            │
│              FastMCP Framework                  │
└─────────────────────────────────────────────────┘
                       │
┌─────────────────────────────────────────────────┐
│              Server Layer (server.py)           │
│    - Request routing                            │
│    - Tool registration                          │
│    - Capability management                      │
└─────────────────────────────────────────────────┘
                       │
┌─────────────────────────────────────────────────┐
│        Dependency Injection Container           │
│    - Config Manager                             │
│    - Project Registry                           │
│    - Language Registry                          │
│    - Tree Cache                                 │
└─────────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
┌───────▼─────┐ ┌─────▼──────┐ ┌────▼─────┐
│   Tools     │ │ Resources  │ │ Prompts  │
│  (Analysis) │ │ (Projects) │ │(Templates)│
└─────────────┘ └────────────┘ └──────────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
┌─────────────────────────────────────────────────┐
│         Tree-sitter Integration Layer           │
│    - Language parsers                           │
│    - AST generation                             │
│    - Query execution                            │
└─────────────────────────────────────────────────┘
```

### State Management
- **In-Memory State**: Projects and configurations persist during server lifetime
- **No Database**: All state is memory-resident for performance
- **Stateless Tools**: Individual tool calls are stateless
- **Cache Management**: LRU-based cache with configurable eviction

## Communication Protocol

### MCP Protocol (stdio-based)
The server communicates via standard input/output using JSON-RPC style messages:

```
┌─────────────┐         stdio          ┌─────────────┐
│   Claude    │◄─────────────────────►│  MCP Server │
│   Desktop   │   JSON-RPC Messages    │             │
└─────────────┘                        └─────────────┘
```

**Key Characteristics**:
- Synchronous request/response model
- No HTTP/REST endpoints
- Interactive mode required
- Suitable for desktop integration

## Configuration System

### Configuration Hierarchy (Precedence Order)
1. **Environment Variables**: `MCP_TS_*` prefix (highest priority)
2. **CLI Arguments**: `--config`, `--debug`, `--disable-cache`
3. **YAML Config File**: `~/.config/tree-sitter/config.yaml`
4. **Defaults**: Built-in sensible defaults (lowest priority)

### Configuration Categories

**Cache Settings**:
```yaml
cache:
  enabled: true
  max_size_mb: 100
  ttl_seconds: 300
```

**Security Settings**:
```yaml
security:
  max_file_size_mb: 5
  excluded_dirs:
    - .git
    - node_modules
    - __pycache__
```

**Language Settings**:
```yaml
language:
  default_max_depth: 5
  preferred_languages:
    - python
    - javascript
```

## Use Cases

### 1. Claude Desktop Integration
Primary use case - enables Claude to:
- Understand project structure
- Analyze code semantically
- Extract symbols and dependencies
- Answer code-related questions with context

### 2. CI/CD Integration
- Code quality checks
- Complexity analysis
- Style enforcement
- Documentation generation

### 3. Development Tools
- IDE extensions
- Code review automation
- Refactoring assistance
- Technical debt analysis

### 4. Code Intelligence Platforms
- Search and navigation
- Cross-reference generation
- Dependency mapping
- Impact analysis

## Security Considerations

### Built-in Protections
1. **File Size Limits**: Configurable max file size (default 5MB)
2. **Directory Filtering**: Exclude sensitive directories (.git, node_modules)
3. **Extension Filtering**: Optional whitelist of allowed extensions
4. **Path Validation**: Prevents directory traversal attacks
5. **Read-Only Access**: No file modification capabilities

### Recommended Practices
- Run with minimal required permissions
- Use read-only volume mounts in containers
- Restrict network access (not required)
- Monitor resource usage (memory, CPU)
- Regular security updates

## Performance Characteristics

### Resource Usage
- **Memory**: ~100-500MB base + cache (configurable)
- **CPU**: Burst during parsing, idle otherwise
- **Disk**: Minimal (log files only)
- **Network**: None (stdio communication)

### Scaling Considerations
- **Vertical**: Benefits from more RAM for larger caches
- **Parser Loading**: First-use latency per language (~100-500ms)
- **Cache Hit Rate**: >80% typical for repeated analysis
- **Concurrent Projects**: Limited only by memory

## Development & Testing

### Test Coverage
- 70+ test files
- Unit tests for all core components
- Integration tests for MCP protocol
- Diagnostic tests for tree-sitter compatibility
- CI/CD via GitHub Actions

### Quality Tools
- **mypy**: Static type checking
- **ruff**: Linting and formatting
- **pytest**: Test framework with coverage
- **uv**: Fast, reliable package management

## Extensibility

### Adding New Languages
Tree-sitter-language-pack provides 40+ languages automatically. Custom languages require:
1. Tree-sitter grammar for the language
2. Query templates for symbol extraction (optional)
3. Language configuration in registry

### Custom Tools
Add new MCP tools by:
1. Implementing tool function in `src/mcp_server_tree_sitter/tools/`
2. Registering with FastMCP in tool registration
3. Adding tests and documentation

### Plugin System
Currently not implemented, but architecture supports:
- Custom analyzers
- Export formats
- Integration hooks
- Custom prompts

## Project Status

### Current State (v0.5.1)
- ✅ Core MCP protocol implementation
- ✅ Multi-language support via tree-sitter
- ✅ Symbol extraction for 12+ languages
- ✅ Caching and performance optimizations
- ✅ Comprehensive test suite
- ✅ Claude Desktop integration
- ❌ Docker containerization (planned)
- ❌ HTTP/REST API (not planned)
- ❌ Database persistence (not planned)

### Roadmap
See [ROADMAP.md](../../ROADMAP.md) for detailed future plans.

## Getting Started

### Quick Install
```bash
pip install mcp-server-tree-sitter
```

### Claude Desktop Setup
```json
{
  "mcpServers": {
    "tree_sitter": {
      "command": "uvx",
      "args": ["mcp-server-tree-sitter"]
    }
  }
}
```

### Docker Setup (Planned)
See [DOCKER_PLAN.md](./DOCKER_PLAN.md) for containerization strategy.

## Resources

- **Repository**: https://github.com/wrale/mcp-server-tree-sitter
- **Documentation**: `/docs` directory
- **Issue Tracker**: GitHub Issues
- **MCP Specification**: https://modelcontextprotocol.io/

## License

MIT License - see [LICENSE](../../LICENSE) file for details.

## Support & Contributing

- See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines
- Report issues on GitHub
- Discussions welcome in GitHub Discussions
