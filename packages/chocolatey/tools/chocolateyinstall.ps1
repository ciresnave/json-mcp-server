$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "json-mcp-server.exe"

if (-not (Test-Path $exePath)) {
    throw "Binary not found at $exePath"
}

Write-Host "json-mcp-server installed successfully to $exePath"
