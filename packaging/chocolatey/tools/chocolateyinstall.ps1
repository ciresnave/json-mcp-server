$ErrorActionPreference = 'Stop'

$packageName = 'json-mcp-server'
$version = '{{VERSION}}'
$url64 = "https://github.com/ciresnave/json-mcp-server/releases/download/v$version/json-mcp-server-v$version-x86_64-pc-windows-msvc.zip"
$checksum64 = '{{CHECKSUM64}}'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
  url64bit      = $url64
  checksum64    = $checksum64
  checksumType64= 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# Create shim for the executable
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$exePath = Join-Path $toolsDir "json-mcp-server.exe"

if (Test-Path $exePath) {
  Write-Host "json-mcp-server installed successfully to $exePath"
} else {
  throw "json-mcp-server.exe not found after installation"
}
