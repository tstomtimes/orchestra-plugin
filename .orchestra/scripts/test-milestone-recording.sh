#!/usr/bin/env bash
# .orchestra/scripts/test-milestone-recording.sh
# Comprehensive test suite for milestone recording functionality

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_MILESTONE_SCRIPT="${SCRIPT_DIR}/record-milestone.sh"
AFTER_TASK_COMPLETE_HOOK="${SCRIPT_DIR}/../../hooks/after_task_complete.sh"
AFTER_PR_MERGE_HOOK="${SCRIPT_DIR}/../../hooks/after_pr_merge.sh"
AFTER_DEPLOY_HOOK="${SCRIPT_DIR}/../../hooks/after_deploy.sh"
MEMORY_BANK_PROJECT="orchestra"
MEMORY_BANK_PATH="$HOME/memory-bank/$MEMORY_BANK_PROJECT"
TEST_LOG="${SCRIPT_DIR}/../logs/test-milestone-recording.log"

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $*" | tee -a "$TEST_LOG"
}

# Test result reporting
test_pass() {
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
    echo -e "${GREEN}✅ PASS${NC}: $1"
    log "PASS: $1"
}

test_fail() {
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
    echo -e "${RED}❌ FAIL${NC}: $1"
    log "FAIL: $1"
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
    log "INFO: $1"
}

# Backup Memory Bank before tests
backup_memory_bank() {
    if [ -d "$MEMORY_BANK_PATH" ]; then
        log "Backing up Memory Bank..."
        cp -r "$MEMORY_BANK_PATH" "${MEMORY_BANK_PATH}.test-backup.$(date +%s)"
        test_info "Memory Bank backed up"
    else
        test_info "No existing Memory Bank to backup"
    fi
}

# Restore Memory Bank after tests
restore_memory_bank() {
    local latest_backup
    latest_backup=$(ls -td "${MEMORY_BANK_PATH}.test-backup."* 2>/dev/null | head -1 || echo "")

    if [ -n "$latest_backup" ]; then
        log "Restoring Memory Bank from backup..."
        rm -rf "$MEMORY_BANK_PATH"
        mv "$latest_backup" "$MEMORY_BANK_PATH"
        test_info "Memory Bank restored"
    fi
}

# Setup test environment
setup_test_env() {
    log "=== Setting up test environment ==="
    mkdir -p "${SCRIPT_DIR}/../logs"
    mkdir -p "$MEMORY_BANK_PATH"
    backup_memory_bank
}

# Cleanup test environment
cleanup_test_env() {
    log "=== Cleaning up test environment ==="
    # Remove test backup files older than 1 day
    find "$HOME/.memory-bank" -name "${MEMORY_BANK_PROJECT}.test-backup.*" -mtime +1 -delete 2>/dev/null || true
}

# Test 1: record-milestone.sh exists and is executable
test_script_existence() {
    log "=== Test 1: Script Existence and Permissions ==="

    if [ -f "$RECORD_MILESTONE_SCRIPT" ]; then
        test_pass "record-milestone.sh exists"
    else
        test_fail "record-milestone.sh not found at $RECORD_MILESTONE_SCRIPT"
        return
    fi

    if [ -x "$RECORD_MILESTONE_SCRIPT" ]; then
        test_pass "record-milestone.sh is executable"
    else
        test_fail "record-milestone.sh is not executable"
    fi
}

# Test 2: record-milestone.sh basic functionality
test_basic_milestone_recording() {
    log "=== Test 2: Basic Milestone Recording ==="

    # Run record-milestone.sh
    if bash "$RECORD_MILESTONE_SCRIPT" "Test Milestone" "Testing basic functionality" "feature" "Test User" >> "$TEST_LOG" 2>&1; then
        test_pass "record-milestone.sh executed successfully"
    else
        test_fail "record-milestone.sh execution failed"
        return
    fi

    # Check if progress.md was created
    if [ -f "$MEMORY_BANK_PATH/progress.md" ]; then
        test_pass "progress.md created in Memory Bank"
    else
        test_fail "progress.md not found in Memory Bank"
        return
    fi

    # Check if milestone was recorded
    if grep -q "Test Milestone" "$MEMORY_BANK_PATH/progress.md"; then
        test_pass "Milestone recorded in progress.md"
    else
        test_fail "Milestone not found in progress.md"
    fi

    # Check if Milestone Updates section exists
    if grep -q "## Milestone Updates" "$MEMORY_BANK_PATH/progress.md"; then
        test_pass "Milestone Updates section exists"
    else
        test_fail "Milestone Updates section not found"
    fi
}

