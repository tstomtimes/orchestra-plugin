#!/usr/bin/env bash
# Test Script for Memory Bank Initialization
# Validates that init-memory-bank.sh works correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MEMORY_BANK_ROOT="${HOME}/memory-bank"
PROJECT_NAME="orchestra"
PROJECT_DIR="${MEMORY_BANK_ROOT}/${PROJECT_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="${SCRIPT_DIR}/init-memory-bank.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function: Print test header
test_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test: ${1}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function: Assert condition
assert() {
    local description="$1"
    local condition="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if eval "$condition"; then
        echo -e "${GREEN}✓ PASS:${NC} ${description}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL:${NC} ${description}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function: Cleanup test environment
cleanup_test_env() {
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}Cleaning up test environment...${NC}"
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
}

# Test 1: Verify init script exists and is executable
test_script_exists() {
    test_header "Script Existence and Permissions"

    assert "Init script exists" "[ -f '$INIT_SCRIPT' ]"
    assert "Init script is executable" "[ -x '$INIT_SCRIPT' ]"
}

# Test 2: New environment setup
test_new_environment_setup() {
    test_header "New Environment Setup"

    # Clean environment
    cleanup_test_env

    # Run init script
    echo -e "${BLUE}Running init-memory-bank.sh...${NC}"
    if bash "$INIT_SCRIPT" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Script executed successfully${NC}"
    else
        echo -e "${RED}✗ Script execution failed${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    # Verify directory creation
    assert "Memory Bank root directory created" "[ -d '$MEMORY_BANK_ROOT' ]"
    assert "Project directory created" "[ -d '$PROJECT_DIR' ]"

    # Verify all template files exist
    assert "project-overview.md exists" "[ -f '$PROJECT_DIR/project-overview.md' ]"
    assert "tech-stack.md exists" "[ -f '$PROJECT_DIR/tech-stack.md' ]"
    assert "decisions.md exists" "[ -f '$PROJECT_DIR/decisions.md' ]"
    assert "progress.md exists" "[ -f '$PROJECT_DIR/progress.md' ]"
    assert "next-steps.md exists" "[ -f '$PROJECT_DIR/next-steps.md' ]"
}

# Test 3: File content validation
test_file_contents() {
    test_header "File Content Validation"

    # Check project-overview.md
    assert "project-overview.md contains project name" \
        "grep -q 'orchestra' '$PROJECT_DIR/project-overview.md'"
    assert "project-overview.md contains creation timestamp" \
        "grep -q 'Created:' '$PROJECT_DIR/project-overview.md'"
    assert "project-overview.md is not empty" \
        "[ -s '$PROJECT_DIR/project-overview.md' ]"

    # Check tech-stack.md
    assert "tech-stack.md contains TypeScript" \
        "grep -q 'TypeScript' '$PROJECT_DIR/tech-stack.md'"
    assert "tech-stack.md contains Node.js" \
        "grep -q 'Node.js' '$PROJECT_DIR/tech-stack.md'"
    assert "tech-stack.md is not empty" \
        "[ -s '$PROJECT_DIR/tech-stack.md' ]"

    # Check decisions.md
    assert "decisions.md contains decision log" \
        "grep -q 'Decision Log' '$PROJECT_DIR/decisions.md'"
    assert "decisions.md is not empty" \
        "[ -s '$PROJECT_DIR/decisions.md' ]"

    # Check progress.md
    assert "progress.md contains milestones" \
        "grep -q 'Milestones' '$PROJECT_DIR/progress.md'"
    assert "progress.md is not empty" \
        "[ -s '$PROJECT_DIR/progress.md' ]"

    # Check next-steps.md
    assert "next-steps.md contains immediate actions" \
        "grep -q 'Immediate Actions' '$PROJECT_DIR/next-steps.md'"
    assert "next-steps.md is not empty" \
        "[ -s '$PROJECT_DIR/next-steps.md' ]"
}

# Test 4: File permissions
test_file_permissions() {
    test_header "File Permissions"

    local files=(
        "project-overview.md"
        "tech-stack.md"
        "decisions.md"
        "progress.md"
        "next-steps.md"
    )

    for file in "${files[@]}"; do
        assert "$file is readable" "[ -r '$PROJECT_DIR/$file' ]"
        assert "$file is writable" "[ -w '$PROJECT_DIR/$file' ]"
    done
}

