@echo off
setlocal EnableDelayedExpansion

REM JSON MCP Server Installation Script for Windows
REM Supports installation via Cargo, pre-built binaries, and Chocolatey (future)

set "VERSION=%~1"
set "METHOD=%~2"
set "REPO=ciresnave/json-mcp-server"

if "%VERSION%"=="" set "VERSION=latest"
if "%METHOD%"=="" set "METHOD=auto"

REM Color codes (limited support on Windows)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

goto main

:print_info
echo %INFO% %~1
goto :eof

:print_success
echo %SUCCESS% %~1
goto :eof

:print_warning
echo %WARNING% %~1
goto :eof

:print_error
echo %ERROR% %~1
goto :eof

:detect_arch
for /f "tokens=*" %%i in ('wmic computersystem get systemtype /value ^| find "="') do (
    set "%%i"
)
if "%systemtype%"=="x64-based PC" (
    set "ARCH=x86_64"
) else if "%systemtype%"=="ARM64-based PC" (
    set "ARCH=aarch64"
) else (
    set "ARCH=unknown"
)
goto :eof

:install_via_cargo
call :print_info "Installing via Cargo..."
where cargo >nul 2>&1
if errorlevel 1 (
    call :print_error "Cargo not found. Please install Rust first: https://rustup.rs/"
    exit /b 1
)

cargo install json-mcp-server
if errorlevel 1 (
    call :print_error "Failed to install via Cargo"
    exit /b 1
)

call :print_success "Installed json-mcp-server via Cargo"
goto :eof

:install_binary
call :detect_arch
call :print_info "Installing pre-built binary for Windows-%ARCH%..."

REM Determine target triple
if "%ARCH%"=="x86_64" (
    set "TARGET=x86_64-pc-windows-msvc"
) else if "%ARCH%"=="aarch64" (
    set "TARGET=aarch64-pc-windows-msvc"
) else (
    call :print_error "No pre-built binary available for Windows-%ARCH%"
    exit /b 1
)

REM Create temp directory
set "TEMP_DIR=%TEMP%\json-mcp-server-install-%RANDOM%"
mkdir "%TEMP_DIR%"

REM Download binary using PowerShell
if "%VERSION%"=="latest" (
    set "PS_SCRIPT=$releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO%/releases/latest'; $asset = $releases.assets ^| Where-Object { $_.name -like '*%TARGET%*' } ^| Select-Object -First 1; if ($asset) { $asset.browser_download_url } else { '' }"
) else (
    set "PS_SCRIPT=Write-Output 'https://github.com/%REPO%/releases/download/v%VERSION%/json-mcp-server-v%VERSION%-%TARGET%.zip'"
)

for /f "usebackq delims=" %%i in (`powershell -Command "!PS_SCRIPT!"`) do set "DOWNLOAD_URL=%%i"

if "%DOWNLOAD_URL%"=="" (
    call :print_error "Could not find binary for %TARGET% version %VERSION%"
    rmdir /s /q "%TEMP_DIR%"
    exit /b 1
)

call :print_info "Downloading %DOWNLOAD_URL%..."
set "ARCHIVE_FILE=%TEMP_DIR%\json-mcp-server.zip"
powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ARCHIVE_FILE%'"

if errorlevel 1 (
    call :print_error "Failed to download binary"
    rmdir /s /q "%TEMP_DIR%"
    exit /b 1
)

REM Extract archive
call :print_info "Extracting archive..."
powershell -Command "Expand-Archive -Path '%ARCHIVE_FILE%' -DestinationPath '%TEMP_DIR%' -Force"

REM Find the binary
for /r "%TEMP_DIR%" %%f in (json-mcp-server.exe) do (
    if exist "%%f" set "BINARY_PATH=%%f"
)

if "%BINARY_PATH%"=="" (
    call :print_error "Could not find json-mcp-server.exe in downloaded archive"
    rmdir /s /q "%TEMP_DIR%"
    exit /b 1
)

