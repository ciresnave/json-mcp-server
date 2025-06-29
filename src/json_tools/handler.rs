use crate::json_tools::{operations::JsonOperations, query::JsonQuery, streaming::JsonStreaming};
use crate::mcp::protocol::{Tool, ToolCall, ToolResult};
use crate::mcp::server::ToolHandler;
use serde_json::{json, Value};
use std::collections::HashMap;

pub struct JsonToolsHandler {
    operations: JsonOperations,
    query: JsonQuery,
    streaming: JsonStreaming,
}

impl JsonToolsHandler {
    pub fn new() -> Self {
        Self {
            operations: JsonOperations::new(),
            query: JsonQuery::new(),
            streaming: JsonStreaming::new(),
        }
    }

    fn create_json_help_tool() -> Tool {
        Tool {
            name: "json-help".to_string(),
            description: "Get comprehensive help about all available JSON tools and their usage patterns. This tool provides guidance on how to effectively use the JSON MCP server for various tasks.".to_string(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "topic": {
                        "type": "string",
                        "description": "Specific topic to get help about. Options: 'overview', 'reading', 'writing', 'querying', 'streaming', 'examples', 'tools'",
                        "enum": ["overview", "reading", "writing", "querying", "streaming", "examples", "tools"]
                    }
                },
                "required": []
            })
        }
    }

    async fn handle_json_help(&self, args: &HashMap<String, Value>) -> anyhow::Result<ToolResult> {
        let topic = args.get("topic")
            .and_then(|v| v.as_str())
            .unwrap_or("overview");

        let help_text = match topic {
            "overview" => {
                r#"# JSON MCP Server Help

This server provides comprehensive JSON file operations for LLMs. Available tools:

## Core Tools:
- **json-read**: Read and parse JSON files of any size with automatic streaming for large files
- **json-write**: Write or update JSON files with various merge strategies  
- **json-query**: Query JSON files using JSONPath expressions
- **json-validate**: Validate JSON structure and content
- **json-help**: Get help about tools (this tool)

## Required Parameters by Tool:
- **json-read**: `file_path` (required)
- **json-write**: `file_path`, `data` (both required)
- **json-query**: `file_path`, `query` (both required)
- **json-validate**: `file_path` (required)
- **json-help**: none (all parameters optional)

## Quick Start Examples:
```json
{"name": "json-read", "arguments": {"file_path": "./data.json"}}
{"name": "json-write", "arguments": {"file_path": "./output.json", "data": {"key": "value"}}}
{"name": "json-query", "arguments": {"file_path": "./data.json", "query": "$.users[0].name"}}
{"name": "json-validate", "arguments": {"file_path": "./data.json"}}
{"name": "json-help", "arguments": {"topic": "reading"}}
```

## Key Features:
- Support for extremely large JSON files via automatic streaming
- JSONPath querying for complex data extraction
- Multiple write/update modes (replace, merge, append)
- Validation and error handling with detailed diagnostics
- LLM-optimized responses and formatting
- Robust error handling for malformed JSON

Use 'json-help' with specific topics for detailed guidance:
- topic: 'reading' - Learn about reading JSON files
- topic: 'writing' - Learn about writing/updating JSON files  
- topic: 'querying' - Learn about JSONPath queries
- topic: 'streaming' - Learn about handling large files
- topic: 'examples' - See practical usage examples
- topic: 'tools' - Get detailed help for individual tools"#
            },
            "reading" => {
                r#"# Reading JSON Files

## json-read Tool
Reads and parses JSON files with automatic streaming for large files.

**Parameters:**
- `file_path` (required): Path to JSON file
- `json_path` (optional): JSONPath to extract specific data
- `format` (optional): Output format - "pretty", "compact", "raw" (default: "pretty")
- `offset` (optional): Starting position for streaming (default: 0)
- `limit` (optional): Maximum number of items to return (default: 1000)

**Examples:**
```json
{
  "name": "json-read",
  "arguments": {
    "file_path": "./data.json"
  }
}
```

```json
{
  "name": "json-read", 
  "arguments": {
    "file_path": "./users.json",
    "json_path": "$.users[*].name",
    "format": "compact"
  }
}
```

**Use Cases:**
- Load entire JSON files (automatically streams if large)
- Extract specific fields or arrays
- Read configuration files
- Parse API responses stored as JSON
- Handle large datasets efficiently"#
            },
            "writing" => {
                r#"# Writing JSON Files

## json-write Tool
Creates or updates JSON files with flexible merge strategies.

**Parameters:**
- `file_path` (required): Path to JSON file
- `data` (required): JSON data to write
- `mode` (optional): Write mode - "replace", "merge", "append" (default: "replace")
- `create_path` (optional): Create directory if needed (default: true)
- `backup` (optional): Create backup before writing (default: false)

**Write Modes:**
- **replace**: Completely replace file content
- **merge**: Merge with existing JSON (objects only)
- **append**: Append to arrays or create new array

**Examples:**
```json
{
  "name": "json-write",
  "arguments": {
    "file_path": "./config.json",
    "data": {"setting": "value", "enabled": true}
  }
}
```

```json
{
  "name": "json-write",
  "arguments": {
    "file_path": "./users.json", 
    "data": {"name": "John", "age": 30},
    "mode": "append"
  }
}
```"#
            },
            "querying" => {
                r#"# Querying JSON with JSONPath

## json-query Tool
Execute complex JSONPath queries on JSON files.

**Parameters:**
- `file_path` (required): Path to JSON file
- `query` (required): JSONPath expression
- `format` (optional): Output format - "json", "text", "table" (default: "json")

**JSONPath Syntax:**
- `$` - Root element
- `.` - Child element  
- `[]` - Array index or filter
- `*` - Wildcard
- `..` - Recursive descent
- `[?()]` - Filter expression

**Examples:**
```json
{
  "name": "json-query",
  "arguments": {
    "file_path": "./data.json",
    "query": "$.users[?(@.age > 25)].name"
  }
}
```

```json
{
  "name": "json-query", 
  "arguments": {
    "file_path": "./products.json",
    "query": "$..products[*].price",
    "format": "table"
  }
}
```

**Common Patterns:**
- `$.array[*]` - All array elements
- `$..field` - All fields named 'field' anywhere
- `$.object.field` - Specific nested field
- `$[*]` - All root level elements"#
            },
            "streaming" => {
                r#"# Streaming Large JSON Files

## json-read Tool (Automatic Streaming)
The json-read tool automatically handles large files via streaming without loading everything into memory.

**Streaming Features:**
- Automatically detects when to use streaming mode
- Handle files larger than available RAM
- Fast queries on massive datasets  
- Memory-efficient processing
- Progressive results for interactive use

**Parameters for Large Files:**
- `file_path` (required): Path to large JSON file
- `json_path` (optional): JSONPath to filter data during streaming
- `limit` (optional): Maximum number of results (default: 1000)
- `offset` (optional): Skip number of results (default: 0)
- `format` (optional): Output format - "pretty", "compact", "raw"

**Examples:**
```json
{
  "name": "json-read",
  "arguments": {
    "file_path": "./large-dataset.json",
    "json_path": "$.records[*].id",
    "limit": 100
  }
}
```

**Best Practices:**
- Use specific JSONPath queries to filter early
- Set reasonable limits for large datasets
- Use offset for pagination
- Stream arrays rather than large objects when possible"#
            },
            "examples" => {
                r#"# Practical JSON Tool Examples

## Example 1: Configuration Management
```json
// Read config
{"name": "json-read", "arguments": {"file_path": "./config.json"}}

// Update specific setting
{"name": "json-write", "arguments": {
  "file_path": "./config.json",
  "data": {"database": {"host": "localhost", "port": 5432}},
  "mode": "merge"
}}
```

## Example 2: Data Analysis
```json
// Query user data
{"name": "json-query", "arguments": {
  "file_path": "./users.json", 
  "query": "$.users[?(@.active == true)]",
  "format": "table"
}}

// Count by category
{"name": "json-query", "arguments": {
  "file_path": "./products.json",
  "query": "$..category"
}}
```

## Example 3: Large File Processing
```json
// Read large log file with automatic streaming
{"name": "json-read", "arguments": {
  "file_path": "./logs.json",
  "json_path": "$.logs[?(@.level == 'ERROR')]",
  "limit": 50
}}
```

## Example 4: API Response Handling
```json
// Extract specific fields
{"name": "json-read", "arguments": {
  "file_path": "./api-response.json",
  "json_path": "$.data.items[*].{id: id, name: name}"
}}
```

## Example 5: Batch Updates
```json
// Add new items to array
{"name": "json-write", "arguments": {
  "file_path": "./items.json",
  "data": [{"id": 123, "name": "New Item"}],
  "mode": "append"
}}
```"#
            },
            "tools" => {
                r#"# Individual Tool Help

## json-read
**Purpose**: Read and parse JSON files with automatic streaming
**Required**: `file_path`
**Optional**: `query`, `limit`, `offset`
**Example**: `{"file_path": "./data.json", "query": "$.users"}`

## json-write  
**Purpose**: Write or update JSON files with various merge strategies
**Required**: `file_path`, `data`
**Optional**: `mode`, `create_dirs`, `pretty`
**Example**: `{"file_path": "./output.json", "data": {"key": "value"}, "mode": "replace"}`

## json-query
**Purpose**: Execute JSONPath queries on JSON files
**Required**: `file_path`, `query`
**Optional**: `format`
**Example**: `{"file_path": "./data.json", "query": "$.users[?(@.age > 25)].name"}`

## json-validate
**Purpose**: Validate JSON file syntax and structure
**Required**: `file_path`
**Optional**: `schema`
**Example**: `{"file_path": "./data.json"}`

## json-help
**Purpose**: Get help about tools and usage patterns
**Required**: none
**Optional**: `topic`
**Example**: `{"topic": "reading"}` or `{}`

## Common Error Fixes:
- **"file_path is required"** → Add: `"file_path": "./your-file.json"`
- **"data is required"** → Add: `"data": {"your": "json data"}`
- **"query is required"** → Add: `"query": "$.your.jsonpath"`"#
            },
            _ => "Unknown help topic. Available topics: overview, reading, writing, querying, streaming, examples, tools"
        };

        Ok(ToolResult::success(help_text.to_string()))
    }
}

#[async_trait::async_trait]
impl ToolHandler for JsonToolsHandler {
    async fn get_tools(&self) -> anyhow::Result<Vec<Tool>> {
        let mut tools = Vec::new();
        
        // Add all tool categories
        tools.extend(self.operations.get_tools().await?);
        tools.extend(self.query.get_tools().await?);
        tools.extend(self.streaming.get_tools().await?);
        
        // Add help tool
        tools.push(Self::create_json_help_tool());
        
        Ok(tools)
    }

    async fn call_tool(&self, tool_call: ToolCall) -> anyhow::Result<ToolResult> {
        match tool_call.name.as_str() {
            "json-help" => self.handle_json_help(&tool_call.arguments).await,
            name if name.starts_with("json-write") || name.starts_with("json-validate") => {
                self.operations.call_tool(tool_call).await
            },
            name if name.starts_with("json-query") => {
                self.query.call_tool(tool_call).await
            },
            name if name.starts_with("json-read") => {
                self.streaming.call_tool(tool_call).await
            },
            _ => Ok(ToolResult::error(format!("Unknown tool: {}", tool_call.name))),
        }
    }
}
