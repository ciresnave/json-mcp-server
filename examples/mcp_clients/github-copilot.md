# GitHub Copilot (VS Code) Configuration

This guide shows how to configure the JSON MCP Server with GitHub Copilot in VS Code.

## Prerequisites

- VS Code with GitHub Copilot extension
- JSON MCP Server installed and accessible in PATH
- MCP extension for VS Code (if available)

## Configuration Methods

### Method 1: VS Code Settings (Recommended)

1. **Open VS Code Settings** (`Ctrl+,` or `Cmd+,`)
2. **Search for "MCP"** in the settings
3. **Add server configuration**:

```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server",
      "args": []
    }
  }
}
```

### Method 2: User Settings JSON

1. **Open Command Palette** (`Ctrl+Shift+P` or `Cmd+Shift+P`)
2. **Type "Preferences: Open User Settings (JSON)"**
3. **Add MCP configuration**:

```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server",
      "args": ["--log-level", "info"],
      "env": {
        "RUST_LOG": "json_mcp_server=info"
      }
    }
  }
}
```

### Method 3: Workspace Settings

For project-specific configuration:

1. **Create `.vscode/settings.json`** in your workspace
2. **Add MCP configuration**:

```json
{
  "mcp.servers": {
    "json-operations": {
      "path": "/absolute/path/to/json-mcp-server",
      "args": [],
      "workingDirectory": "${workspaceFolder}"
    }
  }
}
```

## Advanced Configuration

### Multiple Environments

```json
{
  "mcp.servers": {
    "json-dev": {
      "path": "json-mcp-server",
      "args": ["--log-level", "debug"],
      "env": {
        "RUST_LOG": "debug"
      }
    },
    "json-prod": {
      "path": "json-mcp-server",
      "args": []
    }
  }
}
```

### Custom Working Directory

```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server",
      "args": [],
      "workingDirectory": "/path/to/data/directory",
      "env": {
        "JSON_DATA_PATH": "/path/to/data"
      }
    }
  }
}
```

### Debug Configuration

```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server", 
      "args": ["--log-level", "debug"],
      "env": {
        "RUST_LOG": "json_mcp_server=debug",
        "JSON_MCP_DEBUG": "true"
      }
    }
  }
}
```

## Usage with GitHub Copilot

### Basic JSON Operations

Once configured, you can ask GitHub Copilot to help with JSON operations:

**Example Prompts:**

> "Help me validate the JSON file `config.json` in my workspace"

> "Extract all user names from `users.json` where the age is greater than 25"

> "Update my `package.json` to add a new dependency"

> "Check if `data.json` has valid JSON syntax"

### Working with Large Files

> "Show me the first 50 records from `large-dataset.json`"

> "Find all entries in `logs.json` from today"

> "Count how many users have premium accounts in `users.json`"

### Configuration Management

> "Merge this new configuration into `app-config.json`:
> ```json
> {
>   "database": {
>     "host": "localhost",
>     "port": 5432
>   }
> }
> ```"

> "Add a new feature flag to `features.json`"

> "Update the API endpoint in `config.json`"

### Data Analysis

> "Analyze the structure of `api-response.json`"

> "Show me all error entries from `error-log.json`"

> "Extract unique categories from `products.json`"

## Available Tools in Copilot Context

When the JSON MCP Server is properly configured, GitHub Copilot has access to these tools:

### json-read
- **Purpose**: Read JSON files with optional filtering
- **Copilot Usage**: "Read the contents of file.json"

### json-write  
- **Purpose**: Write or update JSON files
- **Copilot Usage**: "Update config.json with new settings"

### json-query
- **Purpose**: Execute JSONPath queries
- **Copilot Usage**: "Find all users with role 'admin' in users.json"

### json-validate
- **Purpose**: Validate JSON syntax and structure
- **Copilot Usage**: "Check if data.json is valid JSON"

### json-help
- **Purpose**: Get help and examples
- **Copilot Usage**: "Show me JSONPath examples"

## Example Workflows

### Configuration Management Workflow

1. **Ask Copilot to validate** your configuration file
2. **Request specific updates** to configuration values
3. **Verify the changes** by reading the updated file
4. **Get help** if you need JSONPath syntax examples

```
User: "Validate my app-config.json file"
Copilot: [Uses json-validate tool]

User: "Add a new database configuration section"
Copilot: [Uses json-write with merge_deep mode]

User: "Show me the updated database section"
Copilot: [Uses json-query with $.database path]
```

### Data Analysis Workflow

1. **Load and examine** your data file structure
2. **Query specific subsets** of the data
3. **Extract insights** using JSONPath queries
4. **Format results** for better readability

