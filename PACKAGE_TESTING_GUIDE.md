# Package Manager Testing & Submission Guide

This guide provides comprehensive testing procedures for all package managers before production submission.

## 🎯 Testing Philosophy

> **"I don't want to ever have anything I help create fail in production."**

This guide implements rigorous testing across all platforms and package managers to ensure zero production failures.

## 📋 Pre-Submission Testing Checklist

### Phase 1: Local Development Testing

- [ ] **Local package builds** work on development machines
- [ ] **Installation/uninstallation cycles** complete cleanly
- [ ] **Version verification** shows correct version
- [ ] **Basic functionality tests** pass post-installation
- [ ] **Documentation accessibility** verified
- [ ] **Package generation succeeds** for all managers locally

### Phase 2: Automated CI/CD Testing

- [ ] **GitHub Actions workflows pass** for all platforms
- [ ] **Cross-platform installations verified** (Ubuntu, Windows, macOS)
- [ ] **Checksum validation passes** for all binaries
- [ ] **Manifest syntax validation** completes successfully
- [ ] **Integration tests pass** across all target environments

### Phase 3: Staging Environment Testing

- [ ] **Fresh VM testing** on each target platform
- [ ] **Package manager integration** works as expected
- [ ] **Dependency resolution** handles correctly
- [ ] **System PATH updates** work properly
- [ ] **Cleanup verification** after uninstallation

## 🔧 Testing Infrastructure

### Automated Testing (GitHub Actions)

```yaml
# Runs on every push, PR, and daily
- Cross-platform builds (8 platforms)
- Package generation and validation
- Installation testing via multiple methods
- Integration tests for MCP functionality
```

### Local Testing Scripts

```bash
# Generate all packages with current checksums
./scripts/packaging/generate-packages.sh

# Test Windows packages (PowerShell)
./scripts/packaging/test-packages.ps1

# Test Unix packages (Bash)
./scripts/packaging/test-packages.sh
```

## 📦 Package Manager Specific Testing

### 1. Chocolatey (Windows)

**Testing Process:**
```powershell
# 1. Generate package
./scripts/packaging/generate-packages.sh chocolatey

# 2. Test locally
cd dist/chocolatey
choco pack
choco install json-mcp-server -s . -y --force

# 3. Verify installation
json-mcp-server --version
json-mcp-server --help

# 4. Test uninstallation
choco uninstall json-mcp-server -y
```

**Required Tests:**
- [ ] Package builds without errors
- [ ] Installation succeeds on Windows 10/11
- [ ] Binary is added to PATH
- [ ] Uninstallation removes all files
- [ ] Reinstallation works after uninstall

**Validation Criteria:**
- ✅ `.nupkg` file generates successfully
- ✅ PowerShell scripts execute without errors
- ✅ Checksums match released binaries
- ✅ Chocolatey validation passes: `choco pack`

### 2. Winget (Windows)

**Testing Process:**
```powershell
# 1. Generate manifests
./scripts/packaging/generate-packages.sh winget

# 2. Validate manifests
winget validate dist/winget/manifests/c/ciresnave/json-mcp-server/0.1.0/

# 3. Test installation (requires manifest in winget-pkgs)
# This step requires submission to Microsoft's repository first
```

**Required Tests:**
- [ ] All three manifest files validate
- [ ] YAML syntax is correct
- [ ] Checksums match for x64 and ARM64
- [ ] URLs are accessible
- [ ] Version numbers are consistent

**Validation Criteria:**
- ✅ `winget validate` passes without warnings
- ✅ Manifest follows Microsoft guidelines
- ✅ All required fields are populated
- ✅ Architecture-specific binaries specified

### 3. Homebrew (macOS)

**Testing Process:**
```bash
# 1. Generate formula
./scripts/packaging/generate-packages.sh homebrew

# 2. Test formula syntax
brew audit --strict dist/homebrew/json-mcp-server.rb

# 3. Test installation
brew install --build-from-source dist/homebrew/json-mcp-server.rb

# 4. Run tests
brew test json-mcp-server

# 5. Test uninstallation
brew uninstall json-mcp-server
```

**Required Tests:**
- [ ] Formula syntax validates
- [ ] Installation on macOS 12, 13, 14
- [ ] Both x64 and ARM64 architectures
- [ ] Test block executes successfully
- [ ] Binary works after installation

**Validation Criteria:**
- ✅ `brew audit --strict` passes
- ✅ Formula follows Homebrew style guide
- ✅ Test block verifies basic functionality
- ✅ Dependencies are correctly specified

### 4. AUR (Arch Linux)

**Testing Process:**
```bash
# 1. Generate PKGBUILD files
./scripts/packaging/generate-packages.sh aur

# 2. Test source package
cd dist/aur/json-mcp-server
makepkg -si

# 3. Test binary package
cd ../json-mcp-server-bin
makepkg -si

# 4. Validate with namcap
namcap PKGBUILD
namcap *.pkg.tar.zst
```

**Required Tests:**
- [ ] PKGBUILD syntax validates
- [ ] Source compilation succeeds
- [ ] Binary package installs
- [ ] Package files are correctly placed
- [ ] Dependencies are satisfied

**Validation Criteria:**
- ✅ `makepkg` completes without errors
- ✅ `.SRCINFO` generates correctly
- ✅ `namcap` shows no major issues
- ✅ Package installs system-wide correctly

### 5. Snap (Ubuntu)

