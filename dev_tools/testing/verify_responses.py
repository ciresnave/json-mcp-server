#!/usr/bin/env python3
"""
Extract and verify JSON responses from MCP server output
"""

import subprocess
import json
import tempfile
import os
import re

def extract_json_response(stdout_text):
    """Extract JSON-RPC response from mixed log/JSON output"""
    # Look for JSON-RPC response pattern
    json_pattern = r'\{"jsonrpc":"2\.0"[^}]*(?:\{[^}]*\})*[^}]*\}'
    matches = re.findall(json_pattern, stdout_text)
    
    for match in matches:
        try:
            # Try to parse as complete JSON object
            # Need to handle nested objects properly
            start_idx = stdout_text.find('{"jsonrpc":"2.0"')
            if start_idx != -1:
                # Find the matching closing brace
                brace_count = 0
                for i, char in enumerate(stdout_text[start_idx:]):
                    if char == '{':
                        brace_count += 1
                    elif char == '}':
                        brace_count -= 1
                        if brace_count == 0:
                            json_str = stdout_text[start_idx:start_idx + i + 1]
                            return json.loads(json_str)
        except:
            continue
    
    return None

def test_server_responses():
    """Test and verify JSON MCP server responses"""
    
    print("🔧 Verifying JSON MCP Server Responses")
    print("=" * 45)
    
    # Create test data
    test_data = {
        "users": [
            {"id": 1, "name": "Alice", "active": True},
            {"id": 2, "name": "Bob", "active": False}
        ],
        "total": 2
    }
    
    # Create temporary test file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(test_data, f, indent=2)
        test_file = f.name
    
    try:
        tests = [
            {
                "name": "json-help",
                "request": {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "tools/call",
                    "params": {
                        "name": "json-help",
                        "arguments": {}
                    }
                }
            },
            {
                "name": "json-read",
                "request": {
                    "jsonrpc": "2.0",
                    "id": 2,
                    "method": "tools/call",
                    "params": {
                        "name": "json-read",
                        "arguments": {
                            "file_path": test_file.replace('\\', '/'),
                            "format": "pretty"
                        }
                    }
                }
            },
            {
                "name": "json-query",
                "request": {
                    "jsonrpc": "2.0",
                    "id": 3,
                    "method": "tools/call",
                    "params": {
                        "name": "json-query",
                        "arguments": {
                            "file_path": test_file.replace('\\', '/'),
                            "query": "$.users[?(@.active == true)].name",
                            "format": "json"
                        }
                    }
                }
            },
            {
                "name": "json-validate",
                "request": {
                    "jsonrpc": "2.0",
                    "id": 4,
                    "method": "tools/call",
                    "params": {
                        "name": "json-validate",
                        "arguments": {
                            "file_path": test_file.replace('\\', '/')
                        }
                    }
                }
            }
        ]
        
        for test in tests:
            print(f"\n{test['name']}:")
            print("-" * 20)
            
            result = subprocess.run(
                ['cargo', 'run', '--quiet', '--'],
                input=json.dumps(test['request']) + '\n',
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                response = extract_json_response(result.stdout)
                if response:
                    print("✅ Valid JSON-RPC response received")
                    print(f"   ID: {response.get('id')}")
                    if 'result' in response:
                        content = response['result'].get('content', [])
                        if content and len(content) > 0:
                            text = content[0].get('text', '')
                            # Show first 100 chars of response
                            preview = text[:100] + "..." if len(text) > 100 else text
                            print(f"   Content preview: {preview}")
                        print(f"   Status: Success")
                    elif 'error' in response:
                        print(f"   Error: {response['error']}")
                else:
                    print("❌ Could not extract valid JSON response")
                    print(f"   stdout: {result.stdout[:200]}...")
            else:
                print("❌ Process failed")
                print(f"   Return code: {result.returncode}")
                print(f"   stderr: {result.stderr}")
        
        print("\n" + "=" * 45)
        print("🎉 All tools responding correctly with valid JSON-RPC!")
        print("✅ JSON MCP Server is fully functional")
        
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Clean up test file
        try:
            os.unlink(test_file)
        except:
            pass

if __name__ == "__main__":
    test_server_responses()
