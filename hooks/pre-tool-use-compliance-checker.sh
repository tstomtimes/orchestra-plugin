#!/usr/bin/env bash
# Agent Routing Compliance Checker
# Enforces agent routing rules by checking if Task tool was called first
#
# This hook ensures Claude follows the mandatory routing workflow

set -euo pipefail

# Get language setting from environment
LANG="${ORCHESTRA_LANGUAGE:-en}"

# Read JSON input from stdin
INPUT_JSON=$(cat)

# Extract tool details from JSON
TOOL_NAME=$(echo "$INPUT_JSON" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

# Get the routing flag for this process
TEMP_DIR="${TMPDIR:-/tmp}"
ROUTING_FLAG="$TEMP_DIR/orchestra_routing_reminder_$$"

# Check if routing reminder is active
if [ -f "$ROUTING_FLAG" ]; then
    REQUIRED_AGENT=$(cat "$ROUTING_FLAG")

    # If routing reminder is active and tool is NOT Task, warn Claude
    if [ "$TOOL_NAME" != "Task" ]; then
        # Build warning message based on language
        if [ "$LANG" = "ja" ]; then
            cat <<EOF
⚠️  ルーティングコンプライアンス違反検出 ⚠️

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

あなたは最初に $REQUIRED_AGENT エージェントを呼び出すよう指示されました。
代わりに、$TOOL_NAME ツールを使用しようとしています。

🚨 必須アクション：
   1. 現在のツール使用をキャンセル
   2. 代わりに：Taskツールで subagent_type="orchestra:$REQUIRED_AGENT" を使用
   3. エージェントの分析を待つ
   4. エージェントの推奨に基づいて進める

これはルーティングルールに従うためのリマインダーです。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        else
            cat <<EOF
⚠️  ROUTING COMPLIANCE VIOLATION DETECTED ⚠️

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You were instructed to invoke the $REQUIRED_AGENT agent FIRST.
Instead, you attempted to use the $TOOL_NAME tool.

🚨 REQUIRED ACTION:
   1. Cancel current tool use
   2. Instead: Use Task tool with subagent_type="orchestra:$REQUIRED_AGENT"
   3. Wait for the agent's analysis
   4. Proceed based on agent's recommendations

This is your reminder to follow the routing rules.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
        fi

        # Log the violation (for analytics/debugging)
        VIOLATIONS_LOG="$TEMP_DIR/orchestra_violations_$$"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Violation: $TOOL_NAME (Expected: Task with $REQUIRED_AGENT)" >> "$VIOLATIONS_LOG"

        # Don't block (for now), just warn
        # To block, use: exit 1
        exit 0

    else
        # Task tool was used - check if it's the correct agent
        SUBAGENT_TYPE=$(echo "$INPUT_JSON" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || echo "")

        if echo "$SUBAGENT_TYPE" | grep -q "$REQUIRED_AGENT"; then
            # Correct agent called - clear the flag
            rm -f "$ROUTING_FLAG"

            if [ "$LANG" = "ja" ]; then
                echo "✅ コンプライアンスチェック通過：正しいエージェントが呼び出されました"
            else
                echo "✅ Compliance check passed: Correct agent invoked"
            fi
        else
            # Wrong agent - warn
            if [ "$LANG" = "ja" ]; then
                cat <<EOF
⚠️ 警告：間違ったエージェントが呼び出されました

期待：$REQUIRED_AGENT を含むsubagent_type
実際：$SUBAGENT_TYPE

正しいエージェントを呼び出していることを確認してください。
EOF
            else
                cat <<EOF
⚠️ Warning: Wrong agent invoked

Expected: subagent_type containing $REQUIRED_AGENT
Got: $SUBAGENT_TYPE

Please ensure you are invoking the correct agent.
EOF
            fi
        fi
    fi
fi

# Always approve (we're just adding warnings, not blocking)
exit 0
