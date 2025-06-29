#!/bin/bash

# JSON MCP Server Installation Script
# Supports multiple installation methods across different platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version to install (latest by default)
VERSION="${1:-latest}"
REPO="ciresnave/json-mcp-server"

print_colored() {
    printf "${1}${2}${NC}\n"
}

print_info() {
    print_colored "$BLUE" "ℹ $1"
}

print_success() {
    print_colored "$GREEN" "✓ $1"
}

print_warning() {
    print_colored "$YELLOW" "⚠ $1"
}

print_error() {
    print_colored "$RED" "✗ $1"
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "debian"
        elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
            echo "rhel"
        elif command -v pacman >/dev/null 2>&1; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

detect_arch() {
    case $(uname -m) in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

install_via_cargo() {
    print_info "Installing via Cargo..."
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Cargo not found. Please install Rust first: https://rustup.rs/"
        exit 1
    fi
    
    cargo install json-mcp-server
    print_success "Installed json-mcp-server via Cargo"
}

install_debian_package() {
    local arch=$(detect_arch)
    print_info "Installing .deb package for $arch architecture..."
    
    # Download the latest .deb package
    local download_url
    if [[ "$VERSION" == "latest" ]]; then
        download_url=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
                      grep "browser_download_url.*\.deb" | \
                      cut -d '"' -f 4)
    else
        download_url="https://github.com/$REPO/releases/download/v$VERSION/json-mcp-server_${VERSION}_amd64.deb"
    fi
    
    if [[ -z "$download_url" ]]; then
        print_error "Could not find .deb package for version $VERSION"
        return 1
    fi
    
    local temp_file=$(mktemp)
    print_info "Downloading $download_url..."
    curl -L "$download_url" -o "$temp_file"
    
    print_info "Installing package..."
    sudo dpkg -i "$temp_file" || {
        print_warning "Dependency issues detected, trying to fix..."
        sudo apt-get install -f -y
    }
    
    rm "$temp_file"
    print_success "Installed json-mcp-server via .deb package"
}

install_rpm_package() {
    local arch=$(detect_arch)
    print_info "Installing .rpm package for $arch architecture..."
    
    # Download the latest .rpm package
    local download_url
    if [[ "$VERSION" == "latest" ]]; then
        download_url=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
                      grep "browser_download_url.*\.rpm" | \
                      cut -d '"' -f 4)
    else
        download_url="https://github.com/$REPO/releases/download/v$VERSION/json-mcp-server-${VERSION}-1.x86_64.rpm"
    fi
    
    if [[ -z "$download_url" ]]; then
        print_error "Could not find .rpm package for version $VERSION"
        return 1
    fi
    
    local temp_file=$(mktemp)
    print_info "Downloading $download_url..."
    curl -L "$download_url" -o "$temp_file"
    
    print_info "Installing package..."
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$temp_file"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "$temp_file"
    else
        sudo rpm -i "$temp_file"
    fi
    
    rm "$temp_file"
    print_success "Installed json-mcp-server via .rpm package"
}

install_arch_package() {
    print_info "Installing via AUR (manual method)..."
    print_warning "Note: This requires manual intervention for AUR packages"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download PKGBUILD
    local pkgbuild_url
    if [[ "$VERSION" == "latest" ]]; then
        pkgbuild_url=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
                      grep "browser_download_url.*PKGBUILD" | \
                      cut -d '"' -f 4)
    else
        pkgbuild_url="https://github.com/$REPO/releases/download/v$VERSION/PKGBUILD"
    fi
    
    if [[ -z "$pkgbuild_url" ]]; then
        print_error "Could not find PKGBUILD for version $VERSION"
        return 1
    fi
    
    curl -L "$pkgbuild_url" -o PKGBUILD
    
    print_info "Building package with makepkg..."
    makepkg -si --noconfirm
    
    cd - >/dev/null
    rm -rf "$temp_dir"
    print_success "Installed json-mcp-server via AUR"
}

