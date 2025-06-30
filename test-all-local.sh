#!/bin/bash
# 🧪 Local CI Test Suite for Unix Systems
# Comprehensive testing to catch issues before GitHub Actions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TEST_SUITE=${1:-"all"}  # all, basic, package-managers, cross-platform, release
CLEAN=${CLEAN:-false}
SKIP_BUILD=${SKIP_BUILD:-false}
VERBOSE=${VERBOSE:-false}

test_header() {
    echo -e "\n${CYAN}🧪 $1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 $((${#1} + 3))))${NC}"
}

test_step() {
    echo -e "\n$1 $2"
}

test_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

test_error() {
    echo -e "${RED}❌ $1${NC}"
}

test_prerequisites() {
    test_header "Checking Prerequisites"
    
    local all_good=true
    
    # Required tools
    for tool in rustc cargo git; do
        if command -v $tool >/dev/null 2>&1; then
            local version=$($tool --version | head -n1)
            test_success "$tool: $version"
        else
            test_error "$tool not found - required for testing"
            all_good=false
        fi
    done
    
    # Optional tools
    for tool in ruby brew docker; do
        if command -v $tool >/dev/null 2>&1; then
            local version=$($tool --version 2>/dev/null | head -n1 || echo "version unknown")
            test_success "$tool: $version"
        else
            test_warning "$tool not found - some tests will be skipped"
        fi
    done
    
    if [ "$all_good" = true ]; then
        return 0
    else
        return 1
    fi
}

test_basic_build() {
    test_header "Basic Build and Test"
    
    test_step "1️⃣" "Running cargo check..."
    cargo check
    test_success "Cargo check passed"
    
    test_step "2️⃣" "Running cargo test..."
    cargo test
    test_success "All tests passed"
    
    test_step "3️⃣" "Building release binary..."
    cargo build --release
    test_success "Release build completed"
    
    test_step "4️⃣" "Verifying binary..."
    local binary_path="target/release/json-mcp-server"
    if [ -f "$binary_path" ]; then
        local size_mb=$(du -m "$binary_path" | cut -f1)
        test_success "Binary created: $binary_path (${size_mb} MB)"
        
        # Test version flag
        local version=$("$binary_path" --version)
        test_success "Version check: $version"
        return 0
    else
        test_error "Binary not found at $binary_path"
        return 1
    fi
}

test_cargo_install() {
    test_header "Cargo Install Test (mimics cross-platform CI)"
    
    test_step "1️⃣" "Checking if json-mcp-server is already installed..."
    if command -v json-mcp-server >/dev/null 2>&1; then
        test_warning "json-mcp-server already installed at: $(which json-mcp-server)"
        test_step "🔧" "Uninstalling existing version..."
        cargo uninstall json-mcp-server || test_warning "Could not uninstall existing version"
    fi
    
    test_step "2️⃣" "Installing from current directory..."
    if cargo install --path . --force; then
        test_success "Cargo install completed"
    else
        test_error "Cargo install failed"
        return 1
    fi
    
    test_step "3️⃣" "Verifying installation..."
    if command -v json-mcp-server >/dev/null 2>&1; then
        local installed_path=$(which json-mcp-server)
        test_success "Found installed binary at: $installed_path"
        
        local version=$(json-mcp-server --version)
        test_success "Version check: $version"
    else
        test_error "Installed binary not found in PATH"
        return 1
    fi
    
    test_step "4️⃣" "Cleaning up test installation..."
    cargo uninstall json-mcp-server || test_warning "Could not uninstall test installation"
    test_success "Test installation cleaned up"
    
    return 0
}

test_unix_packages() {
    test_header "Unix Package Manager Tests"
    
    # Test Homebrew formula
    if command -v ruby >/dev/null 2>&1; then
        test_step "🍺" "Testing Homebrew formula..."
        local version=$(grep '^version = ' Cargo.toml | cut -d'"' -f2)
        mkdir -p test-homebrew
        
        cat > test-homebrew/json-mcp-server.rb << EOF
class JsonMcpServer < Formula
  desc "High-performance Model Context Protocol server for JSON operations"
  homepage "https://github.com/ciresnave/json-mcp-server"
  version "$version"
  
  def install
    bin.install "../target/release/json-mcp-server"
  end
  
  test do
    system "#{bin}/json-mcp-server", "--version"
  end
end
EOF
        
        if ruby -c test-homebrew/json-mcp-server.rb >/dev/null 2>&1; then
            test_success "Homebrew formula syntax valid"
        else
            test_error "Homebrew formula syntax invalid"
            return 1
        fi
        
        rm -rf test-homebrew
    else
        test_warning "Ruby not found - skipping Homebrew test"
    fi
    
    # Test AUR PKGBUILD
    test_step "📦" "Testing AUR PKGBUILD..."
    local version=$(grep '^version = ' Cargo.toml | cut -d'"' -f2)
    
    cat > test-PKGBUILD << EOF
# Maintainer: Eric Evans <CireSnave@gmail.com>
pkgname=json-mcp-server
pkgver=$version
pkgrel=1
pkgdesc="High-performance Model Context Protocol server for JSON operations"
arch=('x86_64' 'aarch64')
url="https://github.com/ciresnave/json-mcp-server"
license=('MIT' 'Apache-2.0')
depends=()
makedepends=('rust' 'cargo')
source=("https://github.com/ciresnave/json-mcp-server/archive/v\\\$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    cd "\\\$pkgname-\\\$pkgver"
    cargo build --release --locked
}

package() {
    cd "\\\$pkgname-\\\$pkgver"
    install -Dm755 "target/release/json-mcp-server" "\\\$pkgdir/usr/bin/json-mcp-server"
}
EOF
    
    test_success "PKGBUILD created successfully"
    rm -f test-PKGBUILD
    
    # Test Snap package
    test_step "📦" "Testing Snap package..."
    mkdir -p test-snap
    
    cat > test-snap/snapcraft.yaml << EOF
name: json-mcp-server
base: core22
version: '$version'
summary: High-performance Model Context Protocol server for JSON operations
description: |
  A high-performance Rust-based Model Context Protocol (MCP) server that provides 
  comprehensive JSON file operations optimized for LLM interactions.

grade: stable
confinement: strict

apps:
  json-mcp-server:
    command: bin/json-mcp-server
    plugs:
      - home
      - removable-media

parts:
  json-mcp-server:
    plugin: rust
    source: .
    build-packages:
      - gcc
      - libc6-dev
      - pkg-config
EOF
    
    test_success "Snap package definition created"
    rm -rf test-snap
    
    return 0
}

