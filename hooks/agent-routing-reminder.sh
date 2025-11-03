#!/usr/bin/env bash
# Agent Auto-Routing Reminder Hook
# Analyzes user prompts and injects routing reminders for specialized agents
#
# This hook enables automatic agent invocation by detecting keywords
# and triggering appropriate specialist agents

set -euo pipefail

# Get language setting from environment
LANG="${ORCHESTRA_LANGUAGE:-en}"

# Read JSON input from stdin
INPUT_JSON=$(cat)

# Extract user prompt from JSON
USER_PROMPT=$(echo "$INPUT_JSON" | jq -r '.prompt // empty' 2>/dev/null || echo "")

# If no prompt provided, exit silently
if [ -z "$USER_PROMPT" ]; then
    exit 0
fi

# Convert to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

# Track if any agent was matched
AGENT_MATCHED=false
MATCHED_AGENTS=()

# --- Priority 1: Ambiguous Requirements → Riley ---
if echo "$PROMPT_LOWER" | grep -qE "(fast|faster|slow|slower|easy to use|intuitive|clean|simple|improve performance|optimize|better)"; then
    MATCHED_AGENTS+=("Riley")
    AGENT_MATCHED=true
fi

# --- Priority 2: Major Feature Addition → Alex ---
if echo "$PROMPT_LOWER" | grep -qE "(add new|build new|implement new|create new|新しい.*追加|新規.*作成|作りたい|作る|build|make|開発したい)"; then
    if echo "$PROMPT_LOWER" | grep -qE "(system|feature|authentication|auth|認証|payment|決済|api|site|サイト|app|アプリ|website|ウェブサイト|service|サービス)"; then
        MATCHED_AGENTS+=("Alex")
        AGENT_MATCHED=true
    fi
fi

# Authentication specifically triggers Alex + Iris
if echo "$PROMPT_LOWER" | grep -qE "(authentication|auth|login|認証|ログイン|oauth|jwt|session)"; then
    if ! [[ " ${MATCHED_AGENTS[@]+"${MATCHED_AGENTS[@]}"} " =~ " Alex " ]]; then
        MATCHED_AGENTS+=("Alex")
        AGENT_MATCHED=true
    fi
fi

# --- Priority 3: UI/UX → Nova ---
if echo "$PROMPT_LOWER" | grep -qE "(ui|dashboard|ダッシュボード|component|コンポーネント|form|フォーム|design|デザイン|layout|responsive|accessibility|a11y|lighthouse|portfolio|ポートフォリオ|landing.*page|ランディング.*ページ|website|ウェブサイト|site.*design|サイト.*デザイン)"; then
    MATCHED_AGENTS+=("Nova")
    AGENT_MATCHED=true
fi

# --- Priority 4: Database → Leo ---
if echo "$PROMPT_LOWER" | grep -qE "(database|データベース|table|テーブル|schema|スキーマ|migration|マイグレーション|column|カラム|index|インデックス|rls)"; then
    MATCHED_AGENTS+=("Leo")
    AGENT_MATCHED=true
fi

# --- Priority 5: External Integration → Mina ---
if echo "$PROMPT_LOWER" | grep -qE "(stripe|paypal|shopify|aws|gcp|azure|oauth|webhook|api integration|統合)"; then
    MATCHED_AGENTS+=("Mina")
    AGENT_MATCHED=true
fi

# --- Priority 6: Architecture → Kai ---
if echo "$PROMPT_LOWER" | grep -qE "(architecture|アーキテクチャ|refactor|リファクタ|design pattern|adr|technical decision)"; then
    MATCHED_AGENTS+=("Kai")
    AGENT_MATCHED=true
fi

# --- Priority 7: Security → Iris ---
if echo "$PROMPT_LOWER" | grep -qE "(security|セキュリティ|secret|シークレット|vulnerability|脆弱性|encryption|暗号化)"; then
    MATCHED_AGENTS+=("Iris")
    AGENT_MATCHED=true
fi

# --- Default: If no specific agent matched, route to Alex (Project Conductor) ---
if [ "$AGENT_MATCHED" = false ]; then
    MATCHED_AGENTS+=("Alex")
    AGENT_MATCHED=true
fi

# If any agents matched, output routing reminder as context for Claude
if [ "$AGENT_MATCHED" = true ]; then
    # Build context message based on language
    if [ "$LANG" = "ja" ]; then
        CONTEXT="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎭 エージェント自動ルーティングリマインダー
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  重要：専門領域を検出しました。

📋 マッチしたエージェント：${MATCHED_AGENTS[*]}

