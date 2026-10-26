# Patent sweep: json-mcp-server 0.3.x line (swept at manifest 0.3.1, so 0.3.2 is docs-only; first pass covered 0.1.x-0.2.x) @ 8264791

Date: 2026-10-25 (first pass) and 2026-10-26 (second pass, 0.3.x additions); Run by: json-mcp-server lane, Claude Sonnet 5.5; Method: AI-assisted search and read; **NOT legal advice; NOT a freedom-to-operate opinion.**
First pass: `origin/main` 8a8b135 (functionally what 0.2.x ships: PRs #3 and #4 change protocol serialisation, dependencies, CI and licence headers, not the mechanisms of ideas 1-7).
Second pass: `origin/main` 8264791, which ships 0.3.0 (MCP revision 2026-07-28, PR #9) and the CI/docs-only 0.3.1. Ideas 8-10 are new in 0.3.0 and were swept in the second pass; ideas 1-7 are unchanged in 0.3.x.

## Ideas swept
1. A server that exposes JSON-file operations (read, write, query, validate, help) as tools that a language-model client discovers with `tools/list` and invokes with `tools/call` over JSON-RPC on stdio (Model Context Protocol).
2. Reading a JSON file and returning only the part selected by a JSONPath expression.
3. Reading a large JSON file by line, with pagination (offset/limit) and an optional JSONPath filter per record.
4. Deciding whether a file is line-delimited JSON by parsing its first five lines and testing for a complete JSON object per line.
5. Writing a JSON file in `replace`, `merge` (object merge into the existing file) or `append` (array append) mode.
6. Validating a JSON file and returning a parse error message intended for an LLM to act on.
7. A `json-help` tool that returns usage guidance to the LLM client as tool output.
8. A server that answers a `server/discover` request with the protocol versions it supports, its capabilities and its identity, and answers a request that names an unsupported protocol version with an error that lists the supported versions (0.3.0).
9. A server that serves both handshake-based clients (`initialize`, version negotiated once per process) and stateless clients (protocol version carried in every request's metadata), choosing the behaviour from how the client opens (0.3.0).
10. Returning a time-to-live and a public/private cache scope with the tool list and the discovery result (0.3.0).

Note for accuracy (not a patent matter): the non-line-delimited path parses the whole file before iterating, so "streams files of any size" in the README overstates idea 3; this record sweeps what the code does.

## Queries (source: Google Patents via web search, 2026-10-25)
1. `LLM tool server file system JSON file read write query tool call protocol`
2. `method streaming parse large JSON file automatically select streaming based on file size JSONPath query`
3. `line-delimited JSON detect format sampling first lines apply path query each record`
4. `model context protocol server exposes tools to language model JSON-RPC stdio tool listing`
Second pass (2026-10-26, same source), for ideas 8-10:
5. `method server responds to discovery request listing supported protocol versions and capabilities, per-request protocol version in request metadata, unsupported version error listing supported versions`
6. `stateless server serves both legacy handshake session protocol and per-request metadata protocol selecting behavior by whether request carries version metadata or initialize`
7. `response cache time-to-live hint and cache scope public private included in server list result tool list model context protocol`
Only the first four queries (plus two title searches to find the Airia family) were run, on one search source (no direct USPTO/EPO/WIPO query). Claims were read with `tools/patent-claims.py` (Google Patents text, machine-converted).

## Hits
| # | patent | title | assignee | status | claim(s) read | overlap | our difference | verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | US12699693B2 | Framework for language model copilot development | Microsoft | Active (to ~2044) | claim 1 and dependents 2-8 | Tools described to an LLM, LLM decides to call one, tool result used in the response | Claim 1 is performed *by the LLM* ("determining, by the large language model"), receiving the query and tool descriptions. This crate is only the tool side: it lists tools and executes a call; it contains no LLM and does not decide which tool to use | clear (for this crate's code); note the LLM host that uses any MCP server is the claimed actor, outside this project |
| 2 | US7877366B2 | Streaming XML data retrieval using XPath | Oracle | Expired (est. 2025-11-07) | claim 1 and 2-9 | Streaming parser with registered path expressions | XML/XPath and SAX handler registration; we use JSON and evaluate JSONPath per line or on a whole parsed value, with no handler registry. Also expired | clear |
| 3 | US20180181655A1 | Handling Large Streaming File Formats in Web Browsers | VMware | Expired | claim 1 and 2-7 | Processing large files in pieces | Archive-file upload from a browser; unrelated to JSON | clear |
| 4 | US11182354B1 | Data analysis and processing engine | Tekion | Active (to ~2040) | claim 1 (first part) | Samples a file and tests it against format rulesets to find file type | Claim 1 also requires schema detection, normalisation rules, storing to a data lake and answering requests from the reformatted file; we only test whether the first lines are JSON objects and do no normalisation or storage | clear |
| 5 | US12008029B1 | Delimiter determination in input data | Teradata | Active (to ~2042) | claim 1 | Infers record structure by examining input | Claims scoring candidate record/field delimiter pairs by unique-field counts on text data; we do not infer delimiters, only test for a JSON object per line | clear |
| 6 | US7512610B1 | Processing data records | Miosoft | Active (to ~2027) | claim 1 | Viewing selected data pieces of a large file | Claims supplemental location information generated from file analysis so viewing time is independent of piece count; we keep no location index and rescan from the start for each offset | clear |
| 7 | US12730883B1 | Ephemeral nano sandbox for model context protocol server execution | Airia LLC (assignee per its parent on Google Patents; not shown on the USPTO PDF read) | Granted (USPTO full text) | all independent claims, 1, 19 and 20, read from the USPTO PDF (pp. 35-38, page images) | Concerns MCP servers, JSON-RPC resource commands, STDIN/STDOUT pipes | Every independent claim requires a gateway that receives an HTTP request carrying a nano-sandbox definition, instantiates an ephemeral isolated sandbox from it, starts the MCP server inside it, and terminates the sandbox after replying. This crate is a plain stdio MCP server: no HTTP gateway, no sandbox definition, no sandbox instantiation or termination | clear |
| 8 | US12602470B1 | Containerized execution of secure MCP servers for AI agents | Airia LLC | Active | claim 1 (Google Patents text) | Parent of row 7 | Requires an SSE bridge, instantiating a nano sandbox from a definition in the request, and running the MCP server in it; none of these exist here | clear |
| 9 | CN105404665A | JSON format data query management system | Linewell Software | Active | claim 1 | JSON query | Claim requires an applications client, application server and database server, converting tables to JSON views and generating SQL; we read local files with JSONPath and use no database | clear |
| 10 | US9367570B1 | Ad hoc queryable JSON with audit trails | Google | Expired | claim 1 | JSON stored and merged | Requires audit records per user and operational transformation to merge two users' JSON; our `merge` mode is a one-shot object merge into a file, with no audit records or transformation | clear |
| 11 | EP3211853A1 | Real-time validation of JSON data applying tree graph properties | Mitsubishi Electric | Active | claim 1 | JSON validation | Requires a network classifier that reassembles TCP segments of HTTP messages, builds a tree graph and interrupts the connection; we validate a local file by parsing it | clear |
| 12 | US10169601B2 | Reading and writing to big data storage formats | American Express | Active | claim 1 | Read/write requests for data | Requires a centralised access point, a catalog lookup of variable location and storage format, and generating a query in the target format's syntax; we have no catalog or syntax translation, only direct file operations | clear |
| 13 | US6658476B1 | Client-server protocol support list for standard request-response protocols | Microsoft | Expired | claim 1 and 2-5 | Server returns the list of protocols it supports (idea 8) | Expired. Also requires a list specific to the requested resource and ordered by server preference, sent in reply to an HTTP OPTIONS-style request; ours is one list per server, in no preference order beyond newest-first, over stdio JSON-RPC | clear |
| 14 | US20060080676A1 | Support for multiple interface versions | IBM | Expired | claim 1 | Supports a current and earlier interface versions (idea 9) | Expired. Claim requires firing an event with a reference to the call and listeners that process side effects of the current version; we branch on the request's metadata and share no event mechanism | clear |
| 15 | US20130198790A1 | Accessing service discovery metadata | ETRI | Abandoned | claim 1 and 2-4 | Discovery request/response (idea 8) | Abandoned. Requests a described metadata section from a description provider; ours returns versions and capabilities, with no metadata sections or signing | clear |
| 16 | US8577914B2 | APIs discovery service | Google | Expired (lapsed; Google's date estimate 2031) | claim 1 and 2-3 | Server returns machine-readable API metadata (idea 8) | Requires searching an API directory of directory entries that link to discovery documents and retrieving the document; we have no directory and return a fixed result | clear |
| 17 | WO2015051184A1 | Caching content with notification-based invalidation | Akamai | Ceased | claim 1 | Cached content invalidation (idea 10) | Ceased. Requires tokens stored with cached content and a message that a token is invalid; we only send a TTL and scope hint and cache nothing | clear |
| 18 | US20110282939A1 | Preserving state information in a stateless protocol | Gallup | Abandoned | claim 1 | Stateless server (idea 9) | Abandoned. State carried in URLs with a counter; our stateless mode carries a protocol version in request metadata and keeps no state | clear |

## Needs review (to the PM)
None for either pass: no `design-around` or `needs-review` verdicts, and no `unread` rows after the second pass on 2026-10-25 (the first pass left rows 7 and 9-12 unread; they are now read and recorded above). US12730883 is not on Google Patents' claims text endpoint, so it was read from the USPTO page images.

## Limitations
AI-assisted search with only four queries on one source; relevance ranking is the search engine's. Patent coverage outside Google Patents, non-English literature and unpublished applications are not covered. Claim text is machine-converted from Google Patents; status and expiry dates are Google's estimates, not the official record. The ideas were written by the lane that owns the project, and a different list could find different hits.
