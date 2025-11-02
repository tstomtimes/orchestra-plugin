# Web Browse Skill

## Purpose
Safely navigate, interact with, and capture evidence from web pages using automated browser operations.

## Security Features
- **Rate Limiting**: Maximum operations per session (10 navigations, 50 clicks, 30 inputs)
- **Input Sanitization**: Blocks sensitive patterns (passwords, credit cards, SSN)
- **Operation Logging**: All actions are logged to `artifacts/browser/{session}/operations.log`
- **Safe Mode**: Dangerous JavaScript operations are blocked
- **Local Access Only**: Server binds to localhost:3030 (not accessible externally)

## When to Use
- Verify preview deployments (UI/UX checks)
- Capture screenshots for documentation
- Run Lighthouse performance audits
- Scrape public data from allowed domains
- Test user flows without full E2E suite
- Monitor production health with visual checks

## Agents Using This Skill
- **Nova** (Preview Verification): Screenshot + Lighthouse before merge
- **Theo** (Post-Deploy Monitoring): Synthetic monitoring with screenshots
- **Mina** (UI/UX Review): Visual comparison and accessibility checks
- **Alex** (Competitive Analysis): Research and feature comparison (read-only)

## Configuration

No configuration required! The browser server allows access to any valid URL, making it perfect for development workflows.

Optional settings in `.env`:
```bash
# Change server port (default: 3030)
BROWSER_MCP_PORT=3030
```

## API Endpoints

### Initialize Browser
```bash
curl -X POST http://localhost:3030/init
# Response: {"ok": true, "sessionId": "1234567890"}
```

### Navigate to URL
```bash
curl -X POST http://localhost:3030/navigate \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://myapp.vercel.app", "waitUntil": "networkidle"}'
# Response: {"ok": true, "url": "https://myapp.vercel.app", "title": "My App"}
```

### Click Element
```bash
curl -X POST http://localhost:3030/click \
  -H 'Content-Type: application/json' \
  -d '{"selector": "button.primary"}'
# Response: {"ok": true}
```

### Type Text
```bash
curl -X POST http://localhost:3030/type \
  -H 'Content-Type: application/json' \
  -d '{"selector": "input[name=search]", "text": "test query", "pressEnter": true}'
# Response: {"ok": true}
```

### Wait for Element
```bash
curl -X POST http://localhost:3030/wait \
  -H 'Content-Type: application/json' \
  -d '{"selector": ".results", "timeout": 10000}'
# Response: {"ok": true}
```

### Scrape Text Content
```bash
curl -X POST http://localhost:3030/scrape \
  -H 'Content-Type: application/json' \
  -d '{"selector": "h2.product-title", "limit": 50}'
# Response: {"ok": true, "data": ["Product 1", "Product 2", ...]}
```

### Take Screenshot
```bash
curl -X POST http://localhost:3030/screenshot \
  -H 'Content-Type: application/json' \
  -d '{"filename": "homepage.png", "fullPage": true}'
# Response: {"ok": true, "path": "/path/to/artifacts/browser/.../homepage.png"}
```

### Get Page Content
```bash
curl -X POST http://localhost:3030/content
# Response: {"ok": true, "url": "...", "title": "...", "html": "..."}
```

### Evaluate JavaScript
```bash
curl -X POST http://localhost:3030/evaluate \
  -H 'Content-Type: application/json' \
  -d '{"expression": "document.querySelectorAll(\"img\").length"}'
# Response: {"ok": true, "result": 42}
```

### Close Browser
```bash
curl -X POST http://localhost:3030/close
# Response: {"ok": true}
```

### Health Check
```bash
curl http://localhost:3030/health
# Response: {"ok": true, "browser": true, "page": true, "sessionId": "...", "allowedDomains": [...]}
```

## Usage Examples

### Example 1: Screenshot Preview Deployment (Nova)
```bash
#!/usr/bin/env bash
PREVIEW_URL="https://myapp-pr-123.vercel.app"

# Initialize
curl -X POST http://localhost:3030/init

# Navigate
curl -X POST http://localhost:3030/navigate \
  -H 'Content-Type: application/json' \
  -d "{\"url\":\"$PREVIEW_URL\"}"

# Wait for main content
curl -X POST http://localhost:3030/wait \
  -H 'Content-Type: application/json' \
  -d '{"selector":"main"}'

# Screenshot
curl -X POST http://localhost:3030/screenshot \
  -H 'Content-Type: application/json' \
  -d '{"filename":"preview-homepage.png","fullPage":true}'

# Close
curl -X POST http://localhost:3030/close
```

