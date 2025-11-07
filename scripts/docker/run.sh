#!/bin/bash
# Run script for MCP Tree-sitter Server Docker container
# Usage: ./run.sh [PROJECT_PATH] [OPTIONS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_PATH="${1:-.}"
CONFIG_PATH=""
IMAGE_TAG="latest"
CONTAINER_NAME="mcp-tree-sitter"
LOG_LEVEL="INFO"
CACHE_ENABLED="true"
CACHE_MAX_SIZE_MB="100"
INTERACTIVE="-i"
REMOVE="--rm"
DETACH=""
DEBUG=""

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

# Function to show usage
usage() {
    cat << EOF
Run script for MCP Tree-sitter Server Docker container

USAGE:
    $0 [PROJECT_PATH] [OPTIONS]

ARGUMENTS:
    PROJECT_PATH    Path to project to analyze (default: current directory)

OPTIONS:
    -c, --config PATH       Path to config.yaml file
    -t, --tag TAG          Image tag to use (default: latest)
    -n, --name NAME        Container name (default: mcp-tree-sitter)
    -l, --log-level LEVEL  Log level: DEBUG, INFO, WARNING, ERROR (default: INFO)
    --cache-size SIZE      Cache size in MB (default: 100)
    --no-cache             Disable caching
    -d, --detach           Run in background
    --no-rm                Don't remove container on exit
    --debug                Enable debug mode
    -h, --help             Show this help message

EXAMPLES:
    # Run with current directory
    $0

    # Run with specific project
    $0 /path/to/project

    # Run with custom config
    $0 /path/to/project -c /path/to/config.yaml

    # Run with debug logging
    $0 . --debug

    # Run in background
    $0 /path/to/project -d

    # Run with larger cache
    $0 . --cache-size 500

EOF
    exit 0
}

# Parse arguments
shift  # Skip PROJECT_PATH which we already captured

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_PATH="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -l|--log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --cache-size)
            CACHE_MAX_SIZE_MB="$2"
            shift 2
            ;;
        --no-cache)
            CACHE_ENABLED="false"
            shift
            ;;
        -d|--detach)
            DETACH="-d"
            shift
            ;;
        --no-rm)
            REMOVE=""
            shift
            ;;
        --debug)
            DEBUG="true"
            LOG_LEVEL="DEBUG"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Main execution
main() {
    log_info "MCP Tree-sitter Server - Docker Run Script"
    log_info "==========================================="

    # Validate project path
    if [ ! -d "$PROJECT_PATH" ]; then
        log_error "Project path does not exist: $PROJECT_PATH"
        exit 1
    fi

    # Convert to absolute path
    PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
    log_info "Project path: $PROJECT_PATH"

    # Check if image exists
    IMAGE_NAME="mcp-server-tree-sitter:${IMAGE_TAG}"
    if ! docker images "$IMAGE_NAME" --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
        log_warn "Image not found: $IMAGE_NAME"
        log_info "Building image..."

        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        "$SCRIPT_DIR/build.sh" production -t "$IMAGE_TAG"
    fi

    # Build docker run command
    DOCKER_ARGS=()

    # Interactive and remove flags
    if [ -n "$INTERACTIVE" ]; then
        DOCKER_ARGS+=($INTERACTIVE)
    fi

    if [ -n "$REMOVE" ]; then
        DOCKER_ARGS+=($REMOVE)
    fi

    if [ -n "$DETACH" ]; then
        DOCKER_ARGS+=($DETACH)
    fi

    # Container name
    DOCKER_ARGS+=(--name "$CONTAINER_NAME")

    # Volume mounts
    DOCKER_ARGS+=(-v "$PROJECT_PATH:/workspace:ro")
    DOCKER_ARGS+=(-v "mcp-cache:/cache")

    # Config file if provided
    if [ -n "$CONFIG_PATH" ]; then
        if [ ! -f "$CONFIG_PATH" ]; then
            log_error "Config file does not exist: $CONFIG_PATH"
            exit 1
        fi

        CONFIG_PATH="$(cd "$(dirname "$CONFIG_PATH")" && pwd)/$(basename "$CONFIG_PATH")"
        log_info "Config file: $CONFIG_PATH"

        DOCKER_ARGS+=(-v "$CONFIG_PATH:/config/config.yaml:ro")
        DOCKER_ARGS+=(-e "MCP_TS_CONFIG_PATH=/config/config.yaml")
    fi

    # Environment variables
    DOCKER_ARGS+=(-e "MCP_TS_LOG_LEVEL=$LOG_LEVEL")
    DOCKER_ARGS+=(-e "MCP_TS_CACHE_ENABLED=$CACHE_ENABLED")
    DOCKER_ARGS+=(-e "MCP_TS_CACHE_MAX_SIZE_MB=$CACHE_MAX_SIZE_MB")

    # Debug mode
    if [ -n "$DEBUG" ]; then
        log_info "Debug mode enabled"
    fi

    log_info "Configuration:"
    log_info "  - Container name: $CONTAINER_NAME"
    log_info "  - Image: $IMAGE_NAME"
    log_info "  - Log level: $LOG_LEVEL"
    log_info "  - Cache enabled: $CACHE_ENABLED"
    log_info "  - Cache size: ${CACHE_MAX_SIZE_MB}MB"

    if [ -n "$DETACH" ]; then
        log_info "  - Running in background"
    fi

    # Run container
    log_info "Starting container..."

    if [ -n "$DEBUG" ]; then
        # Show the full command in debug mode
        echo ""
        echo "Command: docker run ${DOCKER_ARGS[@]} $IMAGE_NAME ${DEBUG:+--debug}"
        echo ""
    fi

    if docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME" ${DEBUG:+--debug}; then
        if [ -n "$DETACH" ]; then
            log_info "Container started successfully in background"
            log_info "View logs with: docker logs -f $CONTAINER_NAME"
            log_info "Stop with: docker stop $CONTAINER_NAME"
        fi
    else
        EXIT_CODE=$?
        log_error "Container failed with exit code: $EXIT_CODE"

        if [ -z "$DETACH" ]; then
            log_info "Try running with --debug for more information"
        else
            log_info "Check logs with: docker logs $CONTAINER_NAME"
        fi

        exit $EXIT_CODE
    fi
}

# Run main function
main