# Test 5: Existing project protection
test_existing_project_protection() {
    test_header "Existing Project Protection"

    # Project should already exist from previous tests
    local file_count_before=$(ls -1 "$PROJECT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

    echo -e "${BLUE}Running init script on existing project...${NC}"
    bash "$INIT_SCRIPT" > /dev/null 2>&1 || true

    local file_count_after=$(ls -1 "$PROJECT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')

    assert "File count unchanged (no overwrite)" \
        "[ '$file_count_before' -eq '$file_count_after' ]"
    assert "Files still exist after second run" \
        "[ -f '$PROJECT_DIR/project-overview.md' ]"
}

# Test 6: Template file structure
test_template_structure() {
    test_header "Template File Structure"

    # Check for required sections in project-overview.md
    assert "project-overview.md has Purpose section" \
        "grep -q '## Purpose' '$PROJECT_DIR/project-overview.md'"
    assert "project-overview.md has Current State section" \
        "grep -q '## Current State' '$PROJECT_DIR/project-overview.md'"
    assert "project-overview.md has Goals section" \
        "grep -q '## Goals' '$PROJECT_DIR/project-overview.md'"

    # Check for required sections in tech-stack.md
    assert "tech-stack.md has Core Technologies section" \
        "grep -q '## Core Technologies' '$PROJECT_DIR/tech-stack.md'"
    assert "tech-stack.md has MCP Servers section" \
        "grep -q '## MCP Servers' '$PROJECT_DIR/tech-stack.md'"

    # Check for required sections in decisions.md
    assert "decisions.md has Decision Log section" \
        "grep -q '## Decision Log' '$PROJECT_DIR/decisions.md'"
    assert "decisions.md has template" \
        "grep -q 'Decision Template' '$PROJECT_DIR/decisions.md'"

    # Check for required sections in progress.md
    assert "progress.md has Current Sprint section" \
        "grep -q '## Current Sprint' '$PROJECT_DIR/progress.md'"
    assert "progress.md has Milestones section" \
        "grep -q '## Milestones' '$PROJECT_DIR/progress.md'"

    # Check for required sections in next-steps.md
    assert "next-steps.md has Immediate Actions section" \
        "grep -q '## Immediate Actions' '$PROJECT_DIR/next-steps.md'"
    assert "next-steps.md has Short-term Goals section" \
        "grep -q '## Short-term Goals' '$PROJECT_DIR/next-steps.md'"
}

# Test 7: Timestamp validation
test_timestamps() {
    test_header "Timestamp Validation"

    local current_year=$(date +%Y)

    assert "project-overview.md has current year in timestamp" \
        "grep -q '$current_year' '$PROJECT_DIR/project-overview.md'"
    assert "tech-stack.md has current year in timestamp" \
        "grep -q '$current_year' '$PROJECT_DIR/tech-stack.md'"
    assert "decisions.md has current year in timestamp" \
        "grep -q '$current_year' '$PROJECT_DIR/decisions.md'"
    assert "progress.md has current year in timestamp" \
        "grep -q '$current_year' '$PROJECT_DIR/progress.md'"
    assert "next-steps.md has current year in timestamp" \
        "grep -q '$current_year' '$PROJECT_DIR/next-steps.md'"
}

# Test 8: Memory Bank integration readiness
test_memory_bank_integration() {
    test_header "Memory Bank Integration Readiness"

    # Verify file count matches expected
    local file_count=$(ls -1 "$PROJECT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
    assert "Exactly 5 template files created" "[ '$file_count' -eq 5 ]"

    # Verify directory is in correct location
    assert "Directory in ~/memory-bank/" \
        "[ '$PROJECT_DIR' = '${HOME}/memory-bank/orchestra' ]"

    # Verify files are Markdown format
    for file in "$PROJECT_DIR"/*.md; do
        assert "$(basename "$file") is valid Markdown" \
            "grep -q '^#' '$file'"
    done
}

# Display test summary
display_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Total Tests:${NC}   ${TESTS_RUN}"
    echo -e "${GREEN}Passed:${NC}        ${TESTS_PASSED}"
    echo -e "${RED}Failed:${NC}        ${TESTS_FAILED}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ All tests passed!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}❌ Some tests failed!${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🧪 Memory Bank Initialization Test Suite${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Run all tests
    test_script_exists
    test_new_environment_setup
    test_file_contents
    test_file_permissions
    test_existing_project_protection
    test_template_structure
    test_timestamps
    test_memory_bank_integration

    # Display summary
    display_summary
}

# Run main function
main
exit $?
