#!/usr/bin/env bash
# .orchestra/scripts/sync-to-memory-bank.sh
# Sync .orchestra/specs/ documents to Memory Bank

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/.orchestra/config.json"
CACHE_DIR="$PROJECT_ROOT/.orchestra/cache"
SYNC_HISTORY_FILE="$CACHE_DIR/sync-history.json"
SPECS_DIR="$PROJECT_ROOT/.orchestra/specs"

# Parse command line arguments
DRY_RUN=false
FORCE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Sync .orchestra/specs/ documents to Memory Bank"
      echo ""
      echo "OPTIONS:"
      echo "  --dry-run     Show what would be synced without making changes"
      echo "  --force       Force overwrite existing files even if unchanged"
      echo "  --verbose,-v  Show detailed output"
      echo "  --help,-h     Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}[VERBOSE]${NC} $1"
  fi
}

# Check prerequisites
check_prerequisites() {
  log_verbose "Checking prerequisites..."

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    log_error "jq is not installed. Please install it: brew install jq"
    exit 1
  fi

  # Check if config file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
  fi

  # Check if specs directory exists
  if [ ! -d "$SPECS_DIR" ]; then
    log_error "Specs directory not found: $SPECS_DIR"
    exit 1
  fi

  # Create cache directory if it doesn't exist
  mkdir -p "$CACHE_DIR"

  # Initialize sync history if it doesn't exist
  if [ ! -f "$SYNC_HISTORY_FILE" ]; then
    echo '{"syncs": []}' > "$SYNC_HISTORY_FILE"
  fi

  log_verbose "Prerequisites check passed"
}

# Load configuration from config.json
load_config() {
  log_verbose "Loading configuration from $CONFIG_FILE..."

  # Check if Memory Bank integration is enabled
  ENABLED=$(jq -r '.integrations.memoryBank.enabled // false' "$CONFIG_FILE")
  if [ "$ENABLED" != "true" ]; then
    log_warn "Memory Bank integration is disabled in config.json"
    exit 0
  fi

  # Load project name
  PROJECT_NAME=$(jq -r '.integrations.memoryBank.project // "orchestra"' "$CONFIG_FILE")
  log_verbose "Memory Bank project: $PROJECT_NAME"

  # Load sync patterns
  SYNC_PATTERNS=$(jq -r '.integrations.memoryBank.syncPatterns[]?' "$CONFIG_FILE")
  if [ -z "$SYNC_PATTERNS" ]; then
    log_warn "No sync patterns defined in config.json"
    exit 0
  fi

  # Load exclude patterns
  EXCLUDE_PATTERNS=$(jq -r '.integrations.memoryBank.excludePatterns[]?' "$CONFIG_FILE")

  log_verbose "Configuration loaded successfully"
}

# Check if a file matches exclude patterns
is_excluded() {
  local file_path="$1"
  local file_name=$(basename "$file_path")

  # Check each exclude pattern
  while IFS= read -r pattern; do
    if [ -z "$pattern" ]; then
      continue
    fi

    # Convert glob pattern to regex-like matching
    # **/*TEMPLATE*.md -> *TEMPLATE*.md
    pattern=$(echo "$pattern" | sed 's|^\*\*/||')

    case "$file_name" in
      $pattern)
        return 0  # File is excluded
        ;;
    esac
  done <<< "$EXCLUDE_PATTERNS"

  return 1  # File is not excluded
}

# Get file checksum for change detection
get_file_checksum() {
  local file_path="$1"

  if [ -f "$file_path" ]; then
    if command -v md5 &> /dev/null; then
      md5 -q "$file_path"
    elif command -v md5sum &> /dev/null; then
      md5sum "$file_path" | awk '{print $1}'
    else
      # Fallback to file size + modification time
      stat -f "%z-%m" "$file_path" 2>/dev/null || stat -c "%s-%Y" "$file_path"
    fi
  else
    echo ""
  fi
}

