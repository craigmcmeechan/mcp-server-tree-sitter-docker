#!/bin/bash
# Build script for MCP Tree-sitter Server Docker images
# Usage: ./build.sh [production|dev|all] [OPTIONS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
BUILD_TARGET="production"
IMAGE_TAG="latest"
CACHE_FROM=""
NO_CACHE=""
PLATFORM=""
PUSH=""

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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Build script for MCP Tree-sitter Server Docker images

USAGE:
    $0 [TARGET] [OPTIONS]

TARGETS:
    production    Build production image (default)
    dev           Build development image
    all           Build both production and development images

OPTIONS:
    -t, --tag TAG        Image tag (default: latest)
    -p, --platform PLAT  Build for specific platform(s)
                         Example: linux/amd64,linux/arm64
    --no-cache          Build without using cache
    --cache-from IMAGE  Use image as cache source
    --push              Push image after building (requires login)
    -h, --help          Show this help message

EXAMPLES:
    # Build production image
    $0 production

    # Build development image with custom tag
    $0 dev -t v0.5.1

    # Build for multiple platforms
    $0 production -p linux/amd64,linux/arm64

    # Build and push
    $0 production -t latest --push

    # Build without cache
    $0 all --no-cache

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        production|prod)
            BUILD_TARGET="production"
            shift
            ;;
        dev|development)
            BUILD_TARGET="dev"
            shift
            ;;
        all)
            BUILD_TARGET="all"
            shift
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --cache-from)
            CACHE_FROM="--cache-from $2"
            shift 2
            ;;
        --push)
            PUSH="--push"
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

# Build production image
build_production() {
    log_step "Building production image..."

    local BUILD_CMD="docker build"
    local IMAGE_NAME="mcp-server-tree-sitter:${IMAGE_TAG}"

    if [ -n "$PLATFORM" ]; then
        log_info "Building for platform(s): $PLATFORM"
        BUILD_CMD="docker buildx build --platform $PLATFORM"
    fi

    if [ -n "$PUSH" ]; then
        log_info "Will push image after build"
    fi

    cd "$PROJECT_ROOT"

    $BUILD_CMD \
        -f Dockerfile \
        -t "$IMAGE_NAME" \
        $NO_CACHE \
        $CACHE_FROM \
        $PUSH \
        .

    if [ $? -eq 0 ]; then
        log_info "Production image built successfully: $IMAGE_NAME"

        # Show image size
        if [ -z "$PUSH" ]; then
            SIZE=$(docker images "$IMAGE_NAME" --format "{{.Size}}")
            log_info "Image size: $SIZE"
        fi

        return 0
    else
        log_error "Failed to build production image"
        return 1
    fi
}

# Build development image
build_dev() {
    log_step "Building development image..."

    local BUILD_CMD="docker build"
    local IMAGE_NAME="mcp-server-tree-sitter:dev"

    if [ -n "$IMAGE_TAG" ] && [ "$IMAGE_TAG" != "latest" ]; then
        IMAGE_NAME="mcp-server-tree-sitter:dev-${IMAGE_TAG}"
    fi

    if [ -n "$PLATFORM" ]; then
        log_info "Building for platform(s): $PLATFORM"
        BUILD_CMD="docker buildx build --platform $PLATFORM"
    fi

    cd "$PROJECT_ROOT"

    $BUILD_CMD \
        -f Dockerfile.dev \
        -t "$IMAGE_NAME" \
        $NO_CACHE \
        $CACHE_FROM \
        $PUSH \
        .

    if [ $? -eq 0 ]; then
        log_info "Development image built successfully: $IMAGE_NAME"

        # Show image size
        if [ -z "$PUSH" ]; then
            SIZE=$(docker images "$IMAGE_NAME" --format "{{.Size}}")
            log_info "Image size: $SIZE"
        fi

        return 0
    else
        log_error "Failed to build development image"
        return 1
    fi
}

# Main execution
main() {
    log_info "MCP Tree-sitter Server - Docker Build Script"
    log_info "=============================================="
    log_info "Project root: $PROJECT_ROOT"
    log_info "Build target: $BUILD_TARGET"
    log_info "Image tag: $IMAGE_TAG"

    if [ -n "$PLATFORM" ]; then
        # Check if buildx is available
        if ! docker buildx version &> /dev/null; then
            log_error "docker buildx is required for multi-platform builds"
            log_info "Install with: docker buildx install"
            exit 1
        fi

        # Create builder if needed
        if ! docker buildx ls | grep -q "multiplatform"; then
            log_info "Creating multi-platform builder..."
            docker buildx create --name multiplatform --use
        else
            docker buildx use multiplatform
        fi
    fi

    # Check if Dockerfile exists
    if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
        log_error "Dockerfile not found in $PROJECT_ROOT"
        exit 1
    fi

    # Build based on target
    case $BUILD_TARGET in
        production)
            build_production
            exit $?
            ;;
        dev)
            build_dev
            exit $?
            ;;
        all)
            log_info "Building all images..."
            build_production
            PROD_RESULT=$?

            build_dev
            DEV_RESULT=$?

            if [ $PROD_RESULT -eq 0 ] && [ $DEV_RESULT -eq 0 ]; then
                log_info "All images built successfully!"
                exit 0
            else
                log_error "Some builds failed"
                exit 1
            fi
            ;;
    esac
}

# Run main function
main
