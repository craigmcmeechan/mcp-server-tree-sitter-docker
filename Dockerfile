# Multi-stage Dockerfile for MCP Tree-sitter Server
# This build creates a minimal production image with all dependencies

# Stage 1: Builder
# Install build dependencies and compile Python packages
FROM python:3.10-slim AS builder

LABEL maintainer="Wrale LTD <contact@wrale.com>"
LABEL description="MCP Tree-sitter Server - Build Stage"

# Set environment variables for build
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    pkg-config \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /build

# Copy dependency files first for better layer caching
COPY pyproject.toml ./

# Upgrade pip and install build tools
RUN pip install --upgrade pip setuptools wheel

# Install Python dependencies
# This will compile tree-sitter and tree-sitter-language-pack
RUN pip install --prefix=/install .

# Stage 2: Runtime
# Create minimal runtime image
FROM python:3.10-slim AS runtime

LABEL maintainer="Wrale LTD <contact@wrale.com>"
LABEL description="MCP Tree-sitter Server - Code analysis via tree-sitter"
LABEL org.opencontainers.image.title="mcp-server-tree-sitter"
LABEL org.opencontainers.image.description="Model Context Protocol server for tree-sitter code analysis"
LABEL org.opencontainers.image.url="https://github.com/wrale/mcp-server-tree-sitter"
LABEL org.opencontainers.image.source="https://github.com/wrale/mcp-server-tree-sitter"
LABEL org.opencontainers.image.licenses="MIT"

# Set environment variables for runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    MCP_TS_LOG_LEVEL=INFO

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgcc-s1 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r mcp --gid=1000 && \
    useradd -r -g mcp --uid=1000 --home-dir=/home/mcp --shell=/bin/bash mcp && \
    mkdir -p /home/mcp && \
    chown -R mcp:mcp /home/mcp

# Create application directories
RUN mkdir -p /app /workspace /cache /config && \
    chown -R mcp:mcp /app /cache /home/mcp

# Copy installed packages from builder
COPY --from=builder --chown=mcp:mcp /install /usr/local

# Copy application code
WORKDIR /app
COPY --chown=mcp:mcp src/ ./src/
COPY --chown=mcp:mcp pyproject.toml ./
COPY --chown=mcp:mcp README.md ./

# Install the package in editable mode (uses already installed dependencies)
RUN pip install -e .

# Copy entrypoint script
COPY --chown=mcp:mcp docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER mcp

# Set working directory to workspace
WORKDIR /workspace

# Volume mount points
VOLUME ["/workspace", "/cache", "/config"]

# Expose no ports (uses stdio communication)

# Health check (optional - checks if Python can import the module)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import mcp_server_tree_sitter; print('OK')" || exit 1

# Use entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# Default command (can be overridden)
CMD ["python", "-m", "mcp_server_tree_sitter.server"]
