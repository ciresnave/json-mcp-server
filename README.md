# JSON MCP Server

A high-performance Rust-based Model Context Protocol (MCP) server that provides comprehensive JSON file operations optimized for LLM interactions. This server enables LLMs to efficiently read, write, query, and manipulate JSON files with support for extremely large datasets and advanced querying capabilities.

## 🚀 Features

### Core JSON Tools

- **📖 json-read**: Read JSON files with optional JSONPath filtering and pagination
- **✏️ json-write**: Write or update JSON files with multiple merge strategies  
- **🔍 json-query**: Execute complex JSONPath queries with various output formats
- **✅ json-validate**: Validate JSON structure and syntax with detailed diagnostics
- **❓ json-help**: Interactive help system with comprehensive examples and troubleshooting

### Key Capabilities

- **Large File Support**: Pagination for any JSON file; line-by-line streaming for line-delimited JSON (a single large JSON document is parsed whole)
- **JSONPath Querying**: Full JSONPath support for complex data extraction and filtering
- **Flexible Writing**: Three modes (replace, merge, append)
- **LLM-Optimized**: Detailed error messages and usage examples for optimal LLM interaction
- **Bounded Output**: Pagination (`limit`/`offset`) keeps each response small
- **MCP Compliant**: Full Model Context Protocol support with proper error handling
- **Debug Logging**: Set `MCP_DEBUG_LOG=<file>` to log every message to a file (off by default; stdout stays clean JSON-RPC)

## 📦 Installation

### Quick Install

#### Via Cargo (Recommended)

```bash
cargo install json-mcp-server
```

#### Via Installation Script

```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/ciresnave/json-mcp-server/main/scripts/install.sh | bash

# Windows PowerShell  
iwr https://raw.githubusercontent.com/ciresnave/json-mcp-server/main/scripts/install.ps1 | iex
```

#### Pre-built Binaries

