$ErrorActionPreference = 'Stop'

$packageName = 'json-mcp-server'

# Remove from PATH if added by installer
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "json-mcp-server.exe"

if (Test-Path $exePath) {
  Write-Host "Removing json-mcp-server from $exePath"
  Remove-Item $exePath -Force -ErrorAction SilentlyContinue
}

Write-Host "json-mcp-server has been uninstalled."
