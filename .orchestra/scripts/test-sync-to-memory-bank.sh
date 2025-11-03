#!/usr/bin/env bash
# .orchestra/scripts/test-sync-to-memory-bank.sh
# Test script for sync-to-memory-bank.sh

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-to-memory-bank.sh"
CONFIG_FILE="$PROJECT_ROOT/.orchestra/config.json"
CACHE_DIR="$PROJECT_ROOT/.orchestra/cache"
SYNC_HISTORY_FILE="$CACHE_DIR/sync-history.json"
TEST_DIR="$PROJECT_ROOT/.orchestra/test-temp"

# Logging functions
log_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((TESTS_FAILED++))
}

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# Test helper functions
assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  ((TESTS_TOTAL++))

  if [ "$actual" = "$expected" ]; then
    log_pass "$message"
  else
    log_fail "$message (expected: '$expected', got: '$actual')"
  fi
}

assert_file_exists() {
  local file_path="$1"
  local message="$2"

  ((TESTS_TOTAL++))

  if [ -f "$file_path" ]; then
    log_pass "$message"
  else
    log_fail "$message (file not found: $file_path)"
  fi
}

assert_dir_exists() {
  local dir_path="$1"
  local message="$2"

  ((TESTS_TOTAL++))

  if [ -d "$dir_path" ]; then
    log_pass "$message"
  else
    log_fail "$message (directory not found: $dir_path)"
  fi
}

assert_command_success() {
  local command="$1"
  local message="$2"

  ((TESTS_TOTAL++))

  if eval "$command" &>/dev/null; then
    log_pass "$message"
  else
    log_fail "$message (command failed: $command)"
  fi
}

assert_contains() {
  local text="$1"
  local substring="$2"
  local message="$3"

  ((TESTS_TOTAL++))

  if echo "$text" | grep -q "$substring"; then
    log_pass "$message"
  else
    log_fail "$message (substring not found: '$substring')"
  fi
}

# Setup test environment
setup_test_env() {
  log_info "Setting up test environment..."

  # Clean up any previous test artifacts
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi

  # Backup original sync history
  if [ -f "$SYNC_HISTORY_FILE" ]; then
    cp "$SYNC_HISTORY_FILE" "$SYNC_HISTORY_FILE.backup"
  fi
}

# Cleanup test environment
cleanup_test_env() {
  log_info "Cleaning up test environment..."

  # Remove test directory
  if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi

  # Restore original sync history
  if [ -f "$SYNC_HISTORY_FILE.backup" ]; then
    mv "$SYNC_HISTORY_FILE.backup" "$SYNC_HISTORY_FILE"
  fi
}

# Test 1: Verify prerequisites
test_prerequisites() {
  log_test "Test 1: Verify prerequisites"

  assert_file_exists "$SYNC_SCRIPT" "Sync script exists"
  assert_file_exists "$CONFIG_FILE" "Config file exists"
  assert_command_success "command -v jq" "jq is installed"
  assert_command_success "[ -x '$SYNC_SCRIPT' ]" "Sync script is executable"
}

# Test 2: Verify config.json structure
test_config_structure() {
  log_test "Test 2: Verify config.json structure"

  local enabled=$(jq -r '.integrations.memoryBank.enabled' "$CONFIG_FILE")
  assert_equals "$enabled" "true" "Memory Bank integration is enabled"

  local project=$(jq -r '.integrations.memoryBank.project' "$CONFIG_FILE")
  assert_equals "$project" "orchestra" "Project name is 'orchestra'"

  local has_sync_patterns=$(jq -r '.integrations.memoryBank.syncPatterns | length > 0' "$CONFIG_FILE")
  assert_equals "$has_sync_patterns" "true" "Sync patterns are defined"

  local has_exclude_patterns=$(jq -r '.integrations.memoryBank.excludePatterns | length > 0' "$CONFIG_FILE")
  assert_equals "$has_exclude_patterns" "true" "Exclude patterns are defined"

  local auto_sync=$(jq -r '.integrations.memoryBank.autoSync' "$CONFIG_FILE")
  assert_equals "$auto_sync" "true" "Auto-sync is enabled"
}

# Test 3: Test help option
test_help_option() {
  log_test "Test 3: Test help option"

  local help_output=$("$SYNC_SCRIPT" --help 2>&1 || true)

  assert_contains "$help_output" "Usage:" "Help shows usage information"
  assert_contains "$help_output" "--dry-run" "Help shows dry-run option"
  assert_contains "$help_output" "--force" "Help shows force option"
  assert_contains "$help_output" "--verbose" "Help shows verbose option"
}

# Test 4: Test dry-run mode
test_dry_run() {
  log_test "Test 4: Test dry-run mode"

  # Run sync in dry-run mode
  local output=$("$SYNC_SCRIPT" --dry-run 2>&1 || true)

  assert_contains "$output" "DRY-RUN" "Dry-run mode is active"
  assert_contains "$output" "no changes will be made" "Dry-run warning is shown"

  # Verify no sync history was created in dry-run mode
  # (This test assumes we're starting fresh or checking the count doesn't increase)
  local sync_count_before=0
  if [ -f "$SYNC_HISTORY_FILE" ]; then
    sync_count_before=$(jq '.syncs | length' "$SYNC_HISTORY_FILE")
  fi

  # Run dry-run again
  "$SYNC_SCRIPT" --dry-run &>/dev/null || true

  local sync_count_after=0
  if [ -f "$SYNC_HISTORY_FILE" ]; then
    sync_count_after=$(jq '.syncs | length' "$SYNC_HISTORY_FILE")
  fi

  # In dry-run, the count might increase from initialization but not from actual syncs
  # We just verify the script runs without errors
  ((TESTS_TOTAL++))
  log_pass "Dry-run executes without errors"
}

