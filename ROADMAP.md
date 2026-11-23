# Roadmap

Maintained by the json-mcp-server lane. Updated 2026-10-25 after the 0.3.0 publish.

| # | Item | State |
|---|---|---|
| 1 | Publish to crates.io | done: 0.2.1 (tag v0.2.1 at d613666) and 0.3.0 (tag v0.3.0 at 0d6e840), both 2026-10-25; 0.2.0, 0.2.2 and 0.2.3 were never published (no crate change) |
| 2 | Issue #1 (Cline "Failed to fetch tools"): `inputSchema` fix since 0.2.1 | reporter asked to retest 0.2.1 and 0.3.0; close on confirmation, or if no reply by 2026-12-07 (PM sweep 2026-11-16: close if silent for 3 weeks) |
| 3 | Issue #2 (Gemini CLI "Client is not connected"): protocol fixes since 0.2.1, `server/discover` since 0.3.0; **not verified against Gemini CLI itself** | reporter asked to retest 0.2.1 and 0.3.0 with `MCP_DEBUG_LOG`; close only on the reporter's confirmation (never tested by us); PM sweep 2026-11-16 dated it 2026-12-07 |
| 4 | GitHub releases: v0.1.8-v0.1.16 marked pre-release with a note (assets kept); v0.2.1 release exists with binaries | done; check that `Release Builds` produced a v0.3.0 release with binaries |
| 5 | Packaging workflows (Homebrew, Chocolatey, winget, AUR, deb/rpm): run on push to main and on schedule only | verified green on main (push and schedule) at 8264791 and b2f56cc, 2026-10-26 |
| 6 | Committed binaries (`dist/`, `packages/**/*.exe`, `.nupkg`) in git: untrack and rely on releases | done in 0.3.3 (history keeps them) |
| 7 | MCP spec currency: current revision is 2026-07-28 (checked 2026-10-25), supported since 0.3.0 alongside the handshake revisions. Not done: `subscriptions/listen`, multi round-trip requests, pagination (`cursor`), `outputSchema`; the official `rmcp` 3.7 SDK was considered and not adopted (hand-rolled server is ~300 lines) | done except the listed gaps |
| 8 | Real streaming for a large JSON document | partly done in 0.3.5: a top-level array streams element by element and stops at `limit`. Not done: a single large object or a JSONPath over a whole document (parsed whole); measured 2026-11-21 on Windows, release builds of 0.3.4 vs 0.3.5, one 368 MB top-level array (3M objects), `json-read` `limit=5`, peak working set of the server process, 2 runs each: 0.3.4 4955-4958 MB in 12.7-13.1 s; 0.3.5 5.8-6.3 MB (idle server 5.6-6.2 MB) in under 0.01 s. Only this shape and `limit` were measured: no other shape, no larger `limit`, no JSONPath |
