# Cookiecutter MCP Server

A Model Context Protocol (MCP) server that provides seamless integration with Cookiecutter templates for rapid project scaffolding. This server enables you to manage, test, and generate projects from both local and remote Cookiecutter templates through a standardized JSON-RPC 2.0 interface.

## Inspiration & Attribution

This project is built on top of the excellent [MCP Server Bash SDK](https://github.com/muthuishere/mcp-server-bash-sdk) by [@muthuishere](https://github.com/muthuishere). The core MCP protocol implementation (`mcpserver_core.sh`) and testing framework (`test_mcpserver_core.sh`) are directly from that repository, providing a solid foundation for building bash-based MCP servers.

**What's from the SDK:**
- `mcpserver_core.sh` - Complete MCP protocol and JSON-RPC 2.0 implementation
- `test_mcpserver_core.sh` - Comprehensive testing framework
- Core architecture and design patterns

**What's new in this project:**
- `cc_pythonserver.sh` - Cookiecutter-specific tool implementations
- Template management and configuration system
- Git authentication bypass solutions
- Cookiecutter integration and project generation logic

## Features

- **🚀 Template Management** - List, discover, and manage Cookiecutter templates
- **🌐 Remote & Local Support** - Work with GitHub repositories and local template directories  
- **🔐 Authentication Bypass** - Automatic handling of Git authentication issues for public repositories
- **📋 Template Validation** - Test template accessibility before project generation
- **🛠️ Flexible Configuration** - Easy template configuration through JSON files
- **📊 Comprehensive Logging** - Detailed logging and debugging capabilities
- **⚡ MCP Protocol** - Full JSON-RPC 2.0 and MCP protocol compliance

## Prerequisites

- **Bash** 4.0+ (macOS/Linux)
- **jq** - JSON processor (`brew install jq` or `apt-get install jq`)
- **cookiecutter** - Template engine (`pip install cookiecutter`)
- **Git** - For remote template access

## Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd cookiecutter-mcp-server
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x cc_pythonserver.sh mcpserver_core.sh
   ```

3. **Create logs directory:**
   ```bash
   mkdir -p logs
   ```

4. **Install dependencies:**
   ```bash
   # Install jq (if not already installed)
   brew install jq  # macOS
   # or
   sudo apt-get install jq  # Ubuntu/Debian
   
   # Install cookiecutter
   pip install cookiecutter
   ```

> **Note:** This project includes the core MCP server files from the [MCP Server Bash SDK](https://github.com/muthuishere/mcp-server-bash-sdk). No additional SDK installation is required as the necessary files are bundled with this repository.

## Configuration

### Template Configuration

Edit `assets/cc_python_config.json` to add your templates:

```json
{
  "protocolVersion": "2024-11-05",
  "serverInfo": {
    "name": "CookieCutterPythonServer",
    "version": "0.1.0"
  },
  "templates": {
    "pypackage": {
      "name": "pypackage",
      "url": "https://github.com/audreyfeldroy/cookiecutter-pypackage",
      "description": "Cookiecutter template for a Python package with best practices",
      "category": "library",
      "language": "python"
    },
    "local-template": {
      "name": "local-template", 
      "url": "/path/to/your/local/template",
      "description": "Your local cookiecutter template",
      "category": "custom",
      "language": "python"
    }
  }
}
```

### Git Configuration (Optional)

If you encounter Git authentication prompts for public repositories:

```bash
# Disable credential helper for public repos
git config --global credential.helper ""
```

## Usage

### Starting the Server

```bash
# Run the MCP server
./cc_pythonserver.sh
```

The server will listen for JSON-RPC 2.0 messages on stdin and respond on stdout.

### Available Tools

#### 1. List Templates
```bash
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "list_templates"}, "id": 1}' | ./cc_pythonserver.sh
```

#### 2. Get Template Information  
```bash
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_template_info", "arguments": {"templateName": "pypackage"}}, "id": 2}' | ./cc_pythonserver.sh
```

#### 3. Test Template Access
```bash
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "test_template_access", "arguments": {"templateName": "pypackage"}}, "id": 3}' | ./cc_pythonserver.sh
```

#### 4. Generate Project
```bash
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "generate_project", "arguments": {"templateName": "pypackage", "outputDir": "./my-new-project"}}, "id": 4}' | ./cc_pythonserver.sh
```

#### 5. Generate Project (ZIP Download)
For repositories with authentication issues:
```bash
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "generate_project_zip", "arguments": {"templateName": "pypackage", "outputDir": "./my-new-project"}}, "id": 5}' | ./cc_pythonserver.sh
```

## Template Types

### Remote Templates (GitHub)
```json
{
  "template-name": {
    "name": "template-name",
    "url": "https://github.com/user/cookiecutter-template",
    "description": "Description of the template",
    "category": "web-framework",
    "language": "python"
  }
}
```

### Local Templates
```json
{
  "local-template": {
    "name": "local-template",
    "url": "/absolute/path/to/template/directory",
    "description": "Local cookiecutter template",
    "category": "custom", 
    "language": "python"
  }
}
```

**Local template requirements:**
- Must contain a `cookiecutter.json` file at the root
- Follow standard Cookiecutter directory structure
- Use absolute paths in configuration

## Advanced Usage

### Custom Template Variables
```bash
echo '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "generate_project", "arguments": {"templateName": "pypackage", "outputDir": "./output", "templateValues": {"project_name": "my-awesome-project", "author_name": "Your Name"}}}, "id": 6}' | ./cc_pythonserver.sh
```

### Debug Mode
Enable debug logging by setting `DEBUG_MODE=1` in the script:
```bash
# Edit cc_pythonserver.sh
DEBUG_MODE=1
```

## Testing

Run the test suite to verify functionality:

```bash
./test_mcpserver_core.sh
```

This will test:
- MCP protocol compliance
- Tool function execution
- Error handling
- JSON-RPC 2.0 messaging

## Troubleshooting

### Common Issues

**Git Authentication Prompts:**
```bash
# Solution 1: Disable credential helper
git config --global credential.helper ""

