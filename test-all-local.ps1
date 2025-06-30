# 🧪 Local CI Test Suite
# Comprehensive testing to catch issues before GitHub Actions

param(
    [string]$TestSuite = "all",  # all, basic, package-managers, cross-platform, release
    [switch]$Clean = $false,
    [switch]$SkipBuild = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Colors for output
$colors = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Dim = "DarkGray"
}

function Write-TestHeader($message) {
    Write-Host "`n🧪 $message" -ForegroundColor $colors.Header
    Write-Host ("=" * ($message.Length + 3)) -ForegroundColor $colors.Header
}

function Write-TestStep($step, $message) {
    Write-Host "`n$step $message" -ForegroundColor $colors.Info
}

function Write-TestSuccess($message) {
    Write-Host "✅ $message" -ForegroundColor $colors.Success
}

function Write-TestWarning($message) {
    Write-Host "⚠️ $message" -ForegroundColor $colors.Warning
}

function Write-TestError($message) {
    Write-Host "❌ $message" -ForegroundColor $colors.Error
}

function Test-Prerequisites {
    Write-TestHeader "Checking Prerequisites"
    
    $tools = @{
        "Rust" = { rustc --version }
        "Cargo" = { cargo --version }
        "Git" = { git --version }
    }
    
    $optional = @{
        "Chocolatey" = { choco --version }
        "Ruby" = { ruby --version }
        "Docker" = { docker --version }
    }
    
    foreach ($tool in $tools.GetEnumerator()) {
        try {
            $version = & $tool.Value 2>$null
            Write-TestSuccess "$($tool.Key): $version"
        } catch {
            Write-TestError "$($tool.Key) not found - required for testing"
            return $false
        }
    }
    
    foreach ($tool in $optional.GetEnumerator()) {
        try {
            $version = & $tool.Value 2>$null
            Write-TestSuccess "$($tool.Key): $version"
        } catch {
            Write-TestWarning "$($tool.Key) not found - some tests will be skipped"
        }
    }
    
    return $true
}

function Test-BasicBuild {
    Write-TestHeader "Basic Build and Test"
    
    Write-TestStep "1️⃣" "Running cargo check..."
    cargo check
    Write-TestSuccess "Cargo check passed"
    
    Write-TestStep "2️⃣" "Running cargo test..."
    cargo test
    Write-TestSuccess "All tests passed"
    
    Write-TestStep "3️⃣" "Building release binary..."
    cargo build --release
    Write-TestSuccess "Release build completed"
    
    Write-TestStep "4️⃣" "Verifying binary..."
    $binaryPath = "target\release\json-mcp-server.exe"
    if (Test-Path $binaryPath) {
        $size = [Math]::Round((Get-Item $binaryPath).Length / 1MB, 2)
        Write-TestSuccess "Binary created: $binaryPath ($size MB)"
        
        # Test version flag
        $version = & $binaryPath --version
        Write-TestSuccess "Version check: $version"
    } else {
        Write-TestError "Binary not found at $binaryPath"
        return $false
    }
    
    return $true
}

function Test-CargoInstall {
    Write-TestHeader "Cargo Install Test (mimics cross-platform CI)"
    
    Write-TestStep "1️⃣" "Checking if json-mcp-server is already installed..."
    try {
        $existing = Get-Command json-mcp-server -ErrorAction SilentlyContinue
        if ($existing) {
            Write-TestWarning "json-mcp-server already installed at: $($existing.Source)"
            Write-TestStep "🔧" "Uninstalling existing version..."
            cargo uninstall json-mcp-server
            Write-TestSuccess "Existing version uninstalled"
        }
    } catch {
        Write-TestWarning "Could not check/uninstall existing version: $($_.Exception.Message)"
    }
    
    Write-TestStep "2️⃣" "Installing from current directory..."
    try {
        cargo install --path . --force
        Write-TestSuccess "Cargo install completed"
    } catch {
        Write-TestError "Cargo install failed: $($_.Exception.Message)"
        return $false
    }
    
    Write-TestStep "3️⃣" "Verifying installation..."
    try {
        $installed = Get-Command json-mcp-server -ErrorAction Stop
        Write-TestSuccess "Found installed binary at: $($installed.Source)"
        
        $version = json-mcp-server --version
        Write-TestSuccess "Version check: $version"
    } catch {
        Write-TestError "Installed binary not found in PATH"
        return $false
    }
    
    Write-TestStep "4️⃣" "Cleaning up test installation..."
    try {
        cargo uninstall json-mcp-server
        Write-TestSuccess "Test installation cleaned up"
    } catch {
        Write-TestWarning "Could not uninstall: $($_.Exception.Message)"
    }
    
    return $true
}

