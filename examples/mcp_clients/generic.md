# Generic MCP Client Configuration

This guide covers configuration for any MCP-compatible client that supports the Model Context Protocol.

## Overview

The JSON MCP Server implements the Model Context Protocol specification and can work with any compliant MCP client. This includes AI assistants, development tools, and custom applications.

## Basic MCP Configuration

### Server Command

```bash
json-mcp-server
```

### Arguments (Optional)

- `--log-level <level>`: Set logging level (error, warn, info, debug, trace)
- `--help`: Show help information
- `--version`: Show version information

### Environment Variables

- `RUST_LOG`: Controls Rust logging output
- `JSON_MCP_DEBUG`: Enable debug mode (true/false)

## Standard MCP Configuration Format

Most MCP clients use a similar configuration format:

```json
{
  "mcpServers": {
    "json-operations": {
      "command": "json-mcp-server",
      "args": [],
      "env": {},
      "cwd": null
    }
  }
}
```

## Client-Specific Examples

### Claude Desktop

Configuration file: `claude_desktop_config.json`

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

### VS Code with GitHub Copilot

Configuration file: User Settings → Extensions → MCP

```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server"
    }
  }
}
```

### Custom MCP Client

Basic connection:

```python
import asyncio
from mcp_client import MCPClient

async def connect_to_json_server():
    client = MCPClient()
    await client.connect("json-mcp-server", [])
    
    # List available tools
    tools = await client.list_tools()
    print("Available tools:", tools)
    
    # Use a tool
    result = await client.call_tool("json-validate", {
        "file_path": "/path/to/file.json"
    })
    print("Validation result:", result)
```

## Available Tools

### json-read

Read and optionally filter JSON files.

**Parameters:**
- `file_path` (required): Path to JSON file
- `json_path` (optional): JSONPath filter expression
- `start_index` (optional): Starting index for array data
- `limit` (optional): Maximum items to return
- `output_format` (optional): json, pretty, compact

### json-write

Write or update JSON files with various merge strategies.

**Parameters:**
- `file_path` (required): Target file path
- `content` (required): JSON content to write
- `mode` (optional): replace, merge_shallow, merge_deep, append

### json-query

Execute complex JSONPath queries on JSON files.

**Parameters:**
- `file_path` (required): Path to JSON file
- `json_path` (required): JSONPath query expression
- `output_format` (optional): json, pretty, compact, csv, markdown

### json-validate

Validate JSON file syntax and structure.

**Parameters:**
- `file_path` (required): Path to JSON file to validate

### json-help

Get comprehensive help and examples.

**Parameters:**
- `topic` (optional): Specific help topic (overview, tools, jsonpath, examples, troubleshooting)

## Integration Examples

### Basic File Validation

```json
{
  "tool": "json-validate",
  "arguments": {
    "file_path": "/data/config.json"
  }
}
```

### Complex Data Query

```json
{
  "tool": "json-query", 
  "arguments": {
    "file_path": "/data/users.json",
    "json_path": "$.users[?(@.age > 25)].name",
    "output_format": "markdown"
  }
}
```

### Configuration Update

```json
{
  "tool": "json-write",
  "arguments": {
    "file_path": "/config/app.json",
    "content": "{\"database\": {\"host\": \"localhost\"}}",
    "mode": "merge_deep"
  }
}
```

### Large File Processing

```json
{
  "tool": "json-read",
  "arguments": {
    "file_path": "/data/large-dataset.json", 
    "json_path": "$.records",
    "start_index": 1000,
    "limit": 50,
    "output_format": "compact"
  }
}
```

## Protocol Details

### MCP Version

The server implements MCP protocol version 2024-11-05.

### Capabilities

- **Tools**: All 5 JSON operation tools
- **Resources**: File system access (read/write)
- **Prompts**: None (tools-only server)
- **Sampling**: Not supported

### Error Handling

The server provides detailed error messages following MCP error standards:

- Invalid parameters
- File access errors  
- JSON parsing errors
- JSONPath syntax errors
- Permission denied errors

### Resource Management

- **Memory**: Efficient streaming for large files
- **File Handles**: Automatic cleanup and proper closing
- **Concurrency**: Thread-safe operations
- **Limits**: Configurable limits for large datasets

## Best Practices

### Performance

1. **Use JSONPath filtering** to reduce data transfer
2. **Set appropriate limits** for large datasets
3. **Use streaming mode** for very large files
4. **Cache frequently accessed files** in your client

### Security

1. **Validate file paths** before sending to server
2. **Use absolute paths** when possible
3. **Check permissions** on target directories
4. **Sanitize user input** before passing to tools

### Error Handling

1. **Check tool responses** for error status
2. **Provide fallback behavior** for common errors
3. **Log errors** for debugging
4. **Validate JSON** before writing operations

### Development

1. **Start with simple operations** to test connectivity
2. **Use json-help** to explore capabilities
3. **Test with small files** before large datasets
4. **Monitor resource usage** during development

## Debugging

### Enable Debug Logging

Set environment variables:

```bash
RUST_LOG=debug json-mcp-server
```

Or use command line arguments:

```bash
json-mcp-server --log-level debug
```

### Common Issues

1. **Tool not found**: Verify server is running and accessible
2. **Permission denied**: Check file system permissions
3. **Invalid JSON**: Validate input before sending
4. **Memory issues**: Use streaming for large files
5. **Path errors**: Use absolute paths when possible

### Log Analysis

Debug logs include:

- Tool execution timing
- File access operations
- JSON parsing details
- Memory usage patterns
- Error stack traces

### Testing Connection

Basic connectivity test:

```json
{
  "tool": "json-help",
  "arguments": {
    "topic": "overview"
  }
}
```

## Support

### Documentation

- **Built-in help**: Use `json-help` tool
- **Examples**: See `examples/` directory
- **Tests**: Reference `tests/` for usage patterns

### Community

- **Issues**: Report bugs via GitHub issues
- **Discussions**: Join MCP community forums
- **Contributions**: Submit pull requests for improvements

### Version Compatibility

- **MCP Protocol**: 2024-11-05
- **JSON Standards**: RFC 7159, RFC 8259
- **JSONPath**: JSONPath specification draft
- **Rust**: Minimum supported version in Cargo.toml
