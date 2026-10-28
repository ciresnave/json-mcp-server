# HANDOFF: json-mcp-server lane (rewritten 2026-10-28, ref origin/main after #13)

Stopped to zero on 2026-10-28 (CireSnave ruled). Rules: ciresnave-bot only, never Opus (`--model sonnet`), short messages, PM allocates versions, merges and publishes. Do not use `gh auth switch`.

## State
- crates.io 0.3.0 (tag v0.3.0): MCP 2026-07-28 dual-era. 0.3.1-0.3.4 are docs/CI only, not published. 0.3.3 untracked the committed binaries (ROADMAP row 6 done).
- Branch protection: 7 required contexts. Packaging workflows run on push to main/schedule, not required; all green at 0.3.3.
- Patent sweep `docs/PATENT-SWEEP.md` covers 0.1.x-0.3.x; re-sweep before a release adding a new capability family, and by 2027-10-25.
- Ant-first (PM notice 2026-10-28): no NEW hand-rolled config, log-redaction or release/packaging scripting without PM ack. ant-fit census sent: nothing here blocks on any Ant.

## Tasks held
1. Issues #1 (CPapadim, Cline) and #2 (dcharkes, Gemini CLI): reporters were asked on 2026-10-25 to retest 0.3.0; no reply as of 2026-10-28. DECIDE BY 2026-11-08: close #1 on confirmation; close #2 only on the reporter's confirmation (Gemini CLI never tested by us); else comment status. `gh issue view N --repo ciresnave/json-mcp-server --comments`. (The PM's scale-to-zero note said "#2/#3"; only #1 and #2 exist.)
2. ROADMAP row 8 (real streaming of one huge JSON document) and row 7 gaps (pagination, outputSchema, subscriptions): ideas only, wait for PM direction.

## What wakes me
Mail from the PM; a reporter reply on #1/#2; the 2026-11-08 issue deadline; a release/patent-sweep need.

## Gotchas
- Primary checkout stays on main; other work in `git worktree add ../json-mcp-server-wt-<topic>`. Untracked `supertool` is not ours.
- `cargo package --list` ~33 files. `CARGO_BUILD_JOBS=2`, one cargo at a time; long runs use run_in_background.
- Every pushed change bumps the version + CHANGELOG line. Scripted edits must be idempotent; re-read diffs.
- `MSYS_NO_PATHCONV=1` for `git show origin/main:path`. `release.yml` workflow_dispatch can't pass its archive step.
- Patent claims: `python C:\Projects\tools\patent-claims.py <number>`.
