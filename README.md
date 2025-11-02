# Orchestra Plugin for Claude Code

A multi-agent orchestration layer that turns Claude Code into a semi-autonomous "orchestra" with specialized agents, skills, and quality gates.

## Features

- **Multi-Agent System**: Coordinated team of specialized agents (Alex as PM, Eden for QA, Iris for Security, Theo for monitoring, Mina for frontend)
- **Skill-Based Architecture**: Capability-first, stack-agnostic skills for various development tasks
- **Quality Gates**: Automated pre-merge and pre-deploy checks via hooks
- **MCP Integration**: Seamless integration with external services (GitHub, Vercel, Shopify, etc.)
- **Evidence-Based Development**: Automatic generation of changelogs, test plans, and documentation

## Installation

**Quick Setup (Recommended):**
```bash
git clone https://github.com/tstomtimes/orchestra-plugin.git
cd orchestra-plugin
./setup.sh
```

The setup script will:
- ✅ Check prerequisites (Node.js 18+, Python 3.8+)
- ✅ Install all MCP server dependencies (Node.js, Playwright, Python packages)
- ✅ Set up Python virtual environment
- ✅ Create `.env` file from template
- ✅ Configure executable permissions
- ✅ Create artifacts directories
- ✅ Optionally start the Browser MCP server

**Manual Setup:**
1. Clone this repository:
   ```bash
   git clone https://github.com/tstomtimes/orchestra-plugin.git
   cd orchestra-plugin
   ```

2. Install dependencies:
   ```bash
   cd orchestra-plugin/mcp-servers
   npm install
   npx playwright install chromium
   python3 -m venv venv
   source venv/bin/activate
   pip install elevenlabs requests python-dotenv
   ```

3. Configure environment variables (see [.env.example](.env.example)):
   ```bash
   cp .env.example .env
   # Edit .env with your API tokens
   ```

4. In Claude Code, add the plugin and point to `.claude-plugin/manifest.json`.

## Required Environment Variables

Configure the following tokens based on the services you use:
- `GITHUB_TOKEN` - For GitHub integration (repo access, PR management)
- `VERCEL_TOKEN` - For deployment management (optional)
- `SHOPIFY_ADMIN_TOKEN` - For Shopify theme development (optional)
- `SANITY_TOKEN` - For Sanity CMS integration (optional)
- `SUPABASE_SERVICE_ROLE` - For Supabase database access (optional)
- `SLACK_BOT_TOKEN` - For Slack notifications (optional)
- `ELEVENLABS_API_KEY` - For agent voice notifications (optional)
- `BROWSER_ALLOWED_DOMAINS` - Allowed domains for browser automation (optional)

## Project Structure

```
orchestra-plugin/
├── agents/           # Specialized AI agents
│   ├── alex.md      # Project Manager & orchestrator
│   ├── eden.md      # QA & testing specialist
│   ├── iris.md      # Security specialist
│   ├── mina.md      # Frontend specialist
│   └── theo.md      # Monitoring & operations
├── skills/          # Reusable capabilities
│   ├── core/        # Cross-cutting skills
│   └── modes/       # Context-specific skills
├── policies/        # Agent behavior rules
│   ├── skills-map.yaml
│   └── skills-overview.yaml
├── hooks/           # Quality gate scripts
│   ├── before_task.sh
│   ├── before_pr.sh
│   ├── before_merge.sh
│   ├── before_deploy.sh
│   └── after_deploy.sh
├── mcp-servers/     # MCP Server implementations
│   ├── github-server.py
│   ├── shopify-server.py
│   ├── vercel-server.py
│   ├── slack-server.py
│   ├── install.sh
│   ├── requirements.txt
│   └── README.md
└── mcp.json         # Service configurations
```

## Getting Started

### First Run

1. Start with a small task (e.g., UI tweak or new API endpoint)
2. Let **Alex** (PM agent) route the task to appropriate specialists
3. Watch hooks enforce quality gates before merges
4. Review generated artifacts (changelogs, test plans, etc.)

### Example Usage

```
# Simple feature request
"Add a new user profile page with avatar upload"

# Alex will:
# 1. Break down the task
# 2. Route to Mina (frontend) and Eden (QA)
# 3. Trigger security review from Iris
# 4. Enforce pre-merge checks
# 5. Generate documentation
```

## MCP Servers

This plugin includes ready-to-use MCP servers for seamless integration with popular services:

### Available Servers

- **GitHub MCP Server** - PR management, repo access, issue tracking
- **Shopify MCP Server** - Theme development, asset management, validation
- **Vercel MCP Server** - Deployment management, monitoring, logs
- **Slack MCP Server** - Notifications, deployment alerts, team communication
- **Browser MCP Server** - Automated browser testing, screenshots, web scraping (NEW)

### Quick Start

**All servers are automatically set up with `./setup.sh`**

```bash
# Start Browser MCP Server (already installed by setup.sh)
cd orchestra-plugin/mcp-servers
npm run browser &

# Test browser automation
./browser-helper.sh init
./browser-helper.sh navigate https://example.com
./browser-helper.sh screenshot homepage.png true
./browser-helper.sh close
```

For detailed usage instructions, see [mcp-servers/README.md](orchestra-plugin/mcp-servers/README.md).

## Hooks

Orchestra Plugin includes production-ready hooks for quality gates:

### Available Hooks

- [before_task.sh](orchestra-plugin/hooks/before_task.sh) - Validates task clarity and acceptance criteria
- [before_pr.sh](orchestra-plugin/hooks/before_pr.sh) - Runs linting, type checking, tests, secret scanning, and SBOM generation
- [before_merge.sh](orchestra-plugin/hooks/before_merge.sh) - Executes E2E tests, Lighthouse CI, and visual regression tests
- [before_deploy.sh](orchestra-plugin/hooks/before_deploy.sh) - Validates env vars, DB migrations, health checks, and builds
- [after_deploy.sh](orchestra-plugin/hooks/after_deploy.sh) - Runs smoke tests, generates rollout status, sends notifications

### Hook Features

- Auto-detects project type (Node.js, Python, Docker, etc.)
- Gracefully skips checks when tools are not installed
- Provides clear error messages and installation instructions
- Supports multiple frameworks (Prisma, Django, Alembic, Playwright, pytest, etc.)

## Safety & Best Practices

- **Least-privilege credentials**: Use minimal required scopes for each service
- **Pre-merge gates**: Automated review checklist, QA, and security checks
- **Pre-deploy gates**: Release validation and final QA
- **Evidence artifacts**: All changes tracked with changelogs and test plans

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

For issues, questions, or contributions, please open an issue on GitHub.

## Acknowledgments

Built for Claude Code to enable semi-autonomous, multi-agent software development workflows.