# Changelog

## 0.2.3

### Changed
- Workflows: every `uses:` is pinned to a full commit SHA with its version in a comment; `archlinux:latest` is pinned by digest; `dtolnay/rust-toolchain` names its channel explicitly.
- Workflows: top-level `permissions: contents: read` everywhere; `contents: write` only on the two jobs that attach files to a release; the unused `packages: write` is dropped.
- Workflows: `cargo build`/`test`/`install` run with `--locked`.
- `.github/CODEOWNERS` added. Not published to crates.io (no change to the crate).

## 0.2.2

### Changed
- ROADMAP.md brought current after the 0.2.1 publish; HANDOFF.md added. Documentation only; not published to crates.io.

## 0.2.1

### Fixed
- The built-in `json-help` text and the README documented parameter names the tools do not accept (`json_path`, `format`/`output_format` on reads, `content`, `merge_shallow`/`merge_deep`, `backup`, `create_path`, `start_index`); they now match the tool schemas (`query`, `limit`, `offset`, `data`, `mode` = replace/merge/append, `create_dirs`, `pretty`). A client following the old help text had its filter silently ignored.
- Streaming claims corrected: only line-delimited JSON is read record by record; a single large JSON document is parsed whole.

### Changed
- The published crate contains only sources, tests, examples, README, CHANGELOG, licences and lockfile (`include` list); committed binaries and packaging trees are no longer packaged.

## 0.2.0

First release since 0.1.0 on crates.io; includes everything in 0.1.17-0.1.19 below.

### Changed (breaking)
- Minimum supported Rust version is now 1.89 (was 1.75) and the crate uses edition 2024.
- MCP output changed: `inputSchema`/`isError` field names, notifications are not answered, protocol version is negotiated (see 0.1.18).

### Added
- Hosted CI: fmt, clippy `-D warnings`, test, doc on Linux/Windows/macOS, MSRV, cargo-deny, cargo-audit, SPDX header check, CodeRipper portfolio job (advisory).
- `docs/PATENT-SWEEP.md` completed: every hit's independent claims read, all clear.
- `Cargo.lock` is tracked; every dependency is at its current release; every source file carries an SPDX header.

## 0.1.19

### Added
- `docs/PATENT-SWEEP.md`: patent sweep record for the 0.1.x/0.2.0 line.

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
