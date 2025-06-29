use json_mcp_server::json_tools::JsonToolsHandler;
use json_mcp_server::mcp::{
    protocol::ToolCall,
    server::{MCPServer, ToolHandler},
};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use tempfile::TempDir;

/// Helper to create temporary test files
struct TestEnvironment {
    _temp_dir: TempDir,
    temp_path: PathBuf,
}

impl TestEnvironment {
    fn new() -> Self {
        let temp_dir = tempfile::tempdir().unwrap();
        let temp_path = temp_dir.path().to_path_buf();
        Self {
            _temp_dir: temp_dir,
            temp_path,
        }
    }

    fn create_json_file(&self, name: &str, content: &str) -> PathBuf {
        let file_path = self.temp_path.join(name);
        fs::write(&file_path, content).unwrap();
        file_path
    }

    fn read_json_file(&self, name: &str) -> String {
        let file_path = self.temp_path.join(name);
        fs::read_to_string(file_path).unwrap()
    }
}

fn create_args(pairs: &[(&str, Value)]) -> HashMap<String, Value> {
    pairs.iter()
        .map(|(k, v)| (k.to_string(), v.clone()))
        .collect()
}

async fn call_tool(handler: &JsonToolsHandler, name: &str, args: HashMap<String, Value>) -> Result<String, String> {
    let result = handler.call_tool(ToolCall {
        name: name.to_string(),
        arguments: args,
    }).await;

    match result {
        Ok(tool_result) => {
            if tool_result.is_error.unwrap_or(false) {
                Err(tool_result.content.get(0).map(|c| c.text.clone()).unwrap_or_default())
            } else {
                Ok(tool_result.content.get(0).map(|c| c.text.clone()).unwrap_or_default())
            }
        }
        Err(e) => Err(e.to_string())
    }
}

#[tokio::test]
async fn test_complete_json_workflow() {
    let env = TestEnvironment::new();
    let handler = JsonToolsHandler::new();

    // Test data
    let initial_data = json!({
        "users": [
            {"id": 1, "name": "Alice", "age": 30, "active": true},
            {"id": 2, "name": "Bob", "age": 25, "active": false},
            {"id": 3, "name": "Charlie", "age": 35, "active": true}
        ],
        "metadata": {
            "total": 3,
            "created": "2025-01-01"
        }
    });

    // 1. Write initial data
    let file_path = env.temp_path.join("users.json");
    let write_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("data", initial_data.clone()),
    ]);

    let result = call_tool(&handler, "json-write", write_args).await;
    assert!(result.is_ok(), "Failed to write initial data: {:?}", result);

    // 2. Validate the file
    let validate_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
    ]);

    let result = call_tool(&handler, "json-validate", validate_args).await;
    assert!(result.is_ok(), "Validation failed: {:?}", result);
    assert!(result.unwrap().contains("is valid"));

    // 3. Read the entire file
    let read_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
    ]);

    let result = call_tool(&handler, "json-read", read_args).await;
    assert!(result.is_ok(), "Failed to read file: {:?}", result);
    let content = result.unwrap();
    assert!(content.contains("Alice"));
    assert!(content.contains("Bob"));
    assert!(content.contains("Charlie"));

    // 4. Query active users only
    let query_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("query", json!("$.users[?(@.active == true)].name")),
    ]);

    let result = call_tool(&handler, "json-query", query_args).await;
    assert!(result.is_ok(), "Query failed: {:?}", result);
    let query_result = result.unwrap();
    assert!(query_result.contains("Alice"));
    assert!(query_result.contains("Charlie"));
    assert!(!query_result.contains("Bob")); // Bob is inactive

    // 5. Add new user via merge
    let new_user_data = json!({
        "users": [
            {"id": 4, "name": "Diana", "age": 28, "active": true}
        ]
    });

    let merge_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("data", new_user_data),
        ("mode", json!("merge")),
    ]);

    let result = call_tool(&handler, "json-write", merge_args).await;
    assert!(result.is_ok(), "Merge failed: {:?}", result);

    // 6. Verify the merge worked
    let final_read_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("query", json!("$.users[*].name")),
    ]);

    let result = call_tool(&handler, "json-read", final_read_args).await;
    assert!(result.is_ok(), "Final read failed: {:?}", result);
    let final_content = result.unwrap();
    assert!(final_content.contains("Diana"));
}

