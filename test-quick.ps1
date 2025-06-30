# Quick Chocolatey Package Structure Test
# Tests just the package creation without installation

Write-Host "🔍 Quick Package Structure Test" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Clean up
Remove-Item -Path "test-choco-package" -Recurse -Force -ErrorAction SilentlyContinue

# Step 1: Build binary
Write-Host "`n1️⃣ Building binary..." -ForegroundColor Green
cargo build --release

# Step 2: Create package structure (simulating GitHub Actions)
Write-Host "`n2️⃣ Creating package structure..." -ForegroundColor Green
$packageDir = "test-choco-package"
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir\tools" -Force | Out-Null

# Step 3: Copy binary BEFORE building package (key fix)
Write-Host "`n3️⃣ Copying binary to package..." -ForegroundColor Green
Copy-Item "target\release\json-mcp-server.exe" "$packageDir\tools\json-mcp-server.exe" -Force

# Step 4: Create install script that just verifies the binary exists
Write-Host "`n4️⃣ Creating install script..." -ForegroundColor Green
$installScript = @'
$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "json-mcp-server.exe"

Write-Host "Looking for binary at: $exePath"

# Binary should already be in the tools directory
if (-not (Test-Path $exePath)) {
    throw "ERROR: Binary not found at $exePath"
}

Write-Host "SUCCESS: Binary found at $exePath"
Write-Host "json-mcp-server installed successfully!"

# Test the binary
& $exePath --version
'@

$installScript | Out-File -FilePath "$packageDir\tools\chocolateyinstall.ps1" -Encoding utf8

# Step 5: Show what we created
Write-Host "`n5️⃣ Package contents:" -ForegroundColor Green
Get-ChildItem -Path $packageDir -Recurse | ForEach-Object {
    $indent = "  " * (($_.FullName.Split('\').Count) - ($packageDir.Split('\').Count) - 1)
    if ($_.PSIsContainer) {
        Write-Host "$indent📁 $($_.Name)\" -ForegroundColor Yellow
    } else {
        $size = [Math]::Round($_.Length / 1KB, 1)
        Write-Host "$indent📄 $($_.Name) ($size KB)" -ForegroundColor White
    }
}

# Step 6: Test the install script directly
Write-Host "`n6️⃣ Testing install script directly..." -ForegroundColor Green
Push-Location "$packageDir\tools"
try {
    & .\chocolateyinstall.ps1
    Write-Host "`n✅ SUCCESS: Install script works correctly!" -ForegroundColor Green -BackgroundColor DarkGreen
} catch {
    Write-Host "`n❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor DarkRed
} finally {
    Pop-Location
}

Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "- Binary copied to package tools directory: $(Test-Path "$packageDir\tools\json-mcp-server.exe")" -ForegroundColor White
Write-Host "- Install script created: $(Test-Path "$packageDir\tools\chocolateyinstall.ps1")" -ForegroundColor White
Write-Host "- Install script test: See above results" -ForegroundColor White
