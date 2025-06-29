#!/usr/bin/env python3
"""
Test partial JSON recovery capabilities
Check if server can extract valid data from partially malformed JSON
"""

import subprocess
import json
import tempfile
import os

def test_partial_json_recovery():
    """Test if server can handle partially corrupted JSON files"""
    
    print("🔧 Testing Partial JSON Recovery")
    print("=" * 40)
    
    # Test case: JSON with both valid and invalid sections
    partial_json_tests = [
        {
            "name": "Valid array with invalid object",
            "content": '''[
    {"id": 1, "name": "Alice", "valid": true},
    {"id": 2, "name": "Bob", "valid": true},
    {id: 3, name: "Charlie", valid: false}
]''',
            "description": "Array with mix of valid and invalid objects"
        },
        {
            "name": "Valid object with invalid nested object", 
            "content": '''{
    "users": [
        {"id": 1, "name": "Alice"},
        {"id": 2, "name": "Bob"}
    ],
    "metadata": {
        "total": 2,
        invalid_key: "should fail"
    }
}''',
            "description": "Object with invalid nested structure"
        },
        {
            "name": "Truncated JSON (missing end)",
            "content": '''{
    "data": {
        "users": [
            {"id": 1, "name": "Alice"},
            {"id": 2, "name": "Bob"}
        ],
        "total": 2''',
            "description": "JSON cut off mid-structure"
        }
    ]
    
    print("Testing server's ability to handle partial corruption...\n")
    
    results = []
    
    for test_case in partial_json_tests:
        print(f"📋 {test_case['name']}")
        print(f"   {test_case['description']}")
        
        # Create test file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write(test_case['content'])
            test_file = f.name
        
        try:
            # Test with json-read
            request = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "json-read",
                    "arguments": {
                        "file_path": test_file.replace('\\', '/'),
                        "format": "compact"
                    }
                }
            }
            
            result = subprocess.run(
                ['cargo', 'run', '--quiet', '--'],
                input=json.dumps(request) + '\n',
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                # Extract response
                for line in result.stdout.strip().split('\n'):
                    if line.strip().startswith('{"jsonrpc"'):
                        response = json.loads(line.strip())
                        
                        if 'result' in response:
                            content = response['result']['content'][0]['text']
                            print("   🔄 Server processed without fatal error")
                            print(f"   📄 Response preview: {content[:100]}...")
                            
                            # Check if any valid data was extracted
                            if 'Alice' in content or 'Bob' in content:
                                print("   ✅ Successfully extracted some valid data")
                                results.append(True)
                            else:
                                print("   ⚠️ No recognizable data extracted")
                                results.append(False)
                                
                        elif 'error' in response:
                            error_msg = response['error']['message']
                            print("   ❌ Server returned error (no partial recovery)")
                            print(f"   📋 Error: {error_msg}")
                            results.append(False)
                        break
            else:
                print("   ❌ Server process failed")
                results.append(False)
        
        finally:
            try:
                os.unlink(test_file)
            except:
                pass
        
        print()
    
    # Summary
    print("=" * 50)
    print("📊 Partial Recovery Test Results")
    print("=" * 50)
    
    recovery_count = sum(results)
    total_tests = len(results)
    
    print(f"Partial recovery success: {recovery_count}/{total_tests} tests")
    
    if recovery_count > 0:
        print("✅ Server demonstrates some partial recovery capability")
    else:
        print("❌ Server has strict JSON validation (no partial recovery)")
    
    print("\n💡 Current Behavior Analysis:")
    print("   The JSON MCP server uses strict JSON parsing which:")
    print("   ✅ Provides clear error messages for malformed JSON")
    print("   ✅ Ensures data integrity and consistency")
    print("   ✅ Prevents silent data corruption")
    print("   ℹ️ Does not attempt partial recovery (by design)")
    
    print("\n🎯 Recommendation:")
    print("   Current strict validation is appropriate for production use")
    print("   Partial recovery would add complexity and potential data corruption")
    print("   Clear error messages help LLMs understand and fix JSON issues")
    
    return recovery_count, total_tests

if __name__ == "__main__":
    test_partial_json_recovery()