# Solution 2: Use ZIP download method
# Use generate_project_zip instead of generate_project
```

**jq Parse Errors:**
- Ensure all JSON files are valid
- Check for control characters in input
- Enable debug mode to identify parsing issues

**Template Not Found:**
- Verify template name matches configuration exactly
- Check template URL accessibility
- Ensure local template paths are absolute and exist

**Permission Errors:**
```bash
# Make scripts executable
chmod +x cc_pythonserver.sh mcpserver_core.sh

# Check directory permissions
ls -la logs/
```

### Debugging

1. **Enable debug mode** by setting `DEBUG_MODE=1`
2. **Check logs** in `logs/cc_python_tools.log`
3. **Validate JSON** configuration files:
   ```bash
   jq . assets/cc_python_config.json
   jq . assets/cc_python_tools.json
   ```

## Architecture

This project builds upon the [MCP Server Bash SDK](https://github.com/muthuishere/mcp-server-bash-sdk) architecture:

```
┌─────────────────────┐
│   MCP Client        │
└─────────┬───────────┘
          │ JSON-RPC 2.0
┌─────────▼───────────┐
│  cc_pythonserver.sh │ ← Custom Cookiecutter Implementation
│  ┌─────────────────┐│
│  │ Tool Functions  ││
│  │ - list_templates││
│  │ - generate_proj ││
│  │ - test_access   ││
│  └─────────────────┘│
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│  mcpserver_core.sh  │ ← From MCP Server Bash SDK
│  ┌─────────────────┐│
│  │ JSON-RPC Handler││
│  │ Protocol Logic  ││
│  │ Error Handling  ││
│  └─────────────────┘│
└─────────────────────┘
```

**SDK Components (from [mcp-server-bash-sdk](https://github.com/muthuishere/mcp-server-bash-sdk)):**
- JSON-RPC 2.0 protocol handling
- MCP specification compliance  
- Request/response processing
- Error handling and logging
- Testing framework

**Custom Implementation:**
- Cookiecutter template management
- Git authentication bypass
- Project generation workflows
- Template validation and testing

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Run the test suite (`./test_mcpserver_core.sh`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **[MCP Server Bash SDK](https://github.com/muthuishere/mcp-server-bash-sdk)** by [@muthuishere](https://github.com/muthuishere) - The foundational SDK that makes this project possible, providing the complete MCP protocol implementation and testing framework
- [Cookiecutter](https://github.com/cookiecutter/cookiecutter) - The templating engine that powers this server
- [Model Context Protocol](https://modelcontextprotocol.io/) - The protocol specification
- [JSON-RPC 2.0](https://www.jsonrpc.org/specification) - The underlying RPC protocol

## Support

If you encounter issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the logs in `logs/cc_python_tools.log`
3. Open an issue on GitHub with:
   - Your system information (OS, Bash version, etc.)
   - The command that failed
   - Relevant log entries
   - Steps to reproduce

