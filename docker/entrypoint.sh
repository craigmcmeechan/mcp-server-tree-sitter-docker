#!/bin/bash
# Entrypoint script for MCP Tree-sitter Server Docker container
# This script sets up the environment and starts the server

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
log_info "Starting MCP Tree-sitter Server..."

# Check if workspace directory exists and is accessible
if [ ! -d "/workspace" ]; then
    log_warn "Workspace directory /workspace does not exist"
fi

# Check if workspace has any files
if [ -d "/workspace" ] && [ -z "$(ls -A /workspace 2>/dev/null)" ]; then
    log_warn "Workspace directory /workspace is empty"
    log_warn "Mount your project with: -v /path/to/project:/workspace:ro"
fi

# Set up cache directory permissions
if [ -d "/cache" ]; then
    if [ ! -w "/cache" ]; then
        log_error "Cache directory /cache is not writable"
        log_info "Try mounting with: -v mcp-cache:/cache"
    else
        log_info "Cache directory ready at /cache"
    fi
else
    log_warn "Cache directory /cache does not exist"
fi

# Check for config file if MCP_TS_CONFIG_PATH is set
if [ -n "$MCP_TS_CONFIG_PATH" ]; then
    if [ ! -f "$MCP_TS_CONFIG_PATH" ]; then
        log_error "Config file specified but not found: $MCP_TS_CONFIG_PATH"
        log_info "Mount config with: -v /path/to/config.yaml:/config/config.yaml:ro"
        exit 1
    else
        log_info "Using config file: $MCP_TS_CONFIG_PATH"
    fi
fi

# Display environment info
log_info "Environment:"
log_info "  - User: $(whoami) (UID: $(id -u), GID: $(id -g))"
log_info "  - Working directory: $(pwd)"
log_info "  - Python version: $(python --version 2>&1)"
log_info "  - Log level: ${MCP_TS_LOG_LEVEL:-INFO}"

# Check if tree-sitter can be imported
if ! python -c "import tree_sitter" 2>/dev/null; then
    log_error "Failed to import tree-sitter module"
    exit 1
fi

# Check if language pack can be imported
if ! python -c "from tree_sitter_language_pack import get_language; get_language('python')" 2>/dev/null; then
    log_error "Failed to import tree-sitter-language-pack"
    exit 1
fi

# Check if MCP server can be imported
if ! python -c "import mcp_server_tree_sitter" 2>/dev/null; then
    log_error "Failed to import mcp_server_tree_sitter"
    exit 1
fi

log_info "All dependencies loaded successfully"

# Handle signals gracefully
trap 'log_info "Received SIGTERM, shutting down..."; exit 0' SIGTERM
trap 'log_info "Received SIGINT, shutting down..."; exit 0' SIGINT

# If no arguments provided, use default command
if [ $# -eq 0 ]; then
    log_info "Starting MCP server with default command..."
    exec python -m mcp_server_tree_sitter.server
else
    # Execute provided command
    log_info "Executing command: $*"
    exec "$@"
fi
