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
