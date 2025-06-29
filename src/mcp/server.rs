use crate::json_tools::handler::JsonToolsHandler;
use crate::mcp::protocol::{MCPRequest, MCPResponse, Tool, ToolCall, ToolResult};
use serde_json::{json, Value};
use std::collections::HashMap;
use tracing::{debug, error};

#[async_trait::async_trait]
pub trait ToolHandler {
    async fn get_tools(&self) -> anyhow::Result<Vec<Tool>>;
    async fn call_tool(&self, tool_call: ToolCall) -> anyhow::Result<ToolResult>;
}

pub struct MCPServer {
    tools: HashMap<String, Tool>,
    handler: JsonToolsHandler,
}

impl MCPServer {
    pub fn new(handler: JsonToolsHandler) -> Self {
        Self {
            tools: HashMap::new(),
            handler,
        }
    }

    pub async fn register_tools(&mut self) -> anyhow::Result<()> {
        let tools = self.handler.get_tools().await?;
        for tool in tools {
            self.tools.insert(tool.name.clone(), tool);
        }
        Ok(())
    }

    pub async fn handle_request(&self, input: &str) -> anyhow::Result<String> {
        debug!("Handling request: {}", input);

        let request: MCPRequest = serde_json::from_str(input)?;

        let response = match request.method.as_str() {
            "tools/list" => {
                let tools: Vec<&Tool> = self.tools.values().collect();
                MCPResponse::success(request.id, json!({ "tools": tools }))
            }
            "tools/call" => {
                if let Some(params) = request.params {
                    match self.handle_tool_call(params).await {
                        Ok(result) => MCPResponse::success(request.id, json!(result)),
                        Err(e) => {
                            error!("Tool call failed: {}", e);
                            MCPResponse::error(request.id, -32603, &format!("Tool call failed: {}", e))
                        }
                    }
                } else {
                    MCPResponse::error(request.id, -32602, "Missing params for tool call")
                }
            }
            "initialize" => {
                let capabilities = json!({
                    "tools": {},
                    "logging": {},
                    "prompts": {},
                    "resources": {}
                });
                MCPResponse::success(request.id, json!({
                    "protocolVersion": "2024-11-05",
                    "capabilities": capabilities,
                    "serverInfo": {
                        "name": "json-mcp-server",
                        "version": "0.1.0"
                    }
                }))
            }
            "initialized" => {
                // Notification - no response needed, but we'll send success
                MCPResponse::success(request.id, json!({}))
            }
            _ => MCPResponse::error(request.id, -32601, "Method not found"),
        };

        Ok(serde_json::to_string(&response)?)
    }

    async fn handle_tool_call(&self, params: Value) -> anyhow::Result<ToolResult> {
        let tool_call: ToolCall = serde_json::from_value(params)?;

        if !self.tools.contains_key(&tool_call.name) {
            return Ok(ToolResult::error(format!("Unknown tool: {}", tool_call.name)));
        }

        self.handler.call_tool(tool_call).await
    }
}
