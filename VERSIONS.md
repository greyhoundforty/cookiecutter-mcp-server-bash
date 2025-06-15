## Version 0.2.0 - 2025-06-15

### 🐛 Bug Fixes

**Fixed templateValues processing in generate_project tool**
- **Issue**: When `templateValues` were provided in the `generate_project` request, cookiecutter would fail with "EXTRA_CONTEXT should contain items of the form key=value" error, resulting in empty output directories despite success messages.
- **Root Cause**: Incorrect argument order in cookiecutter command construction. Template path was being placed after the extra context arguments instead of before them.
- **Solution**: 
  - Fixed command construction to place template path immediately after `--no-input` flag
  - Template values now correctly follow the template path as individual `key="value"` arguments
  - Improved JSON parsing for template values using `jq` to convert to proper format
- **Impact**: `templateValues` parameter now works correctly for both local and remote templates

**Before (broken):**
```bash
cookiecutter --output-dir "/path" --no-input project_name="test" "./template"
```

**After (fixed):**
```bash
cookiecutter --output-dir "/path" --no-input "./template" project_name="test"
```

### 🔧 Improvements

**Enhanced debugging capabilities**
- Set `DEBUG_MODE=1` by default for easier troubleshooting
- Added comprehensive debug logging throughout `generate_project` function
- Debug output now shows:
  - Parsed template values
  - Final cookiecutter command structure
  - Command execution results and exit codes
  - Step-by-step processing flow

**Improved error handling**
- Better validation of JSON input before processing
- More descriptive error messages for template value parsing failures
- Graceful handling of malformed template values

### 📚 Documentation

**Updated README.md**
- Added examples for using `templateValues` parameter
- Updated code examples to match actual implementation
- Corrected file paths and command structures
- Added new section on Template Values usage

**Added TROUBLESHOOTING.md**
- Comprehensive troubleshooting guide covering common issues
- Step-by-step debug procedures
- Solutions for template values, configuration, and dependency issues
- Debug mode usage instructions

### 🧪 Testing

**Verified fixes with multiple scenarios:**
- Local templates with custom template values ✅
- Local templates with default values ✅  
- Remote templates (when accessible) ✅
- Malformed JSON input handling ✅
- Missing template scenarios ✅

**Test commands validated:**
```bash
# Working with template values
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "generate_project", "arguments": {"templateName": "simple-test", "outputDir": "/tmp/test", "templateValues": {"project_name": "test-project", "author_name": "Ryan"}}}, "id": 1}' | ./cookiecutter_mcp_server.sh

# Working without template values  
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "generate_project", "arguments": {"templateName": "simple-test", "outputDir": "/tmp/test"}}, "id": 1}' | ./cookiecutter_mcp_server.sh
```
