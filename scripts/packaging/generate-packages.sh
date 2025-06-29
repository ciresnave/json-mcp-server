#!/bin/bash

# Package Generation Script for All Package Managers
# This script generates all package definitions with current version and checksums

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PACKAGING_DIR="$PROJECT_ROOT/packaging"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Get version from Cargo.toml
get_version() {
    grep '^version = ' "$PROJECT_ROOT/Cargo.toml" | cut -d'"' -f2
}

# Get SHA256 checksum of a file
get_sha256() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        print_error "No SHA256 utility found"
        return 1
    fi
}

# Download file and get checksum
get_remote_checksum() {
    local url="$1"
    local temp_file=$(mktemp)
    
    print_status "Downloading $url for checksum..."
    if curl -L "$url" -o "$temp_file" 2>/dev/null; then
        get_sha256 "$temp_file"
        rm -f "$temp_file"
    else
        print_warning "Could not download $url, using placeholder"
        echo "PLACEHOLDER_CHECKSUM"
    fi
}

# Generate Chocolatey package
generate_chocolatey() {
    local version="$1"
    print_status "Generating Chocolatey package..."
    
    local choco_dir="$PACKAGING_DIR/chocolatey"
    local temp_dir=$(mktemp -d)
    
    # Copy template files
    cp -r "$choco_dir/"* "$temp_dir/"
    
    # Get checksum for Windows x64 binary
    local win_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-x86_64-pc-windows-msvc.zip"
    local checksum=$(get_remote_checksum "$win_url")
    
    # Replace placeholders
    find "$temp_dir" -type f \( -name "*.nuspec" -o -name "*.ps1" \) -exec sed -i.bak "s/{{VERSION}}/$version/g" {} \;
    find "$temp_dir" -type f \( -name "*.nuspec" -o -name "*.ps1" \) -exec sed -i.bak "s/{{CHECKSUM64}}/$checksum/g" {} \;
    
    # Clean up backup files
    find "$temp_dir" -name "*.bak" -delete
    
    # Create output directory
    local output_dir="$PROJECT_ROOT/dist/chocolatey"
    mkdir -p "$output_dir"
    cp -r "$temp_dir/"* "$output_dir/"
    
    rm -rf "$temp_dir"
    print_success "Chocolatey package generated in dist/chocolatey/"
}

# Generate Winget manifests
generate_winget() {
    local version="$1"
    print_status "Generating Winget manifests..."
    
    local winget_dir="$PACKAGING_DIR/winget"
    local temp_dir=$(mktemp -d)
    
    # Copy template files
    cp -r "$winget_dir/"* "$temp_dir/"
    
    # Get checksums for Windows binaries
    local win_x64_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-x86_64-pc-windows-msvc.zip"
    local win_arm64_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-aarch64-pc-windows-msvc.zip"
    
    local checksum_x64=$(get_remote_checksum "$win_x64_url")
    local checksum_arm64=$(get_remote_checksum "$win_arm64_url")
    local release_date=$(date -u +"%Y-%m-%d")
    
    # Replace placeholders
    find "$temp_dir" -type f -name "*.yaml" -exec sed -i.bak "s/{{VERSION}}/$version/g" {} \;
    find "$temp_dir" -type f -name "*.yaml" -exec sed -i.bak "s/{{INSTALLER_SHA256}}/$checksum_x64/g" {} \;
    find "$temp_dir" -type f -name "*.yaml" -exec sed -i.bak "s/{{INSTALLER_SHA256_ARM64}}/$checksum_arm64/g" {} \;
    find "$temp_dir" -type f -name "*.yaml" -exec sed -i.bak "s/{{RELEASE_DATE}}/$release_date/g" {} \;
    
    # Clean up backup files
    find "$temp_dir" -name "*.bak" -delete
    
    # Create output directory with proper structure
    local output_dir="$PROJECT_ROOT/dist/winget/manifests/c/ciresnave/json-mcp-server/$version"
    mkdir -p "$output_dir"
    cp "$temp_dir/"* "$output_dir/"
    
    rm -rf "$temp_dir"
    print_success "Winget manifests generated in dist/winget/"
}