**Testing Process:**
```bash
# 1. Generate snapcraft.yaml
./scripts/packaging/generate-packages.sh snap

# 2. Build snap
cd dist/snap
snapcraft --destructive-mode

# 3. Install locally
sudo snap install json-mcp-server_*.snap --dangerous

# 4. Test functionality
json-mcp-server --version

# 5. Test confinement
# Ensure file access works within confinement rules
```

**Required Tests:**
- [ ] Snap builds successfully
- [ ] Installation works on Ubuntu LTS
- [ ] Confinement allows necessary file access
- [ ] App appears in snap list
- [ ] Removal works cleanly

**Validation Criteria:**
- ✅ `snapcraft` builds without errors
- ✅ Snap installs and runs correctly
- ✅ File access permissions work
- ✅ Meets Snap Store requirements

## 🧪 Testing Environments

### Recommended Test Matrix

| Package Manager | OS Version | Architecture | VM/Container |
|----------------|------------|--------------|--------------|
| Chocolatey | Windows 10, 11 | x64, ARM64 | Clean Windows VM |
| Winget | Windows 10, 11 | x64, ARM64 | Windows Sandbox |
| Homebrew | macOS 12, 13, 14 | x64, ARM64 | macOS VM/Metal |
| AUR | Arch Linux | x64, ARM64 | Docker Container |
| Snap | Ubuntu 20.04, 22.04 | x64, ARM64 | LXD Container |

### GitHub Actions Testing

```yaml
# Automated testing runs on:
- ubuntu-22.04, ubuntu-24.04
- windows-2022, windows-2025  
- macos-12, macos-13, macos-14

# Test matrix includes:
- Multiple installation methods per platform
- Checksum validation for all binaries
- Package syntax validation
- Basic functionality verification
```

## 🚀 Submission Workflow

### 1. Preparation Phase

```bash
# Ensure all tests pass
git push  # Triggers CI/CD
./scripts/packaging/generate-packages.sh all  # Generate all packages
./scripts/packaging/test-packages.sh all      # Run local tests
```

### 2. Package Generation

```bash
# This creates dist/ directory with all package definitions
./scripts/packaging/generate-packages.sh

# Output structure:
dist/
├── chocolatey/           # Ready for Chocolatey submission
├── winget/              # Ready for winget-pkgs PR
├── homebrew/            # Ready for Homebrew PR
├── aur/                 # Ready for AUR submission
├── snap/                # Ready for Snap Store
└── SUBMISSION_INSTRUCTIONS.md
```

### 3. Sequential Submission

**Order matters for dependency management:**

1. **Chocolatey** (fastest approval)
2. **Winget** (Microsoft review process)
3. **Homebrew** (community review)
4. **AUR** (immediate if maintainer)
5. **Snap** (automated if tests pass)

### 4. Monitoring & Response

- Monitor submission status daily
- Respond to reviewer feedback within 24 hours
- Update documentation once approved
- Test approved packages immediately

## 🔍 Validation Scripts

### Comprehensive Test Runner

```bash
#!/bin/bash
# scripts/test-all-packages.sh

set -e

echo "🧪 Running comprehensive package tests..."

# Test generation
./scripts/packaging/generate-packages.sh all

# Test each package manager
echo "Testing Chocolatey..."
powershell -File scripts/packaging/test-packages.ps1 -PackageManager chocolatey

echo "Testing Homebrew..."
if command -v brew >/dev/null; then
    brew audit --strict dist/homebrew/json-mcp-server.rb
fi

echo "Testing AUR..."
if command -v makepkg >/dev/null; then
    cd dist/aur/json-mcp-server && makepkg --printsrcinfo > .SRCINFO
    namcap PKGBUILD || echo "namcap warnings noted"
fi

echo "Testing Snap..."
if command -v snapcraft >/dev/null; then
    cd dist/snap && snapcraft expand-extensions
fi

echo "✅ All package tests completed!"
```

## 📊 Success Metrics

### Pre-Submission Requirements

- [ ] **100% automated test pass rate**
- [ ] **Zero checksum mismatches**
- [ ] **All syntax validations clean**
- [ ] **Manual verification on 3+ platforms**
- [ ] **Documentation completeness check**

### Post-Submission Monitoring

- [ ] **Package approval within expected timeframes**
- [ ] **No user-reported installation failures**
- [ ] **Download/install metrics tracking**
- [ ] **Community feedback incorporation**

## 🚨 Failure Response Plan

### If Tests Fail

1. **Stop submission immediately**
2. **Document failure cause**
3. **Fix underlying issue**
4. **Re-run full test suite**
5. **Update version if necessary**

### If Submission Rejected

1. **Address reviewer feedback**
2. **Update packages accordingly**
3. **Re-test affected components**
4. **Resubmit with changes documented**

## 📚 Additional Resources

- [Chocolatey Package Guidelines](https://docs.chocolatey.org/en-us/create/create-packages)
- [Winget Manifest Guidelines](https://docs.microsoft.com/en-us/windows/package-manager/package/)
- [Homebrew Formula Guidelines](https://docs.brew.sh/Formula-Cookbook)
- [AUR Package Guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [Snap Store Guidelines](https://snapcraft.io/docs/snap-store-requirements)

---

**Remember**: Better to over-test than to fail in production. This comprehensive testing approach ensures the json-mcp-server maintains its reputation for reliability across all distribution channels.
