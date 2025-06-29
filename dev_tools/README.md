# Development Tools

This directory contains development and testing utilities for the JSON MCP Server project.

## Directory Structure

### testing/
Contains various test scripts and utilities used during development:

- **test_all_tools.py** - Comprehensive test of all 5 JSON tools
- **test_all_fixes.py** - Verification of bug fixes and improvements
- **test_multiple_instances.py** - Tests multiple server instances for conflicts
- **test_json_help.py** - Tests the json-help tool functionality
- **test_json_errors.py** - Tests error handling capabilities
- **test_partial_recovery.py** - Tests JSON parsing and partial recovery
- **verify_responses.py** - Validates server response formats
- **simple_test.py** - Basic connectivity and functionality test
- **examples_simple_test.py** - Alternative simple test from examples
- **manual_test.py** - Manual testing utilities
- **test_server.py** - Server functionality tests
- **test_server.py.backup** - Backup of server test file

## Usage

### Running Individual Tests

```bash
# Basic functionality test
python dev_tools/testing/simple_test.py

# Test all tools
python dev_tools/testing/test_all_tools.py

# Test error handling
python dev_tools/testing/test_json_errors.py

# Test multiple instances
python dev_tools/testing/test_multiple_instances.py
```

### Running All Tests

```bash
# Run from project root
for file in dev_tools/testing/test_*.py; do
    echo "Running $file..."
    python "$file"
done
```

### Development Workflow

1. **Make changes** to server code
2. **Build the server**: `cargo build --release`
3. **Run basic test**: `python dev_tools/testing/simple_test.py`
4. **Run comprehensive tests**: `python dev_tools/testing/test_all_tools.py`
5. **Test error cases**: `python dev_tools/testing/test_json_errors.py`
6. **Verify fixes**: `python dev_tools/testing/test_all_fixes.py`

## Test Categories

### Functionality Tests
- Basic tool execution
- Parameter validation  
- Response format verification
- JSONPath query handling

### Error Handling Tests
- Invalid file paths
- Malformed JSON
- Invalid JSONPath syntax
- Permission errors

### Performance Tests
- Large file handling
- Memory usage
- Response timing
- Concurrent access

### Integration Tests
- MCP protocol compliance
- Multiple client scenarios
- Server lifecycle management
- Resource cleanup

## Adding New Tests

When adding new test files:

1. **Use descriptive names** starting with `test_`
2. **Include docstrings** explaining test purpose
3. **Handle cleanup** of test files
4. **Test both success and error cases**
5. **Document expected behavior**

### Test Template

```python
#!/usr/bin/env python3
"""
Test description here.
"""

import json
import subprocess
import sys
from pathlib import Path

def test_functionality():
    """Test specific functionality."""
    # Test implementation
    pass

def cleanup():
    """Clean up test files."""
    # Cleanup implementation
    pass

def main():
    """Main test function."""
    try:
        test_functionality()
        print("✓ Test passed")
    except Exception as e:
        print(f"✗ Test failed: {e}")
        return 1
    finally:
        cleanup()
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

## Debugging

### Enable Debug Output

Set environment variables before running tests:

```bash
set RUST_LOG=debug
python dev_tools/testing/test_name.py
```

### Common Issues

1. **Server not found**: Ensure `json-mcp-server` is in PATH
2. **Permission errors**: Check file permissions in test directory
3. **Port conflicts**: Tests use stdio, not network ports
4. **Memory issues**: Use small test files for basic tests

### Log Analysis

Debug logs are written to `mcp_debug.log` in the user directory:

```bash
# Windows
type %USERPROFILE%\mcp_debug.log

# Unix-like
tail -f ~/mcp_debug.log
```

## Contributing

When contributing test improvements:

1. **Test your tests** on clean systems
2. **Document test purpose** and expected outcomes
3. **Include error scenarios** not just happy paths
4. **Keep tests focused** on specific functionality
5. **Clean up resources** after test completion

## Maintenance

### Regular Tasks

- **Update tests** when adding new features
- **Verify compatibility** with server changes
- **Clean up** old or redundant test files
- **Document** new testing patterns
- **Review** test coverage regularly

### File Cleanup

Periodically review and remove:
- Obsolete test files
- Temporary test data
- Backup files no longer needed
- Failed test artifacts
