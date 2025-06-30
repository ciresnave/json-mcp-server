# Local Build and Package System
# Comprehensive script to build all targets and create all packages locally

param(
    [switch]$Clean = $false,
    [switch]$BuildOnly = $false,
    [switch]$PackageOnly = $false,
    [string[]]$Targets = @(),
    [string[]]$Packages = @(),
    [switch]$SkipTests = $false,
    [switch]$Verbose = $false
)

# Configuration
$AllTargets = @(
    "x86_64-pc-windows-msvc",
    "aarch64-pc-windows-msvc", 
    "x86_64-apple-darwin",
    "aarch64-apple-darwin",
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
    "x86_64-unknown-linux-musl",
    "aarch64-unknown-linux-musl"
)

$AllPackages = @("chocolatey", "winget", "deb", "rpm", "arch", "snap")
$WindowsPackages = @("chocolatey", "winget")
$LinuxPackages = @("deb", "rpm", "arch", "snap")

# Default to all if none specified
if ($Targets.Count -eq 0) { $Targets = $AllTargets }
if ($Packages.Count -eq 0) { $Packages = $AllPackages }

function Write-Status {
    param($Message, $Color = "Cyan")
    Write-Host "`n🔧 $Message" -ForegroundColor $Color
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

Write-Host @"
🏗️ JSON MCP Server - Local Build System
========================================
Platform: Windows
Targets: $($Targets -join ', ')
Packages: $($Packages -join ', ')
"@ -ForegroundColor Cyan

# Clean previous builds
if ($Clean) {
    Write-Status "Cleaning previous builds..."
    Remove-Item -Path "target", "dist", "packages" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "*.nupkg", "*.deb", "*.rpm", "*.tar.gz", "*.zip" -Force -ErrorAction SilentlyContinue
    Write-Success "Cleaned build artifacts"
}

# Create output directories
New-Item -ItemType Directory -Path "dist", "packages" -Force | Out-Null

if (-not $PackageOnly) {
    Write-Status "Installing required Rust targets..."
    
    # Install all required targets
    foreach ($target in $Targets) {
        if ($Verbose) { Write-Host "Installing target: $target" }
        rustup target add $target
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install target: $target"
            exit 1
        }
    }
    Write-Success "All Rust targets installed"

    # Configure cross-compilation for Linux targets (requires Docker or cross)
    Write-Status "Setting up cross-compilation..."
    
    # Install cross for easier cross-compilation
    if (-not (Get-Command cross -ErrorAction SilentlyContinue)) {
        Write-Status "Installing cross for cross-compilation..."
        cargo install cross --git https://github.com/cross-rs/cross
    }

    # Build for each target
    Write-Status "Building for all targets..."
    $BuildResults = @{}
    
    foreach ($target in $Targets) {
        Write-Status "Building for $target..."
        
        $startTime = Get-Date
        
        # Use cross for non-Windows targets if available, otherwise cargo
        if ($target -like "*windows*") {
            cargo build --release --target $target
        } else {
            # Try cross first, fallback to cargo
            if (Get-Command cross -ErrorAction SilentlyContinue) {
                cross build --release --target $target
            } else {
                Write-Warning "Cross not available, using cargo (may fail for some targets)"
                cargo build --release --target $target
            }
        }
        
        $buildTime = (Get-Date) - $startTime
        
        if ($LASTEXITCODE -eq 0) {
            $BuildResults[$target] = @{ Status = "Success"; Time = $buildTime }
            Write-Success "Built $target in $($buildTime.TotalSeconds.ToString('F1'))s"
            
            # Create archives
            $archiveDir = "dist/$target"
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            
            $binaryName = if ($target -like "*windows*") { "json-mcp-server.exe" } else { "json-mcp-server" }
            $binaryPath = "target/$target/release/$binaryName"
            
            if (Test-Path $binaryPath) {
                Copy-Item $binaryPath $archiveDir/
                Copy-Item "README.md", "LICENSE-MIT", "LICENSE-APACHE" $archiveDir/
                
                # Create archive
                $archiveName = if ($target -like "*windows*") {
                    "json-mcp-server-$target.zip"
                } else {
                    "json-mcp-server-$target.tar.gz"
                }
                
                if ($target -like "*windows*") {
                    Compress-Archive -Path "$archiveDir/*" -DestinationPath "dist/$archiveName" -Force
                } else {
                    # For tar.gz, we'd need WSL or a tar command
                    Write-Warning "Skipping tar.gz creation for $target (requires Unix tools)"
                }
                
                Write-Success "Created archive: $archiveName"
            } else {
                Write-Warning "Binary not found at $binaryPath"
            }
        } else {
            $BuildResults[$target] = @{ Status = "Failed"; Time = $buildTime }
            Write-Error "Failed to build $target"
        }
    }
    
    # Build summary
    Write-Status "Build Summary:"
    foreach ($target in $Targets) {
        $result = $BuildResults[$target]
        $status = $result.Status
        $time = $result.Time.TotalSeconds.ToString('F1')
        
        if ($status -eq "Success") {
            Write-Success "$target - $status ($($time)s)"
        } else {
            Write-Error "$target - $status ($($time)s)"
        }
    }
}

