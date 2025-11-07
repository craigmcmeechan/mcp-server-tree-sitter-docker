#!/bin/bash
# Installation script for Claude Desktop integration
# Usage: ./install-claude-desktop.sh [OPTIONS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SERVER_NAME="tree_sitter"
IMAGE_TAG="latest"
WORKSPACE_PATH="\${workspaceFolder}"
BACKUP=true
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

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Installation script for Claude Desktop integration

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -n, --name NAME        Server name in config (default: tree_sitter)
    -t, --tag TAG          Docker image tag (default: latest)
    -w, --workspace PATH   Workspace path (default: \${workspaceFolder})
    --no-backup            Don't backup existing config
    --dry-run              Show what would be done without doing it
    -h, --help             Show this help message

EXAMPLES:
    # Basic installation
    $0

    # Custom server name
    $0 -n tree_sitter_main

    # Specific image tag
    $0 -t v0.5.1

    # Fixed workspace path
    $0 -w /Users/username/Projects/myproject

    # Preview changes
    $0 --dry-run

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            SERVER_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -w|--workspace)
            WORKSPACE_PATH="$2"
            shift 2
            ;;
        --no-backup)
            BACKUP=false
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

# Detect OS and config location
detect_config_location() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "$HOME/.config/Claude/claude_desktop_config.json"
    else
        log_error "Unsupported OS: $OSTYPE"
        log_info "For Windows, please use install-claude-desktop.ps1"
        exit 1
    fi
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed"
        log_info "Install with:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "  brew install jq"
        else
            log_info "  sudo apt-get install jq  # Debian/Ubuntu"
            log_info "  sudo yum install jq      # CentOS/RHEL"
        fi
        return 1
    fi
    return 0
}

# Main execution
main() {
    log_info "MCP Tree-sitter Server - Claude Desktop Installation"
    log_info "====================================================="

    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY RUN MODE - No actual changes will be made"
    fi

    # Detect config location
    CONFIG_FILE=$(detect_config_location)
    log_info "Config file: $CONFIG_FILE"

    # Check if jq is available
    if ! check_jq; then
        log_warn "Continuing without jq (manual validation required)"
    fi

    # Create config directory if needed
    CONFIG_DIR=$(dirname "$CONFIG_FILE")
    if [ ! -d "$CONFIG_DIR" ]; then
        log_info "Creating config directory: $CONFIG_DIR"

        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$CONFIG_DIR"
        fi
    fi

    # Backup existing config
    if [ -f "$CONFIG_FILE" ] && [ "$BACKUP" = true ]; then
        BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing config to: $BACKUP_FILE"

        if [ "$DRY_RUN" = false ]; then
            cp "$CONFIG_FILE" "$BACKUP_FILE"
        fi
    fi

    # Create or update config
    log_info "Configuring MCP server..."
    echo ""
    log_info "Server configuration:"
    log_info "  Name: $SERVER_NAME"
    log_info "  Image: mcp-server-tree-sitter:$IMAGE_TAG"
    log_info "  Workspace: $WORKSPACE_PATH"
    echo ""

    # Generate server config
    read -r -d '' SERVER_CONFIG << EOF || true
{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "--name", "mcp-tree-sitter",
    "-v", "${WORKSPACE_PATH}:/workspace:ro",
    "-v", "mcp-cache:/cache",
    "-e", "MCP_TS_LOG_LEVEL=INFO",
    "mcp-server-tree-sitter:${IMAGE_TAG}"
  ]
}
EOF

    # Update config file
    if [ -f "$CONFIG_FILE" ]; then
        # Config exists - update it
        if command -v jq &> /dev/null; then
            if [ "$DRY_RUN" = false ]; then
                # Use jq to merge
                TMP_FILE=$(mktemp)
                jq --arg name "$SERVER_NAME" --argjson config "$SERVER_CONFIG" \
                    '.mcpServers[$name] = $config' \
                    "$CONFIG_FILE" > "$TMP_FILE"
                mv "$TMP_FILE" "$CONFIG_FILE"

                log_success "Config updated successfully"
            else
                log_info "Would update existing config with jq"
            fi
        else
            log_warn "Cannot automatically update config without jq"
            log_info "Please manually add the following to $CONFIG_FILE:"
            echo ""
            echo "{"
            echo "  \"mcpServers\": {"
            echo "    \"$SERVER_NAME\": $SERVER_CONFIG"
            echo "  }"
            echo "}"
            echo ""
        fi
    else
        # Create new config
        if [ "$DRY_RUN" = false ]; then
            cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "$SERVER_NAME": $SERVER_CONFIG
  }
}
EOF
            log_success "Config created successfully"
        else
            log_info "Would create new config file"
        fi
    fi

    # Validate JSON
    if [ "$DRY_RUN" = false ] && command -v jq &> /dev/null; then
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            log_success "Config file JSON is valid"
        else
            log_error "Config file JSON is invalid!"
            log_info "Please check: $CONFIG_FILE"

            if [ "$BACKUP" = true ]; then
                log_info "You can restore from backup: $BACKUP_FILE"
            fi

            exit 1
        fi
    fi

    # Final instructions
    echo ""
    log_info "Installation complete!"
    echo ""
    log_info "Next steps:"
    log_info "  1. Restart Claude Desktop"
    log_info "  2. Look for the MCP tools icon (hammer) in the interface"
    log_info "  3. Click the icon to see available tools"
    echo ""
    log_info "Troubleshooting:"
    log_info "  - View config: cat \"$CONFIG_FILE\""
    log_info "  - Test manually: docker run -i --rm mcp-server-tree-sitter:$IMAGE_TAG --version"
    log_info "  - Check logs: ~/Library/Logs/Claude/ (macOS) or ~/.config/Claude/logs/ (Linux)"

    if [ "$BACKUP" = true ] && [ -f "$BACKUP_FILE" ]; then
        echo ""
        log_info "Backup saved at: $BACKUP_FILE"
    fi

    echo ""
    log_info "For more information, see:"
    log_info "  - docs/docker/CLAUDE_INTEGRATION.md"
    log_info "  - examples/docker/claude-desktop/README.md"
}

# Run main function
main
