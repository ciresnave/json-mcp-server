use crate::mcp::protocol::{Tool, ToolCall, ToolResult};
use crate::mcp::server::ToolHandler;
use async_trait::async_trait;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

pub struct JsonStreaming;

impl JsonStreaming {
    pub fn new() -> Self {
        Self
    }

    fn create_stream_read_tool() -> Tool {
        Tool {
            name: "json-read".to_string(),
            description: "Read and query JSON files efficiently. Supports files of any size through automatic streaming, with optional JSONPath filtering for data extraction.".to_string(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the large JSON file to stream"
                    },
                    "query": {
                        "type": "string",
                        "description": "Optional JSONPath expression to filter data during streaming"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results to return (default: 1000)",
                        "default": 1000,
                        "minimum": 1,
                        "maximum": 10000
                    },
                    "offset": {
                        "type": "integer", 
                        "description": "Number of results to skip (default: 0)",
                        "default": 0,
                        "minimum": 0
                    }
                },
                "required": ["file_path"]
            })
        }
    }

    async fn handle_stream_read(&self, args: &HashMap<String, Value>) -> anyhow::Result<ToolResult> {
        let file_path = args.get("file_path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!(
                "file_path is required. Usage example:\n{{\n  \"file_path\": \"./data.json\"\n}}\nOptional parameters: query, limit, offset"
            ))?;

        let query = args.get("query").and_then(|v| v.as_str());
        let limit = args.get("limit")
            .and_then(|v| v.as_u64())
            .unwrap_or(1000) as usize;
        let offset = args.get("offset")
            .and_then(|v| v.as_u64())
            .unwrap_or(0) as usize;

        // Try to stream the file
        let results = self.stream_json_file(file_path, query, limit, offset)?;

        let output = serde_json::to_string_pretty(&results)?;

        Ok(ToolResult::success(format!(
            "Streamed {} results from '{}' (offset: {}, limit: {}):\n\n{}",
            match &results {
                Value::Array(arr) => arr.len(),
                _ => 1,
            },
            file_path,
            offset,
            limit,
            output
        )))
    }

    fn stream_json_file(
        &self,
        file_path: &str,
        query: Option<&str>,
        limit: usize,
        offset: usize,
    ) -> anyhow::Result<Value> {
        let file = File::open(file_path)
            .map_err(|e| anyhow::anyhow!("Failed to open file '{}': {}", file_path, e))?;

        let reader = BufReader::new(file);
        let mut results = Vec::new();
        let mut current_offset = 0;
        let mut found_results = 0;

        // Try to detect if this is a line-delimited JSON file
        let mut lines = reader.lines();
        let mut is_line_delimited = false;

        // Read first few lines to detect format
        let mut first_lines = Vec::new();
        for _ in 0..5 {
            if let Some(Ok(line)) = lines.next() {
                let line_clone = line.clone();
                first_lines.push(line);
                if line_clone.trim().starts_with('{') && line_clone.trim().ends_with('}') {
                    if serde_json::from_str::<Value>(&line_clone).is_ok() {
                        is_line_delimited = true;
                        break;
                    }
                }
            } else {
                break;
            }
        }

        if is_line_delimited {
            // Process line-delimited JSON
            let file = File::open(file_path)?;
            let reader = BufReader::new(file);
            
            for line in reader.lines() {
                let line = line?;
                if line.trim().is_empty() {
                    continue;
                }

                if current_offset < offset {
                    current_offset += 1;
                    continue;
                }

                if found_results >= limit {
                    break;
                }

                if let Ok(json_value) = serde_json::from_str::<Value>(&line) {
                    let should_include = if let Some(query_str) = query {
                        // Apply JSONPath query to individual line
                        match jsonpath_rust::JsonPathFinder::from_str(&line, query_str) {
                            Ok(finder) => {
                                let result = finder.find();
                                match result {
                                    Value::Null => false,
                                    Value::Array(ref arr) if arr.is_empty() => false,
                                    _ => true,
                                }
                            },
                            Err(_) => false,
                        }
                    } else {
                        true
                    };

                    if should_include {
                        results.push(json_value);
                        found_results += 1;
                    }
                }
                current_offset += 1;
            }
        } else {
            // Try to parse as regular JSON file and stream through it
            let content = std::fs::read_to_string(file_path)?;
            let json_value: Value = serde_json::from_str(&content)?;

            // If it's an array, we can stream through elements
            if let Value::Array(arr) = json_value {
                for (_index, item) in arr.iter().enumerate() {
                    if current_offset < offset {
                        current_offset += 1;
                        continue;
                    }

                    if found_results >= limit {
                        break;
                    }

                    let should_include = if let Some(query_str) = query {
                        let item_str = serde_json::to_string(item)?;
                        match jsonpath_rust::JsonPathFinder::from_str(&item_str, query_str) {
                            Ok(finder) => {
                                let result = finder.find();
                                match result {
                                    Value::Null => false,
                                    Value::Array(ref arr) if arr.is_empty() => false,
                                    _ => true,
                                }
                            },
                            Err(_) => false,
                        }
                    } else {
                        true
                    };

                    if should_include {
                        results.push(item.clone());
                        found_results += 1;
                    }
                    current_offset += 1;
                }
            } else {
                // Single object - apply query if provided
                let should_include = if let Some(query_str) = query {
                    match jsonpath_rust::JsonPathFinder::from_str(&content, query_str) {
                        Ok(finder) => {
                            let result = finder.find();
                            match result {
                                Value::Null => false,
                                Value::Array(ref arr) if arr.is_empty() => false,
                                _ => true,
                            }
                        },
                        Err(_) => false,
                    }
                } else {
                    true
                };

                if should_include && current_offset >= offset && found_results < limit {
                    results.push(json_value);
                }
            }
        }

        Ok(Value::Array(results))
    }
}

#[async_trait]
impl ToolHandler for JsonStreaming {
    async fn get_tools(&self) -> anyhow::Result<Vec<Tool>> {
        Ok(vec![Self::create_stream_read_tool()])
    }

    async fn call_tool(&self, tool_call: ToolCall) -> anyhow::Result<ToolResult> {
        match tool_call.name.as_str() {
            "json-read" => self.handle_stream_read(&tool_call.arguments).await,
            _ => Ok(ToolResult::error(format!("Unknown tool: {}", tool_call.name))),
        }
    }
}
