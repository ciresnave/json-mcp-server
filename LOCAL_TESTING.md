# Local Testing Documentation

## Overview

This document describes the comprehensive local testing infrastructure for the JSON MCP Server project. The testing suite is designed to catch issues before they reach GitHub Actions CI, saving valuable CI minutes and improving development efficiency.

## Test Scripts

### Windows PowerShell: `test-all-local.ps1`

**Usage:**

```powershell
# Run all tests
.\test-all-local.ps1

# Run specific test suite
.\test-all-local.ps1 basic
.\test-all-local.ps1 cross-platform
.\test-all-local.ps1 package-managers
.\test-all-local.ps1 release

# Environment variables
$env:CLEAN = "true"           # Clean previous artifacts
$env:SKIP_BUILD = "true"      # Skip build steps
$env:VERBOSE = "true"         # Enable verbose output
```

### Unix/Linux/macOS Bash: `test-all-local.sh`

**Usage:**

```bash
# Run all tests
./test-all-local.sh

# Run specific test suite
./test-all-local.sh basic
./test-all-local.sh cross-platform
./test-all-local.sh package-managers
./test-all-local.sh release

# Environment variables
CLEAN=true ./test-all-local.sh          # Clean previous artifacts
SKIP_BUILD=true ./test-all-local.sh     # Skip build steps
VERBOSE=true ./test-all-local.sh        # Enable verbose output
```

## Test Suites

### 1. Prerequisites Check

- Verifies required tools (Rust, Cargo, Git)
- Checks optional tools (Ruby, Chocolatey, Docker, etc.)
- Reports versions and availability

### 2. Basic Build and Test

- `cargo check` - Fast syntax and dependency check
- `cargo test` - Run all unit and integration tests
- `cargo build --release` - Build optimized binary
- Binary verification and version check

### 3. Cross-Platform Installation Test

- Simulates the CI cross-platform installation workflow
- Tests `cargo install --path . --force`
- Handles existing binary conflicts gracefully
- Verifies installation and cleanup

### 4. Package Manager Tests

#### Windows

- **Chocolatey**: Creates and tests local package structure
- **Winget**: Validates manifest syntax and structure

#### macOS

- **Homebrew**: Tests formula syntax with Ruby validation

#### Linux

- **AUR**: Validates PKGBUILD syntax and structure
- **Snap**: Tests snapcraft.yaml configuration

### 5. Release Workflow Simulation

- Tests cross-compilation targets
- Validates archive creation
- Simulates release artifact generation

### 6. Integration Tests

- Basic JSON operations
- Server startup and shutdown
- Smoke tests for core functionality

## Key Features

### 🎯 CI Issue Prevention

The local tests are designed to catch the exact issues that would fail in CI:

1. **Binary Conflicts**: Tests handle existing installations like CI does
2. **Package Structure**: Validates all package manager configurations
3. **Cross-Platform**: Tests across different platforms and installation methods
4. **Dependency Issues**: Catches missing tools and version conflicts

### 🚀 Fast Feedback Loop

- **Selective Testing**: Run only the tests you need
- **Skip Options**: Skip builds if binary already exists
- **Clear Output**: Color-coded results with progress indicators
- **Early Exit**: Stops on first failure to save time

### 🔧 CI Workflow Mimicking

The local tests closely mirror the GitHub Actions workflows:

- Uses same commands and flags as CI
- Tests same package structures
- Validates same manifests and configurations
- Handles edge cases that occur in CI

## Common Issues Caught

### 1. Existing Binary Conflicts

**Issue**: `cargo install` fails when binary already exists  
**Solution**: Use `--force` flag in both local tests and CI  
**Local Test**: `test-all-local.ps1 cross-platform`

### 2. Package Structure Problems

**Issue**: Package manifests have syntax errors or missing files  
**Solution**: Validate all manifests locally before push  
**Local Test**: `test-all-local.ps1 package-managers`

### 3. Missing Dependencies

**Issue**: Required tools not available in CI environment  
**Solution**: Check tool availability and add installation steps  
**Local Test**: Prerequisites check in all test suites

### 4. Cross-Platform Compatibility

**Issue**: Code works on one platform but fails on others  
**Solution**: Test build and installation across platforms  
**Local Test**: Cross-platform test suite

## Best Practices

### Before Every Push

1. Run `test-all-local.ps1` (Windows) or `test-all-local.sh` (Unix)
2. Fix any failures before pushing to GitHub
3. For quick iterations, use `test-all-local.ps1 basic`

### Before Release

1. Run full test suite: `test-all-local.ps1 all`
2. Test package manager configurations: `test-all-local.ps1 package-managers`
3. Validate release workflow: `test-all-local.ps1 release`

### Debugging Workflow Issues

1. Run the specific test suite that mirrors the failing CI job
2. Use `VERBOSE=true` for detailed output
3. Check CI logs and ensure local test reproduces the issue
4. Fix locally and verify before pushing

## Integration with Development Workflow

### Git Hooks (Optional)

You can add local testing to your git hooks:

```bash
# .git/hooks/pre-push
#!/bin/bash
echo "Running local tests before push..."
./test-all-local.sh basic
```

### IDE Integration

Configure your IDE to run local tests:

- VS Code: Add tasks in `.vscode/tasks.json`
- IntelliJ: Add run configurations
- Vim/Emacs: Add custom commands

### Continuous Development

- Use `SKIP_BUILD=true` when binary is already built
- Run `basic` suite during active development
- Run `all` suite before major commits

## Troubleshooting

### Common Errors

**"Prerequisites check failed"**

- Install missing tools (Rust, Cargo, Git)
- Update PATH environment variable
- Check tool versions meet requirements

**"Binary not found"**

- Run without `SKIP_BUILD=true`
- Check `cargo build --release` completed successfully
- Verify `target/release/json-mcp-server.exe` exists

**"Package manager tests failed"**

- Install required tools (Ruby for Homebrew, etc.)
- Check package configuration files
- Verify version extraction from Cargo.toml

**"Cross-platform test failed"**

- Check if binary already installed: `which json-mcp-server`
- Uninstall manually: `cargo uninstall json-mcp-server`
- Re-run test with clean environment

## Performance Tips

### Faster Testing

- Use `basic` suite for quick validation
- Set `SKIP_BUILD=true` when binary exists
- Run specific suites instead of `all`

### Caching

- Local tests reuse built artifacts
- Cargo cache is preserved between runs
- Package structures are validated without rebuilding

### Parallel Execution

- Some tests can run in parallel
- Package manager validations are independent
- Cross-platform tests can be run separately

## Maintenance

### Updating Tests

When adding new CI workflows:

1. Add corresponding local test suite
2. Mirror the exact commands and configurations
3. Test edge cases and failure scenarios
4. Document new test in this file

### Version Updates

When updating dependencies:

1. Run full test suite to catch breaking changes
2. Update package manager configurations
3. Test cross-platform compatibility
4. Validate all manifests and configurations

## Conclusion

The local testing infrastructure is a critical component for maintaining high-quality releases and preventing CI failures. By running comprehensive tests locally before pushing to GitHub, we can:

- Save GitHub Actions minutes
- Get faster feedback on issues
- Maintain high confidence in deployments
- Catch edge cases before they reach production

Always run local tests before pushing, and use the specific test suites to debug CI issues quickly and efficiently.
