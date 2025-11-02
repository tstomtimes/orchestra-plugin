#!/usr/bin/env bash
# Orchestra Plugin Installation Script
# ⚠️  DEPRECATED: This script is deprecated. Use setup.sh instead.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        ⚠️  DEPRECATED: Use setup.sh instead              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}"
cat << "EOF"

This script is deprecated because MCP servers are required for Orchestra Plugin.

Please use the following installation method instead:

1. Clone the Orchestra repository:
   git clone https://github.com/tstomtimes/orchestra.git
   cd orchestra

2. Run the setup script:
   ./setup.sh

3. In Claude Code, add the plugin:
   /plugin marketplace add /path/to/orchestra
   /plugin install orchestra

4. Restart Claude Code

For more information, see: https://github.com/tstomtimes/orchestra

EOF
echo -e "${NC}"

read -p "$(echo -e ${YELLOW}Do you want to continue with this deprecated script anyway? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installation cancelled. Please use setup.sh instead.${NC}"
    exit 0
fi

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        🎼 Orchestra Plugin Installer (Deprecated)         ║
║        AI-Powered Development Workflow Automation         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get current project directory
PROJECT_DIR="$(pwd)"
echo -e "${BLUE}📂 Installing Orchestra Plugin to: ${PROJECT_DIR}${NC}\n"

# Check if Claude Code is installed
echo -e "${YELLOW}[1/4] Checking Claude Code installation...${NC}"
if [ ! -d "$HOME/.claude" ]; then
    echo -e "${RED}❌ Claude Code not found. Please install Claude Code first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Claude Code is installed${NC}\n"

# Create .claude directory if it doesn't exist
echo -e "${YELLOW}[2/4] Setting up project configuration...${NC}"
mkdir -p "$PROJECT_DIR/.claude"
echo -e "${GREEN}✓ Created .claude directory${NC}\n"

# Create or update settings.json
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
echo -e "${YELLOW}[3/4] Configuring plugin settings...${NC}"

if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠️  .claude/settings.json already exists${NC}"
    echo -e "${YELLOW}Would you like to:${NC}"
    echo -e "  1) Merge Orchestra Plugin settings (recommended)"
    echo -e "  2) Skip settings configuration"
    read -p "Choice [1/2]: " choice

    if [ "$choice" != "1" ]; then
        echo -e "${YELLOW}⏭️  Skipped settings configuration${NC}\n"
    else
        echo -e "${YELLOW}📝 Please manually add Orchestra Plugin settings to your settings.json${NC}"
        echo -e "${YELLOW}See: https://github.com/tstomtimes/orchestra#configuration${NC}\n"
    fi
else
    cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "enabledPlugins": {
    "orchestra@orchestra-marketplace": true
  },
  "extraKnownMarketplaces": {
    "orchestra-marketplace": {
      "source": {
        "source": "github",
        "repo": "tstomtimes/orchestra"
      }
    }
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review the user's request and tool use. Auto-approve safe operations, but block dangerous commands like 'rm -rf /', 'git push --force', etc."
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(curl:*)",
      "Bash(cat:*)",
      "Bash(ls:*)",
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(echo:*)"
    ],
    "deny": [],
    "ask": []
  }
}
SETTINGS_EOF
    echo -e "${GREEN}✓ Created .claude/settings.json with Orchestra Plugin configuration${NC}\n"
fi

# Instructions for Claude Code
echo -e "${YELLOW}[4/4] Next steps in Claude Code...${NC}"
echo -e "${BLUE}"
cat << 'EOF'

Please run the following commands in Claude Code:

1. Add the Orchestra Plugin marketplace:
   /plugin marketplace add tstomtimes/orchestra

2. Install the plugin:
   /plugin install orchestra

3. Restart Claude Code to activate all features

EOF
echo -e "${NC}"

echo -e "${GREEN}✅ Installation preparation complete!${NC}"
echo -e "${BLUE}"
cat << 'EOF'

📚 Available Features:
   • /browser  - Start/restart Browser MCP server
   • /screenshot - Capture web screenshots
   • 12 specialized AI agents (Alex, Riley, Kai, Skye, etc.)
   • Automated quality gates and hooks
   • Multi-agent orchestration

📖 Documentation: https://github.com/tstomtimes/orchestra
🐛 Issues: https://github.com/tstomtimes/orchestra/issues

EOF
echo -e "${NC}"