# Generate Homebrew formula
generate_homebrew() {
    local version="$1"
    print_status "Generating Homebrew formula..."
    
    local homebrew_dir="$PACKAGING_DIR/homebrew"
    local temp_dir=$(mktemp -d)
    
    # Copy template
    cp "$homebrew_dir/json-mcp-server.rb" "$temp_dir/"
    
    # Get checksums for macOS binaries
    local mac_x64_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-x86_64-apple-darwin.tar.gz"
    local mac_arm64_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-aarch64-apple-darwin.tar.gz"
    
    local checksum_x64=$(get_remote_checksum "$mac_x64_url")
    local checksum_arm64=$(get_remote_checksum "$mac_arm64_url")
    
    # Replace placeholders
    sed -i.bak "s/{{VERSION}}/$version/g" "$temp_dir/json-mcp-server.rb"
    sed -i.bak "s/{{SHA256_X64}}/$checksum_x64/g" "$temp_dir/json-mcp-server.rb"
    sed -i.bak "s/{{SHA256_ARM64}}/$checksum_arm64/g" "$temp_dir/json-mcp-server.rb"
    
    # Clean up backup files
    rm -f "$temp_dir/"*.bak
    
    # Create output directory
    local output_dir="$PROJECT_ROOT/dist/homebrew"
    mkdir -p "$output_dir"
    cp "$temp_dir/json-mcp-server.rb" "$output_dir/"
    
    rm -rf "$temp_dir"
    print_success "Homebrew formula generated in dist/homebrew/"
}

# Generate AUR packages
generate_aur() {
    local version="$1"
    print_status "Generating AUR packages..."
    
    local aur_dir="$PACKAGING_DIR/aur"
    local temp_dir=$(mktemp -d)
    
    # Copy templates
    cp -r "$aur_dir/"* "$temp_dir/"
    
    # Get checksums
    local source_url="https://github.com/ciresnave/json-mcp-server/archive/v$version.tar.gz"
    local linux_x64_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-x86_64-unknown-linux-gnu.tar.gz"
    local linux_arm64_url="https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-aarch64-unknown-linux-gnu.tar.gz"
    
    local source_checksum=$(get_remote_checksum "$source_url")
    local checksum_x64=$(get_remote_checksum "$linux_x64_url")
    local checksum_arm64=$(get_remote_checksum "$linux_arm64_url")
    
    # Replace placeholders in both PKGBUILD files
    find "$temp_dir" -name "PKGBUILD*" -exec sed -i.bak "s/{{VERSION}}/$version/g" {} \;
    find "$temp_dir" -name "PKGBUILD*" -exec sed -i.bak "s/{{SOURCE_SHA256}}/$source_checksum/g" {} \;
    find "$temp_dir" -name "PKGBUILD*" -exec sed -i.bak "s/{{SHA256_X64}}/$checksum_x64/g" {} \;
    find "$temp_dir" -name "PKGBUILD*" -exec sed -i.bak "s/{{SHA256_ARM64}}/$checksum_arm64/g" {} \;
    
    # Clean up backup files
    find "$temp_dir" -name "*.bak" -delete
    
    # Create output directories
    local output_dir="$PROJECT_ROOT/dist/aur"
    mkdir -p "$output_dir/json-mcp-server"
    mkdir -p "$output_dir/json-mcp-server-bin"
    
    cp "$temp_dir/PKGBUILD" "$output_dir/json-mcp-server/"
    cp "$temp_dir/PKGBUILD-bin" "$output_dir/json-mcp-server-bin/PKGBUILD"
    
    # Generate .SRCINFO files
    if command -v makepkg >/dev/null 2>&1; then
        cd "$output_dir/json-mcp-server" && makepkg --printsrcinfo > .SRCINFO
        cd "$output_dir/json-mcp-server-bin" && makepkg --printsrcinfo > .SRCINFO
    else
        print_warning "makepkg not found, .SRCINFO files not generated"
    fi
    
    rm -rf "$temp_dir"
    print_success "AUR packages generated in dist/aur/"
}

# Generate Snap package
generate_snap() {
    local version="$1"
    print_status "Generating Snap package..."
    
    local snap_dir="$PACKAGING_DIR/snap"
    local temp_dir=$(mktemp -d)
    
    # Copy template
    cp "$snap_dir/snapcraft.yaml" "$temp_dir/"
    
    # Replace placeholders
    sed -i.bak "s/{{VERSION}}/$version/g" "$temp_dir/snapcraft.yaml"
    
    # Clean up backup files
    rm -f "$temp_dir/"*.bak
    
    # Create output directory
    local output_dir="$PROJECT_ROOT/dist/snap"
    mkdir -p "$output_dir"
    cp "$temp_dir/snapcraft.yaml" "$output_dir/"
    
    rm -rf "$temp_dir"
    print_success "Snap package definition generated in dist/snap/"
}

