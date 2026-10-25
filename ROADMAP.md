# Roadmap

Maintained by the json-mcp-server lane. Updated 2026-10-25 after the 0.3.0 publish.

| # | Item | State |
|---|---|---|
| 1 | Publish to crates.io | done: 0.2.1 (tag v0.2.1 at d613666) and 0.3.0 (tag v0.3.0 at 0d6e840), both 2026-10-25; 0.2.0, 0.2.2 and 0.2.3 were never published (no crate change) |
| 2 | Issue #1 (Cline "Failed to fetch tools"): `inputSchema` fix since 0.2.1 | reporter asked to retest 0.2.1 and 0.3.0; close on confirmation or at the 2026-11-08 decision date |
| 3 | Issue #2 (Gemini CLI "Client is not connected"): protocol fixes since 0.2.1, `server/discover` since 0.3.0; **not verified against Gemini CLI itself** | reporter asked to retest 0.2.1 and 0.3.0 with `MCP_DEBUG_LOG`; decide by 2026-11-08 |
| 4 | GitHub releases: v0.1.8-v0.1.16 marked pre-release with a note (assets kept); v0.2.1 release exists with binaries | done; check that `Release Builds` produced a v0.3.0 release with binaries |
| 5 | Packaging workflows (Homebrew, Chocolatey, winget, AUR, deb/rpm): untested since 2025-06; run on push to main and on schedule only. The AUR job failed after 0.2.3 because of a doubled image digest (fixed in 0.3.1) | verify green on main after 0.3.1; the rest not started |
| 6 | Committed binaries (`dist/`, `packages/**/*.exe`, `.nupkg`) in git: untrack and rely on releases | not started |
| 7 | MCP spec currency: current revision is 2026-07-28 (checked 2026-10-25), supported since 0.3.0 alongside the handshake revisions. Not done: `subscriptions/listen`, multi round-trip requests, pagination (`cursor`), `outputSchema`; the official `rmcp` 3.7 SDK was considered and not adopted (hand-rolled server is ~300 lines) | done except the listed gaps |
| 8 | Real streaming for a single large JSON document (today it is parsed whole) | idea |
