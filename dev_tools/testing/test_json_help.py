#!/usr/bin/env python3
"""
Test json-help tool and check for outdated references
"""

import subprocess
import json
import re

def test_json_help():
    """Test json-help tool and check for outdated information"""
    
    print("🔧 Testing json-help Tool")
    print("=" * 35)
    
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "json-help",
            "arguments": {}
        }
    }
    
    try:
        result = subprocess.run(
            ['cargo', 'run', '--quiet', '--'],
            input=json.dumps(request) + '\n',
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            # Extract JSON response
            lines = result.stdout.strip().split('\n')
            json_response = None
            for line in lines:
                if line.strip().startswith('{"jsonrpc"'):
                    json_response = json.loads(line.strip())
                    break
            
            if json_response and 'result' in json_response:
                content = json_response['result']['content'][0]['text']
                print("✅ json-help responded successfully")
                print("\n📋 Checking for outdated references...")
                
                issues = []
                
                # Check for outdated tool names
                if 'json-stream-read' in content:
                    issues.append("❌ Still references 'json-stream-read' (should be 'json-read')")
                
                if 'json-read' not in content:
                    issues.append("❌ Missing reference to 'json-read' tool")
                
                # Check if all current tools are mentioned
                expected_tools = ['json-read', 'json-write', 'json-query', 'json-validate', 'json-help']
                for tool in expected_tools:
                    if tool not in content:
                        issues.append(f"❌ Missing reference to '{tool}' tool")
                
                if not issues:
                    print("✅ All tool references are up to date")
                else:
                    print("⚠️ Found issues:")
                    for issue in issues:
                        print(f"   {issue}")
                
                print(f"\n📄 Help content preview:")
                print("=" * 40)
                print(content[:500] + "..." if len(content) > 500 else content)
                print("=" * 40)
                
                return len(issues) == 0
                
            else:
                print("❌ No valid response from json-help")
                return False
        else:
            print("❌ json-help request failed")
            print(f"stderr: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        return False

if __name__ == "__main__":
    result = test_json_help()
    exit(0 if result else 1)
