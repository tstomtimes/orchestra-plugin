#\!/usr/bin/env bash
set -euo pipefail
HOOK_NAME="${1:-}"
shift || true
if [ -z "$HOOK_NAME" ]; then echo "Error: Hook name required" >&2; exit 1; fi
if [ -n "${ORCHESTRA_ROOT:-}" ]; then HOOKS_DIR="$ORCHESTRA_ROOT/hooks"
else SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; HOOKS_DIR="$(cd "$SCRIPT_DIR/../../hooks" && pwd)"; fi
if [ \! -f "$HOOKS_DIR/$HOOK_NAME.sh" ]; then echo "Error: Hook \"$HOOK_NAME\" not found at $HOOKS_DIR/$HOOK_NAME.sh" >&2; exit 1; fi
bash "$HOOKS_DIR/$HOOK_NAME.sh" "$@"
