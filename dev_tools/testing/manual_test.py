#!/usr/bin/env python3
"""
Manual test to send a single request to the JSON MCP server
"""

import json

def manual_test():
    """Send a manual test request"""
    
    # Test json-help request
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "json-help",
            "arguments": {"topic": "overview"}
        }
    }
    
    print("📤 Manual Test Request:")
    print(json.dumps(request))
    print("\n🔄 Copy the above JSON and paste it into the server stdin")
    print("   The server is waiting for input...")

if __name__ == "__main__":
    manual_test()
