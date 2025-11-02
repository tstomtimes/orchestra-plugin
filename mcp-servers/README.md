# Orchestra Plugin - MCP Servers

This directory contains Model Context Protocol (MCP) servers that provide seamless integration with popular development and deployment platforms.

## Available MCP Servers

### 1. GitHub MCP Server (`github-server.py`)
Integrates with GitHub API for PR management, repo access, and issue tracking.

**Commands:**
- `list_prs` - List pull requests for a repository
- `get_pr` - Get details of a specific pull request
- `create_pr` - Create a new pull request
- `list_pr_checks` - Get CI/CD check status for a PR
- `merge_pr` - Merge a pull request
- `list_issues` - List issues for a repository
- `get_repo_status` - Get repository status and information

**Required Environment Variables:**
- `GITHUB_TOKEN` - GitHub personal access token with repo permissions

---

### 2. Shopify Theme MCP Server (`shopify-server.py`)
Integrates with Shopify Admin API for theme development and management.

**Commands:**
- `list_themes` - List all themes in the shop
- `get_theme` - Get details of a specific theme
- `list_theme_assets` - List assets for a theme
- `get_theme_asset` - Get a specific theme asset
- `update_theme_asset` - Update or create a theme asset
- `delete_theme_asset` - Delete a theme asset
- `publish_theme` - Publish a theme (set as main theme)
- `duplicate_theme` - Duplicate an existing theme
- `validate_theme` - Validate theme structure and assets
- `get_shop_info` - Get shop information

**Required Environment Variables:**
- `SHOPIFY_ADMIN_TOKEN` - Shopify Admin API access token
- `SHOP_DOMAIN` - Your shop domain (without .myshopify.com)

---

### 3. Shopify App MCP Server (`shopify-app-server.py`)
Integrates with Shopify Admin API for app development with REST and GraphQL support.

**Product Commands:**
- `list_products` - List products in the shop
- `get_product` - Get product details
- `create_product` - Create a new product
- `update_product` - Update a product

**Order Commands:**
- `list_orders` - List orders
- `get_order` - Get order details

**Customer Commands:**
- `list_customers` - List customers
- `get_customer` - Get customer details

**Inventory Commands:**
- `get_inventory_levels` - Get inventory levels
- `update_inventory_level` - Update inventory level

**Collection Commands:**
- `list_collections` - List smart and custom collections

**Webhook Commands:**
- `list_webhooks` - List webhooks
- `create_webhook` - Create a webhook
- `delete_webhook` - Delete a webhook

**GraphQL Commands:**
- `graphql_query` - Execute a custom GraphQL query
- `get_shop_metafields` - Get shop metafields
- `get_app_installations` - Get app installations

**Analytics Commands:**
- `get_shop_analytics` - Get shop analytics for a date range

**Required Environment Variables:**
- `SHOPIFY_ADMIN_TOKEN` - Shopify Admin API access token
- `SHOP_DOMAIN` - Your shop domain (without .myshopify.com)

---

### 4. Vercel MCP Server (`vercel-server.py`)
Integrates with Vercel API for deployment management.

**Commands:**
- `list_deployments` - List deployments
- `get_deployment` - Get details of a specific deployment
- `list_projects` - List projects
- `get_project` - Get details of a specific project
- `get_deployment_logs` - Get logs for a deployment
- `cancel_deployment` - Cancel a deployment
- `delete_deployment` - Delete a deployment
- `list_domains` - List domains
- `get_project_env_vars` - Get environment variables for a project
- `get_deployment_checks` - Get deployment checks status

**Required Environment Variables:**
- `VERCEL_TOKEN` - Vercel API token
- `VERCEL_TEAM_ID` - (Optional) Vercel team ID

---

### 5. Slack MCP Server (`slack-server.py`)
Integrates with Slack API for notifications and chat.

**Commands:**
- `send_message` - Send a message to a channel
- `update_message` - Update an existing message
- `delete_message` - Delete a message
- `list_channels` - List channels
- `get_channel_info` - Get channel information
- `list_users` - List users
- `get_user_info` - Get user information
- `send_deployment_notification` - Send a formatted deployment notification
- `send_alert` - Send a formatted alert

**Required Environment Variables:**
- `SLACK_BOT_TOKEN` - Slack Bot User OAuth token

---

## Installation

### Quick Install

Run the installation script:

```bash
cd orchestra-plugin/mcp-servers
./install.sh
```

### Manual Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Make the servers executable:
```bash
chmod +x *.py
```

3. Configure environment variables:
```bash
cp ../../.env.example ../../.env
# Edit .env with your API tokens
```

---

## Usage

### Command Line Usage

All MCP servers accept JSON input via stdin and return JSON output:

```bash
# GitHub: List PRs
echo '{"command":"list_prs","params":{"owner":"myorg","repo":"myrepo"}}' | python3 github-server.py

# Shopify Theme: List themes
echo '{"command":"list_themes","params":{}}' | python3 shopify-server.py

# Shopify App: List products
echo '{"command":"list_products","params":{"limit":10}}' | python3 shopify-app-server.py

# Vercel: List deployments
echo '{"command":"list_deployments","params":{"limit":10}}' | python3 vercel-server.py

# Slack: Send message
echo '{"command":"send_message","params":{"channel":"#general","text":"Hello from MCP!"}}' | python3 slack-server.py
```