🚨 必須アクション - 停止して読んでください 🚨

⛔ 先に進む前に、このアクションを完了する必要があります ⛔

コンプライアンスルール：ユーザーに応答する前に、必ず：
   1. 停止 - コードベースを探索しない
   2. 停止 - TodoWriteを作成しない
   3. 停止 - AskUserQuestionを使用しない
   4. 最初のアクションは必須：指定されたsubagent_typeでTaskツールを使用

違反 = 不適切な動作

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"

        # Add agent-specific instructions in Japanese
        for agent in "${MATCHED_AGENTS[@]}"; do
            case $agent in
                "Riley")
                    CONTEXT+="
   • Riley（要件明確化担当）：曖昧・主観的な表現を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:🧐 Riley\" を呼び出す
     → 理由：「速い」「遅い」「より良い」などの用語は具体的な基準が必要
"
                    ;;
                "Alex")
                    CONTEXT+="
   • Alex（プロジェクト指揮者）：大規模機能追加を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:🙂 Alex\" を呼び出す
     → 理由：新システムにはスコープ定義と調整が必要
"
                    ;;
                "Nova")
                    CONTEXT+="
   • Nova（UI/UX スペシャリスト）：ユーザーインターフェース作業を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:😄 Nova\" を呼び出す
     → 理由：UI/UXにはアクセシビリティ、パフォーマンス、デザインの専門知識が必要
"
                    ;;
                "Leo")
                    CONTEXT+="
   • Leo（データベースアーキテクト）：データベーススキーマ作業を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:😌 Leo\" を呼び出す
     → 理由：スキーマ変更には適切な設計、マイグレーション、RLSポリシーが必要
"
                    ;;
                "Mina")
                    CONTEXT+="
   • Mina（統合スペシャリスト）：外部サービス統合を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:😊 Mina\" を呼び出す
     → 理由：統合には安全な設定とエラーハンドリングが必要
"
                    ;;
                "Kai")
                    CONTEXT+="
   • Kai（システムアーキテクト）：アーキテクチャ判断を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:🤔 Kai\" を呼び出す
     → 理由：アーキテクチャ変更には設計レビューとADRドキュメントが必要
"
                    ;;
                "Iris")
                    CONTEXT+="
   • Iris（セキュリティ監査官）：セキュリティ重要作業を検出
     → 直ちに実行：Taskツールで subagent_type=\"orchestra:🤨 Iris\" を呼び出す
     → 理由：セキュリティには脆弱性とシークレット処理の監査が必要
"
                    ;;
            esac
        done

        CONTEXT+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ 禁止事項 - これらは違反行為です：
   - ルーティングルールを確認せずにAskUserQuestionを使用
   - 自分でコードベースを探索開始（Glob、Grep、Read）
   - TodoWriteを作成して自分で処理
   - Taskツール呼び出し前に他のツールを使用

✅ 代わりにこれを実行 - 必須のワークフロー：
   1. 最初に：Taskツールを使用して適切なエージェントを呼び出す
   2. 待機：専門エージェントに作業を任せる
   3. レビュー：彼らの出力を確認し、次のステップを調整
   4. その後：エージェントの指示に基づいて実装を進める

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 正しいワークフローの例：

ユーザー：「アプリに認証機能を追加して」

❌ 間違ったアプローチ：
   あなた：「まずコードベースを調べます...」
   [Glob/Grep/Readツールを使用]
   → これはルーティングルール違反です

✅ 正しいアプローチ：
   あなた：「この機能を調整するためにAlexを呼び出します」
   [使用：Taskツールで subagent_type=\"orchestra:🙂 Alex\"]
   [Alexの分析と推奨事項を待つ]
   [Alexの出力をレビュー]
   [Alexの指示に基づいて進める]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 最終リマインダー - 注意深く読んでください：
   → 最初のアクションは必ずTaskツール呼び出し
   → 例外なし。探索優先なし。質問優先なし。
   → これは提案ではなく、必須要件です

⛔ コンプライアンスチェック：応答する前に自問してください：
   □ 正しいsubagent_typeでTaskツールを呼び出しましたか？
   □ Taskツール前に他のツールを使用していませんか？
   □ 必須のワークフローに従っていますか？

上記のいずれかにNOと答えた場合は、停止して修正してください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    else
        CONTEXT="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎭 AGENT AUTO-ROUTING REMINDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  CRITICAL: Detected specialized domain in user request.

📋 Matched Agents: ${MATCHED_AGENTS[*]}

🚨 MANDATORY ACTION REQUIRED - STOP AND READ 🚨

⛔ YOU MUST COMPLETE THIS ACTION BEFORE PROCEEDING ⛔

COMPLIANCE RULE: Before responding to the user, you MUST:
   1. STOP - Do not explore codebase
   2. STOP - Do not create TodoWrite
   3. STOP - Do not use AskUserQuestion
   4. YOUR FIRST ACTION MUST BE: Use Task tool with specified subagent_type

FAILURE TO COMPLY = INCORRECT BEHAVIOR

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"

        # Add agent-specific instructions in English
        for agent in "${MATCHED_AGENTS[@]}"; do
            case $agent in
                "Riley")
                    CONTEXT+="
   • Riley (Clarifier): User request contains ambiguous/subjective language
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:🧐 Riley\"
     → Reason: Terms like 'fast', 'slow', 'better' require specific criteria
