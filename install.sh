#!/bin/bash
# Build and Install Script for KRunner LLM Plugin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
USER_INSTALL=false
AUTO_INSTALL=false
INSTALL_TYPE_EXPLICIT=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --user          Install to user directories (~/.local)"
    echo "  --system        Install to system directories (requires sudo)"
    echo "  --auto-install  Automatically install after building"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "If no install location is specified, the script will:"
    echo "  - Detect if system directories are writable"
    echo "  - Use system install if running as root or if /usr/share is writable"
    echo "  - Use user install on immutable systems or when lacking permissions"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            USER_INSTALL=true
            INSTALL_TYPE_EXPLICIT=true
            shift
            ;;
        --system)
            USER_INSTALL=false
            INSTALL_TYPE_EXPLICIT=true
            shift
            ;;
        --auto-install)
            AUTO_INSTALL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
done

echo -e "${GREEN}Building KRunner LLM Plugin${NC}"

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

echo "Checking dependencies..."
check_tool cmake
check_tool g++
check_tool pkg-config

# Check GCC version
GCC_VERSION=$(g++ -dumpversion | cut -d. -f1)
if [ "$GCC_VERSION" -lt 14 ]; then
    echo -e "${RED}Error: GCC 14 or later is required (found GCC $GCC_VERSION)${NC}"
    exit 1
fi

echo -e "${GREEN}All dependencies found${NC}"

# Detect if system is immutable or if we should use user install
detect_install_type() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo -e "${BLUE}Running as root, using system installation${NC}"
        USER_INSTALL=false
        return
    fi
    
    # Check for immutable system indicators
    local immutable_detected=false
    
    # Check for ostree-based systems (Fedora Silverblue, Bazzite, etc.)
    if [ -f "/run/ostree-booted" ] || command -v ostree &> /dev/null; then
        echo -e "${YELLOW}OSTree-based immutable system detected${NC}"
        immutable_detected=true
    fi
    
    # Check if /usr/share is writable (fallback indicator)
    if [ "$immutable_detected" = false ] && [ ! -w "/usr/share" ]; then
        echo -e "${YELLOW}System directories are not writable${NC}"
        immutable_detected=true
    fi
    
    # Set installation type based on detection
    if [ "$immutable_detected" = true ]; then
        echo -e "${BLUE}Using user-level installation${NC}"
        USER_INSTALL=true
    else
        echo -e "${BLUE}System directories are writable, using system installation${NC}"
        USER_INSTALL=false
    fi
}

# Only auto-detect if user didn't explicitly specify
if [ "$INSTALL_TYPE_EXPLICIT" = false ]; then
    detect_install_type
fi

# Set install prefix based on installation type
if [ "$USER_INSTALL" = true ]; then
    INSTALL_PREFIX="$HOME/.local"
    echo -e "${GREEN}Installation type: User-level${NC}"
    echo -e "${BLUE}Plugin will be installed to: $INSTALL_PREFIX${NC}"
else
    INSTALL_PREFIX="/usr"
    echo -e "${GREEN}Installation type: System-level${NC}"
    echo -e "${BLUE}Plugin will be installed to: $INSTALL_PREFIX${NC}"
fi

# Create build directory
BUILD_DIR="build"
if [ -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}Build directory exists. Cleaning...${NC}"
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure
echo -e "${GREEN}Configuring with CMake...${NC}"
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_CXX_STANDARD=23

# Build
echo -e "${GREEN}Building...${NC}"
make -j$(nproc)

echo -e "${GREEN}Build successful!${NC}"
echo ""

# Install if requested
if [ "$AUTO_INSTALL" = true ]; then
    echo -e "${GREEN}Installing...${NC}"
    if [ "$USER_INSTALL" = true ]; then
        # User-level install never needs sudo
        make install
    else
        # System install: use sudo only if not running as root
        if [ "$EUID" -eq 0 ]; then
            make install
        else
            sudo make install
        fi
    fi
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Plugin installed to:"
    if [ "$USER_INSTALL" = true ]; then
        echo -e "  ${BLUE}$INSTALL_PREFIX/lib/qt6/plugins/kf6/krunner/${NC}"
        echo -e "  ${BLUE}$INSTALL_PREFIX/share/krunner/dbusplugins/${NC}"
    else
        echo -e "  ${BLUE}$INSTALL_PREFIX/lib/qt6/plugins/kf6/krunner/${NC} (or lib64)"
        echo -e "  ${BLUE}$INSTALL_PREFIX/share/krunner/dbusplugins/${NC}"
    fi
    echo ""
    echo "Please restart KRunner to load the plugin:"
    echo -e "  ${BLUE}kquitapp6 krunner && krunner &${NC}"
    if [ "$USER_INSTALL" = true ]; then
        echo ""
        echo "If the plugin doesn't appear, try rebuilding the system cache:"
        echo -e "  ${BLUE}kbuildsycoca6 --noincremental${NC}"
    fi
else
    echo "To install, run:"
    if [ "$USER_INSTALL" = true ]; then
        echo -e "  ${BLUE}cd $BUILD_DIR && make install${NC}"
    else
        echo -e "  ${BLUE}cd $BUILD_DIR && sudo make install${NC}"
    fi
    echo ""
    echo "Plugin will be installed to:"
    if [ "$USER_INSTALL" = true ]; then
        echo -e "  ${BLUE}$INSTALL_PREFIX/lib/qt6/plugins/kf6/krunner/${NC}"
        echo -e "  ${BLUE}$INSTALL_PREFIX/share/krunner/dbusplugins/${NC}"
    else
        echo -e "  ${BLUE}$INSTALL_PREFIX/lib/qt6/plugins/kf6/krunner/${NC} (or lib64)"
        echo -e "  ${BLUE}$INSTALL_PREFIX/share/krunner/dbusplugins/${NC}"
    fi
    echo ""
    echo "Then restart KRunner:"
    echo -e "  ${BLUE}kquitapp6 krunner && krunner &${NC}"
    if [ "$USER_INSTALL" = true ]; then
        echo ""
        echo "If the plugin doesn't appear, try rebuilding the system cache:"
        echo -e "  ${BLUE}kbuildsycoca6 --noincremental${NC}"
    fi
fi