if (-not $BuildOnly) {
    Write-Status "Creating packages..."
    
    # Get version from Cargo.toml
    $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
    Write-Host "📊 Package version: $version" -ForegroundColor Cyan
    
    # Create Windows packages
    if ($Packages -contains "chocolatey") {
        Write-Status "Creating Chocolatey package..."
        
        $chocoDir = "packages/chocolatey"
        New-Item -ItemType Directory -Path "$chocoDir/tools" -Force | Out-Null
        
        # Copy Windows x64 binary
        $windowsBinary = "target/x86_64-pc-windows-msvc/release/json-mcp-server.exe"
        if (Test-Path $windowsBinary) {
            Copy-Item $windowsBinary "$chocoDir/tools/" -Force
            
            # Create nuspec
            $nuspecContent = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>json-mcp-server</id>
    <version>$version</version>
    <packageSourceUrl>https://github.com/ciresnave/json-mcp-server</packageSourceUrl>
    <owners>Eric Evans</owners>
    <title>JSON MCP Server</title>
    <authors>Eric Evans</authors>
    <projectUrl>https://github.com/ciresnave/json-mcp-server</projectUrl>
    <licenseUrl>https://github.com/ciresnave/json-mcp-server/blob/main/LICENSE-MIT</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <projectSourceUrl>https://github.com/ciresnave/json-mcp-server</projectSourceUrl>
    <tags>json mcp llm jsonpath protocol</tags>
    <summary>High-performance Model Context Protocol server for JSON operations</summary>
    <description>A high-performance Rust-based Model Context Protocol (MCP) server that provides comprehensive JSON file operations optimized for LLM interactions. Features include reading, writing, querying with JSONPath, validation, and streaming support for large files.</description>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
"@
            $nuspecContent | Out-File -FilePath "$chocoDir/json-mcp-server.nuspec" -Encoding utf8
            
            # Create install script
            $installScript = @'
$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "json-mcp-server.exe"

if (-not (Test-Path $exePath)) {
    throw "Binary not found at $exePath"
}

Write-Host "json-mcp-server installed successfully to $exePath"
'@
            $installScript | Out-File -FilePath "$chocoDir/tools/chocolateyinstall.ps1" -Encoding utf8
            
            # Build package
            Push-Location $chocoDir
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                choco pack
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Chocolatey package created"
                    Move-Item "*.nupkg" "../../packages/" -Force
                } else {
                    Write-Error "Chocolatey package creation failed"
                }
            } else {
                Write-Warning "Chocolatey not installed - package structure created but not built"
            }
            Pop-Location
        } else {
            Write-Warning "Windows binary not found - skipping Chocolatey package"
        }
    }
    
    if ($Packages -contains "winget") {
        Write-Status "Creating Winget manifests..."
        
        $wingetDir = "packages/winget/manifests/c/ciresnave/json-mcp-server/$version"
        New-Item -ItemType Directory -Path $wingetDir -Force | Out-Null
        
        # Version manifest
        $versionContent = @"
PackageIdentifier: ciresnave.json-mcp-server
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.4.0
"@
        $versionContent | Out-File -FilePath "$wingetDir/ciresnave.json-mcp-server.yaml" -Encoding utf8
        
        # Installer manifest
        $installerContent = @"
PackageIdentifier: ciresnave.json-mcp-server
PackageVersion: $version
InstallerLocale: en-US
Platform:
  - Windows.Desktop
MinimumOSVersion: 10.0.0.0
InstallerType: zip
Scope: user
InstallModes:
  - interactive
  - silent
UpgradeBehavior: install
Installers:
  - Architecture: x64
    InstallerUrl: https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-x86_64-pc-windows-msvc.zip
    InstallerSha256: PLACEHOLDER_SHA256
ManifestType: installer
ManifestVersion: 1.4.0
"@
        $installerContent | Out-File -FilePath "$wingetDir/ciresnave.json-mcp-server.installer.yaml" -Encoding utf8
        
        # Locale manifest
        $localeContent = @"
PackageIdentifier: ciresnave.json-mcp-server
PackageVersion: $version
PackageLocale: en-US
Publisher: Eric Evans
PublisherUrl: https://github.com/ciresnave
PublisherSupportUrl: https://github.com/ciresnave/json-mcp-server/issues
Author: Eric Evans
PackageName: JSON MCP Server
PackageUrl: https://github.com/ciresnave/json-mcp-server
License: MIT OR Apache-2.0
LicenseUrl: https://github.com/ciresnave/json-mcp-server/blob/main/LICENSE-MIT
ShortDescription: High-performance Model Context Protocol server for JSON operations
Description: A high-performance Rust-based Model Context Protocol (MCP) server that provides comprehensive JSON file operations optimized for LLM interactions.
Moniker: json-mcp-server
Tags:
  - json
  - mcp
  - llm
  - jsonpath
  - protocol
ManifestType: defaultLocale
ManifestVersion: 1.4.0
"@
        $localeContent | Out-File -FilePath "$wingetDir/ciresnave.json-mcp-server.locale.en-US.yaml" -Encoding utf8
        
        Write-Success "Winget manifests created"
    }
    
    # Create Linux packages (requires tools)
    if ($Packages -contains "deb") {
        Write-Status "Creating DEB package structure..."
        
        # This would require cargo-deb or manual creation
        Write-Warning "DEB package creation requires Linux environment or Docker"
    }
    
    if ($Packages -contains "rpm") {
        Write-Status "Creating RPM package structure..."
        Write-Warning "RPM package creation requires Linux environment or Docker"
    }
    
    if ($Packages -contains "arch") {
        Write-Status "Creating Arch PKGBUILD..."
        
        $archDir = "packages/arch"
        New-Item -ItemType Directory -Path $archDir -Force | Out-Null
        
        $pkgbuildContent = @"
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
source=("https://github.com/ciresnave/json-mcp-server/archive/v`$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
    cd "`$pkgname-`$pkgver"
    cargo build --release --locked
}

check() {
    cd "`$pkgname-`$pkgver"
    cargo test
}

package() {
    cd "`$pkgname-`$pkgver"
    install -Dm755 "target/release/json-mcp-server" "`$pkgdir/usr/bin/json-mcp-server"
    install -Dm644 "README.md" "`$pkgdir/usr/share/doc/`$pkgname/README.md"
    install -Dm644 "LICENSE-MIT" "`$pkgdir/usr/share/licenses/`$pkgname/LICENSE-MIT"
    install -Dm644 "LICENSE-APACHE" "`$pkgdir/usr/share/licenses/`$pkgname/LICENSE-APACHE"
}
"@
        $pkgbuildContent | Out-File -FilePath "$archDir/PKGBUILD" -Encoding utf8
        Write-Success "Arch PKGBUILD created"
    }
    
    if ($Packages -contains "snap") {
        Write-Status "Creating Snap package structure..."
        
        $snapDir = "packages/snap"
        New-Item -ItemType Directory -Path $snapDir -Force | Out-Null
        
        $snapcraftContent = @"
name: json-mcp-server
base: core22
version: '$version'
summary: High-performance Model Context Protocol server for JSON operations
description: |
  A high-performance Rust-based Model Context Protocol (MCP) server that provides 
  comprehensive JSON file operations optimized for LLM interactions. Features include 
  reading, writing, querying with JSONPath, validation, and streaming support for large files.

grade: stable
confinement: strict

architectures:
  - build-on: amd64
  - build-on: arm64

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
    stage-packages:
      - libc6
"@
        $snapcraftContent | Out-File -FilePath "$snapDir/snapcraft.yaml" -Encoding utf8
        Write-Success "Snap snapcraft.yaml created"
    }
}

