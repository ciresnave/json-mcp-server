# Package Manager Submission Checklist

This document provides a step-by-step checklist for submitting the JSON MCP Server to all major package managers after a GitHub release is published.

## Prerequisites ✅

- [x] Project published to Crates.io
- [x] GitHub repository with proper licensing (dual MIT/Apache-2.0)
- [x] Cross-platform binaries built via GitHub Actions
- [x] Package definitions created for all platforms
- [x] Comprehensive testing infrastructure in place
- [ ] **GitHub release published with binaries** (Required for next steps)

## Submission Order

Submit packages in this order to minimize dependencies and maximize success rate:

### 1. Chocolatey (Windows) 🍫

**Requirements:**

- Windows binaries available in GitHub releases
- Chocolatey account with package maintainer permissions

**Steps:**

1. Generate package with real checksums:

   ```bash
   ./scripts/packaging/generate-packages.sh chocolatey
   ```

2. Test package locally:

   ```powershell
   cd dist/chocolatey
   choco pack
   choco install json-mcp-server -s . -y --force
   json-mcp-server --version
   ```

3. Submit to Chocolatey Community Repository:

   ```powershell
   choco push json-mcp-server.0.1.1.nupkg --source https://push.chocolatey.org/
   ```

4. Monitor moderation queue at: <https://community.chocolatey.org/packages/json-mcp-server>

**Expected Timeline:** 1-3 business days for approval

### 2. Winget (Windows) 🪟

**Requirements:**

- Chocolatey package approved (helps with trust)
- Fork of microsoft/winget-pkgs repository

**Steps:**

1. Generate winget manifests:

   ```bash
   ./scripts/packaging/generate-packages.sh winget
   ```

2. Fork <https://github.com/Microsoft/winget-pkgs>

3. Create PR with manifests in `manifests/c/Ciresnave/JsonMcpServer/0.1.1/`

4. Automated validation will run - address any issues

**Expected Timeline:** 1-2 weeks for review and merge

### 3. Homebrew (macOS/Linux) 🍺

**Requirements:**

- macOS and Linux binaries in GitHub releases
- Fork of homebrew/homebrew-core repository

**Steps:**

1. Generate Homebrew formula:

   ```bash
   ./scripts/packaging/generate-packages.sh homebrew
   ```

2. Test formula locally:

   ```bash
   brew install --build-from-source ./packaging/homebrew/json-mcp-server.rb
   json-mcp-server --version
   ```

3. Fork <https://github.com/Homebrew/homebrew-core>

4. Create PR with formula in `Formula/json-mcp-server.rb`

**Expected Timeline:** 1-4 weeks (more complex review process)

### 4. AUR (Arch Linux) 📦

**Requirements:**

- AUR account
- SSH key configured for AUR
- Linux binaries available

**Steps:**

1. Generate AUR packages:

   ```bash
   ./scripts/packaging/generate-packages.sh aur
   ```

2. Test packages locally:

   ```bash
   cd dist/aur-source
   makepkg -si
   json-mcp-server --version
   ```

3. Submit to AUR:

   ```bash
   # For source package
   cd dist/aur-source
   git clone ssh://aur@aur.archlinux.org/json-mcp-server.git
   cp PKGBUILD json-mcp-server/
   cd json-mcp-server
   git add PKGBUILD
   git commit -m "Initial import of json-mcp-server"
   git push

   # For binary package
   cd ../aur-binary
   git clone ssh://aur@aur.archlinux.org/json-mcp-server-bin.git
   cp PKGBUILD json-mcp-server-bin/
   cd json-mcp-server-bin
   git add PKGBUILD
   git commit -m "Initial import of json-mcp-server-bin"
   git push
   ```

**Expected Timeline:** Immediate (community maintained)

### 5. Snap (Ubuntu/Linux) 📸

**Requirements:**

- Ubuntu One account
- Snap developer registration

**Steps:**

1. Generate snap package:

   ```bash
   ./scripts/packaging/generate-packages.sh snap
   ```

2. Build and test snap:

   ```bash
   cd dist/snap
   snapcraft
   snap install json-mcp-server_0.1.1_amd64.snap --dangerous
   json-mcp-server --version
   ```

3. Submit to Snap Store:

   ```bash
   snapcraft register json-mcp-server
   snapcraft upload json-mcp-server_0.1.1_amd64.snap
   snapcraft release json-mcp-server 1 stable
   ```

**Expected Timeline:** 1-2 days for automated review

## Post-Submission Monitoring

### 1. Track Approval Status

Create a tracking spreadsheet with:

- Package manager name
- Submission date
- Current status
- Approval date
- Issues/feedback
- Download metrics

### 2. Respond to Feedback

Monitor these channels daily:

- GitHub notifications for PR comments
- Email notifications from package managers
- Community forums for user feedback
- Package manager specific communication channels

### 3. Update Documentation

Once packages are approved:

1. Update README.md with confirmed installation methods
2. Add package manager badges
3. Update installation scripts with verified package names
4. Create announcement blog post or release notes

### 4. Metrics and Analytics

Track success metrics:

- Download counts per package manager
- Installation success rates
- User feedback and issues
- Geographic distribution
- Version adoption rates

## Troubleshooting Common Issues

### Checksum Mismatches

- Regenerate packages after any binary changes
- Verify download URLs are correct
- Check that GitHub release assets are public

### License Issues

- Ensure dual MIT/Apache-2.0 licensing is clearly documented
- Include LICENSE files in all packages
- Update package metadata if required

### Security Scans

- Some package managers run security scans
- Address any flagged dependencies
- Provide security contact information

### Build Failures

- Test on clean systems matching package manager requirements
- Update minimum system requirements if needed
- Provide alternative installation methods

## Emergency Procedures

### Package Recall

If a critical issue is discovered:

1. Contact package maintainers immediately
2. Update GitHub releases to mark as pre-release
3. Submit patches through fast-track processes
4. Communicate with users through all available channels

### Version Updates

For future releases:

1. Update version in all package definitions
2. Run full test suite
3. Submit updates in same order as initial submission
4. Monitor for any breaking changes or new requirements

## Success Criteria

The deployment is considered successful when:

- [ ] All 5 package managers have approved packages
- [ ] Users can install via: `choco install`, `winget install`, `brew install`, `yay -S`, `snap install`
- [ ] No critical issues reported in first 30 days
- [ ] Download metrics show healthy adoption
- [ ] Documentation is accurate and complete

## Contact Information

For package manager specific issues:

- **Chocolatey:** <chocolatey-package-maintainer@example.com>
- **Winget:** Submit issues to microsoft/winget-pkgs
- **Homebrew:** Submit issues to homebrew/homebrew-core
- **AUR:** Maintain AUR packages directly
- **Snap:** Use snapcraft.io dashboard

**Project Maintainer:** <cires@example.com>  
**GitHub Issues:** <https://github.com/ciresnave/json-mcp-server/issues>
