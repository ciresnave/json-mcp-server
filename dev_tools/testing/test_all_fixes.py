#!/usr/bin/env python3
"""
Comprehensive test suite for JSON MCP Server fixes
Tests: Multiple instances, updated help, and error handling
"""

import subprocess
import json
import tempfile
import os
import time
import asyncio

def test_multiple_instances():
    """Test multiple server instances can run concurrently"""
    print("1️⃣ Testing Multiple Server Instances")
    print("-" * 40)
    
    test_data = {"test": "concurrent", "id": 123}
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(test_data, f)
        test_file = f.name
    
    processes = []
    try:
        # Start 3 server instances
        for i in range(3):
            process = subprocess.Popen(
                ['cargo', 'run', '--quiet', '--'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            processes.append(process)
            time.sleep(0.3)
        
        print(f"   Started {len(processes)} server instances")
        
        # Test concurrent requests
        request = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "json-read",
                "arguments": {"file_path": test_file.replace('\\', '/')}
            }
        }
        
        success_count = 0
        for i, process in enumerate(processes):
            try:
                stdout, stderr = process.communicate(
                    input=json.dumps(request) + '\n', 
                    timeout=10
                )
                if '{"jsonrpc"' in stdout and '"result"' in stdout:
                    success_count += 1
            except:
                pass
        
        print(f"   {success_count}/{len(processes)} instances responded successfully")
        return success_count == len(processes)
        
    finally:
        for process in processes:
            try:
                if process.poll() is None:
                    process.terminate()
                    process.wait(timeout=2)
            except:
                try:
                    process.kill()
                except:
                    pass
        try:
            os.unlink(test_file)
        except:
            pass

def test_json_help_updated():
    """Test that json-help has updated tool references"""
    print("\n2️⃣ Testing Updated json-help Tool")
    print("-" * 40)
    
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
            # Extract response
            for line in result.stdout.strip().split('\n'):
                if line.strip().startswith('{"jsonrpc"'):
                    response = json.loads(line.strip())
                    if 'result' in response:
                        content = response['result']['content'][0]['text']
                        
                        # Check for issues
                        has_old_refs = 'json-stream-read' in content
                        has_new_refs = 'json-read' in content and 'automatic streaming' in content
                        
                        if has_old_refs:
                            print("   ❌ Still contains old 'json-stream-read' references")
                            return False
                        elif has_new_refs:
                            print("   ✅ Contains correct 'json-read' references")
                            print("   ✅ Mentions automatic streaming feature")
                            return True
                        else:
                            print("   ❌ Missing expected tool references")
                            return False
        
        print("   ❌ No valid response received")
        return False
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def test_json_error_handling():
    """Test JSON error handling for malformed files"""
    print("\n3️⃣ Testing JSON Error Handling")
    print("-" * 40)
    
    test_cases = [
        ('Valid JSON', '{"valid": true}', True),
        ('Missing brace', '{"invalid": true', False),
        ('Trailing comma', '{"invalid": true,}', False)
    ]
    
    success_count = 0
    
    for name, content, should_succeed in test_cases:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write(content)
            test_file = f.name
        
        try:
            request = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "json-read",
                    "arguments": {"file_path": test_file.replace('\\', '/')}
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
                for line in result.stdout.strip().split('\n'):
                    if line.strip().startswith('{"jsonrpc"'):
                        response = json.loads(line.strip())
                        
                        has_result = 'result' in response
                        has_error = 'error' in response
                        
                        if should_succeed and has_result:
                            print(f"   ✅ {name}: Handled correctly (success)")
                            success_count += 1
                        elif not should_succeed and has_error:
                            print(f"   ✅ {name}: Handled correctly (error detected)")
                            success_count += 1
                        else:
                            print(f"   ❌ {name}: Unexpected behavior")
                        break
            else:
                print(f"   ❌ {name}: Process failed")
        
        finally:
            try:
                os.unlink(test_file)
            except:
                pass
    
    print(f"   {success_count}/{len(test_cases)} error handling tests passed")
    return success_count == len(test_cases)

def main():
    """Run all tests and report results"""
    print("🔧 JSON MCP Server - Comprehensive Test Suite")
    print("=" * 50)
    
    results = []
    
    # Test 1: Multiple instances
    results.append(("Multiple Instances", test_multiple_instances()))
    
    # Test 2: Updated help
    results.append(("Updated json-help", test_json_help_updated()))
    
    # Test 3: Error handling
    results.append(("JSON Error Handling", test_json_error_handling()))
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary")
    print("=" * 50)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 Overall: {passed}/{len(results)} tests passed")
    
    if passed == len(results):
        print("🎉 All fixes working correctly!")
        print("\n✅ Multiple instances: Server handles concurrent access")
        print("✅ Updated json-help: All tool references are current")  
        print("✅ Error handling: Malformed JSON properly detected and reported")
        return True
    else:
        print("⚠️ Some tests failed - review results above")
        return False

if __name__ == "__main__":
    result = main()
    exit(0 if result else 1)