REM Install to Program Files or user directory
set "INSTALL_DIR=%LOCALAPPDATA%\Programs\json-mcp-server"
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy "%BINARY_PATH%" "%INSTALL_DIR%\json-mcp-server.exe" >nul
if errorlevel 1 (
    call :print_error "Failed to copy binary to %INSTALL_DIR%"
    rmdir /s /q "%TEMP_DIR%"
    exit /b 1
)

REM Cleanup
rmdir /s /q "%TEMP_DIR%"

call :print_success "Installed json-mcp-server to %INSTALL_DIR%"

REM Check if directory is in PATH
echo %PATH% | findstr /i "%INSTALL_DIR%" >nul
if errorlevel 1 (
    call :print_warning "%INSTALL_DIR% is not in your PATH."
    call :print_info "Add it manually or run:"
    call :print_info "setx PATH \"%%PATH%%;%INSTALL_DIR%\""
    call :print_info "Then restart your command prompt."
)

goto :eof

:install_chocolatey
call :print_info "Installing via Chocolatey..."
where choco >nul 2>&1
if errorlevel 1 (
    call :print_error "Chocolatey not found. Please install Chocolatey first: https://chocolatey.org/"
    exit /b 1
)

REM Note: This would be for future Chocolatey package
call :print_warning "Chocolatey package not yet available. Using binary installation instead."
call :install_binary
goto :eof

:install_winget
call :print_info "Installing via Winget..."
where winget >nul 2>&1
if errorlevel 1 (
    call :print_error "Winget not found. Please install App Installer from Microsoft Store."
    exit /b 1
)

REM Note: This would be for future Winget package
call :print_warning "Winget package not yet available. Using binary installation instead."
call :install_binary
goto :eof

:show_usage
echo JSON MCP Server Installation Script for Windows
echo.
echo Usage: %0 [VERSION] [METHOD]
echo.
echo VERSION: Version to install (default: latest)
echo METHOD:  Installation method (default: auto-detect)
echo          - cargo: Install via Cargo
echo          - binary: Install pre-built binary
echo          - choco: Install via Chocolatey (future)
echo          - winget: Install via Winget (future)
echo.
echo Examples:
echo   %0                    # Install latest version (auto-detect method)
echo   %0 0.1.0              # Install version 0.1.0 (auto-detect method)
echo   %0 latest cargo       # Install latest version via Cargo
echo   %0 0.1.0 binary       # Install version 0.1.0 as binary
goto :eof

:main
if "%~1"=="--help" goto show_usage
if "%~1"=="-h" goto show_usage
if "%~1"=="/?" goto show_usage

call :print_info "JSON MCP Server Installation Script for Windows"
call :print_info "Version: %VERSION%, Method: %METHOD%"

REM Auto-detect method if not specified
if "%METHOD%"=="auto" (
    where cargo >nul 2>&1
    if not errorlevel 1 (
        set "METHOD=cargo"
    ) else (
        set "METHOD=binary"
    )
    call :print_info "Auto-detected installation method: !METHOD!"
)

REM Install based on method
if "%METHOD%"=="cargo" (
    call :install_via_cargo
) else if "%METHOD%"=="binary" (
    call :install_binary
) else if "%METHOD%"=="choco" (
    call :install_chocolatey
) else if "%METHOD%"=="winget" (
    call :install_winget
) else (
    call :print_error "Unknown installation method: %METHOD%"
    call :show_usage
    exit /b 1
)

if errorlevel 1 exit /b 1

REM Verify installation
where json-mcp-server >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('json-mcp-server --version 2^>nul') do set "INSTALLED_VERSION=%%i"
    if "!INSTALLED_VERSION!"=="" set "INSTALLED_VERSION=unknown"
    call :print_success "Installation completed successfully!"
    call :print_info "Installed version: !INSTALLED_VERSION!"
    call :print_info "Try running: json-mcp-server --help"
) else (
    call :print_error "Installation may have failed. json-mcp-server not found in PATH."
    call :print_info "You may need to restart your command prompt or add the installation directory to PATH."
    exit /b 1
)

endlocal