"
                    ;;
                "Alex")
                    CONTEXT+="
   • Alex (Project Conductor): Major feature addition detected
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:🙂 Alex\"
     → Reason: New systems need scope definition and coordination
"
                    ;;
                "Nova")
                    CONTEXT+="
   • Nova (UI/UX Specialist): User interface work detected
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:😄 Nova\"
     → Reason: UI/UX requires accessibility, performance, and design expertise
"
                    ;;
                "Leo")
                    CONTEXT+="
   • Leo (Database Architect): Database schema work detected
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:😌 Leo\"
     → Reason: Schema changes need proper design, migrations, and RLS policies
"
                    ;;
                "Mina")
                    CONTEXT+="
   • Mina (Integration Specialist): External service integration detected
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:😊 Mina\"
     → Reason: Integrations require secure config and error handling
"
                    ;;
                "Kai")
                    CONTEXT+="
   • Kai (System Architect): Architectural decision detected
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:🤔 Kai\"
     → Reason: Architecture changes need design review and ADR documentation
"
                    ;;
                "Iris")
                    CONTEXT+="
   • Iris (Security Auditor): Security-critical work detected
     → IMMEDIATELY invoke: Task tool with subagent_type=\"orchestra:🤨 Iris\"
     → Reason: Security requires audit for vulnerabilities and secret handling
"
                    ;;
            esac
        done

        CONTEXT+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ DO NOT - These actions are VIOLATIONS:
   - Use AskUserQuestion without checking routing rules
   - Start exploring codebase yourself (Glob, Grep, Read)
   - Create TodoWrite and handle it yourself
   - Use any other tool before Task tool invocation

✅ DO THIS INSTEAD - REQUIRED WORKFLOW:
   1. FIRST: Use the Task tool to invoke the appropriate agent(s)
   2. WAIT: Let the specialist agent handle the work
   3. REVIEW: Examine their output and coordinate next steps
   4. THEN: Proceed with implementation based on agent guidance

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 CORRECT WORKFLOW EXAMPLE:

User: \"Add authentication to my app\"

❌ WRONG APPROACH:
   You: \"Let me explore the codebase first...\"
   [Uses Glob/Grep/Read tools]
   → This violates the routing rules

✅ CORRECT APPROACH:
   You: \"I'll invoke Alex to coordinate this feature.\"
   [Uses: Task tool with subagent_type=\"orchestra:🙂 Alex\"]
   [Waits for Alex's analysis and recommendations]
   [Reviews Alex's output]
   [Proceeds based on Alex's guidance]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 FINAL REMINDER - Read this carefully:
   → Your FIRST action MUST be Task tool invocation
   → NO exceptions. NO exploration first. NO questions first.
   → This is a MANDATORY requirement, not a suggestion

⛔ COMPLIANCE CHECK: Before you respond, ask yourself:
   □ Did I invoke the Task tool with the correct subagent_type?
   □ Did I avoid using other tools before Task tool?
   □ Am I following the required workflow?

If you answered NO to any question above, STOP and fix it.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
    fi

    # Store routing requirement for PreToolUse compliance check
    # This allows downstream hooks to verify compliance
    TEMP_DIR="${TMPDIR:-/tmp}"
    ROUTING_FLAG="$TEMP_DIR/orchestra_routing_reminder_$$"
    echo "${MATCHED_AGENTS[0]}" > "$ROUTING_FLAG"

    # Set expiration (clean up after 5 minutes)
    (sleep 300 && rm -f "$ROUTING_FLAG" 2>/dev/null) &

    # Output JSON format for Claude's context
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $(echo "$CONTEXT" | jq -Rs .)
  }
}
EOF
fi

# Always approve (exit 0) - we're just adding reminders, not blocking
exit 0