```
User: "Analyze the structure of sales-data.json"
Copilot: [Uses json-read to examine structure]

User: "Show sales over $1000 from last month"
Copilot: [Uses json-query with filtering]

User: "Format the results as a markdown table"
Copilot: [Uses json-query with markdown output]
```

### Development Workflow

1. **Validate JSON files** in your project
2. **Update package configurations** as needed
3. **Manage environment-specific** configurations
4. **Process API responses** and test data

```
User: "Check all JSON files in my project for syntax errors"
Copilot: [Uses json-validate on multiple files]

User: "Update package.json to add a new dev dependency"
Copilot: [Uses json-write with merge strategy]

User: "Extract error messages from test-results.json"
Copilot: [Uses json-query to find errors]
```

## Troubleshooting

### Tool Not Available

**Symptoms**: Copilot says it can't access JSON tools

**Solutions**:
1. **Verify server path** in settings
2. **Check if server is installed** (`json-mcp-server --version`)
3. **Restart VS Code** after configuration changes
4. **Check VS Code output panel** for MCP errors

### Permission Errors

**Symptoms**: "Permission denied" or "Access denied" errors

**Solutions**:
1. **Check file permissions** on target JSON files
2. **Use absolute paths** in configuration
3. **Verify working directory** settings
4. **Run VS Code with appropriate permissions**

### Server Not Starting

**Symptoms**: MCP server fails to initialize

**Solutions**:
1. **Test server manually** in terminal: `json-mcp-server --help`
2. **Check PATH** contains server location
3. **Verify dependencies** are installed
4. **Review environment variables** in configuration

### Large File Performance

**Symptoms**: Slow responses with large JSON files

**Solutions**:
1. **Use JSONPath filtering** to limit data
2. **Set appropriate limits** for queries
3. **Use pagination** with start_index and limit
4. **Process files in smaller chunks**

### Debugging MCP Communication

**Enable Debug Mode**:

```json
{
  "mcp.servers": {
    "json-mcp-server": {
      "path": "json-mcp-server",
      "args": ["--log-level", "debug"],
      "env": {
        "RUST_LOG": "debug"
      }
    }
  }
}
```

**Check Debug Logs**:
- Look for `mcp_debug.log` in your user directory
- Monitor VS Code Developer Tools console
- Check VS Code Output panel for MCP messages

## Best Practices

### File Organization

1. **Use relative paths** when possible for portability
2. **Organize JSON files** in logical directory structures
3. **Use consistent naming** conventions
4. **Keep large files** in separate directories

### Security

1. **Limit file access** to necessary directories
2. **Validate input data** before processing
3. **Use read-only mode** when appropriate
4. **Be cautious with automatic updates** to critical files

### Performance

1. **Use JSONPath queries** to filter data early
2. **Limit large query results** with pagination
3. **Cache frequently accessed** data
4. **Monitor resource usage** with large datasets

### Collaboration

1. **Share MCP configuration** via workspace settings
2. **Document JSON file** structures and purposes
3. **Use consistent JSONPath** patterns across team
4. **Version control** important JSON configurations

## Integration with Other Extensions

### With Thunder Client (API Testing)

Use JSON MCP Server to:
- **Validate API responses** from Thunder Client
- **Extract test data** from response files  
- **Manage environment** configurations
- **Process test results** for reporting

### With GitLens

Use JSON MCP Server to:
- **Analyze changes** in JSON configuration files
- **Track configuration** evolution over time
- **Validate JSON** before commits
- **Process blame** information for debugging

### With REST Client

Use JSON MCP Server to:
- **Prepare request payloads** from JSON files
- **Validate response** structures
- **Extract specific fields** from responses
- **Manage API** configuration files

## Migration from Other Tools

### From jq Command Line

Replace jq commands with JSON MCP Server:

**Before (jq)**:
```bash
jq '.users[].name' users.json
```

**After (via Copilot)**:
> "Extract all user names from users.json"

### From Manual JSON Editing

Replace manual editing with assisted operations:

**Before**: Manual editing with risk of syntax errors
**After**: Copilot-assisted updates with validation

### From Custom Scripts

Replace custom JSON processing scripts:

**Before**: Custom Python/Node.js scripts for JSON operations
**After**: Natural language requests to Copilot

## Future Enhancements

The JSON MCP Server is actively developed. Future versions may include:

- **Schema validation** against JSON Schema files
- **JSON-to-CSV** conversion capabilities  
- **Diff and merge** operations between JSON files
- **Template-based** JSON generation
- **Batch operations** on multiple files
- **Real-time file** watching and updates

Stay updated by checking the project repository for new releases and features.