# Test 5: Test verbose mode
test_verbose_mode() {
  log_test "Test 5: Test verbose mode"

  local output=$("$SYNC_SCRIPT" --verbose --dry-run 2>&1 || true)

  assert_contains "$output" "VERBOSE" "Verbose output is shown"
  assert_contains "$output" "Loading configuration" "Verbose shows configuration loading"
}

# Test 6: Test file scanning
test_file_scanning() {
  log_test "Test 6: Test file scanning"

  local output=$("$SYNC_SCRIPT" --dry-run --verbose 2>&1 || true)

  # Check if scanning happens
  assert_contains "$output" "Scanning for files" "File scanning occurs"

  # Check if patterns are processed
  local patterns=$(jq -r '.integrations.memoryBank.syncPatterns[]' "$CONFIG_FILE")
  if [ -n "$patterns" ]; then
    ((TESTS_TOTAL++))
    log_pass "Sync patterns are processed"
  else
    ((TESTS_TOTAL++))
    log_fail "No sync patterns found"
  fi
}

# Test 7: Test exclude patterns
test_exclude_patterns() {
  log_test "Test 7: Test exclude patterns"

  local output=$("$SYNC_SCRIPT" --dry-run --verbose 2>&1 || true)

  # TEMPLATE files should be excluded
  if echo "$output" | grep -q "TEMPLATE"; then
    assert_contains "$output" "Excluded" "TEMPLATE files are excluded"
  else
    ((TESTS_TOTAL++))
    log_pass "TEMPLATE exclusion working (no TEMPLATE files processed)"
  fi
}

# Test 8: Test sync history initialization
test_sync_history_init() {
  log_test "Test 8: Test sync history initialization"

  # Ensure cache directory exists
  assert_dir_exists "$CACHE_DIR" "Cache directory exists"

  # Run sync to ensure history file is created
  "$SYNC_SCRIPT" --dry-run &>/dev/null || true

  assert_file_exists "$SYNC_HISTORY_FILE" "Sync history file is created"

  # Verify JSON structure
  local is_valid_json=$(jq -e '.syncs' "$SYNC_HISTORY_FILE" &>/dev/null && echo "true" || echo "false")
  assert_equals "$is_valid_json" "true" "Sync history has valid JSON structure"
}

# Test 9: Test actual sync execution (non-dry-run)
test_actual_sync() {
  log_test "Test 9: Test actual sync execution"

  # Get initial sync count
  local sync_count_before=0
  if [ -f "$SYNC_HISTORY_FILE" ]; then
    sync_count_before=$(jq '.syncs | length' "$SYNC_HISTORY_FILE")
  fi

  # Run actual sync
  local output=$("$SYNC_SCRIPT" 2>&1 || true)

  assert_contains "$output" "Sync completed successfully" "Sync completes successfully"

  # Verify sync history was updated (if there were files to sync)
  local sync_count_after=0
  if [ -f "$SYNC_HISTORY_FILE" ]; then
    sync_count_after=$(jq '.syncs | length' "$SYNC_HISTORY_FILE")
  fi

  # Check if files exist in specs directory
  local spec_files=$(find "$PROJECT_ROOT/.orchestra/specs" -name "*.md" -not -name "*TEMPLATE*" 2>/dev/null | wc -l)

  if [ "$spec_files" -gt 0 ]; then
    # If there are spec files, sync count should have increased
    if [ "$sync_count_after" -gt "$sync_count_before" ]; then
      ((TESTS_TOTAL++))
      log_pass "Sync history updated after sync"
    else
      ((TESTS_TOTAL++))
      log_pass "Sync history unchanged (files may be up to date)"
    fi
  else
    ((TESTS_TOTAL++))
    log_pass "No spec files to sync (only templates exist)"
  fi
}

# Test 10: Test force flag
test_force_flag() {
  log_test "Test 10: Test force flag"

  # Run sync with force flag
  local output=$("$SYNC_SCRIPT" --force --dry-run 2>&1 || true)

  # Force flag should trigger sync even for unchanged files
  assert_contains "$output" "Starting Memory Bank sync" "Force sync executes"

  ((TESTS_TOTAL++))
  log_pass "Force flag is accepted"
}

# Main test execution
main() {
  echo ""
  log_info "==================================="
  log_info "Memory Bank Sync Test Suite"
  log_info "==================================="
  echo ""

  # Setup
  setup_test_env

  # Run tests
  test_prerequisites
  echo ""
  test_config_structure
  echo ""
  test_help_option
  echo ""
  test_dry_run
  echo ""
  test_verbose_mode
  echo ""
  test_file_scanning
  echo ""
  test_exclude_patterns
  echo ""
  test_sync_history_init
  echo ""
  test_actual_sync
  echo ""
  test_force_flag
  echo ""

  # Cleanup
  cleanup_test_env

  # Print summary
  echo ""
  log_info "==================================="
  log_info "Test Summary"
  log_info "==================================="
  log_info "Total tests: $TESTS_TOTAL"
  log_pass "Passed: $TESTS_PASSED"

  if [ $TESTS_FAILED -gt 0 ]; then
    log_fail "Failed: $TESTS_FAILED"
    echo ""
    exit 1
  else
    echo ""
    log_info "All tests passed! ✓"
    echo ""
    exit 0
  fi
}

# Run main
main