### Using with Claude Code

Claude Code can automatically call these MCP servers when configured. The servers provide context and capabilities that Claude can use to:

- Check PR status before merging
- Validate Shopify themes before deployment
- Monitor Vercel deployments
- Send Slack notifications about build status

### Integration with Hooks

MCP servers can be integrated into hooks for automated checks:

```bash
# Example: Check GitHub PR status in before_merge.sh
PR_CHECKS=$(echo '{"command":"list_pr_checks","params":{"owner":"myorg","repo":"myrepo","pr_number":123}}' | python3 mcp-servers/github-server.py)

# Example: Validate Shopify theme in before_deploy.sh
THEME_VALIDATION=$(echo '{"command":"validate_theme","params":{"theme_id":123456}}' | python3 mcp-servers/shopify-server.py)

# Example: Send Slack notification after deployment
echo '{"command":"send_deployment_notification","params":{"channel":"#deployments","status":"success","environment":"production","commit":"abc123","deployer":"'$USER'","url":"https://myapp.com"}}' | python3 mcp-servers/slack-server.py
```

---

## Configuration

### Environment Variables

Create a `.env` file in the project root with your API tokens:

```bash
# GitHub
GITHUB_TOKEN=ghp_your_token_here

# Shopify
SHOPIFY_ADMIN_TOKEN=shpat_your_token_here
SHOP_DOMAIN=your-shop-name

# Vercel
VERCEL_TOKEN=your_vercel_token_here
VERCEL_TEAM_ID=team_your_team_id  # Optional

# Slack
SLACK_BOT_TOKEN=xoxb-your-token-here
```

### Security Best Practices

1. **Never commit tokens to version control**
   - Add `.env` to `.gitignore`
   - Use `.env.example` as a template

2. **Use least-privilege tokens**
   - Only grant necessary scopes/permissions
   - Use separate tokens for different environments

3. **Rotate tokens regularly**
   - Set expiration dates on tokens when possible
   - Monitor token usage

4. **Secure token storage**
   - Use environment variables or secure vaults in production
   - Restrict file permissions: `chmod 600 .env`

---

## Examples

### GitHub: Create a Pull Request

```bash
echo '{
  "command": "create_pr",
  "params": {
    "owner": "myorg",
    "repo": "myrepo",
    "title": "Add new feature",
    "head": "feature-branch",
    "base": "main",
    "body": "This PR adds a new feature"
  }
}' | python3 github-server.py
```

### Shopify Theme: Update Theme Asset

```bash
echo '{
  "command": "update_theme_asset",
  "params": {
    "theme_id": 123456,
    "asset_key": "templates/index.json",
    "value": "{\"sections\":{\"header\":{\"type\":\"header\"}}}"
  }
}' | python3 shopify-server.py
```

### Shopify App: Create Product

```bash
echo '{
  "command": "create_product",
  "params": {
    "title": "New Product",
    "body_html": "<strong>Product description</strong>",
    "vendor": "My Brand",
    "product_type": "Clothing"
  }
}' | python3 shopify-app-server.py
```

### Shopify App: Execute GraphQL Query

```bash
echo '{
  "command": "graphql_query",
  "params": {
    "query": "{ shop { name email myshopifyDomain } }"
  }
}' | python3 shopify-app-server.py
```

### Shopify App: Get Shop Analytics

```bash
echo '{
  "command": "get_shop_analytics",
  "params": {
    "start_date": "2024-01-01",
    "end_date": "2024-01-31"
  }
}' | python3 shopify-app-server.py
```

### Vercel: Get Deployment Status

```bash
echo '{
  "command": "get_deployment",
  "params": {
    "deployment_id": "dpl_your_deployment_id"
  }
}' | python3 vercel-server.py
```

### Slack: Send Deployment Notification

```bash
echo '{
  "command": "send_deployment_notification",
  "params": {
    "channel": "#deployments",
    "status": "success",
    "environment": "production",
    "commit": "abc1234",
    "deployer": "alice",
    "url": "https://myapp.vercel.app"
  }
}' | python3 slack-server.py
```

---

## Troubleshooting

### Common Issues

**ImportError: No module named 'requests'**
- Install dependencies: `pip install -r requirements.txt`

**Authentication Error**
- Check that environment variables are set correctly
- Verify token has necessary permissions
- Ensure token hasn't expired

**Permission Denied**
- Make scripts executable: `chmod +x *.py`
- Check file permissions on `.env`: `chmod 600 .env`

**JSON Parse Error**
- Validate JSON syntax
- Use single quotes for shell strings, double quotes for JSON

### Debug Mode

Enable verbose logging by setting environment variable:
```bash
export DEBUG=1
python3 github-server.py
```

---

## Development

### Adding a New MCP Server

1. Create a new Python file (e.g., `myservice-server.py`)
2. Implement the server class with API methods
3. Add command handler function
4. Add main entry point
5. Update `install.sh` and this README
6. Add required environment variables to `.env.example`

### Testing

Test individual commands:
```bash
# Test GitHub server
echo '{"command":"get_repo_status","params":{"owner":"anthropics","repo":"claude-code"}}' | python3 github-server.py
```

---

## License

See the main project LICENSE file.

---

## Support

For issues and feature requests, please visit:
https://github.com/anthropics/claude-code/issues
