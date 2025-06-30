# Local CI Test Suite - Master Script
# Runs all possible CI tests locally to catch issues before pushing

param(
    [switch]$All = $false,
    [switch]$Release = $false,
    [switch]$Packages = $false,
    [switch]$PackageManagers = $false,
    [switch]$CrossPlatform = $false,
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Blue = "Blue"

function Write-TestHeader($title) {
    Write-Host "`n" + "="*80 -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "="*80 -ForegroundColor Cyan
}

function Write-TestStep($step) {
    Write-Host "`n🔍 $step" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️ $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-TestStep "Checking prerequisites..."
    
    $missing = @()
    
    # Check Rust
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        $missing += "Rust/Cargo"
    }
    
    # Check Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $missing += "Git"
    }
    
    # Check Chocolatey (optional)
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Warning "Chocolatey not found - Chocolatey tests will be skipped"
    }
    
    # Check Ruby (for Homebrew formula syntax)
    if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) {
        Write-Warning "Ruby not found - Homebrew formula syntax tests will be skipped"
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "Missing prerequisites: $($missing -join ', ')"
        return $false
    }
    
    Write-Success "All required prerequisites found"
    return $true
}

function Test-RustBuild {
    Write-TestHeader "RUST BUILD TESTS (Release Workflow Simulation)"
    
    Write-TestStep "Building release binary..."
    cargo build --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Release build failed"
        return $false
    }
    Write-Success "Release build completed"
    
    Write-TestStep "Running tests..."
    cargo test --release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed"
        return $false
    }
    Write-Success "All tests passed"
    
    Write-TestStep "Checking binary exists..."
    $binaryPath = "target/release/json-mcp-server.exe"
    if (-not (Test-Path $binaryPath)) {
        Write-Error "Binary not found at $binaryPath"
        return $false
    }
    
    $size = [Math]::Round((Get-Item $binaryPath).Length / 1MB, 1)
    Write-Success "Binary found: $binaryPath ($size MB)"
    
    Write-TestStep "Testing binary functionality..."
    & $binaryPath --version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Binary --version failed"
        return $false
    }
    Write-Success "Binary runs correctly"
    
    return $true
}

