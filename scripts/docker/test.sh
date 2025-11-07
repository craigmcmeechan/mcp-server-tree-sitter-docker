#!/bin/bash
# Test script for MCP Tree-sitter Server Docker images
# Usage: ./test.sh [OPTIONS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
IMAGE_TAG="latest"
TEST_TYPE="all"
COVERAGE=""
VERBOSE=""

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

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Test script for MCP Tree-sitter Server Docker images

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -t, --tag TAG          Image tag to test (default: latest)
    --type TYPE            Test type: quick, unit, integration, all (default: all)
    --coverage             Run tests with coverage report
    -v, --verbose          Verbose test output
    -h, --help             Show this help message

TEST TYPES:
    quick           Quick smoke tests
    unit            Run unit tests
    integration     Run integration tests
    all             Run all tests (default)

EXAMPLES:
    # Run all tests
    $0

    # Run quick tests only
    $0 --type quick

    # Run with coverage
    $0 --coverage

    # Test specific image tag
    $0 -t v0.5.1

    # Verbose output
    $0 -v

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --type)
            TEST_TYPE="$2"
            shift 2
            ;;
        --coverage)
            COVERAGE="--cov=mcp_server_tree_sitter --cov-report=term --cov-report=html"
            shift
            ;;
        -v|--verbose)
            VERBOSE="-v"
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

# Quick smoke tests
test_quick() {
    log_test "Running quick smoke tests..."

    local IMAGE_NAME="mcp-server-tree-sitter:${IMAGE_TAG}"
    local FAILED=0

    # Test 1: Check if image exists
    log_info "Test 1: Check if image exists"
    if docker images "$IMAGE_NAME" --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
        log_success "Image found: $IMAGE_NAME"
    else
        log_error "Image not found: $IMAGE_NAME"
        return 1
    fi

    # Test 2: Check version
    log_info "Test 2: Check version"
    if docker run --rm "$IMAGE_NAME" --version; then
        log_success "Version check passed"
    else
        log_error "Version check failed"
        FAILED=$((FAILED + 1))
    fi

    # Test 3: Check help
    log_info "Test 3: Check help"
    if docker run --rm "$IMAGE_NAME" --help > /dev/null 2>&1; then
        log_success "Help check passed"
    else
        log_error "Help check failed"
        FAILED=$((FAILED + 1))
    fi

    # Test 4: Check Python import
    log_info "Test 4: Check Python import"
    if docker run --rm "$IMAGE_NAME" python -c "import mcp_server_tree_sitter; print('OK')" | grep -q "OK"; then
        log_success "Python import check passed"
    else
        log_error "Python import check failed"
        FAILED=$((FAILED + 1))
    fi

    # Test 5: Check tree-sitter
    log_info "Test 5: Check tree-sitter import"
    if docker run --rm "$IMAGE_NAME" python -c "import tree_sitter; print('OK')" | grep -q "OK"; then
        log_success "Tree-sitter import check passed"
    else
        log_error "Tree-sitter import check failed"
        FAILED=$((FAILED + 1))
    fi

    # Test 6: Check language pack
    log_info "Test 6: Check language pack"
    if docker run --rm "$IMAGE_NAME" python -c "from tree_sitter_language_pack import get_language; get_language('python'); print('OK')" | grep -q "OK"; then
        log_success "Language pack check passed"
    else
        log_error "Language pack check failed"
        FAILED=$((FAILED + 1))
    fi

    echo ""
    if [ $FAILED -eq 0 ]; then
        log_success "All quick tests passed!"
        return 0
    else
        log_error "$FAILED quick test(s) failed"
        return 1
    fi
}

# Unit tests
test_unit() {
    log_test "Running unit tests..."

    local IMAGE_NAME="mcp-server-tree-sitter:dev"

    # Check if dev image exists
    if ! docker images "$IMAGE_NAME" --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME"; then
        log_warn "Development image not found, building..."

        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        "$SCRIPT_DIR/build.sh" dev
    fi

    log_info "Running pytest in container..."

    if docker run --rm "$IMAGE_NAME" pytest $VERBOSE $COVERAGE; then
        log_success "Unit tests passed!"
        return 0
    else
        log_error "Unit tests failed"
        return 1
    fi
}

# Integration tests
test_integration() {
    log_test "Running integration tests..."

    local IMAGE_NAME="mcp-server-tree-sitter:${IMAGE_TAG}"
    local FAILED=0

    # Create a temporary project for testing
    local TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Create a simple Python file
    cat > "$TEMP_DIR/test.py" << 'EOF'
def hello():
    print("Hello, World!")

if __name__ == "__main__":
    hello()
EOF

    log_info "Test 1: Analyze Python file"
    # This is a basic test - in real scenario would interact with MCP protocol
    if docker run --rm -v "$TEMP_DIR:/workspace:ro" "$IMAGE_NAME" \
        python -c "from mcp_server_tree_sitter.api import register_project; print('OK')" | grep -q "OK"; then
        log_success "Python file analysis test passed"
    else
        log_error "Python file analysis test failed"
        FAILED=$((FAILED + 1))
    fi

    echo ""
    if [ $FAILED -eq 0 ]; then
        log_success "All integration tests passed!"
        return 0
    else
        log_error "$FAILED integration test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    log_info "MCP Tree-sitter Server - Docker Test Script"
    log_info "============================================"
    log_info "Image tag: $IMAGE_TAG"
    log_info "Test type: $TEST_TYPE"

    local TOTAL_FAILED=0

    case $TEST_TYPE in
        quick)
            test_quick
            TOTAL_FAILED=$?
            ;;
        unit)
            test_unit
            TOTAL_FAILED=$?
            ;;
        integration)
            test_integration
            TOTAL_FAILED=$?
            ;;
        all)
            log_info "Running all tests..."
            echo ""

            test_quick
            QUICK_RESULT=$?
            TOTAL_FAILED=$((TOTAL_FAILED + QUICK_RESULT))

            echo ""

            test_unit
            UNIT_RESULT=$?
            TOTAL_FAILED=$((TOTAL_FAILED + UNIT_RESULT))

            echo ""

            test_integration
            INTEGRATION_RESULT=$?
            TOTAL_FAILED=$((TOTAL_FAILED + INTEGRATION_RESULT))

            echo ""
            log_info "Test Summary:"
            log_info "  Quick tests: $([ $QUICK_RESULT -eq 0 ] && echo "PASSED" || echo "FAILED")"
            log_info "  Unit tests: $([ $UNIT_RESULT -eq 0 ] && echo "PASSED" || echo "FAILED")"
            log_info "  Integration tests: $([ $INTEGRATION_RESULT -eq 0 ] && echo "PASSED" || echo "FAILED")"
            ;;
        *)
            log_error "Unknown test type: $TEST_TYPE"
            usage
            ;;
    esac

    echo ""
    if [ $TOTAL_FAILED -eq 0 ]; then
        log_success "All tests passed successfully!"
        exit 0
    else
        log_error "Some tests failed"
        exit 1
    fi
}

# Run main function
main
