#!/usr/bin/env bash
# hooks/before_task.sh
# Non-interactive task clarity reminder
set -euo pipefail

# Read JSON input from stdin
INPUT_JSON=$(cat)

# Extract prompt from JSON
USER_PROMPT=$(echo "$INPUT_JSON" | jq -r '.prompt // empty' 2>/dev/null || echo "")

# Skip if no prompt (shouldn't happen in UserPromptSubmit)
if [ -z "$USER_PROMPT" ]; then
  exit 0
fi

# Only show reminder for substantial requests (skip simple queries)
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')
if echo "$PROMPT_LOWER" | grep -qE "(what|how|why|show|explain|tell).*\?"; then
  # This looks like a question, not a task
  exit 0
fi

echo ""
echo "💡 Task Clarity Best Practice"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Before starting implementation, ensure your task has:"
echo "   ✓ Clear acceptance criteria"
echo "   ✓ Defined scope and boundaries"
echo "   ✓ Success metrics or test cases"
echo ""

# Check for ambiguous language in the prompt
if echo "$PROMPT_LOWER" | grep -qE "(fast|faster|slow|slower|easy|simple|clean|better|improve|optimize)"; then
  echo "⚠️  Detected subjective language: Consider clarifying with Riley agent"
  echo ""
fi

# Check if task file exists for formal task tracking
TASK_FILE=".claude/current-task.md"
if [ -f "$TASK_FILE" ]; then
  echo "📋 Task definition found: $TASK_FILE"

  TASK_CONTENT=$(cat "$TASK_FILE")

  # Quick validation
  has_issues=false

  if ! echo "$TASK_CONTENT" | grep -qiE "(acceptance criteria|AC:|done when|success criteria)"; then
    echo "   ⚠️  Missing acceptance criteria"
    has_issues=true
  fi

  if ! echo "$TASK_CONTENT" | grep -qiE "(scope|in scope|out of scope|boundaries)"; then
    echo "   ⚠️  Missing scope definition"
    has_issues=true
  fi

  if ! echo "$TASK_CONTENT" | grep -qiE "(test|testing|verify|validation)"; then
    echo "   ⚠️  Missing test plan"
    has_issues=true
  fi

  if [ "$has_issues" = false ]; then
    echo "   ✅ Task definition looks good"
  fi
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Always approve - this is just informational
exit 0