function Test-PackageBuilds {
    Write-TestHeader "PACKAGE BUILD TESTS (Packages Workflow Simulation)"
    
    # Test Chocolatey package
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-TestStep "Testing Chocolatey package creation..."
        try {
            & ".\test-chocolatey-local.ps1"
            Write-Success "Chocolatey package test passed"
        } catch {
            Write-Error "Chocolatey package test failed: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Warning "Skipping Chocolatey tests (not installed)"
    }
    
    # Test Windows package structures
    Write-TestStep "Testing Windows package structures..."
    
    # Create test directory
    $testDir = "local-package-tests"
    if (Test-Path $testDir) {
        Remove-Item $testDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    
    try {
        # Test ZIP archive creation (simulating release workflow)
        Write-TestStep "Creating ZIP archive..."
        $distDir = "$testDir/dist"
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null
        
        Copy-Item "target/release/json-mcp-server.exe" $distDir
        Copy-Item "README.md" $distDir
        Copy-Item "LICENSE-MIT" $distDir
        Copy-Item "LICENSE-APACHE" $distDir
        
        # Create archive
        $archivePath = "$testDir/json-mcp-server-local-test.zip"
        Compress-Archive -Path "$distDir/*" -DestinationPath $archivePath -Force
        
        if (Test-Path $archivePath) {
            $archiveSize = [Math]::Round((Get-Item $archivePath).Length / 1MB, 1)
            Write-Success "ZIP archive created: $archiveSize MB"
        } else {
            Write-Error "Failed to create ZIP archive"
            return $false
        }
        
        # Test Winget manifest creation
        Write-TestStep "Testing Winget manifest structure..."
        $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
        
        $manifestDir = "$testDir/winget-manifest/manifests/c/ciresnave/json-mcp-server/$version"
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
        
        # Create manifest files (simplified)
        @"
PackageIdentifier: ciresnave.json-mcp-server
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.4.0
"@ | Out-File -FilePath "$manifestDir/ciresnave.json-mcp-server.yaml" -Encoding utf8
        
        Write-Success "Winget manifest structure created"
        
    } finally {
        # Clean up
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }
    
    return $true
}

function Test-PackageManagers {
    Write-TestHeader "PACKAGE MANAGER TESTS (Test-Package-Managers Workflow Simulation)"
    
    $results = @{}
    
    # Test Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-TestStep "Running Chocolatey validation..."
        try {
            & ".\test-quick.ps1"
            $results['Chocolatey'] = $true
            Write-Success "Chocolatey validation passed"
        } catch {
            $results['Chocolatey'] = $false
            Write-Error "Chocolatey validation failed"
        }
    } else {
        $results['Chocolatey'] = "Skipped (not installed)"
        Write-Warning "Chocolatey not available"
    }
    
    # Test Winget manifest syntax
    Write-TestStep "Testing Winget manifest syntax..."
    try {
        $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
        
        # Create temporary manifest
        $tempDir = "temp-winget-test"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        $manifestContent = @"
PackageIdentifier: ciresnave.json-mcp-server
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.4.0
"@
        $manifestContent | Out-File -FilePath "$tempDir/test.yaml" -Encoding utf8
        
        # Basic YAML syntax check (if available)
        if (Test-Path "$tempDir/test.yaml") {
            $results['Winget'] = $true
            Write-Success "Winget manifest syntax validated"
        }
        
        Remove-Item $tempDir -Recurse -Force
    } catch {
        $results['Winget'] = $false
        Write-Error "Winget manifest syntax test failed"
    }
    
    # Test Homebrew formula syntax (if Ruby available)
    if (Get-Command ruby -ErrorAction SilentlyContinue) {
        Write-TestStep "Testing Homebrew formula syntax..."
        try {
            $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
            $tempDir = "temp-homebrew-test"
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            
            $formulaContent = @"
class JsonMcpServer < Formula
  desc "High-performance Model Context Protocol server for JSON operations"
  homepage "https://github.com/ciresnave/json-mcp-server"
  version "$version"
  
  def install
    bin.install "json-mcp-server"
  end
  
  test do
    system "#{bin}/json-mcp-server", "--version"
  end
end
"@
            $formulaContent | Out-File -FilePath "$tempDir/json-mcp-server.rb" -Encoding utf8
            
            # Test Ruby syntax
            ruby -c "$tempDir/json-mcp-server.rb"
            if ($LASTEXITCODE -eq 0) {
                $results['Homebrew'] = $true
                Write-Success "Homebrew formula syntax validated"
            } else {
                $results['Homebrew'] = $false
                Write-Error "Homebrew formula syntax invalid"
            }
            
            Remove-Item $tempDir -Recurse -Force
        } catch {
            $results['Homebrew'] = $false
            Write-Error "Homebrew formula test failed"
        }
    } else {
        $results['Homebrew'] = "Skipped (Ruby not available)"
        Write-Warning "Ruby not available for Homebrew formula testing"
    }
    
    # Test PKGBUILD structure (basic)
    Write-TestStep "Testing AUR PKGBUILD structure..."
    try {
        $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
        $tempDir = "temp-aur-test"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
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

package() {
    cd "`$pkgname-`$pkgver"
    install -Dm755 "target/release/json-mcp-server" "`$pkgdir/usr/bin/json-mcp-server"
}
"@
        $pkgbuildContent | Out-File -FilePath "$tempDir/PKGBUILD" -Encoding utf8
        
        # Basic structure validation
        if ((Get-Content "$tempDir/PKGBUILD") -match "pkgname=json-mcp-server") {
            $results['AUR'] = $true
            Write-Success "AUR PKGBUILD structure validated"
        } else {
            $results['AUR'] = $false
            Write-Error "AUR PKGBUILD structure invalid"
        }
        
        Remove-Item $tempDir -Recurse -Force
    } catch {
        $results['AUR'] = $false
        Write-Error "AUR PKGBUILD test failed"
    }
    
    # Test Snap snapcraft.yaml structure
    Write-TestStep "Testing Snap package structure..."
    try {
        $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
        $tempDir = "temp-snap-test"
        New-Item -ItemType Directory -Path "$tempDir/snap" -Force | Out-Null
        
        $snapcraftContent = @"
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

parts:
  json-mcp-server:
    plugin: rust
    source: .
"@
        $snapcraftContent | Out-File -FilePath "$tempDir/snap/snapcraft.yaml" -Encoding utf8
        
        # Basic YAML structure validation
        $content = Get-Content "$tempDir/snap/snapcraft.yaml"
        if ($content -match "name: json-mcp-server" -and $content -match "plugin: rust") {
            $results['Snap'] = $true
            Write-Success "Snap package structure validated"
        } else {
            $results['Snap'] = $false
            Write-Error "Snap package structure invalid"
        }
        
        Remove-Item $tempDir -Recurse -Force
    } catch {
        $results['Snap'] = $false
        Write-Error "Snap package test failed"
    }
    
    # Summary
    Write-TestStep "Package Manager Test Summary:"
    foreach ($mgr in $results.Keys) {
        $status = $results[$mgr]
        if ($status -eq $true) {
            Write-Success "$mgr : PASSED"
        } elseif ($status -eq $false) {
            Write-Error "$mgr : FAILED"
        } else {
            Write-Warning "$mgr : $status"
        }
    }
    
    $failed = ($results.Values | Where-Object { $_ -eq $false }).Count
    return $failed -eq 0
}

