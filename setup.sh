#!/bin/bash

# iNeoVim Setup Script
# Quick installation script for containerized Neovim with full development environment
# Usage: curl -fsSL https://raw.githubusercontent.com/iocanel/nvim/main/setup.sh | bash

set -euo pipefail

# Configuration
REPO_URL="https://github.com/iocanel/nvim"
CONTAINER_IMAGE="iocanel/nvim:latest"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="invim"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        log_info "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running or you don't have permission to use Docker"
        log_info "Please start Docker or add your user to the docker group"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi

    log_success "System requirements met"
}

# Create installation directory
setup_install_dir() {
    log_info "Setting up installation directory..."

    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        log_info "Created directory: $INSTALL_DIR"
    fi

    # Check if install dir is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warning "$INSTALL_DIR is not in your PATH"
        log_info "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo -e "${BLUE}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
        echo
    fi
}

# Download ivvim binary
download_binary() {
    log_info "Downloading ivvim binary..."

    local binary_url="$REPO_URL/raw/main/bin/ivvim"
    local temp_file=$(mktemp)

    if curl -fsSL "$binary_url" -o "$temp_file"; then
        chmod +x "$temp_file"
        mv "$temp_file" "$INSTALL_DIR/$BINARY_NAME"
        log_success "Downloaded ivvim binary to $INSTALL_DIR/$BINARY_NAME"
    else
        log_error "Failed to download ivvim binary from $binary_url"
        exit 1
    fi
}

# Pull Docker image
pull_docker_image() {
    log_info "Pulling Docker image: $CONTAINER_IMAGE"
    log_info "This may take a few minutes for the first download..."

    if docker pull "$CONTAINER_IMAGE"; then
        log_success "Successfully pulled Docker image"

        # Show image info
        local image_size=$(docker images --format "table {{.Size}}" "$CONTAINER_IMAGE" | tail -n1)
        log_info "Image size: $image_size"
    else
        log_error "Failed to pull Docker image: $CONTAINER_IMAGE"
        exit 1
    fi
}

# Test installation
test_installation() {
    log_info "Testing installation..."

    if [[ -x "$INSTALL_DIR/$BINARY_NAME" ]]; then
        log_success "ivvim binary is executable"
    else
        log_error "ivvim binary is not executable"
        exit 1
    fi

    # Test Docker image
    if docker run --rm "$CONTAINER_IMAGE" --version &> /dev/null; then
        log_success "Docker container is working"
    else
        log_error "Docker container test failed"
        exit 1
    fi
}

# Show usage information
show_usage() {
    log_success "Installation completed successfully!"
    echo
    log_info "Usage:"
    echo -e "  ${BLUE}$BINARY_NAME [nvim-options]${NC}    # Run Neovim in container"
    echo -e "  ${BLUE}$BINARY_NAME .${NC}                # Open current directory"
    echo -e "  ${BLUE}$BINARY_NAME file.txt${NC}         # Edit a specific file"
    echo
    log_info "Features included:"
    echo "  • Full LSP support (Java, Go, Rust, Python, TypeScript, etc.)"
    echo "  • Debug Adapter Protocol (DAP) for multiple languages"
    echo "  • Git integration with Fugitive and Neogit"
    echo "  • AI assistance with multiple providers"
    echo "  • JPA entity utilities for Java development"
    echo "  • Comprehensive plugin ecosystem"
    echo
    log_info "The container includes:"
    echo "  • Neovim 0.11.3"
    echo "  • Java 21, Go 1.23, Rust, Node.js 22, Python 3"
    echo "  • All necessary LSP servers and debug adapters"
    echo "  • Build tools and compilers"
    echo

    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warning "Don't forget to add $INSTALL_DIR to your PATH!"
        echo -e "${BLUE}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
    fi
}

# Cleanup function
cleanup() {
    if [[ -n "${temp_file:-}" ]] && [[ -f "$temp_file" ]]; then
        rm -f "$temp_file"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main installation process
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      iNeoVim Setup Script                    ║"
    echo "║          Containerized Neovim Development Environment        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_root
    check_requirements
    setup_install_dir
    download_binary
    pull_docker_image
    test_installation
    show_usage

    log_success "Setup completed! You can now use '$BINARY_NAME' to start Neovim."
}

# Run main function
main "$@"
