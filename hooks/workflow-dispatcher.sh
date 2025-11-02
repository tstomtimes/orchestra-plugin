#!/usr/bin/env bash
# Workflow Dispatcher Hook
# Routes tool executions to appropriate workflow hooks based on command patterns

set -euo pipefail

# Read JSON input from stdin
INPUT_JSON=$(cat)

# Extract tool details from JSON
TOOL_NAME=$(echo "$INPUT_JSON" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
TOOL_PARAMS=$(echo "$INPUT_JSON" | jq -c '.tool_input // {}' 2>/dev/null || echo "{}")

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

# Route to appropriate workflow hook based on command pattern
if echo "$COMMAND" | grep -qE "(gh pr create|hub pull-request)"; then
    echo "📋 Pre-PR Quality Checks"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/before_pr.sh" || exit 1
    echo "✅ Pre-PR checks passed"
    echo ""

elif echo "$COMMAND" | grep -qE "git merge"; then
    echo "🔀 Pre-Merge Quality Checks"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/before_merge.sh" || exit 1
    echo "✅ Pre-merge checks passed"
    echo ""

elif echo "$COMMAND" | grep -qE "(deploy|vercel|netlify|git push.*production|git push.*main)"; then
    echo "🚀 Pre-Deploy Validation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/before_deploy.sh" || exit 1
    echo "✅ Pre-deploy checks passed"
    echo ""
fi

exit 0
