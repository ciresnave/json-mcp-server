# HANDOFF: json-mcp-server lane (rewritten 2026-10-25, ref origin/main after #11)

Take-over by the PM on 2026-10-25 ("json-mcp-server has a lane. We maintain it."). Rules: ciresnave-bot only, never Opus, short messages, PM allocates versions and publishes, merges are the PM's.

## State
- crates.io 0.3.0 (tag v0.3.0 at 0d6e840): MCP 2026-07-28 dual-era, breaking error codes (unknown tool / bad params = -32602). 0.2.1 (tag v0.2.1) carried the `inputSchema` fix. 0.3.1 is docs/CI only, not published.
- Branch protection: 7 required contexts (3-OS build/test, MSRV, deny, audit, SPDX). CI = `.github/workflows/ci.yml`. Packaging workflows (`test-package-managers.yml`, `test-prebuilt.yml`) run on push to main/schedule only; they are not required.
- Patent sweep: `docs/PATENT-SWEEP.md` (0.1.x/0.2.x, all clear). It does not cover the 0.3.0 stateless/discover change as a new capability family: re-sweep before the next feature release, and by 2027-10-25 at the latest.
- Workflows pinned to SHAs, least permissions; `coderipper fast --profile extended` is clean for SUP-008/SUP-001 (only the accepted LICENSE-holder findings remain).

## Tasks held
1. Issues #1 and #2 (reporters asked to retest 0.3.0 on 2026-10-25, comments by ciresnave-bot). Decide by 2026-11-08: close #1 on confirmation, #2 only on the reporter's confirmation (Gemini CLI never tested by us), else comment status. `gh issue view N --repo ciresnave/json-mcp-server --comments`.
2. After #11 merges: confirm the "Test AUR Package" job is green on main (`gh run list --branch main`); if still red, fix the job or remove it (PM: main should be clean). ROADMAP row 4: confirm a v0.3.0 GitHub release with binaries exists.
3. ROADMAP rows 5-8 are unblocked ideas; start one if the PM has no other task.

## Gotchas
- Primary `C:\Projects\json-mcp-server` stays on main; use `git worktree add ../json-mcp-server-wt-<topic>`. Untracked `supertool` in the primary is not ours.
- `cargo package --list` must stay ~33 files (the `include` list in Cargo.toml).
- Every pushed change bumps the version and gets a CHANGELOG line (docs and CI included); the PM allocates. Quiet windows: no local cargo when the PM says so.
- `lane-restart --self` was refused (state-file pid mismatch; AgentLife owns it); do not work around it.
- My scripted multi-file edits must be idempotent: a second run doubled the archlinux digest once. Re-read the diff after any scripted edit.
- Windows: `MSYS_NO_PATHCONV=1` for `git -C C:/Projects/X show origin/main:path`; long cargo runs exceed the 120 s tool timeout, use run_in_background; `release.yml` workflow_dispatch can never pass its archive step (version comes from a tag ref).
- Patent claims: `python C:\Projects\tools\patent-claims.py <number>`; USPTO PDFs Google lacks are scanned images (render with PyMuPDF in a scratch venv, read the pages).
