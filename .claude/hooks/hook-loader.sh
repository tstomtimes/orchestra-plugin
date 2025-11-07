#!/usr/bin/env bash
# Hook Loader - Resolves hook paths correctly from any working directory
# Usage: bash hook-loader.sh <hook_name> [args...]
# Environment Variables:
#   ORCHESTRA_ROOT - Optional: Path to orchestra project root (overrides auto-detection)

set -euo pipefail

HOOK_NAME="${1:-}"
shift || true

if [ -z "$HOOK_NAME" ]; then
  echo "Error: Hook name required" >&2
  exit 1
fi

# Determine the orchestra project root
if [ -n "${ORCHESTRA_ROOT:-}" ]; then
  # Use environment variable if set (useful for cross-project plugin loading)
  HOOKS_DIR="$ORCHESTRA_ROOT/hooks"
else
  # Auto-detect based on this script's location
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  HOOKS_DIR="$(cd "$SCRIPT_DIR/../../hooks" && pwd)"
fi

if [ ! -f "$HOOKS_DIR/$HOOK_NAME.sh" ]; then
  echo "Error: Hook '$HOOK_NAME' not found at $HOOKS_DIR/$HOOK_NAME.sh" >&2
  echo "  Current ORCHESTRA_ROOT: ${ORCHESTRA_ROOT:-not set}" >&2
  echo "  Resolved HOOKS_DIR: $HOOKS_DIR" >&2
  exit 1
fi

# Execute the hook with all arguments
bash "$HOOKS_DIR/$HOOK_NAME.sh" "$@"
