pub mod json_tools;
pub mod mcp;

#[cfg(test)]
mod tests {
    use crate::json_tools::JsonToolsHandler;
    use crate::mcp::{
        protocol::ToolCall,
        server::{MCPServer, ToolHandler},
    };
    use serde_json::{json, Value};
    use std::collections::HashMap;
    use std::fs;
    use std::path::PathBuf;

    // Helper function to create test JSON file
    fn create_test_json_file(content: &str) -> PathBuf {
        let mut temp_path = std::env::temp_dir();
        temp_path.push(format!("test_{}.json", std::process::id()));
        fs::write(&temp_path, content).unwrap();
        temp_path
    }

    // Helper function to create argument map
    fn args_map(pairs: &[(&str, Value)]) -> HashMap<String, Value> {
        pairs.iter()
            .map(|(k, v)| (k.to_string(), v.clone()))
            .collect()
    }

    #[tokio::test]
    async fn test_json_help_default() {
        let handler = JsonToolsHandler::new();
        let args = HashMap::new();
        
        let result = handler.call_tool(ToolCall {
            name: "json-help".to_string(),
            arguments: args,
        }).await;
        
        assert!(result.is_ok());
        let tool_result = result.unwrap();
        
        if let Some(is_error) = tool_result.is_error {
            assert!(!is_error, "Expected success but got error: {}", 
                   tool_result.content.get(0).map(|c| c.text.as_str()).unwrap_or("<no text>"));
        }
        
        let text = &tool_result.content[0].text;
        assert!(text.contains("JSON MCP Server Help"));
        assert!(text.contains("json-read"));
        assert!(text.contains("json-write"));
        assert!(text.contains("json-query"));
        assert!(text.contains("json-validate"));
    }

    #[tokio::test]
    async fn test_json_validate_valid_file() {
        let test_data = r#"{"name": "test", "value": 42, "items": [1, 2, 3]}"#;
        let file_path = create_test_json_file(test_data);
        let handler = JsonToolsHandler::new();
        
        let args = args_map(&[("file_path", json!(file_path.to_string_lossy()))]);
        let result = handler.call_tool(ToolCall {
            name: "json-validate".to_string(),
            arguments: args,
        }).await;
        
        assert!(result.is_ok());
        let tool_result = result.unwrap();
        
        if let Some(is_error) = tool_result.is_error {
            assert!(!is_error, "Expected success but got error: {}", 
                   tool_result.content.get(0).map(|c| c.text.as_str()).unwrap_or("<no text>"));
        }
        
        let text = &tool_result.content[0].text;
        assert!(text.contains("is valid"));
        
        // Cleanup
        let _ = fs::remove_file(file_path);
    }

    #[tokio::test]
    async fn test_mcp_server_tool_registration() {
        let handler = JsonToolsHandler::new();
        let mut server = MCPServer::new(handler);
        
        let result = server.register_tools().await;
        assert!(result.is_ok());
        
        // Test that we can get the tool list through the MCP protocol
        let tools_request = r#"{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}"#;
        let response = server.handle_request(tools_request).await;
        assert!(response.is_ok());
        
        let response_str = response.unwrap();
        assert!(response_str.contains("json-read"));
        assert!(response_str.contains("json-write"));
        assert!(response_str.contains("json-query"));
        assert!(response_str.contains("json-validate"));
        assert!(response_str.contains("json-help"));
    }
}