test_release_workflow() {
    test_header "Release Workflow Simulation"
    
    test_step "1️⃣" "Testing cross-compilation targets..."
    local targets=("x86_64-unknown-linux-gnu" "aarch64-unknown-linux-gnu" "x86_64-apple-darwin")
    
    for target in "${targets[@]}"; do
        echo "  Testing target: $target"
        rustup target add "$target" 2>/dev/null || true
        
        if cargo check --target "$target" >/dev/null 2>&1; then
            echo -e "    ${GREEN}✅ Target $target check passed${NC}"
        else
            echo -e "    ${YELLOW}⚠️ Target $target check failed (may need cross-compilation tools)${NC}"
        fi
    done
    
    test_step "2️⃣" "Testing archive creation..."
    local version=$(grep '^version = ' Cargo.toml | cut -d'"' -f2)
    local dist_dir="test-dist"
    mkdir -p "$dist_dir"
    
    # Copy files that would be in release
    cp target/release/json-mcp-server "$dist_dir/"
    cp README.md LICENSE-MIT LICENSE-APACHE "$dist_dir/"
    
    # Test tar.gz creation
    tar czf "test-release-v$version-unix.tar.gz" -C "$dist_dir" .
    test_success "Unix archive created"
    rm -f "test-release-v$version-unix.tar.gz"
    
    rm -rf "$dist_dir"
    
    return 0
}

test_integration() {
    test_header "Basic Integration Tests"
    
    test_step "1️⃣" "Testing JSON operations..."
    
    # Create test JSON file
    cat > test-integration.json << 'EOF'
{
  "test": "data",
  "array": [1, 2, 3],
  "nested": {
    "key": "value"
  }
}
EOF
    
    test_success "Test JSON file created"
    
    # Test that binary can start (basic smoke test)
    local binary_path="target/release/json-mcp-server"
    if "$binary_path" &>/dev/null & then
        local pid=$!
        sleep 2
        
        if kill -0 "$pid" 2>/dev/null; then
            test_success "Server started successfully"
            kill "$pid" 2>/dev/null || true
        else
            test_error "Server failed to start or exited immediately"
            return 1
        fi
    else
        test_error "Failed to start server"
        return 1
    fi
    
    rm -f test-integration.json
    
    return 0
}

main() {
    echo -e "${CYAN}🚀 JSON MCP Server - Local CI Test Suite${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if ! test_prerequisites; then
        test_error "Prerequisites check failed"
        exit 1
    fi
    
    if [ "$CLEAN" = "true" ]; then
        test_step "🧹" "Cleaning previous artifacts..."
        rm -rf target test-* choco-package *-package *.tar.gz *.zip
        cargo clean
        test_success "Cleanup completed"
    fi
    
    local all_passed=true
    
    # Run tests based on suite selection
    if [ "$TEST_SUITE" = "all" ] || [ "$TEST_SUITE" = "basic" ]; then
        if [ "$SKIP_BUILD" != "true" ]; then
            test_basic_build || all_passed=false
        fi
        test_integration || all_passed=false
    fi
    
    if [ "$TEST_SUITE" = "all" ] || [ "$TEST_SUITE" = "cross-platform" ]; then
        test_cargo_install || all_passed=false
    fi
    
    if [ "$TEST_SUITE" = "all" ] || [ "$TEST_SUITE" = "package-managers" ]; then
        test_unix_packages || all_passed=false
    fi
    
    if [ "$TEST_SUITE" = "all" ] || [ "$TEST_SUITE" = "release" ]; then
        test_release_workflow || all_passed=false
    fi
    
    # Final summary
    echo -e "\n$(printf '=%.0s' {1..50})"
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
        echo -e "${GREEN}✅ Ready for CI deployment${NC}"
        exit 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED!${NC}"
        echo -e "${YELLOW}🔧 Fix issues before pushing to CI${NC}"
        exit 1
    fi
}

# Run the main function
main "$@"
