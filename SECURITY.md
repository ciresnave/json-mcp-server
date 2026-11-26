# Security

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository (Security tab, "Report a vulnerability"). Do not open a public issue for a suspected vulnerability. We aim to acknowledge a report within 7 days.

## Scope and trust model

`json-mcp-server` is a local stdio server: it reads and writes the JSON files that the MCP client (and so the model behind it) asks for, with the permissions of the user running it. It does no sandboxing or path restriction of its own. Run it as a user who may touch only the files you are willing to expose, and treat a connected model as able to read and overwrite any JSON file that user can reach.

## Supported versions

Only the latest release on crates.io receives fixes.
