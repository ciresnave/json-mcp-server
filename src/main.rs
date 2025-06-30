use clap::Parser;
use std::io::{self, BufRead, Write};
use std::fs::OpenOptions;

mod json_tools;
mod mcp;

use json_tools::JsonToolsHandler;
use mcp::{
    protocol::MCPResponse,
    server::MCPServer,
};

#[derive(Parser)]
#[command(
    name = "json-mcp-server",
    about = "A Model Context Protocol server for JSON file operations",
    version = env!("CARGO_PKG_VERSION")
)]
struct Args {
    #[arg(short, long, default_value = "off")]
    log_level: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _args = Args::parse();

    // Tracing disabled for MCP compliance - stdout must be clean JSON-RPC only
    // Use --log-level debug if debugging is needed (will output to stderr)

    // Create debug log file for MCP message tracing
    let mut debug_log = OpenOptions::new()
        .create(true)
        .append(true)
        .open("mcp_debug.log")
        .ok();

    // Create the JSON tools handler
    let json_handler = JsonToolsHandler::new();

    // Create the MCP server
    let mut server = MCPServer::new(json_handler);

    // Register JSON tools
    server.register_tools().await?;

    // Start the server loop
    let stdin = io::stdin();
    let mut stdout = io::stdout();

    for line in stdin.lock().lines() {
        match line {
            Ok(input) => {
                if input.trim().is_empty() {
                    continue;
                }

                // Log incoming request
                if let Some(ref mut log) = debug_log {
                    let timestamp = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
                    let _ = writeln!(log, "[{}] INCOMING: {}", timestamp, input);
                    let _ = log.flush();
                }

                match server.handle_request(&input).await {
                    Ok(response) => {
                        // Log outgoing response
                        if let Some(ref mut log) = debug_log {
                            let timestamp = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
                            let _ = writeln!(log, "[{}] OUTGOING: {}", timestamp, response);
                            let _ = log.flush();
                        }

                        if let Err(_e) = writeln!(stdout, "{}", response) {
                            break;
                        }
                        if let Err(_e) = stdout.flush() {
                            break;
                        }
                    }
                    Err(e) => {
                        let error_response = MCPResponse::error(
                            None,
                            -32603,
                            &format!("Internal error: {}", e),
                        );
                        let response_str = serde_json::to_string(&error_response)?;
                        
                        // Log outgoing error response
                        if let Some(ref mut log) = debug_log {
                            let timestamp = chrono::Utc::now().format("%Y-%m-%d %H:%M:%S%.3f");
                            let _ = writeln!(log, "[{}] ERROR_OUTGOING: {}", timestamp, response_str);
                            let _ = log.flush();
                        }

                        if let Err(_e) = writeln!(stdout, "{}", response_str) {
                            break;
                        }
                        if let Err(_e) = stdout.flush() {
                            break;
                        }
                    }
                }
            }
            Err(_e) => {
                break;
            }
        }
    }

    Ok(())
}
