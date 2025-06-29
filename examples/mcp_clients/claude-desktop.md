# Claude Desktop Configuration

## Prerequisites

- Claude Desktop application
- JSON MCP Server built and available

## Configuration

Claude Desktop uses a configuration file to define MCP servers.

### Configuration File Location

**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`  
**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`  
**Linux**: `~/.config/Claude/claude_desktop_config.json`

### Basic Configuration

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

### Advanced Configuration

```json
{
  "mcpServers": {
    "json-mcp-server": {
      "command": "/full/path/to/json-mcp-server",
      "args": ["--log-level", "info"],
      "env": {
        "RUST_LOG": "json_mcp_server=info"
      },
      "cwd": "/path/to/working/directory"
    }
  }
}
```

### Multiple Environment Setup

```json
{
  "mcpServers": {
    "json-mcp-dev": {
      "command": "/path/to/dev/json-mcp-server", 
      "args": ["--log-level", "debug"]
    },
    "json-mcp-prod": {
      "command": "json-mcp-server",
      "args": []
    }
  }
}
```

## Usage

1. **Save configuration** and restart Claude Desktop
2. **Start a conversation** and mention JSON file operations
3. **Claude will automatically** use the JSON MCP Server tools when appropriate

### Example Conversations

**Validate a JSON file:**
```
"Can you check if this JSON file is valid? /path/to/my/file.json"
```

**Query JSON data:**
```
"Extract all user names from users.json where age > 25"
```

**Merge JSON data:**
```
"Add this new configuration to my config.json file:
{\"new_setting\": \"value\"}"
```

**Process large datasets:**
```
"Show me the first 50 records from this large JSON file, 
starting from record 100"
```

## Advanced Features

### Working with Complex Data

Claude can now help you:

- **Validate JSON schemas** against your data files
- **Extract specific fields** using JSONPath expressions  
- **Merge configurations** safely without overwriting
- **Process large files** efficiently with streaming
- **Transform data structures** between different formats

### Example Workflows

**Configuration Management:**
```
"I need to update my app config. Here's the new database settings:
{\"database\": {\"host\": \"newhost\", \"port\": 5432}}

Please merge this into config.json but keep all existing settings."
```

**Data Analysis:**
```
"From sales-data.json, show me all transactions over $1000 
from the last quarter, grouped by customer."
```

**Batch Processing:**
```
"I have user-data.json with 10,000 records. 
Show me users in the 'premium' tier who haven't logged in recently."
```

## Troubleshooting

### Server Not Starting

1. **Check the path** to json-mcp-server
2. **Verify permissions** on the executable
3. **Check Claude Desktop logs** for error messages

### Tool Not Available

1. **Restart Claude Desktop** after configuration changes
2. **Verify JSON syntax** in configuration file
3. **Test with simple file operations** first

### Performance Issues

1. **Use JSONPath queries** to filter data early
2. **Set appropriate limits** for large files
3. **Use streaming features** for very large datasets

### Debugging

Enable debug logging:

```json
{
  "mcpServers": {
    "json-mcp-server": {
      "command": "json-mcp-server",
      "args": ["--log-level", "debug"],
      "env": {
        "RUST_LOG": "debug"
      }
    }
  }
}
```

Debug logs will help identify:
- File access issues
- JSONPath syntax errors  
- Memory usage patterns
- Performance bottlenecks

## Best Practices

1. **Use absolute paths** for better reliability
2. **Start with simple operations** to verify setup
3. **Use JSONPath filtering** for large files
4. **Test configuration** after changes
5. **Monitor resource usage** with large datasets

## Security Considerations

- The server operates with **your user permissions**
- **File access is limited** to readable/writable locations  
- **No network access** - purely local file operations
- **Input validation** prevents malicious JSONPath injection
- **Memory limits** prevent resource exhaustion attacks
