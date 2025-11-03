#!/usr/bin/env bash
# hooks/after_task_complete.sh
# Automatic task completion recording hook

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_MILESTONE_SCRIPT="${SCRIPT_DIR}/../.orchestra/scripts/record-milestone.sh"
LOG_DIR="${SCRIPT_DIR}/../.orchestra/logs"
LOG_FILE="${LOG_DIR}/after-task-complete.log"
MEMORY_BANK_PROJECT="orchestra"
PROGRESS_FILE="progress.md"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function (non-blocking)
log() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    echo "[$timestamp] $*" >> "$LOG_FILE" 2>/dev/null || true
}

# Non-blocking execution wrapper
safe_execute() {
    "$@" 2>> "$LOG_FILE" || log "WARNING: Command failed but continuing: $*"
}

log "=== Task Completion Hook Triggered ==="

# Get language setting from environment
LANG="${ORCHESTRA_LANGUAGE:-en}"

# Try to detect completed task information from environment or recent activity
# Environment variables that might be set by TodoWrite or task systems
TASK_NAME="${COMPLETED_TASK_NAME:-}"
TASK_DESCRIPTION="${COMPLETED_TASK_DESCRIPTION:-}"
TASK_TAG="${COMPLETED_TASK_TAG:-chore}"

# If no task information is available, try to infer from git recent activity
if [ -z "$TASK_NAME" ]; then
    # Check for recent git commits
    RECENT_COMMIT=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")

    if [ -n "$RECENT_COMMIT" ]; then
        TASK_NAME="Task: $RECENT_COMMIT"
        TASK_DESCRIPTION="Completed via git commit"

        # Infer tag from commit message prefix
        if echo "$RECENT_COMMIT" | grep -qE "^feat:"; then
            TASK_TAG="feature"
        elif echo "$RECENT_COMMIT" | grep -qE "^fix:"; then
            TASK_TAG="bugfix"
        elif echo "$RECENT_COMMIT" | grep -qE "^refactor:"; then
            TASK_TAG="refactor"
        elif echo "$RECENT_COMMIT" | grep -qE "^docs:"; then
            TASK_TAG="docs"
        elif echo "$RECENT_COMMIT" | grep -qE "^test:"; then
            TASK_TAG="test"
        elif echo "$RECENT_COMMIT" | grep -qE "^perf:"; then
            TASK_TAG="perf"
        else
            TASK_TAG="chore"
        fi
    else
        log "No task information available, skipping automatic recording"
        exit 0
    fi
fi

log "Task Name: $TASK_NAME"
log "Task Description: $TASK_DESCRIPTION"
log "Task Tag: $TASK_TAG"

# Record milestone using the record-milestone.sh script
if [ -f "$RECORD_MILESTONE_SCRIPT" ] && [ -x "$RECORD_MILESTONE_SCRIPT" ]; then
    log "Recording task completion as milestone..."
    safe_execute "$RECORD_MILESTONE_SCRIPT" \
        "$TASK_NAME" \
        "$TASK_DESCRIPTION" \
        "$TASK_TAG"
    log "✅ Task completion recorded"
else
    log "ERROR: record-milestone.sh not found or not executable at $RECORD_MILESTONE_SCRIPT"
    exit 0  # Non-blocking - don't fail the hook
fi

# Update progress metrics in Memory Bank
log "Updating progress metrics..."

# Direct file access to Memory Bank
MEMORY_BANK_PATH="$HOME/.memory-bank/$MEMORY_BANK_PROJECT/$PROGRESS_FILE"

if [ -f "$MEMORY_BANK_PATH" ]; then
    # Read current metrics
    CURRENT_COMPLETED=$(grep "Total Tasks Completed" "$MEMORY_BANK_PATH" | grep -oE "[0-9]+" || echo "0")
    NEW_COMPLETED=$((CURRENT_COMPLETED + 1))

    # Update the count
    safe_execute sed -i.bak "s/\*\*Total Tasks Completed\*\*: [0-9]*/\*\*Total Tasks Completed\*\*: $NEW_COMPLETED/" "$MEMORY_BANK_PATH"

    # Update last updated timestamp
    CURRENT_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    safe_execute sed -i.bak "s/\*\*Last Updated\*\*: .*/\*\*Last Updated\*\*: $CURRENT_DATE/" "$MEMORY_BANK_PATH"

    # Clean up backup file
    rm -f "${MEMORY_BANK_PATH}.bak" 2>/dev/null || true

    log "✅ Progress metrics updated: $NEW_COMPLETED tasks completed"
else
    log "WARNING: progress.md not found in Memory Bank, skipping metrics update"
fi

# Display completion message
if [ "$LANG" = "ja" ]; then
    echo "[after_task_complete] タスク完了を記録しました: $TASK_NAME" >&2 || true
else
    echo "[after_task_complete] Task completion recorded: $TASK_NAME" >&2 || true
fi

log "=== Task Completion Hook Completed ==="

# Always exit successfully (non-blocking)
exit 0