# Generate package submission instructions
generate_submission_instructions() {
    local version="$1"
    print_status "Generating submission instructions..."
    
    local output_file="$PROJECT_ROOT/dist/SUBMISSION_INSTRUCTIONS.md"
    
    cat > "$output_file" << EOF
# Package Manager Submission Instructions

Version: $version
Generated: $(date -u)

## Chocolatey

1. **Test the package locally:**
   \`\`\`powershell
   cd dist/chocolatey
   choco pack
   choco install json-mcp-server -s . -y --force
   \`\`\`

2. **Submit to Chocolatey Community Repository:**
   - Create account at https://community.chocolatey.org/
   - Upload the generated .nupkg file
   - Package will be automatically tested and reviewed

## Winget

1. **Test the manifests locally:**
   \`\`\`powershell
   winget validate dist/winget/manifests/c/ciresnave/json-mcp-server/$version/
   \`\`\`

2. **Submit to Microsoft's winget-pkgs repository:**
   - Fork https://github.com/microsoft/winget-pkgs
   - Copy manifests to \`manifests/c/ciresnave/json-mcp-server/$version/\`
   - Create pull request with validation checks

## Homebrew

1. **Test the formula locally:**
   \`\`\`bash
   brew install --build-from-source dist/homebrew/json-mcp-server.rb
   brew test json-mcp-server
   \`\`\`

2. **Submit to Homebrew Core:**
   - Fork https://github.com/Homebrew/homebrew-core
   - Add formula to \`Formula/j/json-mcp-server.rb\`
   - Create pull request following Homebrew guidelines

## AUR (Arch User Repository)

### Source Package (json-mcp-server)

1. **Test the package:**
   \`\`\`bash
   cd dist/aur/json-mcp-server
   makepkg -si
   \`\`\`

2. **Submit to AUR:**
   - Create AUR account at https://aur.archlinux.org/
   - Clone AUR repository: \`git clone ssh://aur@aur.archlinux.org/json-mcp-server.git\`
   - Copy PKGBUILD and .SRCINFO files
   - Commit and push

### Binary Package (json-mcp-server-bin)

1. **Test the binary package:**
   \`\`\`bash
   cd dist/aur/json-mcp-server-bin
   makepkg -si
   \`\`\`

2. **Submit to AUR:**
   - Clone: \`git clone ssh://aur@aur.archlinux.org/json-mcp-server-bin.git\`
   - Copy files and push

## Snap

1. **Test the snap locally:**
   \`\`\`bash
   cd dist/snap
   snapcraft --destructive-mode
   sudo snap install json-mcp-server_*.snap --dangerous
   \`\`\`

2. **Submit to Snap Store:**
   - Create account at https://snapcraft.io/
   - Register the name: \`snapcraft register json-mcp-server\`
   - Upload: \`snapcraft upload json-mcp-server_*.snap\`
   - Release to stable channel

## Verification Checklist

Before submitting to any package manager:

- [ ] All packages install successfully
- [ ] Binary runs and shows correct version: \`json-mcp-server --version\`
- [ ] Basic functionality works
- [ ] All checksums are correct
- [ ] License files are included
- [ ] Documentation is accessible
- [ ] Uninstallation works cleanly

## Post-Submission Monitoring

1. Monitor package manager repositories for approval status
2. Respond to reviewer feedback promptly
3. Update documentation once packages are approved
4. Set up automation for future releases

## Troubleshooting

- **Checksum mismatches**: Regenerate this script after releases are published
- **Test failures**: Verify release binaries work on target platforms
- **Review feedback**: Address maintainer guidelines for each package manager

EOF

    print_success "Submission instructions generated in dist/SUBMISSION_INSTRUCTIONS.md"
}

# Main function
main() {
    local command="${1:-all}"
    local version=$(get_version)
    
    print_status "Generating packages for json-mcp-server v$version"
    
    # Clean and create dist directory
    rm -rf "$PROJECT_ROOT/dist"
    mkdir -p "$PROJECT_ROOT/dist"
    
    case "$command" in
        "chocolatey"|"choco")
            generate_chocolatey "$version"
            ;;
        "winget")
            generate_winget "$version"
            ;;
        "homebrew"|"brew")
            generate_homebrew "$version"
            ;;
        "aur")
            generate_aur "$version"
            ;;
        "snap")
            generate_snap "$version"
            ;;
        "all")
            generate_chocolatey "$version"
            generate_winget "$version"
            generate_homebrew "$version"
            generate_aur "$version"
            generate_snap "$version"
            generate_submission_instructions "$version"
            ;;
        *)
            echo "Usage: $0 [chocolatey|winget|homebrew|aur|snap|all]"
            exit 1
            ;;
    esac
    
    print_success "Package generation completed! 🎉"
    print_status "Output directory: $PROJECT_ROOT/dist/"
}

main "$@"
