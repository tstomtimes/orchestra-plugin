#!/usr/bin/env bash
# Orchestra Plugin Setup Script
# Configures Claude Code settings to use the Orchestra plugin
# Usage: bash setup-plugin.sh <target-project-path>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROJECT="${1:-.}"

# Resolve to absolute path
TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"

echo "🎭 Orchestra Plugin Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Orchestra Root: $SCRIPT_DIR"
echo "Target Project: $TARGET_PROJECT"
echo ""

# Create .claude directory if it doesn't exist
mkdir -p "$TARGET_PROJECT/.claude/hooks"

# Create symlink to Orchestra's hook-loader
ln -sf "$SCRIPT_DIR/.claude/hooks/hook-loader.sh" "$TARGET_PROJECT/.claude/hooks/hook-loader.sh"
echo "✓ Created hook-loader.sh symlink"

# Generate settings.json with proper paths
SETTINGS_FILE="$TARGET_PROJECT/.claude/settings.json"

cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh agent-routing-reminder",
            "description": "Agent Auto-Routing: Analyzes prompts and suggests appropriate specialist agents"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh before_task",
            "description": "Task Clarity Reminder: Suggests best practices for well-defined tasks"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh user-prompt-submit",
            "description": "Safety Guard: Blocks dangerous operations (rm -rf, system files, etc.)"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh pre-tool-use-compliance-checker",
            "description": "Routing Compliance: Verifies Task tool is called first when agent routing is required"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh workflow-dispatcher",
            "description": "Workflow Quality Gates: Routes PR/merge/deploy commands to appropriate validation hooks"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh workflow-post-dispatcher",
            "description": "Post-Workflow Validation: Runs smoke tests and validation after deployments"
          }
        ]
      },
      {
        "matcher": "TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh post_code_write",
            "description": "Progress Tracker Integration: Updates progress tracking and displays progress in chat"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/hook-loader.sh session-start",
            "description": "Welcome message for Orchestra Plugin"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF

echo "✓ Created .claude/settings.json"

# Create or update .claude.json to export ORCHESTRA_ROOT for cross-project usage
CLAUDE_JSON="$TARGET_PROJECT/.claude.json"

if [ ! -f "$CLAUDE_JSON" ]; then
  cat > "$CLAUDE_JSON" << CLAUDE_JSON_EOF
{
  "env": {
    "ORCHESTRA_ROOT": "$SCRIPT_DIR"
  }
}
CLAUDE_JSON_EOF
  echo "✓ Created .claude.json with ORCHESTRA_ROOT environment variable"
else
  echo "ℹ  .claude.json already exists (not modified)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: cd $TARGET_PROJECT && claude"
echo "2. Verify Orchestra plugin loads with the welcome message"
echo "3. Check that agents are available for coordination"
echo ""
echo "To use Orchestra from other projects:"
echo "  export ORCHESTRA_ROOT=$SCRIPT_DIR"
echo "  cd /path/to/other-project"
echo "  claude"
echo ""