#[tokio::test]
async fn test_all_write_modes() {
    let env = TestEnvironment::new();
    let handler = JsonToolsHandler::new();

    // Test replace mode (default)
    let file_path = env.temp_path.join("write_test.json");
    let initial_data = json!({"name": "test", "value": 1});

    let replace_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("data", initial_data),
        ("mode", json!("replace")),
    ]);

    let result = call_tool(&handler, "json-write", replace_args).await;
    assert!(result.is_ok());

    // Test merge mode
    let merge_data = json!({"extra": "field", "value": 2});
    let merge_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("data", merge_data),
        ("mode", json!("merge")),
    ]);

    let result = call_tool(&handler, "json-write", merge_args).await;
    assert!(result.is_ok());

    // Verify merge result
    let read_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
    ]);

    let result = call_tool(&handler, "json-read", read_args).await;
    assert!(result.is_ok());
    let content = result.unwrap();
    assert!(content.contains("test")); // Original name
    assert!(content.contains("extra")); // Merged field
    assert!(content.contains("\"value\": 2")); // Updated value

    // Test append mode with array
    let array_file = env.temp_path.join("array_test.json");
    let initial_array = json!([1, 2, 3]);

    let array_args = create_args(&[
        ("file_path", json!(array_file.to_string_lossy())),
        ("data", initial_array),
    ]);

    let result = call_tool(&handler, "json-write", array_args).await;
    assert!(result.is_ok());

    // Append to array
    let append_data = json!([4, 5]);
    let append_args = create_args(&[
        ("file_path", json!(array_file.to_string_lossy())),
        ("data", append_data),
        ("mode", json!("append")),
    ]);

    let result = call_tool(&handler, "json-write", append_args).await;
    assert!(result.is_ok());

    // Verify append
    let read_array_args = create_args(&[
        ("file_path", json!(array_file.to_string_lossy())),
    ]);

    let result = call_tool(&handler, "json-read", read_array_args).await;
    assert!(result.is_ok());
    let array_content = result.unwrap();
    assert!(array_content.contains("1"));
    assert!(array_content.contains("5")); // Should contain both original and appended
}

#[tokio::test]
async fn test_complex_jsonpath_queries() {
    let env = TestEnvironment::new();
    let handler = JsonToolsHandler::new();

    // Create complex test data
    let complex_data = json!({
        "store": {
            "book": [
                {
                    "category": "reference",
                    "author": "Nigel Rees",
                    "title": "Sayings of the Century",
                    "price": 8.95
                },
                {
                    "category": "fiction",
                    "author": "Evelyn Waugh", 
                    "title": "Sword of Honour",
                    "price": 12.99
                },
                {
                    "category": "fiction",
                    "author": "Herman Melville",
                    "title": "Moby Dick",
                    "price": 8.99
                }
            ],
            "bicycle": {
                "color": "red",
                "price": 19.95
            }
        }
    });

    let file_path = env.temp_path.join("bookstore.json");
    let write_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("data", complex_data),
    ]);

    let result = call_tool(&handler, "json-write", write_args).await;
    assert!(result.is_ok());

    // Test various JSONPath queries
    let test_cases = vec![
        // All book titles
        ("$.store.book[*].title", vec!["Sayings of the Century", "Sword of Honour", "Moby Dick"]),
        // Books under $10
        ("$.store.book[?(@.price < 10)].title", vec!["Sayings of the Century", "Moby Dick"]),
        // Fiction books
        ("$.store.book[?(@.category == 'fiction')].author", vec!["Evelyn Waugh", "Herman Melville"]),
        // All prices in the store
        ("$.store..price", vec!["8.95", "12.99", "8.99", "19.95"]),
    ];

    for (query, expected_content) in test_cases {
        let query_args = create_args(&[
            ("file_path", json!(file_path.to_string_lossy())),
            ("query", json!(query)),
        ]);

        let result = call_tool(&handler, "json-query", query_args).await;
        assert!(result.is_ok(), "Query '{}' failed: {:?}", query, result);
        
        let query_result = result.unwrap();
        for expected in expected_content {
            assert!(query_result.contains(expected), 
                   "Query '{}' result should contain '{}', but got: {}", 
                   query, expected, query_result);
        }
    }
}

