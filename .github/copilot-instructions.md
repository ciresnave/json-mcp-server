<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# JSON MCP Server Project

This is a Rust-based Model Context Protocol (MCP) server that provides comprehensive JSON file operations for LLMs. 

## Project Purpose
Enable LLMs to efficiently read, write, query, and manipulate JSON files with support for:
- Large file streaming
- JSONPath queries
- Multiple write modes (replace, merge, append)
- Comprehensive help system

## Key Features
- **json-read**: Read JSON files with optional JSONPath filtering
- **json-write**: Write/update JSON files with flexible merge strategies
- **json-query**: Execute complex JSONPath queries with multiple output formats
- **json-stream-read**: Stream large JSON files efficiently
- **json-validate**: Validate JSON structure and syntax
- **json-help**: Interactive help system for tool discovery

## Architecture
- `src/main.rs`: Application entry point and MCP protocol handling
- `src/mcp/`: MCP protocol implementation (server, protocol definitions)
- `src/json_tools/`: JSON tool implementations (operations, queries, streaming)

## Development Guidelines
- Use anyhow for error handling
- Implement async/await patterns consistently
- Follow Rust naming conventions
- Provide detailed error messages for LLM consumption
- Support JSONPath syntax for complex queries
- Optimize for memory efficiency with large files

You can find more info and examples at https://modelcontextprotocol.io/llms-full.txt
