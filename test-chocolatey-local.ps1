# Local Chocolatey Package Test Script
# This simulates the GitHub Actions workflow locally

param(
    [switch]$Clean = $false
)

Write-Host "🧪 Testing Chocolatey Package Creation Locally" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Clean up from previous runs if requested
if ($Clean) {
    Write-Host "🧹 Cleaning up from previous runs..." -ForegroundColor Yellow
    Remove-Item -Path "choco-package" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "*.nupkg" -Force -ErrorAction SilentlyContinue
}

try {
    # Step 1: Build the Rust binary
    Write-Host "`n📦 Step 1: Building Rust binary..." -ForegroundColor Green
    cargo build --release
    if ($LASTEXITCODE -ne 0) {
        throw "Cargo build failed"
    }
    
    # Verify binary exists
    $binaryPath = "target\release\json-mcp-server.exe"
    if (-not (Test-Path $binaryPath)) {
        throw "Binary not found at $binaryPath"
    }
    Write-Host "✅ Binary built successfully: $binaryPath" -ForegroundColor Green
    
    # Step 2: Create package directory
    Write-Host "`n📁 Step 2: Creating package structure..." -ForegroundColor Green
    $packageDir = "choco-package"
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$packageDir\tools" -Force | Out-Null
    
    # Step 3: Copy binary to package
    Write-Host "`n📋 Step 3: Copying binary to package..." -ForegroundColor Green
    Copy-Item $binaryPath "$packageDir\tools\json-mcp-server.exe" -Force
    
    # Verify the copy worked
    if (-not (Test-Path "$packageDir\tools\json-mcp-server.exe")) {
        throw "Failed to copy binary to package tools directory"
    }
    Write-Host "✅ Binary copied to package: $packageDir\tools\json-mcp-server.exe" -ForegroundColor Green
    
    # Step 4: Create nuspec file
    Write-Host "`n📝 Step 4: Creating nuspec file..." -ForegroundColor Green
    $version = (Select-String -Path "Cargo.toml" -Pattern 'version = "([^"]+)"').Matches[0].Groups[1].Value
    Write-Host "📊 Detected version: $version" -ForegroundColor Cyan
    
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
    
    $nuspecContent | Out-File -FilePath "$packageDir\json-mcp-server.nuspec" -Encoding utf8
    Write-Host "✅ Nuspec file created" -ForegroundColor Green
    
    # Step 5: Create install script
    Write-Host "`n⚙️ Step 5: Creating install script..." -ForegroundColor Green
    $installScript = @'
$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "json-mcp-server.exe"

# Binary is already in the tools directory, just verify it exists
if (-not (Test-Path $exePath)) {
    throw "Binary not found at $exePath"
}

Write-Host "json-mcp-server installed successfully to $exePath"
'@
    
    $installScript | Out-File -FilePath "$packageDir\tools\chocolateyinstall.ps1" -Encoding utf8
    Write-Host "✅ Install script created" -ForegroundColor Green
    
    # Step 6: List package contents for verification
    Write-Host "`n📋 Step 6: Package contents verification..." -ForegroundColor Green
    Write-Host "Package structure:" -ForegroundColor Cyan
    Get-ChildItem -Path $packageDir -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
        if ($_.PSIsContainer) {
            Write-Host "  📁 $relativePath\" -ForegroundColor Yellow
        } else {
            $size = if ($_.Length -gt 1MB) { "{0:N1} MB" -f ($_.Length / 1MB) } 
                   elseif ($_.Length -gt 1KB) { "{0:N1} KB" -f ($_.Length / 1KB) }
                   else { "$($_.Length) bytes" }
            Write-Host "  📄 $relativePath ($size)" -ForegroundColor White
        }
    }
    
    # Step 7: Check if Chocolatey is available
    Write-Host "`n🍫 Step 7: Checking Chocolatey availability..." -ForegroundColor Green
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️ Chocolatey not found. To continue with full testing:" -ForegroundColor Yellow
        Write-Host "   1. Install Chocolatey: https://chocolatey.org/install" -ForegroundColor Yellow
        Write-Host "   2. Restart PowerShell as Administrator" -ForegroundColor Yellow
        Write-Host "   3. Run this script again" -ForegroundColor Yellow
        Write-Host "✅ Package creation completed successfully! (Installation test skipped)" -ForegroundColor Green
        return
    }
    
    # Step 8: Build package
    Write-Host "`n📦 Step 8: Building Chocolatey package..." -ForegroundColor Green
    Push-Location $packageDir
    try {
        choco pack
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey pack failed"
        }
        
        $nupkgFile = Get-ChildItem -Filter "*.nupkg" | Select-Object -First 1
        if (-not $nupkgFile) {
            throw "No .nupkg file was created"
        }
        Write-Host "✅ Package created: $($nupkgFile.Name)" -ForegroundColor Green
        
        # Step 9: Test installation
        Write-Host "`n🚀 Step 9: Testing package installation..." -ForegroundColor Green
        choco install json-mcp-server -s . -y --force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Package installed successfully!" -ForegroundColor Green
            
            # Step 10: Verify installation
            Write-Host "`n✔️ Step 10: Verifying installation..." -ForegroundColor Green
            if (Get-Command json-mcp-server -ErrorAction SilentlyContinue) {
                Write-Host "✅ json-mcp-server command is available!" -ForegroundColor Green
                Write-Host "📊 Version check:" -ForegroundColor Cyan
                json-mcp-server --version
                
                Write-Host "`n🎉 SUCCESS: Chocolatey package works perfectly!" -ForegroundColor Green -BackgroundColor DarkGreen
                
                # Clean up test installation
                Write-Host "`n🧹 Cleaning up test installation..." -ForegroundColor Yellow
                choco uninstall json-mcp-server -y
                
            } else {
                Write-Host "❌ Command not found after installation" -ForegroundColor Red
                return 1
            }
        } else {
            Write-Host "❌ Package installation failed" -ForegroundColor Red
            return 1
        }
        
    } finally {
        Pop-Location
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "📍 Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    return 1
}

Write-Host "`n🎯 All tests completed successfully!" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "The Chocolatey package is ready for deployment! 🚀" -ForegroundColor Cyan
