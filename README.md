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

- **Large File Support**: Efficient pagination and streaming for files of any size
- **JSONPath Querying**: Full JSONPath support for complex data extraction and filtering
- **Flexible Writing**: Multiple modes (replace, merge_shallow, merge_deep, append) with backup options
- **LLM-Optimized**: Detailed error messages and usage examples for optimal LLM interaction
- **Memory Efficient**: Smart pagination prevents memory overflow on large datasets
- **MCP Compliant**: Full Model Context Protocol support with proper error handling
- **Debug Logging**: File-based debug logging for troubleshooting without violating MCP protocol

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
    "json_path": "$.users[*].name",
    "format": "pretty"
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
    "json_path": "$.records[*].id", 
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
- `json_path` (string, optional): JSONPath expression for filtering
- `start_index` (integer, optional): Starting index for pagination (default: 0)
- `limit` (integer, optional): Maximum items to return (default: 1000)
- `output_format` (string, optional): Output format - "json", "pretty", "compact" (default: "json")

### json-write

Write or update JSON files with flexible merge strategies.

**Parameters:**
- `file_path` (string, required): Path to JSON file
- `content` (string, required): JSON content to write
- `mode` (string, optional): Write mode - "replace", "merge_shallow", "merge_deep", "append" (default: "replace")

### json-query

Execute JSONPath queries on JSON files with various output formats.

**Parameters:**
- `file_path` (string, required): Path to JSON file
- `json_path` (string, required): JSONPath query expression
- `output_format` (string, optional): Output format - "json", "pretty", "compact", "csv", "markdown" (default: "json")

### json-validate

Validate JSON file structure and syntax.

**Parameters:**
- `file_path` (string, required): Path to JSON file to validate

### json-help

Get comprehensive help about available tools and JSONPath syntax.

**Parameters:**
- `topic` (string, optional): Help topic - "overview", "tools", "jsonpath", "examples", "troubleshooting" (default: "overview")

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
- Files of any size: The `json-read` tool automatically uses streaming for memory efficiency
- Line-delimited JSON: Automatically detected and processed efficiently  
- Memory usage: Streaming keeps memory usage constant regardless of file size

### Best Practices
- Use specific JSONPath queries to filter data early
- Set reasonable limits when processing large datasets
- Use offset for pagination through large result sets
- The server automatically optimizes for file size and available memory

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
