# VS Code Configuration

## Prerequisites

- VS Code Insiders (recommended) or regular VS Code
- JSON MCP Server installed and available in PATH

## Configuration

### Method 1: Global MCP Configuration

1. Open VS Code settings (Ctrl+,)
2. Search for "MCP" 
3. Edit the MCP configuration or create/edit your MCP config file:

**Windows**: `%APPDATA%\Code\User\mcp.json`  
**macOS**: `~/Library/Application Support/Code/User/mcp.json`  
**Linux**: `~/.config/Code/User/mcp.json`

```json
{
  "servers": {
    "json-mcp-server": {
      "id": "json-mcp-server",
      "name": "JSON MCP Server",
      "version": "0.1.0",
      "config": {
        "type": "stdio",
        "command": "json-mcp-server",
        "args": []
      }
    }
  },
  "inputs": []
}
```

### Method 2: Workspace-Specific Configuration

Create `.vscode/mcp.json` in your workspace:

```json
{
  "servers": {
    "json-mcp-server": {
      "id": "json-mcp-server", 
      "name": "JSON MCP Server",
      "version": "0.1.0",
      "config": {
        "type": "stdio",
        "command": "/path/to/json-mcp-server",
        "args": [],
        "cwd": "${workspaceFolder}"
      }
    }
  }
}
```

## Usage

1. **Restart VS Code** after configuration
2. **Open Command Palette** (Ctrl+Shift+P)
3. **Look for MCP tools** in the assistant interface
4. **Start with help**: Call `json-help` to see available tools

## Example Usage in VS Code

When working with the assistant, you can now use:

```
Can you validate this JSON file for me?
[Assistant will use json-validate tool]

Please query my users.json file for all active users
[Assistant will use json-query with JSONPath]

Help me merge this new data into my config file
[Assistant will use json-write with merge mode]
```

## Troubleshooting

### Server Not Found
- Ensure `json-mcp-server` is in your system PATH
- Use absolute path in configuration if needed
- Check VS Code output panel for MCP logs

### Permission Issues  
- Ensure the executable has proper permissions
- On Unix systems: `chmod +x json-mcp-server`

### Protocol Violations
- Check for any stdout output from the server
- Enable logging with `--log-level debug` for troubleshooting
- Logs go to stderr, not stdout (MCP compliant)

## Advanced Configuration

### With Custom Working Directory
```json
{
  "config": {
    "type": "stdio", 
    "command": "json-mcp-server",
    "args": ["--log-level", "info"],
    "cwd": "/path/to/data/directory",
    "env": {
      "RUST_LOG": "json_mcp_server=debug"
    }
  }
}
```

### Multiple Instances
You can run multiple instances with different configurations:

```json
{
  "servers": {
    "json-mcp-dev": {
      "id": "json-mcp-dev",
      "name": "JSON MCP (Development)",
      "config": {
        "command": "/path/to/dev/json-mcp-server",
        "args": ["--log-level", "debug"]
      }
    },
    "json-mcp-prod": {
      "id": "json-mcp-prod", 
      "name": "JSON MCP (Production)",
      "config": {
        "command": "json-mcp-server",
        "args": []
      }
    }
  }
}
```
