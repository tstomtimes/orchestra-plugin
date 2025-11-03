#!/bin/bash

# Progress Tracker Display Hook
# Shows task progress in chat after TodoWrite updates

set +e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if .orchestra/cache/progress.json exists and display it
if [ -f "$PROJECT_ROOT/.orchestra/cache/progress.json" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Progress Update (via TodoWrite)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Display cached progress data if available
    if command -v jq &> /dev/null; then
        # Extract and display task summary
        TOTAL=$(jq '.todos | length' "$PROJECT_ROOT/.orchestra/cache/progress.json" 2>/dev/null || echo "0")
        COMPLETED=$(jq '[.todos[] | select(.status == "completed")] | length' "$PROJECT_ROOT/.orchestra/cache/progress.json" 2>/dev/null || echo "0")
        IN_PROGRESS=$(jq '[.todos[] | select(.status == "in_progress")] | length' "$PROJECT_ROOT/.orchestra/cache/progress.json" 2>/dev/null || echo "0")
        PENDING=$(jq '[.todos[] | select(.status == "pending")] | length' "$PROJECT_ROOT/.orchestra/cache/progress.json" 2>/dev/null || echo "0")

        if [ "$TOTAL" -gt 0 ]; then
            COMPLETION_RATE=$((COMPLETED * 100 / TOTAL))

            echo "=== Progress Summary ==="
            echo "Total: $TOTAL"
            echo "Completed: $COMPLETED"
            echo "In Progress: $IN_PROGRESS"
            echo "Pending: $PENDING"
            echo "Completion Rate: $COMPLETION_RATE%"
            echo ""

            # Display task list
            echo "=== Tasks ==="
            jq -r '.todos[] | "[\(.status | ascii_upcase)] \(.content)"' "$PROJECT_ROOT/.orchestra/cache/progress.json" 2>/dev/null || true
        fi
    else
        # Fallback: just show the JSON
        cat "$PROJECT_ROOT/.orchestra/cache/progress.json"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

exit 0