### Example 2: Scrape Product Titles (Alex)
```bash
#!/usr/bin/env bash
# Initialize
curl -X POST http://localhost:3030/init

# Navigate to competitor site (must be in allowlist!)
curl -X POST http://localhost:3030/navigate \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://competitor.shopify.com/products"}'

# Scrape product titles
curl -X POST http://localhost:3030/scrape \
  -H 'Content-Type: application/json' \
  -d '{"selector":"h3.product-title","limit":20}' \
  > artifacts/competitor-products.json

# Close
curl -X POST http://localhost:3030/close
```

### Example 3: Test Search Flow (Mina)
```bash
#!/usr/bin/env bash
PREVIEW_URL="https://myapp.vercel.app"

# Initialize
curl -X POST http://localhost:3030/init

# Navigate
curl -X POST http://localhost:3030/navigate \
  -H 'Content-Type: application/json' \
  -d "{\"url\":\"$PREVIEW_URL\"}"

# Type in search box
curl -X POST http://localhost:3030/type \
  -H 'Content-Type: application/json' \
  -d '{"selector":"input[type=search]","text":"test product","pressEnter":true}'

# Wait for results
curl -X POST http://localhost:3030/wait \
  -H 'Content-Type: application/json' \
  -d '{"selector":".search-results"}'

# Screenshot results
curl -X POST http://localhost:3030/screenshot \
  -H 'Content-Type: application/json' \
  -d '{"filename":"search-results.png","fullPage":false}'

# Close
curl -X POST http://localhost:3030/close
```

## Integration with Hooks

### before_merge.sh - Visual Regression Check
```bash
#!/usr/bin/env bash
if [ -n "$PREVIEW_URL" ]; then
  echo "→ Capturing preview screenshot..."

  curl -s -X POST http://localhost:3030/init > /dev/null
  curl -s -X POST http://localhost:3030/navigate \
    -H 'Content-Type: application/json' \
    -d "{\"url\":\"$PREVIEW_URL\"}" > /dev/null

  curl -s -X POST http://localhost:3030/screenshot \
    -H 'Content-Type: application/json' \
    -d '{"filename":"preview.png","fullPage":true}' | jq -r '.path'

  curl -s -X POST http://localhost:3030/close > /dev/null

  echo "✅ Screenshot saved"
fi
```

### after_deploy.sh - Production Health Check
```bash
#!/usr/bin/env bash
PROD_URL="${PRODUCTION_URL:-https://app.example.com}"

echo "→ Running production health check..."

curl -s -X POST http://localhost:3030/init > /dev/null
curl -s -X POST http://localhost:3030/navigate \
  -H 'Content-Type: application/json' \
  -d "{\"url\":\"$PROD_URL\"}" > /dev/null

# Check if critical element exists
RESULT=$(curl -s -X POST http://localhost:3030/evaluate \
  -H 'Content-Type: application/json' \
  -d '{"expression":"document.querySelector(\".app-loaded\") !== null"}' | jq -r '.result')

if [ "$RESULT" = "true" ]; then
  echo "✅ Production app loaded successfully"
else
  echo "❌ Production app failed to load"
  exit 1
fi

curl -s -X POST http://localhost:3030/close > /dev/null
```

## Best Practices

1. **Always Initialize**: Call `/init` before any browser operations
2. **Clean Up**: Call `/close` when done to free resources
3. **Wait for Elements**: Use `/wait` before interacting with dynamic content
4. **Rate Limit Awareness**: Monitor operation counts to avoid hitting limits
5. **Security First**: Never type credentials or PII (blocked by default)
6. **Evidence Collection**: Save screenshots and logs for audit trail
7. **Domain Approval**: Add domains to allowlist before accessing

## Troubleshooting

### Error: "Domain not allowed"
Add the domain to `BROWSER_ALLOWED_DOMAINS` in `.env`

### Error: "Browser not initialized"
Call `/init` endpoint first

### Error: "Navigation limit exceeded"
You've hit the 10 navigation limit per session. Close and reinitialize.

### Error: "No active page"
Navigate to a URL first using `/navigate`

### Screenshots not saving
Check that `artifacts/` directory has write permissions

## Artifacts

All browser operations save artifacts to:
```
artifacts/browser/{sessionId}/
├── operations.log       # All operations with timestamps
├── screenshot.png       # Screenshots (custom filenames)
├── preview.png
└── ...
```

## Rate Limits (Per Session)

- Navigations: 10
- Clicks: 50
- Type operations: 30

## Blocked Patterns

Input containing these patterns will be rejected:
- `password` (case-insensitive)
- `credit card`
- `ssn` / `social security`

## JavaScript Evaluation Restrictions

Blocked keywords in `/evaluate`:
- `delete`
- `drop`
- `remove`
- `cookie`
- `localStorage`
