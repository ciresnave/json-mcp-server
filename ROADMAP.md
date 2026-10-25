# Roadmap

Maintained by the json-mcp-server lane. Updated 2026-10-25 after the 0.2.1 publish.

| # | Item | State |
|---|---|---|
| 1 | Publish 0.2.1 (protocol fix #3, CI/deps #4, patent sweep #5, docs/package #7) to crates.io; tag `v0.2.1` | done 2026-10-25 (crates.io 0.2.1, tag v0.2.1 at d613666; 0.2.0 was never published) |
| 2 | Issue #1 (Cline "Failed to fetch tools"): fixed in #3; close once the reporter or a retest confirms | fixed in 0.2.1; reporter asked to retest 2026-10-25; close on confirmation or at the 2026-11-08 decision date |
| 3 | Issue #2 (Gemini CLI "Client is not connected"): protocol fixes in #3; **not verified against Gemini CLI itself**; reporter asked to retest with `MCP_DEBUG_LOG` 2026-10-25 | open, decide by 2026-11-08 |
| 4 | GitHub releases v0.1.1-v0.1.16 carry binaries built before the protocol fix; v0.1.8-v0.1.16 marked pre-release with a note (assets kept) 2026-10-25; `Release Builds` ran on tag v0.2.1: check that it produced a v0.2.1 GitHub release with binaries, otherwise `/releases/latest` (linked from the README) is 404 | in progress |
| 5 | Packaging workflows (Homebrew, Chocolatey, winget, AUR, deb/rpm): untested since 2025-06; they run only on push to main and on schedule | not started |
| 6 | Committed binaries (`dist/`, `packages/**/*.exe`, `.nupkg`) in git: untrack and rely on releases | not started |
| 7 | MCP spec currency: current revision is 2026-07-28 (checked 2026-10-25); dual-era support added in 0.3.0. Not done: `subscriptions/listen`, multi round-trip requests, pagination (`cursor`), `outputSchema`; the official `rmcp` 3.7 SDK was considered and not adopted (hand-rolled server is ~200 lines) | done except listed gaps |
| 8 | Real streaming for a single large JSON document (today it is parsed whole) | idea |