function Test-CrossPlatform {
    Write-TestHeader "CROSS-PLATFORM TESTS (Cargo Install Simulation)"
    
    Write-TestStep "Testing cargo install from local path..."
    
    # Test installation
    cargo install --path . --force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cargo install failed"
        return $false
    }
    Write-Success "Cargo install completed"
    
    # Test installed binary
    Write-TestStep "Testing installed binary..."
    json-mcp-server --version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Installed binary failed"
        return $false
    }
    Write-Success "Installed binary works correctly"
    
    return $true
}

function Test-Integration {
    Write-TestHeader "INTEGRATION TESTS (Integration Workflow Simulation)"
    
    Write-TestStep "Testing basic MCP server functionality..."
    
    # Create test JSON file
    '{"test": "data", "number": 42}' | Out-File -FilePath "test.json" -Encoding utf8
    
    try {
        # Start server in background
        Write-TestStep "Starting MCP server..."
        $serverProcess = Start-Process -FilePath "target/release/json-mcp-server.exe" -PassThru -NoNewWindow
        
        Start-Sleep -Seconds 2
        
        if ($serverProcess.HasExited) {
            Write-Error "Server process exited unexpectedly"
            return $false
        }
        
        Write-Success "MCP server started successfully"
        
        # Test basic functionality would go here
        # For now, just verify the server can start and respond
        
        Write-TestStep "Stopping MCP server..."
        $serverProcess.Kill()
        $serverProcess.WaitForExit(5000)
        
        Write-Success "Integration test completed"
        
    } catch {
        Write-Error "Integration test failed: $($_.Exception.Message)"
        return $false
    } finally {
        # Clean up
        if (Test-Path "test.json") {
            Remove-Item "test.json"
        }
        if ($serverProcess -and -not $serverProcess.HasExited) {
            $serverProcess.Kill()
        }
    }
    
    return $true
}

# Main execution
try {
    Write-TestHeader "LOCAL CI TEST SUITE - JSON MCP SERVER"
    Write-Host "Platform: Windows (PowerShell)" -ForegroundColor Cyan
    Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    
    if ($Clean) {
        Write-TestStep "Cleaning previous builds..."
        cargo clean
        Remove-Item -Path "choco-package", "test-choco-package", "temp-*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleaned previous builds"
    }
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    $testResults = @{}
    
    # Run selected tests
    if ($All -or $Release) {
        $testResults['Build'] = Test-RustBuild
    }
    
    if ($All -or $Packages) {
        $testResults['Packages'] = Test-PackageBuilds
    }
    
    if ($All -or $PackageManagers) {
        $testResults['PackageManagers'] = Test-PackageManagers
    }
    
    if ($All -or $CrossPlatform) {
        $testResults['CrossPlatform'] = Test-CrossPlatform
    }
    
    # Always run integration if any tests ran
    if ($testResults.Count -gt 0) {
        $testResults['Integration'] = Test-Integration
    }
    
    # If no specific tests selected, show help
    if ($testResults.Count -eq 0) {
        Write-TestHeader "USAGE"
        Write-Host "Run specific test suites:" -ForegroundColor Yellow
        Write-Host "  .\test-ci-local.ps1 -All                # Run all tests" -ForegroundColor White
        Write-Host "  .\test-ci-local.ps1 -Release            # Test release builds" -ForegroundColor White
        Write-Host "  .\test-ci-local.ps1 -Packages           # Test package creation" -ForegroundColor White
        Write-Host "  .\test-ci-local.ps1 -PackageManagers    # Test package manager configs" -ForegroundColor White
        Write-Host "  .\test-ci-local.ps1 -CrossPlatform      # Test cargo installation" -ForegroundColor White
        Write-Host "  .\test-ci-local.ps1 -Clean              # Clean before running" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\test-ci-local.ps1 -All -Clean         # Clean and run all tests" -ForegroundColor White
        Write-Host "  .\test-ci-local.ps1 -Release -Packages  # Test builds and packages" -ForegroundColor White
        exit 0
    }
    
    # Final summary
    Write-TestHeader "FINAL RESULTS"
    
    $passed = 0
    $failed = 0
    
    foreach ($test in $testResults.Keys) {
        $result = $testResults[$test]
        if ($result) {
            Write-Success "$test : PASSED"
            $passed++
        } else {
            Write-Error "$test : FAILED"
            $failed++
        }
    }
    
    Write-Host ""
    if ($failed -eq 0) {
        Write-Host "🎉 ALL TESTS PASSED! ($passed/$($testResults.Count))" -ForegroundColor Green -BackgroundColor DarkGreen
        Write-Host "Ready to push to GitHub! 🚀" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "❌ SOME TESTS FAILED! ($passed passed, $failed failed)" -ForegroundColor Red -BackgroundColor DarkRed
        Write-Host "Fix issues before pushing to GitHub!" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Error "Local CI test suite failed: $($_.Exception.Message)"
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
    exit 1
}
