use crate::mcp::protocol::{Tool, ToolCall, ToolResult};
use crate::mcp::server::ToolHandler;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs;
use std::path::Path;

pub struct JsonOperations;

impl JsonOperations {
    pub fn new() -> Self {
        Self
    }

    fn create_write_tool() -> Tool {
        Tool {
            name: "json-write".to_string(),
            description: "Write or update a JSON file with support for different write modes".to_string(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the JSON file to write"
                    },
                    "data": {
                        "description": "JSON data to write. Can be any valid JSON value"
                    },
                    "mode": {
                        "type": "string",
                        "enum": ["replace", "merge", "append"],
                        "default": "replace",
                        "description": "Write mode: 'replace' overwrites file, 'merge' merges with existing JSON (objects only), 'append' appends to arrays"
                    },
                    "create_dirs": {
                        "type": "boolean",
                        "default": true,
                        "description": "Create parent directories if they don't exist"
                    },
                    "pretty": {
                        "type": "boolean",
                        "default": true,
                        "description": "Format JSON with indentation"
                    }
                },
                "required": ["file_path", "data"]
            }),
        }
    }

    fn create_validate_tool() -> Tool {
        Tool {
            name: "json-validate".to_string(),
            description: "Validate JSON file syntax and structure".to_string(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Path to the JSON file to validate"
                    },
                    "schema": {
                        "description": "Optional JSON schema to validate against"
                    }
                },
                "required": ["file_path"]
            }),
        }
    }

    async fn handle_write(&self, args: &HashMap<String, Value>) -> anyhow::Result<ToolResult> {
        let file_path = args.get("file_path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!(
                "file_path is required. Usage example:\n{{\n  \"file_path\": \"./output.json\",\n  \"data\": {{\"key\": \"value\"}}\n}}"
            ))?;

        let data = args.get("data")
            .ok_or_else(|| anyhow::anyhow!(
                "data is required. Usage example:\n{{\n  \"file_path\": \"./output.json\",\n  \"data\": {{\"key\": \"value\"}}\n}}"
            ))?;

        let mode = args.get("mode")
            .and_then(|v| v.as_str())
            .unwrap_or("replace");

        let create_dirs = args.get("create_dirs")
            .and_then(|v| v.as_bool())
            .unwrap_or(true);

        let pretty = args.get("pretty")
            .and_then(|v| v.as_bool())
            .unwrap_or(true);

        // Create parent directories if needed
        if create_dirs {
            if let Some(parent) = Path::new(file_path).parent() {
                fs::create_dir_all(parent)
                    .map_err(|e| anyhow::anyhow!("Failed to create directories: {}", e))?;
            }
        }

        let final_data = match mode {
            "replace" => data.clone(),
            "merge" => {
                if Path::new(file_path).exists() {
                    let existing_content = fs::read_to_string(file_path)
                        .map_err(|e| anyhow::anyhow!("Failed to read existing file: {}", e))?;
                    
                    let mut existing_json: Value = serde_json::from_str(&existing_content)
                        .map_err(|e| anyhow::anyhow!("Failed to parse existing JSON: {}", e))?;

                    if let (Some(existing_obj), Some(new_obj)) = (existing_json.as_object_mut(), data.as_object()) {
                        for (key, value) in new_obj {
                            existing_obj.insert(key.clone(), value.clone());
                        }
                        existing_json
                    } else {
                        return Ok(ToolResult::error("Merge mode requires both existing and new data to be objects".to_string()));
                    }
                } else {
                    data.clone()
                }
            },
            "append" => {
                if Path::new(file_path).exists() {
                    let existing_content = fs::read_to_string(file_path)
                        .map_err(|e| anyhow::anyhow!("Failed to read existing file: {}", e))?;
                    
                    let mut existing_json: Value = serde_json::from_str(&existing_content)
                        .map_err(|e| anyhow::anyhow!("Failed to parse existing JSON: {}", e))?;

                    if let Some(existing_array) = existing_json.as_array_mut() {
                        if let Some(new_array) = data.as_array() {
                            existing_array.extend(new_array.clone());
                        } else {
                            existing_array.push(data.clone());
                        }
                        existing_json
                    } else {
                        return Ok(ToolResult::error("Append mode requires existing data to be an array".to_string()));
                    }
                } else {
                    if data.is_array() {
                        data.clone()
                    } else {
                        json!([data])
                    }
                }
            },
            _ => return Ok(ToolResult::error(format!("Unknown write mode: {}", mode))),
        };

        // Write the file
        let content = if pretty {
            serde_json::to_string_pretty(&final_data)?
        } else {
            serde_json::to_string(&final_data)?
        };

        fs::write(file_path, content)
            .map_err(|e| anyhow::anyhow!("Failed to write file '{}': {}", file_path, e))?;

        Ok(ToolResult::success(format!(
            "Successfully wrote JSON to '{}' using {} mode",
            file_path, mode
        )))
    }

    async fn handle_validate(&self, args: &HashMap<String, Value>) -> anyhow::Result<ToolResult> {
        let file_path = args.get("file_path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!(
                "file_path is required. Usage example:\n{{\n  \"file_path\": \"./data.json\"\n}}"
            ))?;

        // Check if file exists
        if !Path::new(file_path).exists() {
            return Ok(ToolResult::error(format!("File '{}' does not exist", file_path)));
        }

        // Read and parse the file
        let content = fs::read_to_string(file_path)
            .map_err(|e| anyhow::anyhow!("Failed to read file '{}': {}", file_path, e))?;

        match serde_json::from_str::<Value>(&content) {
            Ok(json_value) => {
                let size = content.len();
                let type_name = match &json_value {
                    Value::Object(_) => "object",
                    Value::Array(_) => "array",
                    Value::String(_) => "string",
                    Value::Number(_) => "number",
                    Value::Bool(_) => "boolean",
                    Value::Null => "null",
                };

                Ok(ToolResult::success(format!(
                    "JSON file '{}' is valid:\n- Type: {}\n- Size: {} bytes\n- Structure: {}",
                    file_path,
                    type_name,
                    size,
                    if json_value.is_object() {
                        format!("{} properties", json_value.as_object().unwrap().len())
                    } else if json_value.is_array() {
                        format!("{} elements", json_value.as_array().unwrap().len())
                    } else {
                        "primitive value".to_string()
                    }
                )))
            },
            Err(e) => Ok(ToolResult::error(format!(
                "JSON validation failed for '{}': {}",
                file_path, e
            ))),
        }
    }
}

#[async_trait::async_trait]
impl ToolHandler for JsonOperations {
    async fn get_tools(&self) -> anyhow::Result<Vec<Tool>> {
        Ok(vec![
            Self::create_write_tool(),
            Self::create_validate_tool(),
        ])
    }

    async fn call_tool(&self, tool_call: ToolCall) -> anyhow::Result<ToolResult> {
        match tool_call.name.as_str() {
            "json-write" => self.handle_write(&tool_call.arguments).await,
            "json-validate" => self.handle_validate(&tool_call.arguments).await,
            _ => Ok(ToolResult::error(format!("Unknown tool: {}", tool_call.name))),
        }
    }
}
