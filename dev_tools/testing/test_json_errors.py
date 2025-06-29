#!/usr/bin/env python3
"""
Test JSON error handling and malformed JSON parsing
"""

import subprocess
import json
import tempfile
import os

def test_json_error_handling():
    """Test how the server handles malformed JSON files"""
    
    print("🔧 Testing JSON Error Handling")
    print("=" * 35)
    
    test_cases = [
        {
            "name": "Valid JSON",
            "content": '{"users": [{"name": "Alice", "id": 1}], "total": 1}',
            "should_succeed": True
        },
        {
            "name": "Missing closing brace",
            "content": '{"users": [{"name": "Alice", "id": 1}], "total": 1',
            "should_succeed": False
        },
        {
            "name": "Trailing comma",
            "content": '{"users": [{"name": "Alice", "id": 1},], "total": 1}',
            "should_succeed": False
        },
        {
            "name": "Unquoted keys",
            "content": '{users: [{"name": "Alice", "id": 1}], "total": 1}',
            "should_succeed": False
        },
        {
            "name": "Mixed valid/invalid (partial corruption)",
            "content": '{"users": [{"name": "Alice", "id": 1}], "total": 1, "metadata": {bad_key: "value"}}',
            "should_succeed": False
        }
    ]
    
    results = []
    
    for test_case in test_cases:
        print(f"\n📋 Testing: {test_case['name']}")
        print("-" * 30)
        
        # Create test file with potentially malformed JSON
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write(test_case['content'])
            test_file = f.name
        
        try:
            # Test json-read
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
                # Extract JSON response
                lines = result.stdout.strip().split('\n')
                json_response = None
                for line in lines:
                    if line.strip().startswith('{"jsonrpc"'):
                        json_response = json.loads(line.strip())
                        break
                
                if json_response:
                    if 'result' in json_response:
                        content = json_response['result']['content'][0]['text']
                        print("✅ Server responded successfully")
                        
                        # Check if error/warning is mentioned
                        if 'error' in content.lower() or 'invalid' in content.lower() or 'malformed' in content.lower():
                            print("✅ Server detected and reported JSON issues")
                        else:
                            print("ℹ️ Server processed without explicit error reporting")
                        
                        # Show preview of response
                        preview = content[:150] + "..." if len(content) > 150 else content
                        print(f"   Response: {preview}")
                        
                        results.append({
                            "test": test_case['name'],
                            "succeeded": True,
                            "detected_error": 'error' in content.lower() or 'invalid' in content.lower(),
                            "expected_success": test_case['should_succeed']
                        })
                        
                    elif 'error' in json_response:
                        error_msg = json_response['error']['message']
                        print("❌ Server returned error")
                        print(f"   Error: {error_msg}")
                        
                        results.append({
                            "test": test_case['name'],
                            "succeeded": False,
                            "detected_error": True,
                            "expected_success": test_case['should_succeed']
                        })
                else:
                    print("❌ No valid JSON response")
                    results.append({
                        "test": test_case['name'],
                        "succeeded": False,
                        "detected_error": False,
                        "expected_success": test_case['should_succeed']
                    })
            else:
                print("❌ Server process failed")
                print(f"   stderr: {result.stderr}")
                results.append({
                    "test": test_case['name'],
                    "succeeded": False,
                    "detected_error": False,
                    "expected_success": test_case['should_succeed']
                })
        
        finally:
            # Clean up test file
            try:
                os.unlink(test_file)
            except:
                pass
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 JSON Error Handling Test Results:")
    print("=" * 50)
    
    for result in results:
        status = "✅" if (result['succeeded'] == result['expected_success']) else "❌"
        detection = "🔍" if result['detected_error'] else "❓"
        print(f"{status} {detection} {result['test']}")
        print(f"   Expected success: {result['expected_success']}, Got success: {result['succeeded']}")
        print(f"   Error detection: {result['detected_error']}")
    
    # Check if server can handle partial recovery
    correct_behavior = sum(1 for r in results if r['succeeded'] == r['expected_success'])
    error_detection = sum(1 for r in results if r['detected_error'] and not r['expected_success'])
    
    print(f"\n📈 Summary:")
    print(f"   Correct behavior: {correct_behavior}/{len(results)} tests")
    print(f"   Error detection: {error_detection}/{sum(1 for r in results if not r['expected_success'])} invalid JSON cases")
    
    return results

if __name__ == "__main__":
    test_json_error_handling()