# Test 3: Timestamp format validation
test_timestamp_format() {
    log "=== Test 3: Timestamp Format Validation ==="

    # Record a milestone
    bash "$RECORD_MILESTONE_SCRIPT" "Timestamp Test" "Testing timestamp format" "test" >> "$TEST_LOG" 2>&1

    # Check for ISO 8601 compatible timestamp format (YYYY-MM-DD HH:MM:SS UTC)
    if grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC" "$MEMORY_BANK_PATH/progress.md" > /dev/null; then
        test_pass "Timestamp format is correct (ISO 8601 compatible)"
    else
        test_fail "Timestamp format is incorrect"
    fi
}

# Test 4: Tag validation
test_tag_validation() {
    log "=== Test 4: Tag Validation ==="

    # Test valid tags
    local valid_tags=("feature" "bugfix" "refactor" "docs" "test" "perf" "chore")
    for tag in "${valid_tags[@]}"; do
        if bash "$RECORD_MILESTONE_SCRIPT" "Tag Test: $tag" "Testing $tag tag" "$tag" >> "$TEST_LOG" 2>&1; then
            test_pass "Valid tag accepted: $tag"
        else
            test_fail "Valid tag rejected: $tag"
        fi
    done

    # Test invalid tag
    if bash "$RECORD_MILESTONE_SCRIPT" "Invalid Tag Test" "Testing invalid tag" "invalid_tag" >> "$TEST_LOG" 2>&1; then
        test_fail "Invalid tag was accepted (should be rejected)"
    else
        test_pass "Invalid tag correctly rejected"
    fi
}

# Test 5: Duplicate milestone handling
test_duplicate_milestone() {
    log "=== Test 5: Duplicate Milestone Handling ==="

    # Record the same milestone twice
    bash "$RECORD_MILESTONE_SCRIPT" "Duplicate Test" "First entry" "feature" >> "$TEST_LOG" 2>&1
    bash "$RECORD_MILESTONE_SCRIPT" "Duplicate Test" "Second entry (update)" "feature" >> "$TEST_LOG" 2>&1

    # Count occurrences of the milestone name
    local count
    count=$(grep -c "Duplicate Test" "$MEMORY_BANK_PATH/progress.md" || echo "0")

    if [ "$count" -eq 1 ]; then
        test_pass "Duplicate milestone handled correctly (only one entry)"
    else
        test_fail "Duplicate milestone not handled correctly (found $count entries)"
    fi
}

# Test 6: Progress metrics update
test_progress_metrics() {
    log "=== Test 6: Progress Metrics Update ==="

    # Record multiple milestones
    bash "$RECORD_MILESTONE_SCRIPT" "Metric Test 1" "First milestone" "feature" >> "$TEST_LOG" 2>&1
    bash "$RECORD_MILESTONE_SCRIPT" "Metric Test 2" "Second milestone" "bugfix" >> "$TEST_LOG" 2>&1

    # Check if milestone count is updated
    if grep -q "Total Milestones" "$MEMORY_BANK_PATH/progress.md"; then
        test_pass "Progress metrics section exists"

        # Extract milestone count
        local count
        count=$(grep "Total Milestones" "$MEMORY_BANK_PATH/progress.md" | grep -oE "[0-9]+" || echo "0")

        if [ "$count" -gt 0 ]; then
            test_pass "Milestone count is tracked (count: $count)"
        else
            test_fail "Milestone count is not tracked correctly"
        fi
    else
        test_fail "Progress metrics section not found"
    fi
}

