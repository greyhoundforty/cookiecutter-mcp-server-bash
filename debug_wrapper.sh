#!/bin/bash

# debug_wrapper.sh - Wrapper to debug MCP server calls

DEBUG_LOG="/tmp/mcp_debug.log"

echo "=== DEBUG SESSION START: $(date) ===" >> $DEBUG_LOG

# Capture the input JSON
INPUT=$(cat)
echo "INPUT JSON: $INPUT" >> $DEBUG_LOG

# Pass it to the MCP server and capture both stdout and stderr
echo "$INPUT" | ./cookiecutter_mcp_server.sh 2>> $DEBUG_LOG

echo "=== DEBUG SESSION END ===" >> $DEBUG_LOG
