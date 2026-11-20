# Design note: real streaming for `json-read` (ROADMAP row 8)

Status: proposal, 2026-11-20. Not implemented.

## Problem (read from `src/json_tools/streaming.rs` at origin/main 3356f85)
`json-read` is described as "files of any size through automatic streaming", but:
- A non-line-delimited file goes through `read_to_string` + `serde_json::from_str::<Value>` and
  then `item.clone()` per result: the whole file is held in memory whatever `limit` is (not measured).
- Line-delimited detection looks only at the first 5 lines and only for `{...}` lines; an NDJSON
  file of arrays/scalars falls to the whole-file path and fails to parse.
- In NDJSON mode a malformed line is silently skipped (not counted, not reported).

## Proposal
1. Top-level array: drive `serde_json::Deserializer::from_reader(BufReader)` with a custom
   `Visitor::visit_seq` that deserializes ONE element at a time into `Value`, applies
   offset/limit/query, drops the element, and stops once `limit` results are collected.
   Memory is expected to track the largest element plus results (unmeasured). No new dependency.
2. Early stop leaves the file tail unvalidated; the result text says "stopped at limit; rest of file
   not read" so a truncated/invalid tail is not claimed valid (`json-validate` stays the full check).
3. NDJSON: detect by "top level is not `[`" and a second value follows (`StreamDeserializer`),
   replacing the first-5-lines heuristic; report a count of skipped malformed lines.
4. Out of scope: JSONPath over the whole document, and a single huge object/scalar. JSONPath needs
   a `Value`; those paths keep whole-parse and a size warning above a threshold (proposed 256 MB,
   tunable) instead of a silent OOM.

## Tests (each names the claim it backs)
- 1M-element array, limit=10: peak RSS old vs new, same clock (to be measured before any memory claim).
- offset/limit/query parity with the current output on small fixtures (golden comparison).
- NDJSON of arrays/scalars; malformed-line count reported; truncated tail after limit accepted.

## Why row 8 before row 7
Row 7's remaining gaps are `tools/list` pagination (5 tools: no consumer value), `outputSchema`
and `subscriptions/listen` (no file-change use here). Row 8 closes a gap between what the tool
advertises and what it does.