Download platform-specific binaries from [GitHub Releases](https://github.com/ciresnave/json-mcp-server/releases):

- **Windows**: `json-mcp-server-v{version}-x86_64-pc-windows-msvc.zip`
- **macOS**: `json-mcp-server-v{version}-x86_64-apple-darwin.tar.gz`  
- **Linux**: `json-mcp-server-v{version}-x86_64-unknown-linux-gnu.tar.gz`

### Package Managers

#### Debian/Ubuntu (.deb packages)

```bash
# Download and install .deb package
wget https://github.com/ciresnave/json-mcp-server/releases/latest/download/json-mcp-server_*_amd64.deb
sudo dpkg -i json-mcp-server_*_amd64.deb
```

#### RHEL/Fedora/CentOS (.rpm packages)

```bash
# Download and install .rpm package
wget https://github.com/ciresnave/json-mcp-server/releases/latest/download/json-mcp-server-*.x86_64.rpm
sudo rpm -i json-mcp-server-*.x86_64.rpm
```

#### Arch Linux (AUR)

```bash
# Manual install using PKGBUILD
wget https://github.com/ciresnave/json-mcp-server/releases/latest/download/PKGBUILD
makepkg -si
```

### Building from Source

```bash
# Clone the repository
git clone https://github.com/ciresnave/json-mcp-server.git
cd json-mcp-server

# Build the project
cargo build --release

# Run the server
cargo run
```

### Verification

After installation, verify it works:

```bash
json-mcp-server --version
json-mcp-server --help
```

## Usage

The JSON MCP Server communicates via JSON-RPC over stdin/stdout following the Model Context Protocol specification.

### Getting Started

1. **Start the server**:
   ```bash
   cargo run
   ```

2. **Get help**: Use the `json-help` tool to learn about available functionality:
   ```json
   {
     "jsonrpc": "2.0",
     "id": 1,
     "method": "tools/call",
     "params": {
       "name": "json-help",
       "arguments": {"topic": "overview"}
     }
   }
   ```

### Example Usage

#### Reading JSON Files

```json
{
  "name": "json-read",
  "arguments": {
    "file_path": "./data.json",
    "query": "$.users[*].name"
  }
}
```

#### Writing JSON Data

```json
{
  "name": "json-write", 
  "arguments": {
    "file_path": "./config.json",
    "data": {"setting": "value", "enabled": true},
    "mode": "merge"
  }
}
```

#### Querying with JSONPath

```json
{
  "name": "json-query",
  "arguments": {
    "file_path": "./products.json", 
    "query": "$.products[?(@.price > 100)].name",
    "format": "table"
  }
}
```

#### Processing Large Files

```json
{
  "name": "json-read",
  "arguments": {
    "file_path": "./large-dataset.json",
    "query": "$.records[*].id",
    "limit": 1000,
    "offset": 0
  }
}
```

## Tool Reference

### json-read

Read and parse JSON files with optional JSONPath filtering and pagination.

**Parameters:**
- `file_path` (string, required): Path to JSON file
- `query` (string, optional): JSONPath expression for filtering
- `offset` (integer, optional): Number of results to skip (default: 0)
- `limit` (integer, optional): Maximum results to return (default: 1000, max 10000)

### json-write

Write or update JSON files with flexible merge strategies.

**Parameters:**
- `file_path` (string, required): Path to JSON file
- `data` (any JSON value, required): JSON data to write
- `mode` (string, optional): "replace", "merge" (shallow object merge) or "append" (array append) (default: "replace")
- `create_dirs` (boolean, optional): Create parent directories (default: true)
- `pretty` (boolean, optional): Indent the output (default: true)

### json-query

Execute JSONPath queries on JSON files with various output formats.

**Parameters:**
- `file_path` (string, required): Path to JSON file
- `query` (string, required): JSONPath query expression
- `format` (string, optional): "json", "text" or "table" (default: "json")

### json-validate

Validate JSON file structure and syntax.

**Parameters:**
- `file_path` (string, required): Path to JSON file to validate
- `schema` (any JSON value, optional): JSON schema to validate against

### json-help

Get usage guidance for the tools.

**Parameters:**
- `topic` (string, optional): Help topic - "overview", "reading", "writing", "querying", "streaming", "examples", "tools" (default: "overview")

## JSONPath Support

The server supports full JSONPath syntax for querying JSON data:

- `$` - Root element
- `.field` - Child field access
- `[index]` - Array index access  
- `[*]` - All array elements
- `..field` - Recursive descent
- `[?(@.field > value)]` - Filter expressions
- `{field1, field2}` - Projection

### JSONPath Examples

```bash
# Get all user names
$.users[*].name

# Filter users over 25
$.users[?(@.age > 25)]

# Get nested data
$.data.items[*].details.price

# All prices anywhere in document  
$..price

# Complex filtering
$.products[?(@.category == 'electronics' && @.price < 500)].name
```

## Performance Notes

### Large File Handling
- Line-delimited JSON: detected from the first lines of the file and read record by record, so memory stays small regardless of file size
- A single large JSON document is parsed whole before paging, so memory grows with file size

### Best Practices
- Use specific JSONPath queries to filter data early
- Set reasonable limits when processing large datasets
- Use offset for pagination through large result sets

## Error Handling

The server provides detailed error messages to help diagnose issues:

- **File not found**: Clear path resolution guidance
- **JSON syntax errors**: Line and column information when available
- **JSONPath errors**: Syntax validation and suggestions
- **Memory issues**: Guidance on using streaming alternatives

## MCP Client Configuration

The JSON MCP Server works with any MCP-compatible client. Detailed configuration guides are available in the `examples/mcp_clients/` directory:

### Supported Clients

- **[VS Code with GitHub Copilot](examples/mcp_clients/github-copilot.md)** - Complete setup guide
- **[Claude Desktop](examples/mcp_clients/claude-desktop.md)** - Configuration and usage examples  
- **[Generic MCP Client](examples/mcp_clients/generic.md)** - Universal configuration guide
- **[Custom Implementation](examples/mcp_clients/client_implementation.md)** - Build your own client

### Quick Setup

**VS Code + GitHub Copilot:**
```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server"
    }
  }
}
```

**Claude Desktop:**
```json
{
  "mcpServers": {
    "json-mcp-server": {
      "command": "json-mcp-server",
      "args": []
    }
  }
}
```

**Gemini CLI** (`.gemini/settings.json`) and **Cline** use the same shape:
```json
{
  "mcpServers": {
    "json-mcp-server": { "command": "json-mcp-server", "args": [] }
  }
}
```
If a client cannot connect, add `"env": { "MCP_DEBUG_LOG": "/tmp/json-mcp.log" }` to the server entry and read the log of every message exchanged.

For detailed setup instructions, troubleshooting, and advanced configurations, see the respective client guides in the `examples/mcp_clients/` directory.

## Development

## Project Structure

```
json-mcp-server/
├── src/                    # Source code
│   ├── main.rs            # Application entry point and MCP server
│   ├── lib.rs             # Library exports for testing
│   ├── mcp/               # MCP protocol implementation
│   │   ├── mod.rs
│   │   ├── protocol.rs    # Protocol definitions and types
│   │   └── server.rs      # MCP server implementation
│   └── json_tools/        # JSON tool implementations
│       ├── mod.rs
│       ├── handler.rs     # Tool coordination and help system
│       ├── operations.rs  # Read/write/validate operations
│       ├── query.rs       # JSONPath querying with multiple formats
│       └── streaming.rs   # Large file streaming and pagination
├── tests/                 # Integration tests
│   └── integration_tests.rs
├── examples/              # Example configurations and data
│   ├── mcp_clients/       # Client configuration guides
│   │   ├── vscode.md      # VS Code setup
│   │   ├── claude-desktop.md
│   │   ├── github-copilot.md
│   │   ├── generic.md     # Generic MCP client setup
│   │   ├── client_implementation.md
│   │   └── python_client.py
│   ├── sample-data.json   # Sample test data
│   ├── test-commands.jsonl
│   └── test-output.json
├── dev_tools/             # Development and testing utilities
│   ├── README.md          # Development tools documentation
│   └── testing/           # Test scripts and utilities
│       ├── test_all_tools.py
│       ├── test_multiple_instances.py
│       ├── test_json_help.py
│       └── [other test files]
├── Cargo.toml            # Rust project configuration
└── README.md             # This file
```

### Building
```bash
# Development build
cargo build

# Release build  
cargo build --release

# Run tests
cargo test

# Check for issues
cargo check
```

### Dependencies
- `tokio`: Async runtime
- `serde`/`serde_json`: JSON serialization
- `jsonpath-rust`: JSONPath query support
- `anyhow`: Error handling
- `clap`: Command line parsing

## License

This project is licensed under the MIT OR Apache-2.0 license.

## Contributing

Contributions are welcome! Please ensure:

1. Code follows Rust conventions
2. All tests pass
3. New features include appropriate tests
4. Documentation is updated for new functionality

## Support

For issues, questions, or contributions, please refer to the project repository.
