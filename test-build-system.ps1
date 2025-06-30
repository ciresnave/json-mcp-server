# Quick Build System Test
# Tests core functionality without requiring admin rights

Write-Host "🧪 Testing Build System" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Step 1: Basic build
Write-Host "📦 Building release binary..." -ForegroundColor Yellow
$result = cargo build --release
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Binary built successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Step 2: Test binary exists
$binaryPath = "target\release\json-mcp-server.exe"
if (Test-Path $binaryPath) {
    $size = (Get-Item $binaryPath).Length / 1MB
    Write-Host "✅ Binary exists: $binaryPath (${size:F1} MB)" -ForegroundColor Green
} else {
    Write-Host "❌ Binary not found: $binaryPath" -ForegroundColor Red
    exit 1
}

# Step 3: Test binary functionality
Write-Host "🔧 Testing binary functionality..." -ForegroundColor Yellow
$testResult = & $binaryPath --help 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Binary runs successfully" -ForegroundColor Green
    Write-Host "📋 Help output sample:" -ForegroundColor Gray
    $testResult | Select-Object -First 3 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "❌ Binary execution failed" -ForegroundColor Red
    Write-Host "Error: $testResult" -ForegroundColor Red
    exit 1
}

# Step 4: Package structure test
Write-Host "📁 Testing package creation..." -ForegroundColor Yellow
if (Test-Path "choco-package") {
    Remove-Item -Recurse -Force "choco-package"
}
New-Item -ItemType Directory -Path "choco-package\tools" -Force | Out-Null
Copy-Item $binaryPath "choco-package\tools\" -Force

if (Test-Path "choco-package\tools\json-mcp-server.exe") {
    Write-Host "✅ Package structure created successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Package structure creation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 All build system tests passed!" -ForegroundColor Green
Write-Host "✅ Binary compilation works" -ForegroundColor Green
Write-Host "✅ Binary functionality verified" -ForegroundColor Green
Write-Host "✅ Package structure creation works" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Ready for deployment!" -ForegroundColor Cyan