# Find files matching sync patterns
find_sync_files() {
  log_verbose "Scanning for files to sync..." >&2

  local files=()

  # Process each sync pattern
  while IFS= read -r pattern; do
    if [ -z "$pattern" ]; then
      continue
    fi

    log_verbose "Processing pattern: $pattern" >&2

    # Convert pattern to find command
    # .orchestra/specs/requirements/*.md -> find .orchestra/specs/requirements -name "*.md"
    local dir_pattern=$(dirname "$pattern")
    local file_pattern=$(basename "$pattern")
    local search_dir="$PROJECT_ROOT/$dir_pattern"

    if [ ! -d "$search_dir" ]; then
      log_verbose "Directory not found: $search_dir" >&2
      continue
    fi

    # Find matching files
    while IFS= read -r file; do
      if [ -f "$file" ]; then
        # Check if file is excluded
        if is_excluded "$file"; then
          log_verbose "Excluded: $file" >&2
        else
          # Check file size (skip files > 1MB)
          local file_size=$(stat -f "%z" "$file" 2>/dev/null || stat -c "%s" "$file")
          if [ "$file_size" -gt 1048576 ]; then
            log_warn "Skipping large file (>1MB): $file" >&2
          else
            files+=("$file")
            log_verbose "Found: $file" >&2
          fi
        fi
      fi
    done < <(find "$search_dir" -name "$file_pattern" -type f)

  done <<< "$SYNC_PATTERNS"

  # Return unique files
  if [ ${#files[@]} -gt 0 ]; then
    printf '%s\n' "${files[@]}" | sort -u
  fi
}

# Get relative path from specs directory
get_relative_path() {
  local file_path="$1"
  echo "$file_path" | sed "s|^$SPECS_DIR/||"
}

# Sync a file to Memory Bank
sync_file() {
  local file_path="$1"
  local relative_path=$(get_relative_path "$file_path")
  local file_name=$(basename "$file_path")

  log_verbose "Syncing: $relative_path"

  # Read file content
  local content
  if ! content=$(cat "$file_path" 2>&1); then
    log_error "Failed to read file: $file_path"
    return 1
  fi

  # Get file checksum
  local checksum=$(get_file_checksum "$file_path")

  # Check sync history
  local last_checksum=$(jq -r --arg file "$relative_path" '.syncs[] | select(.file == $file) | .checksum // ""' "$SYNC_HISTORY_FILE" | tail -1)

  # Determine if sync is needed
  local should_sync=true
  if [ "$FORCE" = false ] && [ -n "$last_checksum" ] && [ "$last_checksum" = "$checksum" ]; then
    log_verbose "File unchanged, skipping: $relative_path"
    should_sync=false
  fi

  if [ "$should_sync" = true ]; then
    if [ "$DRY_RUN" = true ]; then
      echo -e "${YELLOW}[DRY-RUN]${NC} Would sync: $relative_path"
    else
      log_info "Syncing to Memory Bank: $relative_path"

      # Convert relative path to Memory Bank filename format
      # Example: requirements/REQ-001.md -> requirements-REQ-001.md
      local mb_filename=$(echo "$relative_path" | sed 's|/|-|g')
      local mb_path="$HOME/memory-bank/$PROJECT_NAME/$mb_filename"

      # Ensure Memory Bank directory exists
      mkdir -p "$(dirname "$mb_path")"

      # Write content to Memory Bank
      if ! echo "$content" > "$mb_path"; then
        log_error "Failed to write to Memory Bank: $mb_path"
        return 1
      fi

      log_verbose "Written to Memory Bank: $mb_path"

      # Verify file was written successfully
      if [ ! -f "$mb_path" ]; then
        log_error "File verification failed: $mb_path"
        return 1
      fi

      # Record sync in history
      local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      local sync_record=$(jq -n \
        --arg file "$relative_path" \
        --arg checksum "$checksum" \
        --arg timestamp "$timestamp" \
        --arg action "sync" \
        '{file: $file, checksum: $checksum, timestamp: $timestamp, action: $action}')

      # Update sync history
      local updated_history=$(jq --argjson record "$sync_record" '.syncs += [$record]' "$SYNC_HISTORY_FILE")
      echo "$updated_history" > "$SYNC_HISTORY_FILE"

      log_verbose "Sync history updated for: $relative_path"
      return 0
    fi
  fi

  return 0
}

# Main sync process
main() {
  log_info "Starting Memory Bank sync..."

  if [ "$DRY_RUN" = true ]; then
    log_warn "Running in DRY-RUN mode - no changes will be made"
  fi

  # Check prerequisites
  check_prerequisites

  # Load configuration
  load_config

  # Find files to sync
  log_info "Scanning for files matching sync patterns..."
  local sync_files=()
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      sync_files+=("$file")
    fi
  done < <(find_sync_files)

  if [ ${#sync_files[@]} -eq 0 ]; then
    log_warn "No files found to sync"
    exit 0
  fi

  log_info "Found ${#sync_files[@]} file(s) to process"

  # Sync each file
  local synced_count=0
  local skipped_count=0
  local error_count=0

  for file in "${sync_files[@]}"; do
    if sync_file "$file"; then
      ((synced_count++))
    else
      ((error_count++))
    fi
  done

  # Print summary
  echo ""
  log_info "=== Sync Summary ==="
  log_info "Total files processed: ${#sync_files[@]}"
  log_success "Successfully synced: $synced_count"

  if [ "$error_count" -gt 0 ]; then
    log_error "Errors encountered: $error_count"
  fi

  if [ "$DRY_RUN" = true ]; then
    log_warn "DRY-RUN mode - no actual changes were made"
  else
    log_success "Sync completed successfully!"
  fi

  exit 0
}

# Run main function
main