install_binary() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    
    print_info "Installing pre-built binary for $os-$arch..."
    
    # Determine target triple
    local target
    case "$os-$arch" in
        "linux-x86_64")
            target="x86_64-unknown-linux-gnu"
            ;;
        "linux-aarch64")
            target="aarch64-unknown-linux-gnu"
            ;;
        "macos-x86_64")
            target="x86_64-apple-darwin"
            ;;
        "macos-aarch64")
            target="aarch64-apple-darwin"
            ;;
        *)
            print_error "No pre-built binary available for $os-$arch"
            return 1
            ;;
    esac
    
    # Download binary
    local download_url
    if [[ "$VERSION" == "latest" ]]; then
        download_url=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
                      grep "browser_download_url.*$target" | \
                      cut -d '"' -f 4)
    else
        download_url="https://github.com/$REPO/releases/download/v$VERSION/json-mcp-server-v$VERSION-$target.tar.gz"
    fi
    
    if [[ -z "$download_url" ]]; then
        print_error "Could not find binary for $target version $VERSION"
        return 1
    fi
    
    local temp_file=$(mktemp)
    print_info "Downloading $download_url..."
    curl -L "$download_url" -o "$temp_file"
    
    # Extract and install
    local temp_dir=$(mktemp -d)
    tar -xzf "$temp_file" -C "$temp_dir"
    
    # Find the binary (it might be in a subdirectory)
    local binary_path=$(find "$temp_dir" -name "json-mcp-server" -type f)
    
    if [[ -z "$binary_path" ]]; then
        print_error "Could not find json-mcp-server binary in downloaded archive"
        return 1
    fi
    
    # Install to /usr/local/bin or ~/.local/bin
    local install_dir
    if [[ -w "/usr/local/bin" ]]; then
        install_dir="/usr/local/bin"
    else
        install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"
    fi
    
    cp "$binary_path" "$install_dir/json-mcp-server"
    chmod +x "$install_dir/json-mcp-server"
    
    # Cleanup
    rm "$temp_file"
    rm -rf "$temp_dir"
    
    print_success "Installed json-mcp-server to $install_dir"
    
    # Check if directory is in PATH
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        print_warning "$install_dir is not in your PATH. Add it to your shell profile:"
        print_info "echo 'export PATH=\"$install_dir:\$PATH\"' >> ~/.bashrc"
    fi
}

show_usage() {
    echo "JSON MCP Server Installation Script"
    echo ""
    echo "Usage: $0 [VERSION] [METHOD]"
    echo ""
    echo "VERSION: Version to install (default: latest)"
    echo "METHOD:  Installation method (default: auto-detect)"
    echo "         - cargo: Install via Cargo"
    echo "         - deb: Install .deb package (Debian/Ubuntu)"
    echo "         - rpm: Install .rpm package (RHEL/Fedora/CentOS)"
    echo "         - arch: Install via AUR (Arch Linux)"
    echo "         - binary: Install pre-built binary"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install latest version (auto-detect method)"
    echo "  $0 0.1.0              # Install version 0.1.0 (auto-detect method)"
    echo "  $0 latest cargo       # Install latest version via Cargo"
    echo "  $0 0.1.0 binary       # Install version 0.1.0 as binary"
}

main() {
    local method="${2:-auto}"
    
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    print_info "JSON MCP Server Installation Script"
    print_info "Version: $VERSION, Method: $method"
    
    # Auto-detect method if not specified
    if [[ "$method" == "auto" ]]; then
        local os=$(detect_os)
        case "$os" in
            "debian")
                method="deb"
                ;;
            "rhel")
                method="rpm"
                ;;
            "arch")
                method="arch"
                ;;
            *)
                if command -v cargo >/dev/null 2>&1; then
                    method="cargo"
                else
                    method="binary"
                fi
                ;;
        esac
        print_info "Auto-detected installation method: $method"
    fi
    
    # Install based on method
    case "$method" in
        "cargo")
            install_via_cargo
            ;;
        "deb")
            install_debian_package
            ;;
        "rpm")
            install_rpm_package
            ;;
        "arch")
            install_arch_package
            ;;
        "binary")
            install_binary
            ;;
        *)
            print_error "Unknown installation method: $method"
            show_usage
            exit 1
            ;;
    esac
    
    # Verify installation
    if command -v json-mcp-server >/dev/null 2>&1; then
        local installed_version=$(json-mcp-server --version 2>/dev/null || echo "unknown")
        print_success "Installation completed successfully!"
        print_info "Installed version: $installed_version"
        print_info "Try running: json-mcp-server --help"
    else
        print_error "Installation may have failed. json-mcp-server not found in PATH."
        exit 1
    fi
}

main "$@"
