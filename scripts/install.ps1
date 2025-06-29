# JSON MCP Server Installation Script for Windows PowerShell
# Supports installation via Cargo, pre-built binaries, and package managers

param(
    [string]$Version = "latest",
    [string]$Method = "auto",
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Repo = "ciresnave/json-mcp-server"

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Get-Architecture {
    $arch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
    switch ($arch) {
        "AMD64" { return "x86_64" }
        "ARM64" { return "aarch64" }
        default { return "unknown" }
    }
}

function Install-ViaCargoFunction {
    Write-Info "Installing via Cargo..."
    
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Write-Error "Cargo not found. Please install Rust first: https://rustup.rs/"
        throw "Cargo not available"
    }
    
    try {
        & cargo install json-mcp-server
        Write-Success "Installed json-mcp-server via Cargo"
    }
    catch {
        Write-Error "Failed to install via Cargo: $($_.Exception.Message)"
        throw
    }
}

function Install-BinaryFunction {
    $arch = Get-Architecture
    Write-Info "Installing pre-built binary for Windows-$arch..."
    
    # Determine target triple
    $target = switch ($arch) {
        "x86_64" { "x86_64-pc-windows-msvc" }
        "aarch64" { "aarch64-pc-windows-msvc" }
        default {
            Write-Error "No pre-built binary available for Windows-$arch"
            throw "Unsupported architecture"
        }
    }
    
    # Get download URL
    try {
        if ($Version -eq "latest") {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
            $asset = $releases.assets | Where-Object { $_.name -like "*$target*" } | Select-Object -First 1
            if (-not $asset) {
                throw "No asset found for target $target"
            }
            $downloadUrl = $asset.browser_download_url
        }
        else {
            $downloadUrl = "https://github.com/$Repo/releases/download/v$Version/json-mcp-server-v$Version-$target.zip"
        }
    }
    catch {
        Write-Error "Could not find binary for $target version $Version"
        throw
    }
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "json-mcp-server-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        # Download binary
        $archiveFile = Join-Path $tempDir "json-mcp-server.zip"
        Write-Info "Downloading $downloadUrl..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archiveFile -UseBasicParsing
        
        # Extract archive
        Write-Info "Extracting archive..."
        Expand-Archive -Path $archiveFile -DestinationPath $tempDir -Force
        
        # Find the binary
        $binaryPath = Get-ChildItem -Path $tempDir -Name "json-mcp-server.exe" -Recurse | Select-Object -First 1
        if (-not $binaryPath) {
            throw "Could not find json-mcp-server.exe in downloaded archive"
        }
        $binaryPath = Join-Path $tempDir $binaryPath
        
        # Install to user programs directory
        $installDir = Join-Path $env:LOCALAPPDATA "Programs\json-mcp-server"
        if (-not (Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
        
        $targetPath = Join-Path $installDir "json-mcp-server.exe"
        Copy-Item -Path $binaryPath -Destination $targetPath -Force
        
        Write-Success "Installed json-mcp-server to $installDir"
        
        # Check if directory is in PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$installDir*") {
            Write-Warning "$installDir is not in your PATH."
            Write-Info "Add it by running:"
            Write-Info "`$env:PATH += ';$installDir'"
            Write-Info "Or permanently: [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$installDir', 'User')"
        }
    }
    finally {
        # Cleanup
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-ChocolateyFunction {
    Write-Info "Installing via Chocolatey..."
    
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey not found. Please install Chocolatey first: https://chocolatey.org/"
        throw "Chocolatey not available"
    }
    
    # Note: This would be for future Chocolatey package
    Write-Warning "Chocolatey package not yet available. Using binary installation instead."
    Install-BinaryFunction
}

function Install-WingetFunction {
    Write-Info "Installing via Winget..."
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "Winget not found. Please install App Installer from Microsoft Store."
        throw "Winget not available"
    }
    
    # Note: This would be for future Winget package
    Write-Warning "Winget package not yet available. Using binary installation instead."
    Install-BinaryFunction
}

function Show-Usage {
    Write-Host "JSON MCP Server Installation Script for Windows PowerShell"
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [-Version VERSION] [-Method METHOD] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Version    Version to install (default: latest)"
    Write-Host "  -Method     Installation method (default: auto-detect)"
    Write-Host "              - cargo: Install via Cargo"
    Write-Host "              - binary: Install pre-built binary"
    Write-Host "              - choco: Install via Chocolatey (future)"
    Write-Host "              - winget: Install via Winget (future)"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1                           # Install latest version (auto-detect method)"
    Write-Host "  .\install.ps1 -Version 0.1.0            # Install version 0.1.0 (auto-detect method)"
    Write-Host "  .\install.ps1 -Version latest -Method cargo # Install latest version via Cargo"
    Write-Host "  .\install.ps1 -Version 0.1.0 -Method binary # Install version 0.1.0 as binary"
}

function Main {
    if ($Help) {
        Show-Usage
        return
    }
    
    Write-Info "JSON MCP Server Installation Script for Windows PowerShell"
    Write-Info "Version: $Version, Method: $Method"
    
    # Auto-detect method if not specified
    if ($Method -eq "auto") {
        if (Get-Command cargo -ErrorAction SilentlyContinue) {
            $Method = "cargo"
        }
        else {
            $Method = "binary"
        }
        Write-Info "Auto-detected installation method: $Method"
    }
    
    # Install based on method
    try {
        switch ($Method) {
            "cargo" { Install-ViaCargoFunction }
            "binary" { Install-BinaryFunction }
            "choco" { Install-ChocolateyFunction }
            "winget" { Install-WingetFunction }
            default {
                Write-Error "Unknown installation method: $Method"
                Show-Usage
                throw "Invalid method"
            }
        }
        
        # Verify installation
        $jsonMcpServer = Get-Command json-mcp-server -ErrorAction SilentlyContinue
        if ($jsonMcpServer) {
            try {
                $installedVersion = & json-mcp-server --version 2>$null
                if (-not $installedVersion) { $installedVersion = "unknown" }
            }
            catch {
                $installedVersion = "unknown"
            }
            
            Write-Success "Installation completed successfully!"
            Write-Info "Installed version: $installedVersion"
            Write-Info "Try running: json-mcp-server --help"
        }
        else {
            Write-Warning "Installation may have succeeded, but json-mcp-server not found in PATH."
            Write-Info "You may need to restart your terminal or add the installation directory to PATH."
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run main function
Main