#[tokio::test]
async fn test_error_handling() {
    let env = TestEnvironment::new();
    let handler = JsonToolsHandler::new();

    // Test missing file
    let missing_file = env.temp_path.join("nonexistent.json");
    let read_args = create_args(&[
        ("file_path", json!(missing_file.to_string_lossy())),
    ]);

    let result = call_tool(&handler, "json-read", read_args).await;
    assert!(result.is_err(), "Should fail for missing file");

    // Test invalid JSON
    let invalid_file = env.create_json_file("invalid.json", "{invalid json");
    let validate_args = create_args(&[
        ("file_path", json!(invalid_file.to_string_lossy())),
    ]);

    let result = call_tool(&handler, "json-validate", validate_args).await;
    assert!(result.is_err(), "Should fail for invalid JSON");

    // Test missing required parameters
    let empty_args = HashMap::new();
    let result = call_tool(&handler, "json-read", empty_args).await;
    assert!(result.is_err(), "Should fail without file_path");
    assert!(result.unwrap_err().contains("file_path is required"));

    // Test invalid JSONPath
    let valid_file = env.create_json_file("valid.json", r#"{"test": "data"}"#);
    let invalid_query_args = create_args(&[
        ("file_path", json!(valid_file.to_string_lossy())),
        ("query", json!("$[invalid")), // Invalid JSONPath syntax
    ]);

    let result = call_tool(&handler, "json-query", invalid_query_args).await;
    assert!(result.is_err(), "Should fail for invalid JSONPath");
}

#[tokio::test]
async fn test_large_file_simulation() {
    let env = TestEnvironment::new();
    let handler = JsonToolsHandler::new();

    // Create a larger JSON structure
    let mut large_data = json!({
        "records": [],
        "metadata": {
            "total": 1000,
            "generated": "2025-01-01"
        }
    });

    // Add 1000 records
    for i in 0..1000 {
        large_data["records"].as_array_mut().unwrap().push(json!({
            "id": i,
            "name": format!("User {}", i),
            "score": i * 10,
            "active": i % 2 == 0
        }));
    }

    let file_path = env.temp_path.join("large_data.json");
    let write_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("data", large_data),
    ]);

    let result = call_tool(&handler, "json-write", write_args).await;
    assert!(result.is_ok(), "Failed to write large file");

    // Test reading with limit
    let limited_read_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("query", json!("$.records[*].id")),
        ("limit", json!(10)),
    ]);

    let result = call_tool(&handler, "json-read", limited_read_args).await;
    assert!(result.is_ok(), "Failed to read with limit");
    
    // Test reading with offset
    let offset_read_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("query", json!("$.records[*].id")),
        ("limit", json!(5)),
        ("offset", json!(10)),
    ]);

    let result = call_tool(&handler, "json-read", offset_read_args).await;
    assert!(result.is_ok(), "Failed to read with offset");

    // Test high-score query
    let high_score_args = create_args(&[
        ("file_path", json!(file_path.to_string_lossy())),
        ("query", json!("$.records[?(@.score > 5000)].name")),
    ]);

    let result = call_tool(&handler, "json-query", high_score_args).await;
    assert!(result.is_ok(), "Failed high score query");
    let high_score_result = result.unwrap();
    assert!(high_score_result.contains("User 50")); // Score would be 500, so this shouldn't match
}

#[tokio::test]
async fn test_help_system_comprehensive() {
    let handler = JsonToolsHandler::new();
    
    let help_topics = vec![
        ("", "JSON MCP Server Help"), // Default topic content
        ("overview", "JSON MCP Server Help"),
        ("reading", "Reading JSON Files"),
        ("writing", "Writing JSON Files"),
        ("querying", "Querying JSON with JSONPath"),
        ("streaming", "Streaming Large JSON Files"),
        ("examples", "Practical JSON Tool Examples"),
        ("tools", "Individual Tool Help"),
    ];

    for (topic, expected_content) in help_topics {
        let args = if topic.is_empty() {
            HashMap::new()
        } else {
            create_args(&[("topic", json!(topic))])
        };

        let result = call_tool(&handler, "json-help", args).await;
        assert!(result.is_ok(), "Help topic '{}' failed: {:?}", topic, result);
        
        let help_content = result.unwrap();
        assert!(help_content.contains(expected_content), 
               "Help topic '{}' should contain '{}', but got: {}", 
               topic, expected_content, help_content);
    }
}

#[tokio::test]
async fn test_mcp_protocol_integration() {
    let handler = JsonToolsHandler::new();
    let mut server = MCPServer::new(handler);
    
    // Test tool registration
    let result = server.register_tools().await;
    assert!(result.is_ok(), "Failed to register tools");

    // Test tools/list method
    let tools_request = r#"{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}"#;
    let response = server.handle_request(tools_request).await;
    assert!(response.is_ok(), "tools/list failed");
    
    let response_str = response.unwrap();
    assert!(response_str.contains("json-read"));
    assert!(response_str.contains("json-write"));
    assert!(response_str.contains("json-query"));
    assert!(response_str.contains("json-validate"));
    assert!(response_str.contains("json-help"));

    // Test actual tool call through MCP
    let env = TestEnvironment::new();
    let test_file = env.create_json_file("mcp_test.json", r#"{"test": "mcp integration"}"#);
    
    let tool_call_request = format!(
        r#"{{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {{"name": "json-validate", "arguments": {{"file_path": "{}"}}}}}}"#,
        test_file.to_string_lossy().replace('\\', "\\\\")
    );
    
    let response = server.handle_request(&tool_call_request).await;
    assert!(response.is_ok(), "MCP tool call failed");
    
    let response_str = response.unwrap();
    assert!(response_str.contains("is valid"));
}
