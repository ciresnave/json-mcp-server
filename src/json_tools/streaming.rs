// SPDX-License-Identifier: MIT OR Apache-2.0
use crate::mcp::protocol::{Tool, ToolCall, ToolResult};
use crate::mcp::server::ToolHandler;
use async_trait::async_trait;
use jsonpath_rust::JsonPath;
use serde_json::{Value, json};
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
            description: "Read and query JSON files efficiently. A top-level array or line-delimited file is streamed element by element and reading stops at `limit`; a single large object is parsed whole. Optional JSONPath filter applies per element.".to_string(),
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

    async fn handle_stream_read(
        &self,
        args: &HashMap<String, Value>,
    ) -> anyhow::Result<ToolResult> {
        let file_path = args.get("file_path")
            .and_then(|v| v.as_str())
            .ok_or_else(|| anyhow::anyhow!(
                "file_path is required. Usage example:\n{{\n  \"file_path\": \"./data.json\"\n}}\nOptional parameters: query, limit, offset"
            ))?;

        let query = args.get("query").and_then(|v| v.as_str());
        let limit = args.get("limit").and_then(|v| v.as_u64()).unwrap_or(1000) as usize;
        let offset = args.get("offset").and_then(|v| v.as_u64()).unwrap_or(0) as usize;

        // Try to stream the file
        let (results, stopped_at_limit) = self.stream_json_file(file_path, query, limit, offset)?;

        let output = serde_json::to_string_pretty(&results)?;

        let note = if stopped_at_limit {
            "\nNote: stopped at the limit; the rest of the file was not read or validated.\n"
        } else {
            ""
        };
        Ok(ToolResult::success(format!(
            "Streamed {} results from '{}' (offset: {}, limit: {}):{}\n\n{}",
            match &results {
                Value::Array(arr) => arr.len(),
                _ => 1,
            },
            file_path,
            offset,
            limit,
            note,
            output
        )))
    }

    fn stream_json_file(
        &self,
        file_path: &str,
        query: Option<&str>,
        limit: usize,
        offset: usize,
    ) -> anyhow::Result<(Value, bool)> {
        let file = File::open(file_path)
            .map_err(|e| anyhow::anyhow!("Failed to open file '{}': {}", file_path, e))?;

        let mut peek = BufReader::new(file);
        let mut results = Vec::new();
        let mut current_offset = 0;
        let mut found_results = 0;

        // A top-level array is recognised first, from its first byte, so no physical line is
        // ever buffered for it (a compact array may be a single huge line).
        if first_json_ws_skipped_byte(&mut peek)? == Some(b'[') {
            let mut de = serde_json::Deserializer::from_reader(peek);
            let mut collected = Vec::new();
            let collector = ArrayCollector {
                query,
                offset,
                limit,
                out: &mut collected,
            };
            let parsed = serde::Deserializer::deserialize_seq(&mut de, collector);
            let stopped_at_limit = collected.len() >= limit;
            match parsed {
                // Reached the end of the array before `limit`: the rest must be valid JSON
                // (nothing but whitespace after the closing bracket).
                Ok(()) if !stopped_at_limit => de.end()?,
                Ok(()) => {}
                // Stopping at `limit` leaves the array unclosed, which serde_json reports as
                // an error; that is expected, so only a failure before the limit is real.
                Err(e) if !stopped_at_limit => return Err(e.into()),
                Err(_) => {}
            }
            return Ok((Value::Array(collected), stopped_at_limit));
        }

        // Not an array: line-delimited JSON when the first two non-empty lines are each a
        // complete JSON value (any type); otherwise one JSON document.
        let mut is_line_delimited = false;
        {
            let mut seen = 0;
            for line in BufReader::new(File::open(file_path)?).lines().take(20) {
                let line = line?;
                if line.trim().is_empty() {
                    continue;
                }
                if serde_json::from_str::<Value>(&line).is_err() {
                    break;
                }
                seen += 1;
                if seen == 2 {
                    is_line_delimited = true;
                    break;
                }
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
                        match json_value.query(query_str) {
                            Ok(results) => !results.is_empty(),
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
            let content = std::fs::read_to_string(file_path)?;
            let json_value: Value = serde_json::from_str(&content)?;

            {
                // Single object - apply query if provided
                let should_include = if let Some(query_str) = query {
                    match json_value.query(query_str) {
                        Ok(results) => !results.is_empty(),
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

        Ok((Value::Array(results), false))
    }
}

/// Returns the first byte that is not JSON whitespace (space, tab, CR, LF) without consuming it.
fn first_json_ws_skipped_byte<R: BufRead>(r: &mut R) -> std::io::Result<Option<u8>> {
    loop {
        let buf = r.fill_buf()?;
        if buf.is_empty() {
            return Ok(None);
        }
        match buf
            .iter()
            .position(|b| !matches!(b, b' ' | b'\t' | b'\r' | b'\n'))
        {
            Some(i) => return Ok(Some(buf[i])),
            None => {
                let n = buf.len();
                r.consume(n);
            }
        }
    }
}

/// Visits a top-level JSON array one element at a time, applying offset, limit and an
/// optional JSONPath filter. Stops reading once `limit` results are collected, so the
/// rest of the file is neither read nor validated.
struct ArrayCollector<'a> {
    query: Option<&'a str>,
    offset: usize,
    limit: usize,
    out: &'a mut Vec<Value>,
}

impl<'de> serde::de::Visitor<'de> for ArrayCollector<'_> {
    type Value = ();

    fn expecting(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        f.write_str("a JSON array")
    }

    fn visit_seq<A: serde::de::SeqAccess<'de>>(self, mut seq: A) -> Result<(), A::Error> {
        let mut index = 0usize;
        while self.out.len() < self.limit {
            let Some(item) = seq.next_element::<Value>()? else {
                break;
            };
            let keep = index >= self.offset
                && match self.query {
                    Some(q) => item.query(q).map(|r| !r.is_empty()).unwrap_or(false),
                    None => true,
                };
            index += 1;
            if keep {
                self.out.push(item);
            }
        }
        Ok(())
    }
}

impl Default for JsonStreaming {
    fn default() -> Self {
        Self::new()
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
            _ => Ok(ToolResult::error(format!(
                "Unknown tool: {}",
                tool_call.name
            ))),
        }
    }
}
