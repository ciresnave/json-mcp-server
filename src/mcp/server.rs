// SPDX-License-Identifier: MIT OR Apache-2.0
use crate::json_tools::handler::JsonToolsHandler;
use crate::mcp::protocol::{MCPError, MCPRequest, MCPResponse, Tool, ToolCall, ToolResult};
use serde_json::{Value, json};
use std::collections::BTreeMap;
use tracing::{debug, error};

#[async_trait::async_trait]
pub trait ToolHandler {
    async fn get_tools(&self) -> anyhow::Result<Vec<Tool>>;
    async fn call_tool(&self, tool_call: ToolCall) -> anyhow::Result<ToolResult>;
}

/// Per-request-metadata ("modern", stateless) protocol revision.
const MODERN_VERSION: &str = "2026-07-28";
/// Handshake-based ("legacy") revisions answered through `initialize`, newest first.
const LEGACY_VERSIONS: [&str; 4] = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"];
/// Every revision this server accepts, newest first.
const SUPPORTED_VERSIONS: [&str; 5] = [
    MODERN_VERSION,
    LEGACY_VERSIONS[0],
    LEGACY_VERSIONS[1],
    LEGACY_VERSIONS[2],
    LEGACY_VERSIONS[3],
];
/// `_meta` key a modern request uses to declare its protocol version.
const META_VERSION_KEY: &str = "io.modelcontextprotocol/protocolVersion";
/// JSON-RPC error code for `UnsupportedProtocolVersionError`.
const UNSUPPORTED_VERSION_CODE: i32 = -32022;
/// How long clients may cache `tools/list` and `server/discover` (the tool set is static).
const CACHE_TTL_MS: u64 = 300_000;

pub struct MCPServer {
    tools: BTreeMap<String, Tool>,
    handler: JsonToolsHandler,
}

impl MCPServer {
    pub fn new(handler: JsonToolsHandler) -> Self {
        Self {
            tools: BTreeMap::new(),
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

    /// Handles one JSON-RPC message. Returns an empty string for a notification
    /// (a message without an `id`), which must not be answered.
    ///
    /// The server is dual-era: `initialize` selects a handshake-based revision, while a request
    /// carrying `_meta["io.modelcontextprotocol/protocolVersion"]` is served statelessly as
    /// revision 2026-07-28 (results carry `resultType`; lists carry caching hints).
    pub async fn handle_request(&self, input: &str) -> anyhow::Result<String> {
        debug!("Handling request: {}", input);

        let request: MCPRequest = serde_json::from_str(input)?;

        if request.id.is_none() {
            // JSON-RPC notifications (e.g. notifications/initialized) get no response.
            return Ok(String::new());
        }

        let modern = match request
            .params
            .as_ref()
            .and_then(|p| p.get("_meta"))
            .and_then(|m| m.get(META_VERSION_KEY))
        {
            None => false,
            Some(Value::String(v)) if v == MODERN_VERSION => true,
            Some(requested) => {
                return Ok(serde_json::to_string(&MCPResponse {
                    jsonrpc: "2.0".to_string(),
                    id: request.id,
                    result: None,
                    error: Some(MCPError {
                        code: UNSUPPORTED_VERSION_CODE,
                        message: "Unsupported protocol version".to_string(),
                        data: Some(json!({
                            "supported": SUPPORTED_VERSIONS,
                            "requested": requested,
                        })),
                    }),
                })?);
            }
        };

        let response = match request.method.as_str() {
            "tools/list" => {
                let tools: Vec<&Tool> = self.tools.values().collect();
                let mut result = json!({ "tools": tools });
                if modern {
                    add_modern_fields(&mut result, true);
                }
                MCPResponse::success(request.id, result)
            }
            "tools/call" => {
                if let Some(params) = request.params {
                    match self.handle_tool_call(params).await {
                        Ok(result) => {
                            let mut result = json!(result);
                            if modern {
                                add_modern_fields(&mut result, false);
                            }
                            MCPResponse::success(request.id, result)
                        }
                        Err(e)
                            if e.downcast_ref::<serde_json::Error>().is_some()
                                || e.downcast_ref::<UnknownTool>().is_some() =>
                        {
                            MCPResponse::error(request.id, -32602, &e.to_string())
                        }
                        Err(e) => {
                            error!("Tool call failed: {}", e);
                            MCPResponse::error(
                                request.id,
                                -32603,
                                &format!("Tool call failed: {}", e),
                            )
                        }
                    }
                } else {
                    MCPResponse::error(request.id, -32602, "Missing params for tool call")
                }
            }
            "server/discover" => {
                let mut result = json!({
                    "supportedVersions": SUPPORTED_VERSIONS,
                    "capabilities": { "tools": {} },
                    "_meta": {
                        "io.modelcontextprotocol/serverInfo": {
                            "name": "json-mcp-server",
                            "version": env!("CARGO_PKG_VERSION")
                        }
                    },
                });
                add_modern_fields(&mut result, true);
                MCPResponse::success(request.id, result)
            }
            "initialize" => {
                // Echo the client's protocol version when we support it, else our newest
                // handshake-based revision.
                let requested = request
                    .params
                    .as_ref()
                    .and_then(|p| p.get("protocolVersion"))
                    .and_then(Value::as_str);
                let version = match requested {
                    Some(v) if LEGACY_VERSIONS.contains(&v) => v,
                    _ => LEGACY_VERSIONS[0],
                };
                MCPResponse::success(
                    request.id,
                    json!({
                        "protocolVersion": version,
                        "capabilities": { "tools": {} },
                        "serverInfo": {
                            "name": "json-mcp-server",
                            "version": env!("CARGO_PKG_VERSION")
                        }
                    }),
                )
            }
            "ping" => MCPResponse::success(request.id, json!({})),
            _ => MCPResponse::error(request.id, -32601, "Method not found"),
        };

        Ok(serde_json::to_string(&response)?)
    }

    async fn handle_tool_call(&self, params: Value) -> anyhow::Result<ToolResult> {
        let tool_call: ToolCall = serde_json::from_value(params)?;

        if !self.tools.contains_key(&tool_call.name) {
            return Err(UnknownTool(tool_call.name).into());
        }

        self.handler.call_tool(tool_call).await
    }
}

/// Adds the revision 2026-07-28 result fields: `resultType`, and for cacheable results the
/// caching hints.
fn add_modern_fields(result: &mut Value, cacheable: bool) {
    if let Some(obj) = result.as_object_mut() {
        obj.insert("resultType".to_string(), json!("complete"));
        if cacheable {
            obj.insert("ttlMs".to_string(), json!(CACHE_TTL_MS));
            obj.insert("cacheScope".to_string(), json!("public"));
        }
    }
}

/// A `tools/call` for a tool this server does not have: a protocol error (-32602).
#[derive(Debug)]
struct UnknownTool(String);

impl std::fmt::Display for UnknownTool {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Unknown tool: {}", self.0)
    }
}

impl std::error::Error for UnknownTool {}
