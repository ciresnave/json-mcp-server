# Package Testing and Validation Script for Windows PowerShell

param(
    [string]$PackageManager = "all",
    [string]$Version,
    [switch]$SkipDownloads,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Show-Usage {
    Write-Host "Package Testing Script for json-mcp-server"
    Write-Host ""
    Write-Host "Usage: .\test-packages.ps1 [-PackageManager <manager>] [-Version <version>] [-SkipDownloads] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -PackageManager    Package manager to test (chocolatey, winget, all) [default: all]"
    Write-Host "  -Version          Version to test [default: current from Cargo.toml]"
    Write-Host "  -SkipDownloads    Skip downloading files for checksum validation"
    Write-Host "  -Help             Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\test-packages.ps1                               # Test all Windows package managers"
    Write-Host "  .\test-packages.ps1 -PackageManager chocolatey    # Test only Chocolatey"
    Write-Host "  .\test-packages.ps1 -Version 0.1.0               # Test specific version"
}

function Get-Version {
    if ($Version) {
        return $Version
    }
    
    $cargoToml = Get-Content "Cargo.toml" -Raw
    if ($cargoToml -match 'version\s*=\s*"([^"]+)"') {
        return $Matches[1]
    }
    
    throw "Could not determine version from Cargo.toml"
}

function Get-FileChecksum {
    param([string]$FilePath)
    
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    return $hash.Hash.ToLower()
}

function Get-RemoteChecksum {
    param([string]$Url)
    
    if ($SkipDownloads) {
        Write-Warning "Skipping download of $Url"
        return "SKIP"
    }
    
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Write-Info "Downloading $Url for checksum validation..."
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing
        $checksum = Get-FileChecksum -FilePath $tempFile
        Remove-Item $tempFile -Force
        return $checksum
    }
    catch {
        Write-Warning "Could not download $Url for checksum: $($_.Exception.Message)"
        return "DOWNLOAD_FAILED"
    }
}

