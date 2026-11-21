# HANDOFF: json-mcp-server lane (rewritten 2026-11-21, ref origin/main b5882b1)

Rules: ciresnave-bot only, never Opus (`--model sonnet`), short messages, PM allocates versions, merges and publishes. Reports go to cluster PM pm-platform; `[READY]` to pm-assist cc pm-platform. No `gh auth switch`. Sign posts `— lane: json-mcp-server`.

## State
- crates.io 0.3.0 (tag v0.3.0, 11 release assets). 0.3.1-0.3.5 unpublished; 0.3.5 (#15, merged 2026-11-20) streams a top-level array in `json-read` and stops at `limit`.
- Remote has only `main` (`git ls-remote --heads origin`); no stale lane branches.
- Branch `lane/roadmap-memory` (worktree `../json-mcp-server-wt-roadmap`): ROADMAP rows 2/3/8 + this HANDOFF, docs only, committed not pushed.
- rustix RUSTSEC-2026-0486: answered to pm-platform, NOT affected (lock 1.1.6 is patched; dev-dep via tempfile only).
- Soft-stopped 2026-11-21 at pm-platform's request (memory for image generation). pm-platform mails after 00:05Z to wake me.

## Tasks held
1. **Day PR 2026-11-22 UTC** (one PR per UTC day): push `lane/roadmap-memory` (row-8 measurement already committed, ece1fc7: 0.3.4 ~4955 MB vs 0.3.5 ~6 MB peak, see ROADMAP), `cargo fmt --check`, open ONE PR, `[READY]` to pm-assist cc pm-platform. Docs-only, so the PM allocates the version at gate.
2. Issues #1 (Cline) and #2 (Gemini CLI): no reply since the 2026-10-25 retest request. PM sweep 2026-11-16: close if silent by 2026-12-07; no early close; #2 never tested by us.
3. ROADMAP row 7 gaps (pagination, outputSchema, subscriptions): low value, after row 8.

WAIT: issue-1-reporter-retest | check: gh issue view 1 --repo ciresnave/json-mcp-server --comments | wake: 2026-12-07T00:00:00Z
WAIT: issue-2-reporter-retest | check: gh issue view 2 --repo ciresnave/json-mcp-server --comments | wake: 2026-12-07T00:00:00Z

## Gotchas
- Primary checkout stays on main; other work in worktrees. Untracked `supertool` is not ours.
- Python edits via heredoc: quoted `<<'PYEOF'` and raw strings for `\t`/`\n` in Rust source.
- `CARGO_BUILD_JOBS=2`, one cargo at a time. `cargo fmt --check` before every push.
- Patent sweep `docs/PATENT-SWEEP.md`; re-sweep before a release adding a capability family, by 2027-10-25.
- `MSYS_NO_PATHCONV=1` for `git show origin/main:path`. `git fetch --prune` before trusting `origin/*` branch lists.
