#!/usr/bin/env bash
# hooks/after_pr_merge.sh
# Automatic PR merge recording hook

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_MILESTONE_SCRIPT="${SCRIPT_DIR}/../.orchestra/scripts/record-milestone.sh"
LOG_DIR="${SCRIPT_DIR}/../.orchestra/logs"
LOG_FILE="${LOG_DIR}/after-pr-merge.log"
MEMORY_BANK_PROJECT="orchestra"
DECISIONS_FILE="decisions.md"

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

log "=== PR Merge Hook Triggered ==="

# Get language setting from environment
LANG="${ORCHESTRA_LANGUAGE:-en}"

# Try to extract PR information from environment or git
PR_NUMBER="${PR_NUMBER:-}"
PR_TITLE="${PR_TITLE:-}"
PR_DESCRIPTION="${PR_DESCRIPTION:-}"
PR_MERGER="${PR_MERGER:-$(git config user.name 2>/dev/null || echo "Unknown")}"
PR_BRANCH="${PR_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")}"

# If GitHub CLI is available, try to get PR info
if command -v gh &> /dev/null && [ -z "$PR_NUMBER" ]; then
    log "Attempting to fetch PR info using GitHub CLI..."

    # Get PR number from current branch
    PR_INFO=$(gh pr view --json number,title,body,mergedBy 2>/dev/null || echo "")

    if [ -n "$PR_INFO" ]; then
        PR_NUMBER=$(echo "$PR_INFO" | grep -o '"number":[0-9]*' | grep -o '[0-9]*' || echo "")
        PR_TITLE=$(echo "$PR_INFO" | grep -o '"title":"[^"]*"' | sed 's/"title":"//;s/"$//' || echo "")
        PR_DESCRIPTION=$(echo "$PR_INFO" | grep -o '"body":"[^"]*"' | sed 's/"body":"//;s/"$//' || echo "")
        PR_MERGER=$(echo "$PR_INFO" | grep -o '"login":"[^"]*"' | sed 's/"login":"//;s/"$//' || echo "$PR_MERGER")

        log "PR info extracted from GitHub: #$PR_NUMBER - $PR_TITLE"
    fi
fi

# Fallback: Use git log to infer merge information
if [ -z "$PR_TITLE" ]; then
    log "Falling back to git log for PR information..."

    # Try to get merge commit message
    MERGE_COMMIT=$(git log -1 --merges --pretty=format:"%s" 2>/dev/null || echo "")

    if [ -n "$MERGE_COMMIT" ]; then
        # Extract PR number from merge commit (format: "Merge pull request #123 from branch")
        PR_NUMBER=$(echo "$MERGE_COMMIT" | grep -oE "#[0-9]+" | grep -oE "[0-9]+" | head -1 || echo "")
        PR_TITLE="$MERGE_COMMIT"
        PR_DESCRIPTION="Merged from branch: $PR_BRANCH"
        log "Merge commit found: $MERGE_COMMIT"
    else
        # No merge commit found, check if this is a squash merge
        RECENT_COMMIT=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
        if [ -n "$RECENT_COMMIT" ]; then
            PR_TITLE="$RECENT_COMMIT"
            PR_DESCRIPTION="Commit from branch: $PR_BRANCH"
            log "Using recent commit as PR info: $RECENT_COMMIT"
        else
            log "No PR information available, skipping automatic recording"
            exit 0
        fi
    fi
fi

# Determine tag from PR title or description
PR_TAG="feature"
if echo "$PR_TITLE" | grep -qiE "(fix|bug)"; then
    PR_TAG="bugfix"
elif echo "$PR_TITLE" | grep -qiE "refactor"; then
    PR_TAG="refactor"
elif echo "$PR_TITLE" | grep -qiE "(doc|docs)"; then
    PR_TAG="docs"
elif echo "$PR_TITLE" | grep -qiE "test"; then
    PR_TAG="test"
elif echo "$PR_TITLE" | grep -qiE "perf"; then
    PR_TAG="perf"
elif echo "$PR_TITLE" | grep -qiE "chore"; then
    PR_TAG="chore"
fi