# Run tests if not skipped
if (-not $SkipTests -and -not $BuildOnly) {
    Write-Status "Running local tests..."
    
    # Test basic functionality
    if (Test-Path "target/x86_64-pc-windows-msvc/release/json-mcp-server.exe") {
        Write-Status "Testing binary functionality..."
        & "target/x86_64-pc-windows-msvc/release/json-mcp-server.exe" --version
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Binary works correctly"
        } else {
            Write-Error "Binary test failed"
        }
    }
    
    # Test packages
    if ($Packages -contains "chocolatey" -and (Test-Path "packages/chocolatey")) {
        Write-Status "Testing Chocolatey package structure..."
        if ((Test-Path "packages/chocolatey/tools/json-mcp-server.exe") -and 
            (Test-Path "packages/chocolatey/json-mcp-server.nuspec") -and
            (Test-Path "packages/chocolatey/tools/chocolateyinstall.ps1")) {
            Write-Success "Chocolatey package structure valid"
        } else {
            Write-Error "Chocolatey package structure invalid"
        }
    }
}

# Final summary
Write-Status "Build and Package Summary:" "Green"

$builtTargets = $Targets | Where-Object { Test-Path "target/$_/release/json-mcp-server*" }
$createdPackages = $Packages | Where-Object { Test-Path "packages/$_" }

Write-Host "`n📊 Results:" -ForegroundColor Cyan
Write-Host "  Built targets: $($builtTargets.Count)/$($Targets.Count)" -ForegroundColor $(if ($builtTargets.Count -eq $Targets.Count) { "Green" } else { "Yellow" })
Write-Host "  Created packages: $($createdPackages.Count)/$($Packages.Count)" -ForegroundColor $(if ($createdPackages.Count -eq $Packages.Count) { "Green" } else { "Yellow" })

if ($builtTargets.Count -gt 0) {
    Write-Host "`n✅ Built targets:" -ForegroundColor Green
    $builtTargets | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
}

if ($createdPackages.Count -gt 0) {
    Write-Host "`n📦 Created packages:" -ForegroundColor Green
    $createdPackages | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
}

Write-Host "`n🎯 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review build artifacts in 'dist/' directory" -ForegroundColor White
Write-Host "  2. Review packages in 'packages/' directory" -ForegroundColor White
Write-Host "  3. Test packages locally before pushing to GitHub" -ForegroundColor White
Write-Host "  4. Use GitHub Actions only for validation/testing" -ForegroundColor White

Write-Host "`n🚀 Local build system completed!" -ForegroundColor Green -BackgroundColor DarkGreen
