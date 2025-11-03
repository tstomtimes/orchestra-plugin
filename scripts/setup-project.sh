#!/usr/bin/env bash
# Setup Orchestra Plugin for a project
# Usage: ./scripts/setup-project.sh /path/to/your/project

set -euo pipefail

# Get Orchestra root directory (parent of scripts directory)
ORCHESTRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get target project directory
if [ $# -eq 0 ]; then
  echo "Usage: $0 <project-directory>"
  echo "Example: $0 /path/to/your/project"
  exit 1
fi

PROJECT_DIR="$1"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: Project directory does not exist: $PROJECT_DIR"
  exit 1
fi

echo "Setting up Orchestra Plugin for: $PROJECT_DIR"
echo "Orchestra root: $ORCHESTRA_ROOT"

# Create .claude directory if it doesn't exist
mkdir -p "$PROJECT_DIR/.claude"

# Check if settings.json exists
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
  echo "⚠️  Warning: $SETTINGS_FILE already exists"
  echo "   The script will add Orchestra hooks to the existing file."
  echo "   Creating backup at $SETTINGS_FILE.backup"
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

  # Use jq to add hooks to existing settings
  TMP_FILE=$(mktemp)
  jq --arg orchestra_root "$ORCHESTRA_ROOT" '
    .enabledPlugins.orchestra = true |
    .hooks.SessionStart = [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": ("bash " + $orchestra_root + "/hooks/session-start.sh"),
            "description": "Welcome message for Orchestra Plugin"
          }
        ]
      }
    ]
  ' "$SETTINGS_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$SETTINGS_FILE"
else
  # Create new settings file
  cat > "$SETTINGS_FILE" <<EOF
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json",
  "enabledPlugins": {
    "orchestra": true
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash $ORCHESTRA_ROOT/hooks/session-start.sh",
            "description": "Welcome message for Orchestra Plugin"
          }
        ]
      }
    ]
  }
}
EOF
fi

echo "✅ Orchestra Plugin setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code"
echo "2. Open your project: $PROJECT_DIR"
echo "3. The Orchestra welcome message will appear on first prompt"
echo ""
echo "To verify setup:"
echo "  cat $SETTINGS_FILE"