log "PR Title: $PR_TITLE"
log "PR Description: $PR_DESCRIPTION"
log "PR Merger: $PR_MERGER"
log "PR Branch: $PR_BRANCH"
log "PR Tag: $PR_TAG"

# Record PR merge as milestone
if [ -f "$RECORD_MILESTONE_SCRIPT" ] && [ -x "$RECORD_MILESTONE_SCRIPT" ]; then
    log "Recording PR merge as milestone..."

    MILESTONE_NAME="PR"
    if [ -n "$PR_NUMBER" ]; then
        MILESTONE_NAME="PR #$PR_NUMBER"
    fi
    MILESTONE_NAME="$MILESTONE_NAME: $PR_TITLE"

    safe_execute "$RECORD_MILESTONE_SCRIPT" \
        "$MILESTONE_NAME" \
        "$PR_DESCRIPTION" \
        "$PR_TAG" \
        "$PR_MERGER"

    log "✅ PR merge recorded as milestone"
else
    log "ERROR: record-milestone.sh not found or not executable at $RECORD_MILESTONE_SCRIPT"
    exit 0  # Non-blocking
fi

# Update decisions.md if this PR contains important decisions
log "Checking for decision updates..."

MEMORY_BANK_PATH="$HOME/.memory-bank/$MEMORY_BANK_PROJECT/$DECISIONS_FILE"
CURRENT_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Check if PR description contains keywords indicating a decision
DECISION_KEYWORDS="(decision|decided|choose|chose|selected|approach|strategy|architecture)"
if echo "$PR_DESCRIPTION" | grep -qiE "$DECISION_KEYWORDS"; then
    log "PR contains decision-related content, updating decisions.md..."

    # Ensure decisions.md exists
    if [ ! -f "$MEMORY_BANK_PATH" ]; then
        mkdir -p "$(dirname "$MEMORY_BANK_PATH")"
        cat > "$MEMORY_BANK_PATH" <<EOF
# Architecture Decision Records (ADR)

This file tracks important architectural and technical decisions made during the project.

## Decision Log

| Date | Decision | Context | Status | Related PR |
|------|----------|---------|--------|------------|
EOF
        log "Created new decisions.md file"
    fi

    # Check if Decision Log section exists
    if ! grep -q "## Decision Log" "$MEMORY_BANK_PATH"; then
        cat >> "$MEMORY_BANK_PATH" <<EOF

## Decision Log

| Date | Decision | Context | Status | Related PR |
|------|----------|---------|--------|------------|
EOF
        log "Added Decision Log section to decisions.md"
    fi

    # Prepare decision entry
    DECISION_TITLE="$PR_TITLE"
    DECISION_CONTEXT="$PR_DESCRIPTION"
    DECISION_STATUS="Implemented"
    PR_REFERENCE="PR #$PR_NUMBER (commit: $COMMIT_HASH)"

    # Truncate long descriptions
    if [ ${#DECISION_CONTEXT} -gt 100 ]; then
        DECISION_CONTEXT="${DECISION_CONTEXT:0:100}..."
    fi

    DECISION_ENTRY="| $CURRENT_DATE | $DECISION_TITLE | $DECISION_CONTEXT | $DECISION_STATUS | $PR_REFERENCE |"

    # Insert decision entry after table header
    awk -v entry="$DECISION_ENTRY" '
        /## Decision Log/ {
            print
            getline
            print
            getline
            print
            getline
            print
            print entry
            next
        }
        { print }
    ' "$MEMORY_BANK_PATH" > "${MEMORY_BANK_PATH}.tmp"

    mv "${MEMORY_BANK_PATH}.tmp" "$MEMORY_BANK_PATH"

    log "✅ Decision log updated in decisions.md"
fi

# Display completion message
if [ "$LANG" = "ja" ]; then
    echo "[after_pr_merge] PRマージを記録しました: $PR_TITLE" >&2 || true
else
    echo "[after_pr_merge] PR merge recorded: $PR_TITLE" >&2 || true
fi

log "=== PR Merge Hook Completed ==="

# Always exit successfully (non-blocking)
exit 0
