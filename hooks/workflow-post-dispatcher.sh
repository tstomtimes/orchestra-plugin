#!/usr/bin/env bash
# Workflow Post-Execution Dispatcher Hook
# Routes completed tool executions to appropriate post-workflow hooks

set -euo pipefail

# Read JSON input from stdin
INPUT_JSON=$(cat)

# Extract tool details from JSON
TOOL_NAME=$(echo "$INPUT_JSON" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
TOOL_PARAMS=$(echo "$INPUT_JSON" | jq -c '.tool_input // {}' 2>/dev/null || echo "{}")
TOOL_OUTPUT=$(echo "$INPUT_JSON" | jq -r '.tool_output // empty' 2>/dev/null || echo "")

# Only process Bash tool executions
if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

# Extract the command from tool parameters
COMMAND=$(echo "$TOOL_PARAMS" | jq -r '.command // empty' 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
    exit 0
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Convert INPUT_JSON to environment variables for legacy hooks
export TOOL_NAME
export TOOL_PARAMS
export COMMAND
export TOOL_OUTPUT

# Route to appropriate post-workflow hook based on command pattern
if echo "$COMMAND" | grep -qE "(deploy|vercel|netlify|git push.*production|git push.*main)"; then
    echo ""
    echo "🎯 Post-Deploy Validation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/after_deploy.sh" || {
        echo "⚠️  Post-deploy checks failed. Consider rollback."
        # Don't exit 1 here - deployment already happened
        exit 0
    }
    echo "✅ Post-deploy validation passed"
    echo ""
fi

exit 0
