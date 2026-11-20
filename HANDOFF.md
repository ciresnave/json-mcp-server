# HANDOFF: json-mcp-server lane (rewritten 2026-11-20, ref origin/main b5882b1)

Rules: ciresnave-bot only, never Opus (`--model sonnet`), short messages, PM allocates versions, merges and publishes. Reports go to cluster PM pm-platform; `[READY]` to pm-assist cc pm-platform. No `gh auth switch`. Sign posts `— lane: json-mcp-server`.

## State
- crates.io 0.3.0 (tag v0.3.0, release has 11 assets, read 2026-11-20). 0.3.1-0.3.4 docs/CI only, unpublished.
- **PR #15 merged 2026-11-20 (main b5882b1, 0.3.5, branch and worktree cleaned)**: `json-read` streams a top-level array and stops at `limit` (ROADMAP row 8 partly done); rustix 1.1.6 (lockfile only); dated chrono RUSTSEC-2026-0543 ignore in deny.toml (re-review 2026-12-17, auth-framework #499).
- Branch `lane/roadmap-memory` (worktree `../json-mcp-server-wt-roadmap`): ROADMAP rows 2/3/8 + this HANDOFF, committed not pushed; **open its PR on 2026-11-21 or later** (one PR per UTC day; today's is used). Add the memory measurement to it if done.
- Peak memory NOT measured; claim only "streams / stops at limit". Measure (huge file, old vs new, same clock) before any memory claim.
- 

## Tasks held
1. Issues #1 (Cline) and #2 (Gemini CLI): reporters asked to retest 0.3.0, no reply as of 2026-11-20. PM sweep 2026-11-16: close if no reply in 3 weeks (2026-12-07). PM-platform: no early close; #2 never tested by us.
2. ROADMAP row 7 gaps (pagination of 5 tools, outputSchema, subscriptions): low value, after row 8 lands.

WAIT: issue-1-reporter-retest | check: gh issue view 1 --repo ciresnave/json-mcp-server --comments | wake: 2026-12-07T00:00:00Z
WAIT: issue-2-reporter-retest | check: gh issue view 2 --repo ciresnave/json-mcp-server --comments | wake: 2026-12-07T00:00:00Z

## Gotchas
- Primary checkout stays on main; other work in `git worktree add ../json-mcp-server-wt-<topic>`. Untracked `supertool` is not ours.
- Python edits via heredoc: use quoted `<<'PYEOF'` and raw strings for `\t`/`\n` in Rust source (an escaped `\t` became a literal tab once).
- `CARGO_BUILD_JOBS=2`, one cargo at a time. `cargo fmt --check` before every push (CI fmt failed once).
- Patent sweep `docs/PATENT-SWEEP.md`; re-sweep before a release adding a new capability family, by 2027-10-25.
- `MSYS_NO_PATHCONV=1` for `git show origin/main:path`.
