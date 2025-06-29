#!/usr/bin/env python3
"""
Example Python MCP client for JSON MCP Server

This demonstrates how to connect to and use the JSON MCP Server
from a Python application using the MCP protocol.
"""

import asyncio
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional


class JSONMCPClient:
    """Simple MCP client for JSON operations"""
    
    def __init__(self, server_command: str = "json-mcp-server"):
        self.server_command = server_command
        self.process = None
        self.request_id = 0
    
    async def connect(self) -> bool:
        """Connect to the JSON MCP Server"""
        try:
            self.process = await asyncio.create_subprocess_exec(
                self.server_command,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            # Send initialization request
            init_request = {
                "jsonrpc": "2.0",
                "id": self._next_id(),
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {}
                    },
                    "clientInfo": {
                        "name": "python-mcp-client",
                        "version": "1.0.0"
                    }
                }
            }
            
            response = await self._send_request(init_request)
            return response.get("result") is not None
            
        except Exception as e:
            print(f"Failed to connect: {e}")
            return False
    
    async def disconnect(self):
        """Disconnect from the server"""
        if self.process:
            self.process.stdin.close()
            await self.process.wait()
    
    async def list_tools(self) -> List[Dict[str, Any]]:
        """List available tools"""
        request = {
            "jsonrpc": "2.0",
            "id": self._next_id(),
            "method": "tools/list"
        }
        
        response = await self._send_request(request)
        return response.get("result", {}).get("tools", [])
    
    async def call_tool(self, name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
        """Call a specific tool"""
        request = {
            "jsonrpc": "2.0",
            "id": self._next_id(),
            "method": "tools/call",
            "params": {
                "name": name,
                "arguments": arguments
            }
        }
        
        return await self._send_request(request)
    
    async def validate_json(self, file_path: str) -> Dict[str, Any]:
        """Validate a JSON file"""
        return await self.call_tool("json-validate", {"file_path": file_path})
    
    async def read_json(self, file_path: str, json_path: Optional[str] = None, 
                       limit: Optional[int] = None) -> Dict[str, Any]:
        """Read JSON file with optional filtering"""
        args = {"file_path": file_path}
        if json_path:
            args["json_path"] = json_path
        if limit:
            args["limit"] = limit
        
        return await self.call_tool("json-read", args)
    
    async def write_json(self, file_path: str, content: str, 
                        mode: str = "replace") -> Dict[str, Any]:
        """Write JSON content to file"""
        return await self.call_tool("json-write", {
            "file_path": file_path,
            "content": content,
            "mode": mode
        })
    
    async def query_json(self, file_path: str, json_path: str, 
                        output_format: str = "json") -> Dict[str, Any]:
        """Query JSON file with JSONPath"""
        return await self.call_tool("json-query", {
            "file_path": file_path,
            "json_path": json_path,
            "output_format": output_format
        })
    
    async def get_help(self, topic: Optional[str] = None) -> Dict[str, Any]:
        """Get help information"""
        args = {}
        if topic:
            args["topic"] = topic
        
        return await self.call_tool("json-help", args)
    
    def _next_id(self) -> int:
        """Generate next request ID"""
        self.request_id += 1
        return self.request_id
    
    async def _send_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Send request and get response"""
        if not self.process:
            raise RuntimeError("Not connected to server")
        
        # Send request
        request_json = json.dumps(request) + "\n"
        self.process.stdin.write(request_json.encode())
        await self.process.stdin.drain()
        
        # Read response
        response_line = await self.process.stdout.readline()
        if not response_line:
            raise RuntimeError("Server disconnected")
        
        try:
            return json.loads(response_line.decode())
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Invalid JSON response: {e}")


async def demo_basic_operations():
    """Demonstrate basic JSON operations"""
    client = JSONMCPClient()
    
    print("Connecting to JSON MCP Server...")
    if not await client.connect():
        print("Failed to connect!")
        return
    
    try:
        # List available tools
        print("\n=== Available Tools ===")
        tools = await client.list_tools()
        for tool in tools:
            print(f"- {tool.get('name', 'Unknown')}: {tool.get('description', 'No description')}")
        
        # Get help
        print("\n=== Getting Help ===")
        help_response = await client.get_help("overview")
        if "result" in help_response:
            content = help_response["result"]["content"][0]["text"]
            print(content[:300] + "..." if len(content) > 300 else content)
        
        # Create test data
        test_file = Path("test_data.json")
        test_data = {
            "users": [
                {"id": 1, "name": "Alice", "age": 30, "department": "Engineering"},
                {"id": 2, "name": "Bob", "age": 25, "department": "Marketing"},
                {"id": 3, "name": "Carol", "age": 35, "department": "Engineering"}
            ],
            "config": {
                "version": "1.0",
                "features": ["authentication", "logging"]
            }
        }
        
        # Write test data
        print("\n=== Writing Test Data ===")
        write_response = await client.write_json(
            str(test_file), 
            json.dumps(test_data, indent=2)
        )
        if "result" in write_response:
            print("✓ Test data written successfully")
        else:
            print(f"✗ Write failed: {write_response.get('error', 'Unknown error')}")
            return
        
        # Validate the file
        print("\n=== Validating JSON ===")
        validate_response = await client.validate_json(str(test_file))
        if "result" in validate_response:
            result = validate_response["result"]["content"][0]["text"]
            print(f"✓ Validation: {result}")
        
        # Read full file
        print("\n=== Reading Full File ===")
        read_response = await client.read_json(str(test_file))
        if "result" in read_response:
            print("✓ File read successfully")
        
        # Query specific data
        print("\n=== Querying Data ===")
        query_response = await client.query_json(
            str(test_file),
            "$.users[?(@.department == 'Engineering')].name"
        )
        if "result" in query_response:
            result = query_response["result"]["content"][0]["text"]
            print(f"Engineering users: {result}")
        
        # Update configuration
        print("\n=== Updating Configuration ===")
        new_config = {"config": {"debug": True}}
        update_response = await client.write_json(
            str(test_file),
            json.dumps(new_config),
            mode="merge_deep"
        )
        if "result" in update_response:
            print("✓ Configuration updated")
        
        # Verify update
        print("\n=== Verifying Update ===")
        verify_response = await client.query_json(
            str(test_file),
            "$.config"
        )
        if "result" in verify_response:
            result = verify_response["result"]["content"][0]["text"]
            print(f"Updated config: {result}")
        
        # Clean up
        test_file.unlink()
        print("\n✓ Demo completed successfully!")
        
    except Exception as e:
        print(f"\n✗ Demo failed: {e}")
    
    finally:
        await client.disconnect()


async def demo_large_file_processing():
    """Demonstrate large file processing capabilities"""
    client = JSONMCPClient()
    
    print("Connecting for large file demo...")
    if not await client.connect():
        print("Failed to connect!")
        return
    
    try:
        # Create large dataset
        large_file = Path("large_data.json")
        large_data = {
            "records": [
                {
                    "id": i,
                    "name": f"User_{i}",
                    "score": i * 10,
                    "active": i % 2 == 0,
                    "category": "premium" if i % 5 == 0 else "standard"
                }
                for i in range(1000)
            ]
        }
        
        print(f"\n=== Creating Large Dataset ({len(large_data['records'])} records) ===")
        await client.write_json(str(large_file), json.dumps(large_data))
        print("✓ Large dataset created")
        
        # Read with pagination
        print("\n=== Reading with Pagination ===")
        page_response = await client.read_json(
            str(large_file),
            json_path="$.records",
            limit=10
        )
        if "result" in page_response:
            print("✓ First 10 records retrieved")
        
        # Query premium users
        print("\n=== Querying Premium Users ===")
        premium_response = await client.query_json(
            str(large_file),
            "$.records[?(@.category == 'premium')].name",
            output_format="compact"
        )
        if "result" in premium_response:
            result = premium_response["result"]["content"][0]["text"]
            print(f"Premium users: {len(json.loads(result))} found")
        
        # Clean up
        large_file.unlink()
        print("\n✓ Large file demo completed!")
        
    except Exception as e:
        print(f"\n✗ Large file demo failed: {e}")
    
    finally:
        await client.disconnect()


async def demo_error_handling():
    """Demonstrate error handling"""
    client = JSONMCPClient()
    
    print("Connecting for error handling demo...")
    if not await client.connect():
        print("Failed to connect!")
        return
    
    try:
        print("\n=== Testing Error Handling ===")
        
        # Test with non-existent file
        print("Testing non-existent file...")
        response = await client.validate_json("nonexistent.json")
        if "error" in response:
            print(f"✓ Handled missing file: {response['error']['message']}")
        
        # Test with invalid JSON
        print("\nTesting invalid JSON...")
        invalid_file = Path("invalid.json")
        invalid_file.write_text("{ invalid json }")
        
        response = await client.validate_json(str(invalid_file))
        if "result" in response:
            result = response["result"]["content"][0]["text"]
            print(f"✓ Validation caught error: {result}")
        
        # Test with invalid JSONPath
        print("\nTesting invalid JSONPath...")
        valid_file = Path("valid.json")
        valid_file.write_text('{"test": "data"}')
        
        response = await client.query_json(str(valid_file), "invalid[path")
        if "error" in response:
            print(f"✓ Handled invalid JSONPath: {response['error']['message']}")
        
        # Clean up
        invalid_file.unlink()
        valid_file.unlink()
        print("\n✓ Error handling demo completed!")
        
    except Exception as e:
        print(f"\n✗ Error handling demo failed: {e}")
    
    finally:
        await client.disconnect()


def main():
    """Main demo function"""
    print("JSON MCP Server Python Client Demo")
    print("=" * 40)
    
    async def run_demos():
        await demo_basic_operations()
        await demo_large_file_processing()
        await demo_error_handling()
    
    try:
        asyncio.run(run_demos())
    except KeyboardInterrupt:
        print("\nDemo interrupted by user")
    except Exception as e:
        print(f"Demo failed: {e}")


if __name__ == "__main__":
    main()
