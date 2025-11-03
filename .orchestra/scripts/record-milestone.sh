#!/usr/bin/env bash
# .orchestra/scripts/record-milestone.sh
# Universal milestone recording script for Memory Bank

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOG_DIR}/milestone-recording.log"
MEMORY_BANK_PROJECT="orchestra"
PROGRESS_FILE="progress.md"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

# Error handler
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Usage information
usage() {
    cat <<EOF
Usage: $0 <milestone_name> <description> <tag> [contributor]

Arguments:
  milestone_name  : Name of the milestone (required)
  description     : Brief description of the milestone (required)
  tag             : Category tag (feature/bugfix/refactor/docs/test/perf/chore) (required)
  contributor     : Optional contributor name (defaults to git user)

Example:
  $0 "Feature XYZ" "Implemented core functionality" "feature" "John Doe"
  $0 "Bug Fix #123" "Fixed authentication issue" "bugfix"

Tags:
  feature   - New feature implementation
  bugfix    - Bug fix
  refactor  - Code refactoring
  docs      - Documentation update
  test      - Test implementation
  perf      - Performance optimization
  chore     - Maintenance task
EOF
    exit 1
}

# Validate arguments
if [ $# -lt 3 ]; then
    log "ERROR: Insufficient arguments"
    usage
fi

MILESTONE_NAME="$1"
DESCRIPTION="$2"
TAG="$3"
CONTRIBUTOR="${4:-$(git config user.name 2>/dev/null || echo "Unknown")}"

# Validate tag
VALID_TAGS=("feature" "bugfix" "refactor" "docs" "test" "perf" "chore")
if [[ ! " ${VALID_TAGS[*]} " =~ ${TAG} ]]; then
    error_exit "Invalid tag: $TAG. Valid tags are: ${VALID_TAGS[*]}"
fi

# Generate timestamp in ISO 8601 format (UTC)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
READABLE_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

log "Recording milestone: $MILESTONE_NAME"
log "Description: $DESCRIPTION"
log "Tag: $TAG"
log "Contributor: $CONTRIBUTOR"

# Check if Claude Code CLI with MCP is available
if ! command -v claude &> /dev/null; then
    log "WARNING: Claude Code CLI not available. Using direct file access fallback."
    USE_MCP=false
else
    USE_MCP=true
fi

# Function to read Memory Bank file via MCP
read_memory_bank() {
    local project="$1"
    local file="$2"

    if [ "$USE_MCP" = true ]; then
        # Use Claude Code CLI to read from Memory Bank
        # Note: This requires Claude Code session, so we'll use direct file access
        USE_MCP=false
    fi

    # Fallback: Direct file access
    local memory_bank_path="$HOME/memory-bank/$project/$file"
    if [ -f "$memory_bank_path" ]; then
        cat "$memory_bank_path"
    else
        echo ""
    fi
}

# Function to write to Memory Bank file via MCP
write_memory_bank() {
    local project="$1"
    local file="$2"
    local content="$3"

    # Direct file access (MCP requires active Claude session)
    local memory_bank_path="$HOME/memory-bank/$project"
    mkdir -p "$memory_bank_path"
    echo "$content" > "$memory_bank_path/$file"
}

# Read current progress.md
log "Reading current progress.md from Memory Bank..."
CURRENT_CONTENT=$(read_memory_bank "$MEMORY_BANK_PROJECT" "$PROGRESS_FILE")

# Check if content is empty (new file)
if [ -z "$CURRENT_CONTENT" ]; then
    log "Creating new progress.md file"
    CURRENT_CONTENT="# Progress Tracking

This file tracks project progress, milestones, and metrics.

## Milestone Updates

| Date | Milestone | Description | Tag | Contributor |
|------|-----------|-------------|-----|-------------|

## Progress Metrics

- **Total Tasks Completed**: 0
- **Total Milestones**: 0
- **Last Updated**: $READABLE_DATE

## Deployment History

| Date | Environment | Commit | Status |
|------|-------------|--------|--------|
"
fi

# Check if "## Milestone Updates" section exists
if ! echo "$CURRENT_CONTENT" | grep -q "## Milestone Updates"; then
    log "Adding Milestone Updates section to progress.md"
    CURRENT_CONTENT="${CURRENT_CONTENT}

## Milestone Updates

| Date | Milestone | Description | Tag | Contributor |
|------|-----------|-------------|-----|-------------|
"
fi

# Check if "## Progress Metrics" section exists
if ! echo "$CURRENT_CONTENT" | grep -q "## Progress Metrics"; then
    log "Adding Progress Metrics section to progress.md"
    # Insert Progress Metrics section after Milestone Updates
    CURRENT_CONTENT=$(echo "$CURRENT_CONTENT" | awk -v date="$READABLE_DATE" '
        /## Milestone Updates/ {
            print
            milestone_section = 1
        }
        milestone_section && /^$/ && !metrics_added {
            print
            print "## Progress Metrics"
            print ""
            print "- **Total Tasks Completed**: 0"
            print "- **Total Milestones**: 0"
            print "- **Last Updated**: " date
            print ""
            metrics_added = 1
            next
        }
        { print }
    ')
fi

# Prepare new milestone entry
NEW_ENTRY="| $READABLE_DATE | $MILESTONE_NAME | $DESCRIPTION | \`$TAG\` | $CONTRIBUTOR |"

# Check if milestone already exists (prevent duplicates)
if echo "$CURRENT_CONTENT" | grep -Fq "$MILESTONE_NAME"; then
    log "WARNING: Milestone '$MILESTONE_NAME' already exists. Updating..."
    # Remove old entry and add new one
    CURRENT_CONTENT=$(echo "$CURRENT_CONTENT" | grep -v "$MILESTONE_NAME")
fi

# Insert new entry after the table header
UPDATED_CONTENT=$(echo "$CURRENT_CONTENT" | awk -v entry="$NEW_ENTRY" '
    /## Milestone Updates/ {
        print
        getline  # Print blank line
        print
        getline  # Print table header
        print
        getline  # Print separator
        print
        print entry  # Insert new entry
        next
    }
    { print }
')

# Update milestone count
MILESTONE_COUNT=$(echo "$UPDATED_CONTENT" | grep -c "^|.*|.*|.*|.*|.*|" || echo "1")
((MILESTONE_COUNT--)) || true  # Subtract header row

UPDATED_CONTENT=$(echo "$UPDATED_CONTENT" | awk -v count="$MILESTONE_COUNT" -v date="$READABLE_DATE" '
    /\*\*Total Milestones\*\*/ {
        print "- **Total Milestones**: " count
        next
    }
    /\*\*Last Updated\*\*/ {
        print "- **Last Updated**: " date
        next
    }
    { print }
')

# Write updated content back to Memory Bank
log "Writing updated progress.md to Memory Bank..."
write_memory_bank "$MEMORY_BANK_PROJECT" "$PROGRESS_FILE" "$UPDATED_CONTENT"

log "✅ Milestone recorded successfully"
log "   Milestone: $MILESTONE_NAME"
log "   Tag: $TAG"
log "   Timestamp: $TIMESTAMP"

# Exit successfully
exit 0
