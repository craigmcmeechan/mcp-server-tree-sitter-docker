#!/bin/bash
# Cleanup script for MCP Tree-sitter Server Docker resources
# Usage: ./clean.sh [OPTIONS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLEAN_CONTAINERS=false
CLEAN_IMAGES=false
CLEAN_VOLUMES=false
CLEAN_ALL=false
FORCE=false
DRY_RUN=false

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

log_clean() {
    echo -e "${BLUE}[CLEAN]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Cleanup script for MCP Tree-sitter Server Docker resources

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -c, --containers       Clean stopped containers
    -i, --images           Clean dangling images
    -v, --volumes          Clean unused volumes (CAUTION: removes cache!)
    -a, --all              Clean everything (containers, images, volumes)
    -f, --force            Don't ask for confirmation
    --dry-run              Show what would be cleaned without doing it
    -h, --help             Show this help message

EXAMPLES:
    # Clean only stopped containers
    $0 -c

    # Clean images and containers
    $0 -c -i

    # Clean everything (with confirmation)
    $0 -a

    # Clean everything without confirmation
    $0 -a -f

    # See what would be cleaned
    $0 -a --dry-run

EOF
    exit 0
}

# Parse arguments
if [ $# -eq 0 ]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--containers)
            CLEAN_CONTAINERS=true
            shift
            ;;
        -i|--images)
            CLEAN_IMAGES=true
            shift
            ;;
        -v|--volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        -a|--all)
            CLEAN_ALL=true
            CLEAN_CONTAINERS=true
            CLEAN_IMAGES=true
            CLEAN_VOLUMES=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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

# Function to confirm action
confirm() {
    if [ "$FORCE" = true ] || [ "$DRY_RUN" = true ]; then
        return 0
    fi

    local prompt="$1"
    read -p "$prompt (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Clean containers
clean_containers() {
    log_clean "Cleaning MCP Tree-sitter containers..."

    local CONTAINERS=$(docker ps -a --filter "name=mcp-tree-sitter" --format "{{.ID}} {{.Names}}" 2>/dev/null || true)

    if [ -z "$CONTAINERS" ]; then
        log_info "No MCP Tree-sitter containers found"
        return 0
    fi

    echo ""
    echo "Found containers:"
    echo "$CONTAINERS"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would remove the above containers"
        return 0
    fi

    if confirm "Remove these containers?"; then
        echo "$CONTAINERS" | while read -r line; do
            local CONTAINER_ID=$(echo "$line" | awk '{print $1}')
            local CONTAINER_NAME=$(echo "$line" | awk '{print $2}')

            log_info "Removing container: $CONTAINER_NAME ($CONTAINER_ID)"
            docker rm -f "$CONTAINER_ID" 2>/dev/null || log_warn "Failed to remove $CONTAINER_NAME"
        done

        log_info "Containers cleaned"
    else
        log_info "Skipped container cleanup"
    fi
}

# Clean images
clean_images() {
    log_clean "Cleaning MCP Tree-sitter images..."

    # Find dangling images
    local DANGLING=$(docker images -f "dangling=true" --format "{{.ID}} {{.Repository}}:{{.Tag}}" 2>/dev/null | grep -v "<none>" || true)

    # Find MCP server images
    local MCP_IMAGES=$(docker images "mcp-server-tree-sitter" --format "{{.ID}} {{.Repository}}:{{.Tag}}" 2>/dev/null || true)

    if [ -z "$DANGLING" ] && [ -z "$MCP_IMAGES" ]; then
        log_info "No images to clean"
        return 0
    fi

    if [ -n "$DANGLING" ]; then
        echo ""
        echo "Dangling images:"
        echo "$DANGLING"
    fi

    if [ -n "$MCP_IMAGES" ]; then
        echo ""
        echo "MCP Tree-sitter images:"
        echo "$MCP_IMAGES"
    fi

    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would remove the above images"
        return 0
    fi

    # Clean dangling images
    if [ -n "$DANGLING" ] && confirm "Remove dangling images?"; then
        docker image prune -f
        log_info "Dangling images removed"
    fi

    # Clean MCP images (with confirmation)
    if [ -n "$MCP_IMAGES" ]; then
        log_warn "This will remove MCP Tree-sitter images"
        log_warn "You will need to rebuild them with: ./build.sh"

        if confirm "Remove MCP Tree-sitter images?"; then
            echo "$MCP_IMAGES" | while read -r line; do
                local IMAGE_ID=$(echo "$line" | awk '{print $1}')
                local IMAGE_TAG=$(echo "$line" | awk '{print $2}')

                log_info "Removing image: $IMAGE_TAG ($IMAGE_ID)"
                docker rmi -f "$IMAGE_ID" 2>/dev/null || log_warn "Failed to remove $IMAGE_TAG"
            done

            log_info "MCP images removed"
        else
            log_info "Skipped MCP image cleanup"
        fi
    fi
}

# Clean volumes
clean_volumes() {
    log_clean "Cleaning MCP Tree-sitter volumes..."

    local VOLUMES=$(docker volume ls --format "{{.Name}}" | grep "mcp-cache" || true)

    if [ -z "$VOLUMES" ]; then
        log_info "No MCP Tree-sitter volumes found"
        return 0
    fi

    echo ""
    echo "Found volumes:"
    echo "$VOLUMES"
    echo ""

    # Show volume sizes
    log_info "Volume sizes:"
    echo "$VOLUMES" | while read -r vol; do
        local SIZE=$(docker run --rm -v "$vol:/cache" alpine du -sh /cache 2>/dev/null | awk '{print $1}' || echo "unknown")
        echo "  $vol: $SIZE"
    done
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would remove the above volumes"
        return 0
    fi

    log_warn "WARNING: This will DELETE all cached parse trees!"
    log_warn "The cache will be rebuilt when you next use the server"

    if confirm "Remove these volumes?"; then
        echo "$VOLUMES" | while read -r vol; do
            log_info "Removing volume: $vol"
            docker volume rm "$vol" 2>/dev/null || log_warn "Failed to remove $vol"
        done

        log_info "Volumes cleaned"
    else
        log_info "Skipped volume cleanup"
    fi
}

# Calculate space saved
show_space_saved() {
    log_info "Calculating space saved..."

    # This is approximate - actual space saved depends on what was removed
    local INITIAL_SIZE=$(docker system df --format "{{.Size}}" 2>/dev/null || echo "Unknown")

    echo ""
    log_info "Docker disk usage:"
    docker system df
    echo ""
}

# Main execution
main() {
    log_info "MCP Tree-sitter Server - Docker Cleanup Script"
    log_info "==============================================="

    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY RUN MODE - No actual changes will be made"
    fi

    echo ""

    # Clean in order
    if [ "$CLEAN_CONTAINERS" = true ]; then
        clean_containers
        echo ""
    fi

    if [ "$CLEAN_IMAGES" = true ]; then
        clean_images
        echo ""
    fi

    if [ "$CLEAN_VOLUMES" = true ]; then
        clean_volumes
        echo ""
    fi

    if [ "$DRY_RUN" = false ]; then
        show_space_saved
    fi

    log_info "Cleanup complete!"
}

# Run main function
main
