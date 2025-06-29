#!/usr/bin/env python3
"""
Simple JSON MCP Server Test
Tests the server using subprocess communication
"""

import subprocess
import json
import tempfile
import os

def test_json_server():
    """Test JSON MCP server via subprocess"""
    
    print("🔧 Testing JSON MCP Server")
    print("=" * 40)
    
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
        # Test 1: json-help
        print("\n1️⃣ Testing json-help...")
        help_request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "json-help",
                "arguments": {}
            }
        }
        
        result = subprocess.run(
            ['cargo', 'run', '--quiet', '--'],
            input=json.dumps(help_request) + '\n',
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            try:
                response = json.loads(result.stdout.strip())
                if 'result' in response:
                    print("✅ json-help: Working correctly")
                else:
                    print("❌ json-help: No result in response")
            except json.JSONDecodeError:
                print("❌ json-help: Invalid JSON response")
                print(f"stdout: {result.stdout}")
                print(f"stderr: {result.stderr}")
        else:
            print("❌ json-help: Process failed")
            print(f"Return code: {result.returncode}")
            print(f"stderr: {result.stderr}")
        
        # Test 2: json-read
        print("\n2️⃣ Testing json-read...")
        read_request = {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "json-read",
                "arguments": {
                    "file_path": test_file.replace('\\', '/'),  # Use forward slashes
                    "format": "pretty"
                }
            }
        }
        
        result = subprocess.run(
            ['cargo', 'run', '--quiet', '--'],
            input=json.dumps(read_request) + '\n',
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            try:
                response = json.loads(result.stdout.strip())
                if 'result' in response:
                    print("✅ json-read: Working correctly")
                else:
                    print("❌ json-read: No result in response")
            except json.JSONDecodeError:
                print("❌ json-read: Invalid JSON response")
                print(f"stdout: {result.stdout}")
        else:
            print("❌ json-read: Process failed")
            print(f"Return code: {result.returncode}")
            print(f"stderr: {result.stderr}")
        
        # Test 3: json-query
        print("\n3️⃣ Testing json-query...")
        query_request = {
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
        
        result = subprocess.run(
            ['cargo', 'run', '--quiet', '--'],
            input=json.dumps(query_request) + '\n',
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            try:
                response = json.loads(result.stdout.strip())
                if 'result' in response:
                    print("✅ json-query: Working correctly")
                else:
                    print("❌ json-query: No result in response")
            except json.JSONDecodeError:
                print("❌ json-query: Invalid JSON response")
                print(f"stdout: {result.stdout}")
        else:
            print("❌ json-query: Process failed")
            print(f"Return code: {result.returncode}")
            print(f"stderr: {result.stderr}")
        
        # Test 4: json-validate
        print("\n4️⃣ Testing json-validate...")
        validate_request = {
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
        
        result = subprocess.run(
            ['cargo', 'run', '--quiet', '--'],
            input=json.dumps(validate_request) + '\n',
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            try:
                response = json.loads(result.stdout.strip())
                if 'result' in response:
                    print("✅ json-validate: Working correctly")
                else:
                    print("❌ json-validate: No result in response")
            except json.JSONDecodeError:
                print("❌ json-validate: Invalid JSON response")
                print(f"stdout: {result.stdout}")
        else:
            print("❌ json-validate: Process failed")
            print(f"Return code: {result.returncode}")
            print(f"stderr: {result.stderr}")
        
        print("\n" + "=" * 40)
        print("🎉 Basic Test Complete!")
        
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
    test_json_server()
