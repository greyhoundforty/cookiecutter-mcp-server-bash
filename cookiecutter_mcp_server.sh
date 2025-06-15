#!/bin/bash
# Cookiecutter Python templates business logic implementation

# Debug mode - set to 1 to enable debugging
DEBUG_MODE=1

debug_log() {
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Override configuration paths BEFORE sourcing the core
MCP_CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/assets/cookiecutter_mcp_config.json"
MCP_TOOLS_LIST_FILE="$(dirname "${BASH_SOURCE[0]}")/assets/cookiecutter_mcp_tools.json"
MCP_LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/logs/cookiecutter_mcp.log"

debug_log "Config file: $MCP_CONFIG_FILE"
debug_log "Tools file: $MCP_TOOLS_LIST_FILE"
debug_log "Log file: $MCP_LOG_FILE"

# MCP Server Tool Function Guidelines:
# 1. Name all tool functions with prefix "tool_" followed by the same name defined in tools_list.json
# 2. Function should accept a single parameter "$1" containing JSON arguments
# 3. For successful operations: Echo the expected result and return 0
# 4. For errors: Echo an error message and return 1
# 5. All tool functions are automatically exposed to the MCP server based on tools_list.json

# Source the core MCP server implementation
source "$(dirname "${BASH_SOURCE[0]}")/mcpserver_core.sh"

# Helper function to get templates from config
get_templates_from_config() {
    debug_log "get_templates_from_config called"
    debug_log "Config file path: $MCP_CONFIG_FILE"
    
    if [[ -f "$MCP_CONFIG_FILE" ]]; then
        debug_log "Config file exists, reading templates"
        local result=$(jq -c '.templates' "$MCP_CONFIG_FILE" 2>&1)
        local exit_code=$?
        debug_log "jq exit code: $exit_code"
        debug_log "jq result: $result"
        
        if [[ $exit_code -eq 0 ]]; then
            echo "$result"
        else
            debug_log "jq failed to parse config file: $result"
            echo "{}"
        fi
    else
        debug_log "Config file not found: $MCP_CONFIG_FILE"
        echo "{}"
    fi
}

# Tool: List available cookiecutter templates
# No parameters required
# Success: Echo JSON result and return 0
tool_list_templates() {
    debug_log "tool_list_templates called"
    local templates=$(get_templates_from_config)
    
    debug_log "Templates from config: $templates"
    
    if [[ "$templates" == "null" || "$templates" == "{}" ]]; then
        echo "No templates configured"
        return 1
    fi
    
    # Convert templates object to array format for easier consumption
    local templates_array=$(echo "$templates" | jq -c '[to_entries[] | {name: .key, url: .value.url, description: .value.description, category: .value.category, language: .value.language}]' 2>&1)
    local jq_exit_code=$?
    
    debug_log "jq conversion exit code: $jq_exit_code"
    debug_log "Templates array: $templates_array"
    
    if [[ $jq_exit_code -ne 0 ]]; then
        echo "Failed to process templates: $templates_array"
        return 1
    fi
    
    echo "$templates_array"
    return 0
}

# Tool: Get information about a specific template
# Parameters: Takes a JSON object with templateName
# Success: Echo JSON result and return 0
# Error: Echo error message and return 1
tool_get_template_info() {
    local args="$1"
    
    debug_log "tool_get_template_info called with args: $args"
    
    # Clean the input args to remove any control characters
    local clean_args=$(echo "$args" | tr -d '\000-\037' | tr -d '\177-\377')
    debug_log "Cleaned args: $clean_args"
    
    # Validate JSON before parsing
    if ! echo "$clean_args" | jq . >/dev/null 2>&1; then
        echo "Invalid JSON input: $clean_args"
        return 1
    fi
    
    local template_name=$(echo "$clean_args" | jq -r '.templateName // empty')
    debug_log "Template name: $template_name"
    
    # Parameter validation
    if [[ -z "$template_name" ]]; then
        echo "Missing required parameter: templateName"
        return 1
    fi
    
    local templates=$(get_templates_from_config)
    local template_info=$(echo "$templates" | jq -c --arg name "$template_name" '.[$name]' 2>&1)
    local jq_exit_code=$?
    
    debug_log "Template info jq exit code: $jq_exit_code"
    debug_log "Template info: $template_info"
    
    if [[ $jq_exit_code -ne 0 ]]; then
        echo "Failed to get template info: $template_info"
        return 1
    fi
    
    if [[ "$template_info" == "null" ]]; then
        echo "Template not found: $template_name"
        return 1
    fi
    
    echo "$template_info"
    return 0
}

# Tool: Test template access
# Parameters: Takes a JSON object with templateName
# Success: Echo test result and return 0
# Error: Echo error message and return 1
tool_test_template_access() {
    local args="$1"
    
    local template_name=$(echo "$args" | jq -r '.templateName')
    
    # Parameter validation
    if [[ -z "$template_name" ]]; then
        echo "Missing required parameter: templateName"
        return 1
    fi
    
    # Get template URL from config
    local templates=$(get_templates_from_config)
    local template_url=$(echo "$templates" | jq -r --arg name "$template_name" '.[$name].url')
    
    if [[ "$template_url" == "null" ]]; then
        echo "Template not found: $template_name"
        return 1
    fi
    
    # Test URL accessibility
    echo "Testing template: $template_name"
    echo "URL: $template_url"
    
    # Use curl to test if the URL is accessible
    if command -v curl &> /dev/null; then
        local http_status=$(curl -s -o /dev/null -w "%{http_code}" "$template_url")
        if [[ "$http_status" == "200" ]]; then
            echo "✓ URL is accessible (HTTP $http_status)"
        else
            echo "✗ URL returned HTTP $http_status"
        fi
    fi
    
    # Test git access
    local git_test=$(git ls-remote "$template_url" 2>&1)
    local git_exit_code=$?
    
    if [[ $git_exit_code -eq 0 ]]; then
        echo "✓ Git repository is accessible"
        # Show available branches/tags
        local branches=$(echo "$git_test" | head -3 | awk '{print $2}' | sed 's|refs/heads/||' | sed 's|refs/tags/||')
        echo "Available refs: $branches"
    else
        echo "✗ Git access failed: $git_test"
        return 1
    fi
    
    echo "Template access test completed successfully"
    return 0
}

# Tool: Generate a project using ZIP download (bypasses git authentication)
# Parameters: Takes a JSON object with templateName, outputDir (optional)
# Success: Echo result and return 0
# Error: Echo error message and return 1
tool_generate_project_zip() {
    local args="$1"
    
    local template_name=$(echo "$args" | jq -r '.templateName')
    local output_dir=$(echo "$args" | jq -r '.outputDir // "."')
    
    # Parameter validation
    if [[ -z "$template_name" ]]; then
        echo "Missing required parameter: templateName"
        return 1
    fi
    
    # Check if cookiecutter is installed
    if ! command -v cookiecutter &> /dev/null; then
        echo "cookiecutter is not installed. Please install it with: pip install cookiecutter"
        return 1
    fi
    
    # Get template URL from config
    local templates=$(get_templates_from_config)
    local template_url=$(echo "$templates" | jq -r --arg name "$template_name" '.[$name].url')
    
    if [[ "$template_url" == "null" ]]; then
        echo "Template not found: $template_name"
        return 1
    fi
    
    # Convert GitHub URL to ZIP download URL
    local zip_url=""
    if [[ "$template_url" =~ ^https://github.com/([^/]+)/([^/]+)/?.*$ ]]; then
        local user="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]}"
        # Remove .git suffix if present
        repo="${repo%.git}"
        zip_url="https://github.com/$user/$repo/archive/refs/heads/main.zip"
        debug_log "Converted to ZIP URL: $zip_url"
    else
        echo "Only GitHub repositories are supported for ZIP download method"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Try the ZIP download approach
    debug_log "Using ZIP download: cookiecutter --no-input --output-dir $output_dir $zip_url"
    
    # Execute with simplified approach
    local result=$(cookiecutter --no-input --output-dir "$output_dir" "$zip_url" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "ZIP download failed: $result"
        return 1
    fi
    
    echo "Project '$template_name' generated successfully using ZIP download in '$output_dir'"
    return 0
}

# Tool: Generate a project from a cookiecutter template
# Parameters: Takes a JSON object with templateName, outputDir (optional), templateValues (optional), cacheAction (optional)
# Success: Echo JSON result and return 0
# Error: Echo error message and return 1
tool_generate_project() {
    local args="$1"
    
    debug_log "tool_generate_project called with args: $args"
    
    # Clean the input args to remove any control characters
    local clean_args=$(echo "$args" | tr -d '\000-\037' | tr -d '\177-\377')
    debug_log "Cleaned args: $clean_args"
    
    # Validate JSON before parsing
    if ! echo "$clean_args" | jq . >/dev/null 2>&1; then
        echo "Invalid JSON input: $clean_args"
        return 1
    fi
    
    local template_name=$(echo "$clean_args" | jq -r '.templateName // empty')
    local output_dir=$(echo "$clean_args" | jq -r '.outputDir // "."')
    local template_values=$(echo "$clean_args" | jq -r '.templateValues // {}')
    local cache_action=$(echo "$clean_args" | jq -r '.cacheAction // "use"')  # use, clear, or force
    local overwrite_output=$(echo "$clean_args" | jq -r '.overwriteOutput // false')
    
    debug_log "Parsed - template_name: $template_name"
    debug_log "Parsed - output_dir: $output_dir"
    debug_log "Parsed - template_values: $template_values"
    debug_log "Parsed - cache_action: $cache_action"
    debug_log "Parsed - overwrite_output: $overwrite_output"
    
    # Parameter validation
    if [[ -z "$template_name" ]]; then
        echo "Missing required parameter: templateName"
        return 1
    fi
    
    # Check if cookiecutter is installed
    if ! command -v cookiecutter &> /dev/null; then
        echo "cookiecutter is not installed. Please install it with: pip install cookiecutter"
        return 1
    fi
    
    # Get template URL from config
    debug_log "Reading templates from config file"
    local templates=$(get_templates_from_config)
    debug_log "Templates from config: $templates"
    
    if [[ -z "$templates" || "$templates" == "null" || "$templates" == "{}" ]]; then
        echo "No templates found in config"
        return 1
    fi
    
    local template_url=$(echo "$templates" | jq -r --arg name "$template_name" '.[$name].url // empty')
    debug_log "Template URL for $template_name: $template_url"
    
    if [[ -z "$template_url" || "$template_url" == "null" ]]; then
        echo "Template not found: $template_name"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    debug_log "Created/verified output directory: $output_dir"
    
    # Check if template_url is a local path or remote URL
    local is_local=false
    if [[ "$template_url" =~ ^(/|\./) ]] || [[ ! "$template_url" =~ ^https?:// ]]; then
        is_local=true
        debug_log "Using local template: $template_url"
        
        # Verify local path exists
        if [[ ! -d "$template_url" ]]; then
            echo "Local template directory not found: $template_url"
            return 1
        fi
        
        # Check if it's a valid cookiecutter template
        if [[ ! -f "$template_url/cookiecutter.json" ]]; then
            echo "Invalid cookiecutter template: missing cookiecutter.json in $template_url"
            return 1
        fi
    else
        debug_log "Using remote template: $template_url"
        
        # Handle cache management for remote templates
        if [[ "$cache_action" == "clear" ]]; then
            debug_log "Clearing cookiecutter cache"
            # Get cookiecutter cache directory
            local cache_dir="$HOME/.cookiecutters"
            if [[ -d "$cache_dir" ]]; then
                # Extract repo name from URL for cache cleanup
                local repo_name=$(basename "$template_url" .git)
                local cached_template="$cache_dir/$repo_name"
                if [[ -d "$cached_template" ]]; then
                    debug_log "Removing cached template: $cached_template"
                    rm -rf "$cached_template"
                fi
            fi
        elif [[ "$cache_action" == "force" ]]; then
            debug_log "Using force mode - will overwrite cache"
        fi
    fi
    
    # Build cookiecutter command
    local cookiecutter_cmd="cookiecutter --output-dir \"$output_dir\" --no-input"
    
    # Add overwrite flag if requested
    if [[ "$overwrite_output" == "true" ]]; then
        cookiecutter_cmd="$cookiecutter_cmd --overwrite-if-exists"
        debug_log "Added --overwrite-if-exists flag"
    fi
    
    # Add template URL
    cookiecutter_cmd="$cookiecutter_cmd \"$template_url\""
    
    # Process template values for --no-input mode
    if [[ "$template_values" != "{}" && "$template_values" != "null" ]]; then
        debug_log "Processing template values: $template_values"
        
        # Convert JSON object to key=value pairs for cookiecutter --no-input
        local template_args=""
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                template_args="$template_args $line"
            fi
        done < <(echo "$template_values" | jq -r 'to_entries[] | "\(.key)=\"\(.value)\""' 2>/dev/null)
        
        debug_log "Template args: $template_args"
        
        if [[ -n "$template_args" ]]; then
            cookiecutter_cmd="$cookiecutter_cmd$template_args"
        else
            debug_log "Failed to parse template values, using defaults"
        fi
    else
        debug_log "No template values provided, using defaults"
    fi
    
    debug_log "Final cookiecutter command: $cookiecutter_cmd"
    
    # Execute cookiecutter command with proper error handling
    if [[ "$is_local" == true ]]; then
        debug_log "Executing local template generation"
        
        local result=$(eval "$cookiecutter_cmd" 2>&1)
        local exit_code=$?
        
        debug_log "Local cookiecutter exit code: $exit_code"
        debug_log "Local cookiecutter result: $result"
        
        if [[ $exit_code -ne 0 ]]; then
            # Clean the result output to avoid JSON parsing issues
            local clean_result=$(echo "$result" | tr -d '\000-\037' | tr -d '\177-\377' | head -c 500)
            echo "Local template generation failed: $clean_result"
            return 1
        fi
        
        echo "Local template '$template_name' generated successfully in '$output_dir'"
        return 0
    else
        # Handle remote templates with full error handling
        debug_log "Executing remote template generation"
        
        # Create temporary files for stdout and stderr
        local stdout_file=$(mktemp)
        local stderr_file=$(mktemp)
        
        # Set environment variables to completely disable git authentication prompts
        export GIT_TERMINAL_PROMPT=0
        export GIT_ASKPASS=/bin/false
        export COOKIECUTTER_NO_INPUT=1
        
        # Add force flag for cache if requested
        if [[ "$cache_action" == "force" ]]; then
            # For force mode, we'll use a different approach
            # Set cookiecutter to always use latest version
            cookiecutter_cmd=$(echo "$cookiecutter_cmd" | sed 's/--no-input/--no-input --checkout HEAD/')
            debug_log "Modified command for force mode: $cookiecutter_cmd"
        fi
        
        # Run cookiecutter with timeout to prevent hanging
        debug_log "About to execute: $cookiecutter_cmd"
        timeout 60 bash -c "$cookiecutter_cmd" >"$stdout_file" 2>"$stderr_file"
        local exit_code=$?
        
        debug_log "Remote cookiecutter exit code: $exit_code"
        
        # Reset environment variables
        unset GIT_TERMINAL_PROMPT
        unset GIT_ASKPASS
        unset COOKIECUTTER_NO_INPUT
        
        # Read output files and clean them (remove control characters)
        local stdout_content=""
        local stderr_content=""
        if [[ -f "$stdout_file" ]]; then
            stdout_content=$(cat "$stdout_file" 2>/dev/null | tr -d '\000-\037' | tr -d '\177-\377' | head -c 1000)
        fi
        if [[ -f "$stderr_file" ]]; then
            stderr_content=$(cat "$stderr_file" 2>/dev/null | tr -d '\000-\037' | tr -d '\177-\377' | head -c 1000)
        fi
        
        debug_log "stdout_content: $stdout_content"
        debug_log "stderr_content: $stderr_content"
        
        # Clean up temporary files
        rm -f "$stdout_file" "$stderr_file"
        
        # Check if the error is related to cache confirmation
        if [[ $exit_code -ne 0 && "$stderr_content" =~ (already|exists|overwrite|delete) ]]; then
            debug_log "Detected cache/overwrite issue, suggesting solutions"
            # Properly escape the error message for JSON
            local clean_error=$(echo "$stderr_content" | tr -cd '[:print:]' | head -c 200)
            echo "Template generation failed due to cache/overwrite issue. Try one of these solutions:
1. Use cacheAction: 'clear' to remove cached template
2. Use cacheAction: 'force' to force overwrite
3. Use overwriteOutput: true to overwrite existing output directory
Error details: $clean_error"
            return 1
        elif [[ $exit_code -ne 0 ]]; then
            # Clean all error messages to remove control characters
            local clean_stderr=$(echo "$stderr_content" | tr -cd '[:print:]' | head -c 200)
            local clean_stdout=$(echo "$stdout_content" | tr -cd '[:print:]' | head -c 200)
            
            local error_msg="Remote template generation failed (exit code: $exit_code)"
            if [[ -n "$clean_stderr" ]]; then
                error_msg="$error_msg. Error: $clean_stderr"
            fi
            if [[ -n "$clean_stdout" ]]; then
                error_msg="$error_msg. Output: $clean_stdout"
            fi
            debug_log "Error message: $error_msg"
            echo "$error_msg"
            return 1
        fi
        
        echo "Remote template '$template_name' generated successfully in '$output_dir'"
        return 0
    fi
}

# Start the MCP server
run_mcp_server "$@"