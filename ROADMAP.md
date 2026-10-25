# Roadmap

Maintained by the json-mcp-server lane. Updated 2026-10-25.

| # | Item | State |
|---|---|---|
| 1 | Publish 0.2.0 (protocol fix #3, CI/deps #4, patent sweep #5, docs/package #7) to crates.io; tag `v0.2.0` | waits on PM (publish is the PM's) |
| 2 | Issue #1 (Cline "Failed to fetch tools"): fixed in #3; close after the release and the reporter or a retest confirms | open, decide by 2026-11-08 |
| 3 | Issue #2 (Gemini CLI "Client is not connected"): protocol fixes in #3; **not verified against Gemini CLI itself**; ask the reporter to retest with `MCP_DEBUG_LOG` | open, decide by 2026-11-08 |
| 4 | GitHub releases v0.1.1-v0.1.16 carry binaries built before the protocol fix; after 0.2.0, re-cut release binaries from the tag or mark the old releases pre-release | not started |
| 5 | Packaging workflows (Homebrew, Chocolatey, winget, AUR, deb/rpm): untested since 2025-06; they run only on push to main and on schedule | not started |
| 6 | Committed binaries (`dist/`, `packages/**/*.exe`, `.nupkg`) in git: untrack and rely on releases | not started |
| 7 | MCP spec currency: 2025-06-18 is the newest revision implemented; check newer revisions and consider the official `rmcp` SDK | not started |
| 8 | Real streaming for a single large JSON document (today it is parsed whole) | idea |
