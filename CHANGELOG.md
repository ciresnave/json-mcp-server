# Changelog

## 0.1.18

### Fixed
- `tools/list` now serializes `inputSchema` (was `input_schema`), and tool results use `isError` (#1).
- Notifications such as `notifications/initialized` are no longer answered with an error (#2).
- Added `ping`; `initialize` negotiates the protocol version and reports the real crate version.
- `tools/call` accepts a missing `arguments` field.
- `mcp_debug.log` is written only when `MCP_DEBUG_LOG` names a file (it used to be created in the client's working directory).

## 0.1.17

### Changed
- CI: packaging-manager tests no longer run on pull requests (push to main, schedule and manual runs remain); retired `macos-12`/`macos-13` runners replaced by `macos-14`/`macos-15`; the Snap test job, which validated nothing, is removed.

## Version history note

`Cargo.toml` reached 0.1.16 and git tags `v0.1.1`-`v0.1.16` exist, but only 0.1.0 was ever
published to crates.io. Versions 0.1.1-0.1.16 were never released as crates and, being
pre-protocol-fix, advertised tools that MCP clients rejected (#1).
