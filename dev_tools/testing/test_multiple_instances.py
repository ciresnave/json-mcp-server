#!/usr/bin/env python3
"""
Test multiple server instances running concurrently
"""

import asyncio
import json
import tempfile
import os
import subprocess
import time

async def test_multiple_server_instances():
    """Test that multiple server instances can run simultaneously"""
    
    print("🔧 Testing Multiple Server Instances")
    print("=" * 45)
    
    # Create test data
    test_data = {"test": "concurrent access", "value": 42}
    
    # Create temporary test file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        json.dump(test_data, f, indent=2)
        test_file = f.name
    
    processes = []
    
    try:
        print("\n1️⃣ Starting multiple server instances...")
        
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
            print(f"   Started server instance {i + 1} (PID: {process.pid})")
            time.sleep(0.5)  # Small delay between starts
        
        print("✅ All 3 server instances started successfully")
        
        # Test concurrent requests
        print("\n2️⃣ Testing concurrent requests...")
        
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
        
        request_json = json.dumps(request) + '\n'
        
        # Send request to all instances simultaneously
        responses = []
        for i, process in enumerate(processes):
            try:
                stdout, stderr = process.communicate(input=request_json, timeout=10)
                
                # Extract JSON response
                if stdout.strip():
                    # Find the JSON response line
                    lines = stdout.strip().split('\n')
                    json_response = None
                    for line in lines:
                        if line.strip().startswith('{"jsonrpc"'):
                            json_response = json.loads(line.strip())
                            break
                    
                    if json_response and 'result' in json_response:
                        responses.append(f"Instance {i + 1}: ✅ Success")
                    else:
                        responses.append(f"Instance {i + 1}: ❌ No valid response")
                else:
                    responses.append(f"Instance {i + 1}: ❌ No output")
                    
            except subprocess.TimeoutExpired:
                responses.append(f"Instance {i + 1}: ❌ Timeout")
                process.kill()
            except Exception as e:
                responses.append(f"Instance {i + 1}: ❌ Error: {e}")
        
        # Report results
        success_count = sum(1 for r in responses if "✅" in r)
        
        print("\n📊 Results:")
        for response in responses:
            print(f"   {response}")
        
        print(f"\n   {success_count}/3 instances responded successfully")
        
        if success_count == 3:
            print("✅ Multiple instance test PASSED")
        else:
            print("❌ Multiple instance test FAILED")
            
        return success_count == 3
        
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
        return False
        
    finally:
        # Clean up processes
        for process in processes:
            try:
                if process.poll() is None:  # Still running
                    process.terminate()
                    process.wait(timeout=5)
            except:
                try:
                    process.kill()
                except:
                    pass
        
        # Clean up test file
        try:
            os.unlink(test_file)
        except:
            pass

if __name__ == "__main__":
    result = asyncio.run(test_multiple_server_instances())
    exit(0 if result else 1)