function Test-Chocolatey {
    param([string]$TestVersion)
    
    Write-Info "Testing Chocolatey package generation and validation..."
    
    # Check if Chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Warning "Chocolatey not installed. Installing..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    # Create test directory
    $testDir = Join-Path $env:TEMP "choco-test-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    
    try {
        # Copy Chocolatey package files
        $chocoSource = "packaging\chocolatey"
        if (-not (Test-Path $chocoSource)) {
            throw "Chocolatey package source not found at $chocoSource"
        }
        
        Copy-Item -Path "$chocoSource\*" -Destination $testDir -Recurse -Force
        
        # Get checksum for validation
        $winUrl = "https://github.com/ciresnave/json-mcp-server/releases/download/v$TestVersion/json-mcp-server-v$TestVersion-x86_64-pc-windows-msvc.zip"
        $checksum = Get-RemoteChecksum -Url $winUrl
        
        # Replace placeholders
        $nuspecFile = Join-Path $testDir "json-mcp-server.nuspec"
        $installScript = Join-Path $testDir "tools\chocolateyinstall.ps1"
        
        if (Test-Path $nuspecFile) {
            (Get-Content $nuspecFile) -replace '{{VERSION}}', $TestVersion | Set-Content $nuspecFile
        }
        
        if (Test-Path $installScript) {
            (Get-Content $installScript) -replace '{{VERSION}}', $TestVersion | Set-Content $installScript
            (Get-Content $installScript) -replace '{{CHECKSUM64}}', $checksum | Set-Content $installScript
        }
        
        # Build package
        Push-Location $testDir
        try {
            choco pack
            
            # Validate package
            $packageFile = Get-ChildItem -Path . -Filter "*.nupkg" | Select-Object -First 1
            if ($packageFile) {
                Write-Success "Chocolatey package built successfully: $($packageFile.Name)"
                
                # Test installation (if not in CI)
                if (-not $env:GITHUB_ACTIONS) {
                    Write-Info "Testing package installation..."
                    choco install json-mcp-server -s . -y --force
                    
                    # Verify installation
                    if (Get-Command json-mcp-server -ErrorAction SilentlyContinue) {
                        Write-Success "Chocolatey package installation test passed"
                        & json-mcp-server --version
                        
                        # Cleanup
                        choco uninstall json-mcp-server -y
                    } else {
                        Write-Error "Chocolatey package installation test failed"
                    }
                }
            } else {
                Write-Error "No .nupkg file generated"
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        # Cleanup
        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-Winget {
    param([string]$TestVersion)
    
    Write-Info "Testing Winget manifest generation and validation..."
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "Winget not available. Install from Microsoft Store or skip this test."
        return
    }
    
    # Create test directory
    $testDir = Join-Path $env:TEMP "winget-test-$(Get-Random)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    
    try {
        # Copy Winget manifest files
        $wingetSource = "packaging\winget"
        if (-not (Test-Path $wingetSource)) {
            throw "Winget manifest source not found at $wingetSource"
        }
        
        Copy-Item -Path "$wingetSource\*" -Destination $testDir -Recurse -Force
        
        # Get checksums for validation
        $winX64Url = "https://github.com/ciresnave/json-mcp-server/releases/download/v$TestVersion/json-mcp-server-v$TestVersion-x86_64-pc-windows-msvc.zip"
        $winArm64Url = "https://github.com/ciresnave/json-mcp-server/releases/download/v$TestVersion/json-mcp-server-v$TestVersion-aarch64-pc-windows-msvc.zip"
        
        $checksumX64 = Get-RemoteChecksum -Url $winX64Url
        $checksumArm64 = Get-RemoteChecksum -Url $winArm64Url
        $releaseDate = Get-Date -Format "yyyy-MM-dd"
        
        # Replace placeholders in all YAML files
        Get-ChildItem -Path $testDir -Filter "*.yaml" | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            $content = $content -replace '{{VERSION}}', $TestVersion
            $content = $content -replace '{{INSTALLER_SHA256}}', $checksumX64
            $content = $content -replace '{{INSTALLER_SHA256_ARM64}}', $checksumArm64
            $content = $content -replace '{{RELEASE_DATE}}', $releaseDate
            Set-Content -Path $_.FullName -Value $content
        }
        
        # Validate manifests
        Write-Info "Validating Winget manifests..."
        winget validate $testDir
        
        Write-Success "Winget manifest validation passed"
    }
    catch {
        Write-Error "Winget manifest validation failed: $($_.Exception.Message)"
    }
    finally {
        # Cleanup
        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-AllPackages {
    param([string]$TestVersion)
    
    Write-Info "Testing all Windows package managers for version $TestVersion"
    
    $results = @()
    
    try {
        Test-Chocolatey -TestVersion $TestVersion
        $results += "✅ Chocolatey"
    }
    catch {
        Write-Error "Chocolatey test failed: $($_.Exception.Message)"
        $results += "❌ Chocolatey"
    }
    
    try {
        Test-Winget -TestVersion $TestVersion
        $results += "✅ Winget"
    }
    catch {
        Write-Error "Winget test failed: $($_.Exception.Message)"
        $results += "❌ Winget"
    }
    
    Write-Host ""
    Write-Host "Package Manager Test Results:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    $results | ForEach-Object { Write-Host $_ }
    Write-Host ""
}

function Main {
    if ($Help) {
        Show-Usage
        return
    }
    
    $testVersion = Get-Version
    Write-Info "Testing packages for json-mcp-server v$testVersion"
    
    switch ($PackageManager.ToLower()) {
        "chocolatey" { Test-Chocolatey -TestVersion $testVersion }
        "choco" { Test-Chocolatey -TestVersion $testVersion }
        "winget" { Test-Winget -TestVersion $testVersion }
        "all" { Test-AllPackages -TestVersion $testVersion }
        default {
            Write-Error "Unknown package manager: $PackageManager"
            Show-Usage
            exit 1
        }
    }
}

# Run main function
Main
