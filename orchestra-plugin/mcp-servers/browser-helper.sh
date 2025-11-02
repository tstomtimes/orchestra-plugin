#!/usr/bin/env bash
# Browser Helper Script
# Convenient wrapper for browser MCP operations

set -euo pipefail

BROWSER_URL="${BROWSER_MCP_URL:-http://localhost:3030}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function: Make API call
api_call() {
    local endpoint="$1"
    local data="${2:-}"

    if [ -z "$data" ]; then
        curl -s "$BROWSER_URL/$endpoint"
    else
        curl -s -X POST "$BROWSER_URL/$endpoint" \
            -H 'Content-Type: application/json' \
            -d "$data"
    fi
}

# Check if server is running
check_server() {
    if ! curl -s "$BROWSER_URL/health" > /dev/null 2>&1; then
        echo -e "${RED}❌ Browser MCP server is not running${NC}" >&2
        echo "   Start it with: cd orchestra-plugin/mcp-servers && npm run browser" >&2
        exit 1
    fi
}

# Commands
case "${1:-help}" in
    init)
        check_server
        curl -s -X POST "$BROWSER_URL/init" | jq
        ;;

    navigate|nav|open)
        check_server
        URL="${2:-}"
        if [ -z "$URL" ]; then
            echo "Usage: $0 navigate <url>" >&2
            exit 1
        fi
        api_call "navigate" "{\"url\":\"$URL\"}" | jq
        ;;

    click)
        check_server
        SELECTOR="${2:-}"
        if [ -z "$SELECTOR" ]; then
            echo "Usage: $0 click <selector>" >&2
            exit 1
        fi
        api_call "click" "{\"selector\":\"$SELECTOR\"}" | jq
        ;;

    type|input)
        check_server
        SELECTOR="${2:-}"
        TEXT="${3:-}"
        PRESS_ENTER="${4:-false}"
        if [ -z "$SELECTOR" ] || [ -z "$TEXT" ]; then
            echo "Usage: $0 type <selector> <text> [pressEnter]" >&2
            exit 1
        fi
        api_call "type" "{\"selector\":\"$SELECTOR\",\"text\":\"$TEXT\",\"pressEnter\":$PRESS_ENTER}" | jq
        ;;

    wait)
        check_server
        SELECTOR="${2:-}"
        TIMEOUT="${3:-15000}"
        if [ -z "$SELECTOR" ]; then
            echo "Usage: $0 wait <selector> [timeout_ms]" >&2
            exit 1
        fi
        api_call "wait" "{\"selector\":\"$SELECTOR\",\"timeout\":$TIMEOUT}" | jq
        ;;

    scrape)
        check_server
        SELECTOR="${2:-}"
        LIMIT="${3:-50}"
        if [ -z "$SELECTOR" ]; then
            echo "Usage: $0 scrape <selector> [limit]" >&2
            exit 1
        fi
        api_call "scrape" "{\"selector\":\"$SELECTOR\",\"limit\":$LIMIT}" | jq
        ;;

    screenshot|snap)
        check_server
        FILENAME="${2:-screenshot.png}"
        FULLPAGE="${3:-false}"
        api_call "screenshot" "{\"filename\":\"$FILENAME\",\"fullPage\":$FULLPAGE}" | jq
        ;;

    content|html)
        check_server
        curl -s -X POST "$BROWSER_URL/content" | jq
        ;;

    eval|evaluate)
        check_server
        EXPRESSION="${2:-}"
        if [ -z "$EXPRESSION" ]; then
            echo "Usage: $0 eval <javascript_expression>" >&2
            exit 1
        fi
        api_call "evaluate" "{\"expression\":\"$EXPRESSION\"}" | jq
        ;;

    close|quit)
        check_server
        curl -s -X POST "$BROWSER_URL/close" | jq
        ;;

    health|status)
        check_server
        curl -s "$BROWSER_URL/health" | jq
        ;;

    help|--help|-h)
        cat << EOF
Browser Helper Script - Convenient wrapper for browser MCP operations

Usage: $0 <command> [arguments]

Commands:
  init                          Initialize browser session
  navigate <url>                Navigate to URL
  click <selector>              Click element
  type <selector> <text> [enter] Type text into element
  wait <selector> [timeout]     Wait for element to appear
  scrape <selector> [limit]     Scrape text content from elements
  screenshot [filename] [full]  Take screenshot
  content                       Get page HTML content
  evaluate <expression>         Evaluate JavaScript
  close                         Close browser session
  health                        Check server status

Examples:
  $0 init
  $0 navigate https://example.com
  $0 wait "main"
  $0 screenshot homepage.png true
  $0 scrape "h2.title" 20
  $0 evaluate "document.title"
  $0 close

Environment Variables:
  BROWSER_MCP_URL              Browser MCP server URL (default: http://localhost:3030)

See: orchestra-plugin/agents/skills/web-browse.md for full documentation
EOF
        ;;

    *)
        echo -e "${RED}Unknown command: $1${NC}" >&2
        echo "Run '$0 help' for usage" >&2
        exit 1
        ;;
esac
