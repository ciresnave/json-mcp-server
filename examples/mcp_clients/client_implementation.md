# Building Custom MCP Clients

This guide shows how to build custom clients for the JSON MCP Server.

## Protocol Basics

The JSON MCP Server implements the Model Context Protocol (MCP) over stdio. Communication happens via JSON-RPC 2.0 messages.

### Connection Flow

1. **Start server process** with stdin/stdout pipes
2. **Send initialize request** to establish connection
3. **Exchange tool calls** using JSON-RPC
4. **Close connection** by terminating process

### Message Format

All messages follow JSON-RPC 2.0:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "method_name",
  "params": { }
}
```

## Implementation Examples

### JavaScript/Node.js

```javascript
const { spawn } = require('child_process');

class JSONMCPClient {
  constructor() {
    this.requestId = 0;
    this.process = null;
  }

  async connect() {
    this.process = spawn('json-mcp-server', [], {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    const initRequest = {
      jsonrpc: "2.0",
      id: ++this.requestId,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} }
      }
    };

    return await this.sendRequest(initRequest);
  }

  async sendRequest(request) {
    return new Promise((resolve, reject) => {
      this.process.stdout.once('data', (data) => {
        try {
          resolve(JSON.parse(data.toString()));
        } catch (e) {
          reject(e);
        }
      });

      this.process.stdin.write(JSON.stringify(request) + '\n');
    });
  }

  async validateJSON(filePath) {
    const request = {
      jsonrpc: "2.0",
      id: ++this.requestId,
      method: "tools/call",
      params: {
        name: "json-validate",
        arguments: { file_path: filePath }
      }
    };

    return await this.sendRequest(request);
  }
}
```

### Rust

```rust
use serde_json::{json, Value};
use tokio::process::Command;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};

pub struct JSONMCPClient {
    process: Option<tokio::process::Child>,
    request_id: u64,
}

impl JSONMCPClient {
    pub fn new() -> Self {
        Self {
            process: None,
            request_id: 0,
        }
    }

    pub async fn connect(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        let mut process = Command::new("json-mcp-server")
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .spawn()?;

        let init_request = json!({
            "jsonrpc": "2.0",
            "id": self.next_id(),
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": { "tools": {} }
            }
        });

        self.send_request(&mut process, init_request).await?;
        self.process = Some(process);
        Ok(())
    }

    async fn send_request(
        &mut self,
        process: &mut tokio::process::Child,
        request: Value,
    ) -> Result<Value, Box<dyn std::error::Error>> {
        let stdin = process.stdin.as_mut().unwrap();
        let stdout = process.stdout.as_mut().unwrap();

        let request_str = serde_json::to_string(&request)?;
        stdin.write_all(format!("{}\n", request_str).as_bytes()).await?;
        stdin.flush().await?;

        let mut reader = BufReader::new(stdout);
        let mut response_line = String::new();
        reader.read_line(&mut response_line).await?;

        Ok(serde_json::from_str(&response_line)?)
    }

    fn next_id(&mut self) -> u64 {
        self.request_id += 1;
        self.request_id
    }
}
```

### Go

```go
package main

import (
    "bufio"
    "encoding/json"
    "os/exec"
)

type JSONMCPClient struct {
    cmd       *exec.Cmd
    stdin     io.WriteCloser
    stdout    io.ReadCloser
    requestID int
}

func NewJSONMCPClient() *JSONMCPClient {
    return &JSONMCPClient{requestID: 0}
}

func (c *JSONMCPClient) Connect() error {
    c.cmd = exec.Command("json-mcp-server")
    
    stdin, err := c.cmd.StdinPipe()
    if err != nil {
        return err
    }
    c.stdin = stdin

    stdout, err := c.cmd.StdoutPipe()
    if err != nil {
        return err
    }
    c.stdout = stdout

    if err := c.cmd.Start(); err != nil {
        return err
    }

    initRequest := map[string]interface{}{
        "jsonrpc": "2.0",
        "id":      c.nextID(),
        "method":  "initialize",
        "params": map[string]interface{}{
            "protocolVersion": "2024-11-05",
            "capabilities":    map[string]interface{}{"tools": map[string]interface{}{}},
        },
    }

    _, err = c.sendRequest(initRequest)
    return err
}

func (c *JSONMCPClient) sendRequest(request map[string]interface{}) (map[string]interface{}, error) {
    requestJSON, err := json.Marshal(request)
    if err != nil {
        return nil, err
    }

    if _, err := c.stdin.Write(append(requestJSON, '\n')); err != nil {
        return nil, err
    }

    scanner := bufio.NewScanner(c.stdout)
    if !scanner.Scan() {
        return nil, fmt.Errorf("no response from server")
    }

    var response map[string]interface{}
    if err := json.Unmarshal(scanner.Bytes(), &response); err != nil {
        return nil, err
    }

    return response, nil
}

func (c *JSONMCPClient) nextID() int {
    c.requestID++
    return c.requestID
}
```

## Available Methods

### Initialize

Establish connection with the server:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {}
    },
    "clientInfo": {
      "name": "my-client",
      "version": "1.0.0"
    }
  }
}
```

### List Tools

Get available tools:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}
```

### Call Tool

Execute a specific tool:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "json-validate",
    "arguments": {
      "file_path": "/path/to/file.json"
    }
  }
}
```

## Tool Reference

### json-read

Read JSON files with optional filtering:

```json
{
  "name": "json-read",
  "arguments": {
    "file_path": "/path/to/file.json",
    "json_path": "$.users[*].name",
    "limit": 10,
    "start_index": 0,
    "output_format": "pretty"
  }
}
```

### json-write

Write JSON content to files:

```json
{
  "name": "json-write", 
  "arguments": {
    "file_path": "/path/to/file.json",
    "content": "{\"key\": \"value\"}",
    "mode": "merge_deep"
  }
}
```

### json-query

Execute JSONPath queries:

```json
{
  "name": "json-query",
  "arguments": {
    "file_path": "/path/to/file.json",
    "json_path": "$.users[?(@.age > 25)]",
    "output_format": "markdown"
  }
}
```

### json-validate

Validate JSON syntax:

```json
{
  "name": "json-validate",
  "arguments": {
    "file_path": "/path/to/file.json"
  }
}
```

### json-help

Get documentation:

```json
{
  "name": "json-help",
  "arguments": {
    "topic": "jsonpath"
  }
}
```

## Error Handling

### Standard Errors

The server returns standard JSON-RPC errors:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "details": "file_path parameter is required"
    }
  }
}
```

### Common Error Codes

- **-32700**: Parse error (invalid JSON)
- **-32600**: Invalid request
- **-32601**: Method not found
- **-32602**: Invalid params
- **-32603**: Internal error

### Tool-Specific Errors

Tool execution errors are returned in the result:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "isError": true,
    "content": [{
      "type": "text",
      "text": "File not found: /path/to/missing.json"
    }]
  }
}
```

## Best Practices

### Connection Management

1. **Always initialize** before using tools
2. **Handle process termination** gracefully
3. **Implement timeouts** for requests
4. **Monitor stderr** for server errors

### Request Handling

1. **Use unique request IDs** for each call
2. **Validate responses** before processing
3. **Handle both success and error cases**
4. **Implement retries** for network issues

### Performance Optimization

1. **Reuse connections** when possible
2. **Use JSONPath filtering** to reduce data transfer
3. **Implement request batching** if needed
4. **Monitor memory usage** with large files

### Security Considerations

1. **Validate file paths** before sending
2. **Sanitize user input** for JSONPath queries
3. **Use absolute paths** when possible
4. **Implement access controls** in your client

## Testing Your Client

### Basic Connectivity Test

```python
async def test_connection():
    client = YourMCPClient()
    await client.connect()
    
    # Test with help command
    response = await client.call_tool("json-help", {"topic": "overview"})
    assert "result" in response
    
    await client.disconnect()
```

### Tool Functionality Test

```python
async def test_tools():
    client = YourMCPClient()
    await client.connect()
    
    # Create test file
    test_data = '{"test": "data"}'
    write_response = await client.call_tool("json-write", {
        "file_path": "test.json",
        "content": test_data
    })
    assert "result" in write_response
    
    # Validate file
    validate_response = await client.call_tool("json-validate", {
        "file_path": "test.json"
    })
    assert "result" in validate_response
    
    await client.disconnect()
```

### Error Handling Test

```python
async def test_error_handling():
    client = YourMCPClient()
    await client.connect()
    
    # Test with missing file
    response = await client.call_tool("json-validate", {
        "file_path": "nonexistent.json"
    })
    
    # Should return error in result
    assert "result" in response
    result = response["result"]
    assert result.get("isError") == True
    
    await client.disconnect()
```

## Debugging

### Enable Debug Output

Set environment variables before starting:

```bash
RUST_LOG=debug json-mcp-server
```

### Log Analysis

Monitor the debug log file:

```bash
tail -f mcp_debug.log
```

### Common Issues

1. **Process doesn't start**: Check PATH and permissions
2. **No response**: Verify JSON formatting
3. **Tool not found**: Check tool name spelling
4. **Invalid params**: Validate required parameters
5. **File errors**: Check file paths and permissions

## Advanced Features

### Async Operations

For long-running operations, implement proper async handling:

```javascript
async function processLargeFile(client, filePath) {
  const chunkSize = 1000;
  let startIndex = 0;
  const results = [];
  
  while (true) {
    const response = await client.callTool("json-read", {
      file_path: filePath,
      json_path: "$.records",
      start_index: startIndex,
      limit: chunkSize
    });
    
    if (!response.result || response.result.content[0].text === "[]") {
      break;
    }
    
    results.push(JSON.parse(response.result.content[0].text));
    startIndex += chunkSize;
  }
  
  return results.flat();
}
```

### Connection Pooling

For high-throughput applications:

```python
class MCPConnectionPool:
    def __init__(self, pool_size=5):
        self.pool = []
        self.pool_size = pool_size
        
    async def get_connection(self):
        if self.pool:
            return self.pool.pop()
        
        client = JSONMCPClient()
        await client.connect()
        return client
        
    async def return_connection(self, client):
        if len(self.pool) < self.pool_size:
            self.pool.append(client)
        else:
            await client.disconnect()
```

### Streaming Responses

For large datasets, process responses in chunks:

```rust
async fn stream_large_query(client: &mut JSONMCPClient, query: &str) -> Result<(), Box<dyn std::error::Error>> {
    let mut start_index = 0;
    const CHUNK_SIZE: u32 = 100;
    
    loop {
        let response = client.call_tool("json-read", json!({
            "file_path": "large_file.json",
            "json_path": query,
            "start_index": start_index,
            "limit": CHUNK_SIZE
        })).await?;
        
        // Process chunk
        if let Some(content) = response.get("result")
            .and_then(|r| r.get("content"))
            .and_then(|c| c.get(0))
            .and_then(|item| item.get("text")) {
            
            let data: Vec<serde_json::Value> = serde_json::from_str(content.as_str().unwrap())?;
            if data.is_empty() {
                break;
            }
            
            // Process the data chunk here
            process_chunk(data).await?;
            start_index += CHUNK_SIZE;
        } else {
            break;
        }
    }
    
    Ok(())
}
```