# Test 7: after_task_complete.sh hook
test_after_task_complete_hook() {
    log "=== Test 7: after_task_complete.sh Hook ==="

    if [ -f "$AFTER_TASK_COMPLETE_HOOK" ]; then
        test_pass "after_task_complete.sh exists"
    else
        test_fail "after_task_complete.sh not found"
        return
    fi

    if [ -x "$AFTER_TASK_COMPLETE_HOOK" ]; then
        test_pass "after_task_complete.sh is executable"
    else
        test_fail "after_task_complete.sh is not executable"
        return
    fi

    # Test hook execution (non-blocking)
    export COMPLETED_TASK_NAME="Test Task"
    export COMPLETED_TASK_DESCRIPTION="Testing task completion hook"
    export COMPLETED_TASK_TAG="test"

    if bash "$AFTER_TASK_COMPLETE_HOOK" >> "$TEST_LOG" 2>&1; then
        test_pass "after_task_complete.sh executed successfully"
    else
        test_fail "after_task_complete.sh execution failed"
    fi

    # Check if task was recorded
    if grep -q "Test Task" "$MEMORY_BANK_PATH/progress.md"; then
        test_pass "Task completion recorded in progress.md"
    else
        test_fail "Task completion not found in progress.md"
    fi

    unset COMPLETED_TASK_NAME COMPLETED_TASK_DESCRIPTION COMPLETED_TASK_TAG
}

# Test 8: after_pr_merge.sh hook
test_after_pr_merge_hook() {
    log "=== Test 8: after_pr_merge.sh Hook ==="

    if [ -f "$AFTER_PR_MERGE_HOOK" ]; then
        test_pass "after_pr_merge.sh exists"
    else
        test_fail "after_pr_merge.sh not found"
        return
    fi

    if [ -x "$AFTER_PR_MERGE_HOOK" ]; then
        test_pass "after_pr_merge.sh is executable"
    else
        test_fail "after_pr_merge.sh is not executable"
        return
    fi

    # Test hook execution (non-blocking)
    export PR_NUMBER="123"
    export PR_TITLE="Test PR: Add new feature"
    export PR_DESCRIPTION="This PR adds a new feature for testing purposes"
    export PR_MERGER="Test User"

    if bash "$AFTER_PR_MERGE_HOOK" >> "$TEST_LOG" 2>&1; then
        test_pass "after_pr_merge.sh executed successfully"
    else
        test_fail "after_pr_merge.sh execution failed"
    fi

    # Check if PR was recorded
    if grep -q "Test PR" "$MEMORY_BANK_PATH/progress.md"; then
        test_pass "PR merge recorded in progress.md"
    else
        test_fail "PR merge not found in progress.md"
    fi

    unset PR_NUMBER PR_TITLE PR_DESCRIPTION PR_MERGER
}

# Test 9: Error handling
test_error_handling() {
    log "=== Test 9: Error Handling ==="

    # Test missing arguments
    if bash "$RECORD_MILESTONE_SCRIPT" >> "$TEST_LOG" 2>&1; then
        test_fail "Script should fail with missing arguments"
    else
        test_pass "Script correctly handles missing arguments"
    fi

    # Test invalid arguments (should not crash)
    if bash "$RECORD_MILESTONE_SCRIPT" "" "" "" >> "$TEST_LOG" 2>&1; then
        test_fail "Script should fail with empty arguments"
    else
        test_pass "Script correctly handles empty arguments"
    fi
}

# Test 10: Log file creation
test_log_file_creation() {
    log "=== Test 10: Log File Creation ==="

    local milestone_log="${SCRIPT_DIR}/../logs/milestone-recording.log"

    if [ -f "$milestone_log" ]; then
        test_pass "Milestone recording log file created"
    else
        test_fail "Milestone recording log file not created"
    fi

    # Check if log contains entries
    if [ -s "$milestone_log" ]; then
        test_pass "Log file contains entries"
    else
        test_fail "Log file is empty"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Milestone Recording Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    setup_test_env

    # Run all tests
    test_script_existence
    test_basic_milestone_recording
    test_timestamp_format
    test_tag_validation
    test_duplicate_milestone
    test_progress_metrics
    test_after_task_complete_hook
    test_after_pr_merge_hook
    test_error_handling
    test_log_file_creation

    # Restore original state
    restore_memory_bank
    cleanup_test_env

    # Print summary
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total Tests: ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        log "=== ALL TESTS PASSED ==="
        exit 0
    else
        echo -e "${RED}❌ Some tests failed!${NC}"
        log "=== SOME TESTS FAILED ==="
        exit 1
    fi
}

# Run tests
main "$@"
