#!/usr/bin/env python3
# SPDX-License-Identifier: MIT OR Apache-2.0
"""
Comprehensive JSON MCP Server Test Suite
Tests all 5 tools with various scenarios to verify functionality.
"""

import asyncio
import json
import tempfile
import os
from typing import Dict, Any


async def send_mcp_request(reader: asyncio.StreamReader, writer: asyncio.StreamWriter, request: Dict[str, Any]) -> Dict[str, Any]:
    """Send MCP request and get response"""
    message = json.dumps(request) + '\n'
    writer.write(message.encode())
    await writer.drain()
    
    response_line = await reader.readline()
    return json.loads(response_line.decode().strip())


async def test_json_mcp_server() -> None:
    """Test all JSON MCP server tools"""
    
    # Start the server process
    process = await asyncio.create_subprocess_exec(
        'cargo', 'run', '--',
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    reader = process.stdout
    writer = process.stdin
    
    try:
        print("🔧 Testing JSON MCP Server - All Tools")
        print("=" * 50)
        
        # 1. Test json-help
        print("\n1️⃣ Testing json-help tool...")
        help_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "json-help",
                "arguments": {"tool": "json-read"}
            }
        }
        
        response = await send_mcp_request(reader, writer, help_request)
        if response.get('result', {}).get('content'):
            print("✅ json-help: Working correctly")
        else:
            print("❌ json-help: Failed")
            print(f"Response: {response}")
        
        # 2. Create test file for other operations
        test_data = {
            "users": [
                {"id": 1, "name": "Alice", "email": "alice@example.com", "active": True},
                {"id": 2, "name": "Bob", "email": "bob@example.com", "active": False},
                {"id": 3, "name": "Charlie", "email": "charlie@example.com", "active": True}
            ],
            "metadata": {
                "version": "1.0",
                "created": "2024-01-15",
                "total_users": 3
            }
        }
        
        # Create temporary test file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(test_data, f, indent=2)
            test_file = f.name
        
        try:
            # 3. Test json-write
            print("\n2️⃣ Testing json-write tool...")
            write_request = {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": "json-write",
                    "arguments": {
                        "file_path": test_file,
                        "data": test_data,
                        "strategy": "replace"
                    }
                }
            }
            
            response = await send_mcp_request(reader, writer, write_request)
            if 'error' not in response:
                print("✅ json-write: Working correctly")
            else:
                print("❌ json-write: Failed")
                print(f"Error: {response.get('error')}")
            
            # 4. Test json-read
            print("\n3️⃣ Testing json-read tool...")
            read_request = {
                "jsonrpc": "2.0",
                "id": 3,
                "method": "tools/call",
                "params": {
                    "name": "json-read",
                    "arguments": {
                        "file_path": test_file,
                        "format": "pretty"
                    }
                }
            }
            
            response = await send_mcp_request(reader, writer, read_request)
            if response.get('result', {}).get('content'):
                print("✅ json-read: Working correctly")
            else:
                print("❌ json-read: Failed")
                print(f"Response: {response}")
            
            # 5. Test json-query
            print("\n4️⃣ Testing json-query tool...")
            query_request = {
                "jsonrpc": "2.0",
                "id": 4,
                "method": "tools/call",
                "params": {
                    "name": "json-query",
                    "arguments": {
                        "file_path": test_file,
                        "query": "$.users[?(@.active == true)].name",
                        "format": "json"
                    }
                }
            }
            
            response = await send_mcp_request(reader, writer, query_request)
            if response.get('result', {}).get('content'):
                print("✅ json-query: Working correctly")
                result = json.loads(response['result']['content'][0]['text'])
                print(f"   Found active users: {result}")
            else:
                print("❌ json-query: Failed")
                print(f"Response: {response}")
            
            # 6. Test json-validate
            print("\n5️⃣ Testing json-validate tool...")
            validate_request = {
                "jsonrpc": "2.0",
                "id": 5,
                "method": "tools/call",
                "params": {
                    "name": "json-validate",
                    "arguments": {
                        "file_path": test_file
                    }
                }
            }
            
            response = await send_mcp_request(reader, writer, validate_request)
            if response.get('result', {}).get('content'):
                print("✅ json-validate: Working correctly")
            else:
                print("❌ json-validate: Failed")
                print(f"Response: {response}")
            
            # 7. Test error handling with invalid file
            print("\n6️⃣ Testing error handling...")
            error_request = {
                "jsonrpc": "2.0",
                "id": 6,
                "method": "tools/call",
                "params": {
                    "name": "json-read",
                    "arguments": {
                        "file_path": "/nonexistent/file.json"
                    }
                }
            }
            
            response = await send_mcp_request(reader, writer, error_request)
            if 'error' in response:
                print("✅ Error handling: Working correctly")
            else:
                print("❌ Error handling: Should have failed but didn't")
                print(f"Response: {response}")
            
        finally:
            # Clean up test file
            try:
                os.unlink(test_file)
            except:
                pass
        
        print("\n" + "=" * 50)
        print("🎉 Test Suite Complete!")
        print("All JSON MCP Server tools have been tested.")
        
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Clean shutdown
        writer.close()
        await writer.wait_closed()
        
        try:
            await asyncio.wait_for(process.wait(), timeout=5.0)
        except asyncio.TimeoutError:
            process.terminate()
            await process.wait()

if __name__ == "__main__":
    asyncio.run(test_json_mcp_server())
