# JSON MCP Server Examples

This directory contains examples and sample data for demonstrating the JSON MCP Server capabilities.

## Sample Data

### `sample_data.json`
A sample JSON file containing user data with nested objects and arrays. Perfect for testing JSONPath queries and various operations.

**Structure:**
- `users[]`: Array of user objects
- `metadata`: Metadata about the dataset

## Example Queries

Here are some example JSONPath queries you can try with the sample data:

### Basic Queries

1. **Get all users:**
   ```
   $.users[*]
   ```

2. **Get active users only:**
   ```
   $.users[?(@.active == true)]
   ```

3. **Get users in Engineering department:**
   ```
   $.users[?(@.department == 'Engineering')]
   ```

4. **Get all user names:**
   ```
   $.users[*].name
   ```

5. **Get all project names:**
   ```
   $.users[*].projects[*].name
   ```

### Advanced Queries

1. **Get users with Python skills:**
   ```
   $.users[?('Python' in @.skills)]
   ```

2. **Get users older than 30:**
   ```
   $.users[?(@.age > 30)]
   ```

3. **Get completed projects:**
   ```
   $.users[*].projects[?(@.status == 'completed')]
   ```

4. **Get first user's email:**
   ```
   $.users[0].email
   ```

5. **Get metadata version:**
   ```
   $.metadata.version
   ```

## Testing with MCP Client

You can test these queries using any MCP client by calling the `json-query` tool:

```json
{
  "method": "tools/call",
  "params": {
    "name": "json-query",
    "arguments": {
      "file_path": "./examples/sample_data.json",
      "query": "$.users[?(@.active == true)].name",
      "output_format": "json"
    }
  }
}
```

## Creating Your Own Examples

Feel free to modify `sample_data.json` or create your own JSON files to test with. The JSON MCP Server can handle files of any size and complexity.

### Tips for Large Files
- Use pagination with `page` and `page_size` parameters
- Filter data early with JSONPath queries
- Use `json-validate` to check file syntax before processing