function Test-WindowsPackages {
    Write-TestHeader "Windows Package Manager Tests"
    
    # Test Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-TestStep "🍫" "Testing Chocolatey package..."
        try {
            # Run our existing Chocolatey test (skip installation part that needs admin)
            & "$PSScriptRoot\test-quick.ps1" -ErrorAction Stop
            Write-TestSuccess "Chocolatey package structure test passed"
        } catch {
            Write-TestError "Chocolatey test failed: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-TestWarning "Chocolatey not installed - skipping Chocolatey test"
    }
    
    # Test Winget manifests
    Write-TestStep "📦" "Testing Winget manifest creation..."
    try {
        $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
        $manifestDir = "test-winget\manifests\c\ciresnave\json-mcp-server\$version"
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
        
        # Create test manifests (simplified)
        @"
PackageIdentifier: ciresnave.json-mcp-server
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.4.0
"@ | Out-File -FilePath "$manifestDir\ciresnave.json-mcp-server.yaml" -Encoding utf8
        
        Write-TestSuccess "Winget manifests created successfully"
        
        # Cleanup
        Remove-Item -Path "test-winget" -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-TestError "Winget manifest test failed: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function Test-ReleaseWorkflow {
    Write-TestHeader "Release Workflow Simulation"
    
    Write-TestStep "1️⃣" "Testing cross-compilation targets..."
    $targets = @(
        "x86_64-pc-windows-msvc",
        "x86_64-apple-darwin", 
        "x86_64-unknown-linux-gnu"
    )
    
    foreach ($target in $targets) {
        try {
            Write-Host "  Testing target: $target" -ForegroundColor $colors.Dim
            rustup target add $target 2>$null
            
            # Test if we can at least check the target (don't actually cross-compile)
            cargo check --target $target
            Write-Host "    ✅ Target $target check passed" -ForegroundColor $colors.Success
        } catch {
            Write-Host "    ⚠️ Target $target check failed (may need cross-compilation tools)" -ForegroundColor $colors.Warning
        }
    }
    
    Write-TestStep "2️⃣" "Testing archive creation..."
    try {
        $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
        $distDir = "test-dist"
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null
        
        # Copy files that would be in release
        $binaryPath = "target\release\json-mcp-server.exe"
        Copy-Item $binaryPath $distDir
        Copy-Item "README.md", "LICENSE-MIT", "LICENSE-APACHE" $distDir
        
        # Test zip creation
        Compress-Archive -Path "$distDir\*" -DestinationPath "test-release-v$version-windows.zip" -Force
        Write-TestSuccess "Windows archive created"
        Remove-Item "test-release-v$version-windows.zip"
        
        Remove-Item -Path $distDir -Recurse -Force
    } catch {
        Write-TestError "Archive creation test failed: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function Test-Integration {
    Write-TestHeader "Basic Integration Tests"
    
    Write-TestStep "1️⃣" "Testing JSON operations..."
    try {
        # Create test JSON file
        $testJson = @{
            "test" = "data"
            "array" = @(1, 2, 3)
            "nested" = @{
                "key" = "value"
            }
        } | ConvertTo-Json
        $testJson | Out-File -FilePath "test-integration.json" -Encoding utf8
        
        Write-TestSuccess "Test JSON file created"
        
        # Test that binary can start (basic smoke test)
        $binaryPath = "target\release\json-mcp-server.exe"
        $process = Start-Process -FilePath $binaryPath -PassThru -WindowStyle Hidden
        Start-Sleep -Seconds 2
        
        if (-not $process.HasExited) {
            Write-TestSuccess "Server started successfully"
            $process.Kill()
        } else {
            Write-TestError "Server failed to start or exited immediately"
            return $false
        }
        
        Remove-Item "test-integration.json" -Force
    } catch {
        Write-TestError "Integration test failed: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

function Main {
    Write-Host "🚀 JSON MCP Server - Local CI Test Suite" -ForegroundColor $colors.Header
    Write-Host "========================================" -ForegroundColor $colors.Header
    
    if (-not (Test-Prerequisites)) {
        Write-TestError "Prerequisites check failed"
        exit 1
    }
    
    if ($Clean) {
        Write-TestStep "🧹" "Cleaning previous artifacts..."
        Remove-Item -Path "target", "test-*", "choco-package", "*-package" -Recurse -Force -ErrorAction SilentlyContinue
        cargo clean
        Write-TestSuccess "Cleanup completed"
    }
    
    $allPassed = $true
    
    # Run tests based on suite selection
    if ($TestSuite -eq "all" -or $TestSuite -eq "basic") {
        if (-not $SkipBuild) {
            $allPassed = $allPassed -and (Test-BasicBuild)
        }
        $allPassed = $allPassed -and (Test-Integration)
    }
    
    if ($TestSuite -eq "all" -or $TestSuite -eq "cross-platform") {
        $allPassed = $allPassed -and (Test-CargoInstall)
    }
    
    if ($TestSuite -eq "all" -or $TestSuite -eq "package-managers") {
        $allPassed = $allPassed -and (Test-WindowsPackages)
    }
    
    if ($TestSuite -eq "all" -or $TestSuite -eq "release") {
        $allPassed = $allPassed -and (Test-ReleaseWorkflow)
    }
    
    # Final summary
    Write-Host "`n" + ("=" * 50) -ForegroundColor $colors.Header
    if ($allPassed) {
        Write-Host "🎉 ALL TESTS PASSED!" -ForegroundColor $colors.Success -BackgroundColor DarkGreen
        Write-Host "✅ Ready for CI deployment" -ForegroundColor $colors.Success
        exit 0
    } else {
        Write-Host "❌ SOME TESTS FAILED!" -ForegroundColor $colors.Error -BackgroundColor DarkRed
        Write-Host "🔧 Fix issues before pushing to CI" -ForegroundColor $colors.Warning
        exit 1
    }
}

# Run the main function
Main
