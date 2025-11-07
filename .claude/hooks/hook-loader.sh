#!/usr/bin/env bash
# Hook Loader - Resolves hook paths correctly from any working directory
# Usage: bash hook-loader.sh <hook_name> [args...]

set -euo pipefail

HOOK_NAME="${1:-}"
shift || true

if [ -z "$HOOK_NAME" ]; then
  echo "Error: Hook name required" >&2
  exit 1
fi

# Resolve the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../../hooks" && pwd)"

if [ ! -f "$HOOKS_DIR/$HOOK_NAME.sh" ]; then
  echo "Error: Hook '$HOOK_NAME' not found at $HOOKS_DIR/$HOOK_NAME.sh" >&2
  exit 1
fi

# Execute the hook with all arguments
bash "$HOOKS_DIR/$HOOK_NAME.sh" "$@"
