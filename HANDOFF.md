# HANDOFF: json-mcp-server lane (written 2026-10-25, ref origin/main d613666)

Take-over by the PM on 2026-10-25 ("json-mcp-server has a lane. We maintain it."). Rules: ciresnave-bot only, never Opus, short messages, PM allocates versions and publishes, merges are the PM's.

## State
- crates.io 0.2.1 published, tag v0.2.1 (d613666); GitHub release v0.2.1 exists (11 assets). v0.1.8-0.1.16 releases marked pre-release with a note (assets kept).
- Branch protection set by the PM: 7 required contexts (3-OS build/test, MSRV, deny, audit, SPDX). CI = `.github/workflows/ci.yml`. Packaging workflows run on push to main / schedule only.
- Patent sweep complete (`docs/PATENT-SWEEP.md`, covers 0.1.x/0.2.x, all clear). Re-sweep on a new capability family or yearly (by 2027-10-25).
- PR #8 (ROADMAP + HANDOFF, 0.2.2, docs-only, not to be published) is READY and waits on the PM's gate.

## Tasks held
1. Issues #1 (Cline) and #2 (Gemini CLI): fixed in 0.2.1, both reporters asked to retest 2026-10-25 (comments 6402035408, 6402035701). Issue clock: decide by 2026-11-08. On a reply: close #1 on confirmation; #2 is NOT verified against Gemini CLI, only close on the reporter's confirmation, else comment status. Check with `gh issue view N --repo ciresnave/json-mcp-server --comments`.
2. ROADMAP rows 5-8 (packaging workflows untested since 2025-06, committed binaries in git, MCP spec currency/rmcp, real streaming of a single large document) are unblocked ideas; start one only if the PM has no other task (don't wait for a [TASK]).

## Gotchas
- Primary `C:\Projects\json-mcp-server` stays on main; use `git worktree add ../json-mcp-server-wt-<topic>`. Untracked `supertool` in the primary is not ours.
- `cargo package --list` must stay at ~33 files (the `include` list in Cargo.toml); check it after adding top-level files.
- Every pushed change bumps the version and gets a CHANGELOG line (docs included), PM allocates.
- Windows: `git -C C:/Projects/X show origin/main:path` needs `MSYS_NO_PATHCONV=1`. Long cargo runs exceed the 120s tool timeout: use run_in_background.
- Patent claims: `python C:\Projects\tools\patent-claims.py <number>`; for USPTO patents Google lacks, the USPTO PDF is scanned images (render pages with PyMuPDF in a scratch venv and read them).
