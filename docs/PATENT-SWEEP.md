# Patent sweep: json-mcp-server 0.1.x line (covers the 0.2.0 release) @ 8a8b135

Date: 2026-10-25; Run by: json-mcp-server lane, Claude Sonnet 5.5; Method: AI-assisted search and read; **NOT legal advice; NOT a freedom-to-operate opinion.**
Swept commit is `origin/main` 8a8b135 (functionally identical to what 0.2.0 ships: PRs #3 and #4 change protocol serialisation, dependencies, CI and licence headers, not the mechanisms below).

## Ideas swept
1. A server that exposes JSON-file operations (read, write, query, validate, help) as tools that a language-model client discovers with `tools/list` and invokes with `tools/call` over JSON-RPC on stdio (Model Context Protocol).
2. Reading a JSON file and returning only the part selected by a JSONPath expression.
3. Reading a large JSON file by line, with pagination (offset/limit) and an optional JSONPath filter per record.
4. Deciding whether a file is line-delimited JSON by parsing its first five lines and testing for a complete JSON object per line.
5. Writing a JSON file in `replace`, `merge` (object merge into the existing file) or `append` (array append) mode.
6. Validating a JSON file and returning a parse error message intended for an LLM to act on.
7. A `json-help` tool that returns usage guidance to the LLM client as tool output.

Note for accuracy (not a patent matter): the non-line-delimited path parses the whole file before iterating, so "streams files of any size" in the README overstates idea 3; this record sweeps what the code does.

## Queries (source: Google Patents via web search, 2026-10-25)
1. `LLM tool server file system JSON file read write query tool call protocol`
2. `method streaming parse large JSON file automatically select streaming based on file size JSONPath query`
3. `line-delimited JSON detect format sampling first lines apply path query each record`
4. `model context protocol server exposes tools to language model JSON-RPC stdio tool listing`
Only these four queries were run, on one search source (no direct USPTO/EPO/WIPO query). Claims were read with `tools/patent-claims.py` (Google Patents text, machine-converted).

## Hits
| # | patent | title | assignee | status | claim(s) read | overlap | our difference | verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | US12699693B2 | Framework for language model copilot development | Microsoft | Active (to ~2044) | claim 1 and dependents 2-8 | Tools described to an LLM, LLM decides to call one, tool result used in the response | Claim 1 is performed *by the LLM* ("determining, by the large language model"), receiving the query and tool descriptions. This crate is only the tool side: it lists tools and executes a call; it contains no LLM and does not decide which tool to use | clear (for this crate's code); note the LLM host that uses any MCP server is the claimed actor, outside this project |
| 2 | US7877366B2 | Streaming XML data retrieval using XPath | Oracle | Expired (est. 2025-11-07) | claim 1 and 2-9 | Streaming parser with registered path expressions | XML/XPath and SAX handler registration; we use JSON and evaluate JSONPath per line or on a whole parsed value, with no handler registry. Also expired | clear |
| 3 | US20180181655A1 | Handling Large Streaming File Formats in Web Browsers | VMware | Expired | claim 1 and 2-7 | Processing large files in pieces | Archive-file upload from a browser; unrelated to JSON | clear |
| 4 | US11182354B1 | Data analysis and processing engine | Tekion | Active (to ~2040) | claim 1 (first part) | Samples a file and tests it against format rulesets to find file type | Claim 1 also requires schema detection, normalisation rules, storing to a data lake and answering requests from the reformatted file; we only test whether the first lines are JSON objects and do no normalisation or storage | clear |
| 5 | US12008029B1 | Delimiter determination in input data | Teradata | Active (to ~2042) | claim 1 | Infers record structure by examining input | Claims scoring candidate record/field delimiter pairs by unique-field counts on text data; we do not infer delimiters, only test for a JSON object per line | clear |
| 6 | US7512610B1 | Processing data records | Miosoft | Active (to ~2027) | claim 1 | Viewing selected data pieces of a large file | Claims supplemental location information generated from file analysis so viewing time is independent of piece count; we keep no location index and rescan from the start for each offset | clear |
| 7 | US12730883 (Ephemeral nano sandbox for MCP server execution) | | unknown | unknown | **unread** | Concerns running MCP servers inside a sandbox | The tool could not fetch it under the numbers tried (B1, B2, A1 all 404); only its title and abstract-level description were seen. This crate does not sandbox or launch servers | unread: not `clear` |
| 8 | CN105404665A, US9367570B1, EP3211853A1, US10169601B2 | JSON query / audit / validation / big-data read-write | various | not checked | **unread** (titles only) | JSON querying or validation in other settings | Titles only, no claims read | unread: not `clear` |

## Needs review (to the PM)
No `design-around` or `needs-review` verdicts. **Two items are `unread`** (row 7, row 8) and are not cleared; a human or a second pass should read them, row 7 first, before the 0.2.0 publish is called swept.

## Limitations
AI-assisted search with only four queries on one source; relevance ranking is the search engine's. Patent coverage outside Google Patents, non-English literature and unpublished applications are not covered. Claim text is machine-converted from Google Patents; status and expiry dates are Google's estimates, not the official record. The ideas were written by the lane that owns the project, and a different list could find different hits.
