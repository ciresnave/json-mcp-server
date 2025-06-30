use crate::mcp::protocol::{Tool, ToolCall, ToolResult};
use crate::mcp::server::ToolHandler;
use async_trait::async_trait;
use serde_json::{json, Value};
use jsonpath_rust::JsonPath;
use std::collections::HashMap;
use std::fs;

pub struct JsonQuery;

impl JsonQuery {
    pub fn new() -> Self {
        Self
    }

    fn create_query_tool() -> Tool {
        Tool {
            name: "json-query".to_string(),
            description: "Execute JSONPath queries on JSON files. Supports complex queries with filtering, projection, and various output formats.".to_string(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the JSON file to query"
                    },
                    "query": {
                        "type": "string",
                        "description": "JSONPath expression to execute (e.g., '$.users[?(@.age > 25)].name')"
                    },
                    "format": {
                        "type": "string",
                        "description": "Output format: 'json' (default), 'text', or 'table'",
                        "enum": ["json", "text", "table"],
                        "default": "json"
                    }
                },
                "required": ["file_path", "query"]
            })
        }
    }

    async fn handle_query(&self, args: &HashMap<String, Value>) -> anyhow::Result<ToolResult> {
        let file_path = args.get("file_path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!(
                "file_path is required. Usage example:\n{{\n  \"file_path\": \"./data.json\",\n  \"query\": \"$.users[0].name\"\n}}"
            ))?;

        let query = args.get("query")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!(
                "query is required. Usage example:\n{{\n  \"file_path\": \"./data.json\",\n  \"query\": \"$.users[0].name\"\n}}\nUse JSONPath syntax: $ (root), .property, [index], [?(@.condition)]"
            ))?;

        let format = args.get("format")
            .and_then(|v| v.as_str())
            .unwrap_or("json");

        // Read the file
        let content = fs::read_to_string(file_path)
            .map_err(|e| anyhow::anyhow!("Failed to read file '{}': {}", file_path, e))?;

        // Parse JSON content
        let json_value: Value = serde_json::from_str(&content)
            .map_err(|e| anyhow::anyhow!("Failed to parse JSON: {}", e))?;

        // Execute JSONPath query
        let results = match json_value.query(query) {
            Ok(values) => {
                // Convert the results to JSON values
                values.into_iter().map(|v| v.clone()).collect::<Vec<Value>>()
            },
            Err(e) => return Ok(ToolResult::error(format!("JSONPath query error: {}", e))),
        };

        // Format output based on requested format
        let results_value = Value::Array(results);
        let output = match format {
            "json" => serde_json::to_string_pretty(&results_value)?,
            "text" => self.format_as_text(&results_value),
            "table" => self.format_as_table(&results_value),
            _ => return Ok(ToolResult::error(format!("Unknown format: {}", format))),
        };

        Ok(ToolResult::success(format!(
            "Query results from '{}' using JSONPath '{}':\n\n{}",
            file_path, query, output
        )))
    }

    fn format_as_text(&self, value: &Value) -> String {
        match value {
            Value::Array(arr) => {
                arr.iter()
                    .map(|v| match v {
                        Value::String(s) => s.clone(),
                        _ => v.to_string().trim_matches('"').to_string(),
                    })
                    .collect::<Vec<_>>()
                    .join("\n")
            },
            Value::String(s) => s.clone(),
            _ => value.to_string().trim_matches('"').to_string(),
        }
    }

    fn format_as_table(&self, value: &Value) -> String {
        match value {
            Value::Array(arr) => {
                if arr.is_empty() {
                    return "No results found".to_string();
                }

                // Try to format as table if items are objects
                if let Some(Value::Object(first_obj)) = arr.first() {
                    let headers: Vec<String> = first_obj.keys().cloned().collect();
                    let mut table = vec![headers.join(" | ")];
                    table.push(headers.iter().map(|_| "---").collect::<Vec<_>>().join(" | "));

                    for item in arr {
                        if let Value::Object(obj) = item {
                            let row: Vec<String> = headers.iter()
                                .map(|h| obj.get(h)
                                    .map(|v| match v {
                                        Value::String(s) => s.clone(),
                                        _ => v.to_string().trim_matches('"').to_string(),
                                    })
                                    .unwrap_or_else(|| "".to_string()))
                                .collect();
                            table.push(row.join(" | "));
                        }
                    }
                    table.join("\n")
                } else {
                    // Simple list format
                    arr.iter()
                        .enumerate()
                        .map(|(i, v)| format!("{}: {}", i + 1, match v {
                            Value::String(s) => s.clone(),
                            _ => v.to_string().trim_matches('"').to_string(),
                        }))
                        .collect::<Vec<_>>()
                        .join("\n")
                }
            },
            _ => value.to_string().trim_matches('"').to_string(),
        }
    }
}

#[async_trait]
impl ToolHandler for JsonQuery {
    async fn get_tools(&self) -> anyhow::Result<Vec<Tool>> {
        Ok(vec![Self::create_query_tool()])
    }

    async fn call_tool(&self, tool_call: ToolCall) -> anyhow::Result<ToolResult> {
        match tool_call.name.as_str() {
            "json-query" => self.handle_query(&tool_call.arguments).await,
            _ => Ok(ToolResult::error(format!("Unknown tool: {}", tool_call.name))),
        }
    }
}
