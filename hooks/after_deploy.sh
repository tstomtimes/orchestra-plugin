# hooks/after_deploy.sh
#!/usr/bin/env bash
set -euo pipefail

# Get language setting from environment
LANG="${ORCHESTRA_LANGUAGE:-en}"

if [ "$LANG" = "ja" ]; then
  echo "[after_deploy] スモークテスト & ロールバック準備..."
else
  echo "[after_deploy] Smoke tests & rollback readiness..."
fi

DEPLOY_ENV="${DEPLOY_ENV:-production}"
DEPLOY_URL="${DEPLOY_URL:-https://app.example.com}"
ROLLOUT_STATUS_FILE="rollout-status.md"

if [ "$LANG" = "ja" ]; then
  echo "→ デプロイ環境：$DEPLOY_ENV"
  echo "→ デプロイURL：$DEPLOY_URL"
else
  echo "→ Deployment environment: $DEPLOY_ENV"
  echo "→ Deployment URL: $DEPLOY_URL"
fi

# Wait for deployment to be ready
if [ "$LANG" = "ja" ]; then
  echo "→ デプロイの安定化を待機中..."
else
  echo "→ Waiting for deployment to stabilize..."
fi
sleep 10

# Smoke tests - Critical path validation
if [ "$LANG" = "ja" ]; then
  echo "→ スモークテスト実行中..."
else
  echo "→ Running smoke tests..."
fi

smoke_test_failed=false

# Test 1: Health endpoint
if [ "$LANG" = "ja" ]; then
  echo "  • ヘルスエンドポイントをテスト中..."
else
  echo "  • Testing health endpoint..."
fi

if curl -f -s --max-time 10 "$DEPLOY_URL/health" > /dev/null 2>&1; then
  if [ "$LANG" = "ja" ]; then
    echo "    ✅ ヘルスエンドポイントが応答"
  else
    echo "    ✅ Health endpoint responsive"
  fi
else
  if [ "$LANG" = "ja" ]; then
    echo "    ❌ ヘルスエンドポイントが失敗"
  else
    echo "    ❌ Health endpoint failed"
  fi
  smoke_test_failed=true
fi

# Test 2: API endpoints
if [ "$LANG" = "ja" ]; then
  echo "  • APIエンドポイントをテスト中..."
else
  echo "  • Testing API endpoints..."
fi

if curl -f -s --max-time 10 "$DEPLOY_URL/api/status" > /dev/null 2>&1; then
  if [ "$LANG" = "ja" ]; then
    echo "    ✅ APIエンドポイントが応答"
  else
    echo "    ✅ API endpoints responsive"
  fi
else
  if [ "$LANG" = "ja" ]; then
    echo "    ❌ APIエンドポイントが失敗"
  else
    echo "    ❌ API endpoints failed"
  fi
  smoke_test_failed=true
fi

# Test 3: Database connectivity
if [ "$LANG" = "ja" ]; then
  echo "  • データベース接続性をテスト中..."
else
  echo "  • Testing database connectivity..."
fi

if curl -f -s --max-time 10 "$DEPLOY_URL/api/db-check" > /dev/null 2>&1; then
  if [ "$LANG" = "ja" ]; then
    echo "    ✅ データベース接続性を確認"
  else
    echo "    ✅ Database connectivity verified"
  fi
else
  if [ "$LANG" = "ja" ]; then
    echo "    ❌ データベース接続性が失敗"
  else
    echo "    ❌ Database connectivity failed"
  fi
  smoke_test_failed=true
fi

# Test 4: Authentication flow (if applicable)
if [ -n "${AUTH_TEST_TOKEN:-}" ]; then
  if [ "$LANG" = "ja" ]; then
    echo "  • 認証をテスト中..."
  else
    echo "  • Testing authentication..."
  fi

  if curl -f -s --max-time 10 -H "Authorization: Bearer $AUTH_TEST_TOKEN" "$DEPLOY_URL/api/me" > /dev/null 2>&1; then
    if [ "$LANG" = "ja" ]; then
      echo "    ✅ 認証が機能"
    else
      echo "    ✅ Authentication working"
    fi
  else
    if [ "$LANG" = "ja" ]; then
      echo "    ❌ 認証が失敗"
    else
      echo "    ❌ Authentication failed"
    fi
    smoke_test_failed=true
  fi
fi

# Generate rollout status report
if [ "$LANG" = "ja" ]; then
  echo "→ ロールアウトステータスレポート生成中..."
else
  echo "→ Generating rollout status report..."
fi

if [ "$LANG" = "ja" ]; then
  cat > "$ROLLOUT_STATUS_FILE" <<EOF
# デプロイロールアウトステータス

**環境：** $DEPLOY_ENV
**デプロイURL：** $DEPLOY_URL
**タイムスタンプ：** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**デプロイ実行者：** ${USER:-unknown}
**Gitコミット：** $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
**Gitブランチ：** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

## スモークテスト結果

| テスト | ステータス |
|------|--------|
| ヘルスエンドポイント | $(curl -f -s --max-time 5 "$DEPLOY_URL/health" > /dev/null 2>&1 && echo "✅ 合格" || echo "❌ 不合格") |
| APIエンドポイント | $(curl -f -s --max-time 5 "$DEPLOY_URL/api/status" > /dev/null 2>&1 && echo "✅ 合格" || echo "❌ 不合格") |
| データベース接続性 | $(curl -f -s --max-time 5 "$DEPLOY_URL/api/db-check" > /dev/null 2>&1 && echo "✅ 合格" || echo "❌ 不合格") |

## ロールバック手順

問題が検出された場合、以下でロールバック：

\`\`\`bash
# Vercel
vercel rollback <deployment-url>

# Kubernetes
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Docker / Docker Compose
docker-compose down && git checkout <previous-commit> && docker-compose up -d

# Heroku
heroku releases:rollback -a <app-name>
\`\`\`

## 監視

- **ログ：** \`kubectl logs -f deployment/<name>\` またはロギングサービスを確認
- **メトリクス：** Datadog/Grafana/CloudWatchダッシュボードを確認
- **エラー：** Sentry/エラートラッキングサービスを監視
- **パフォーマンス：** レスポンスタイムとエラー率を確認

## 次のステップ

- [ ] 今後30分間エラー率を監視
- [ ] ユーザー向け機能を手動確認
- [ ] アナリティクス/トラッキングが機能していることを確認
- [ ] チームチャンネルでデプロイをアナウンス
- [ ] リリースノートを更新

---

**ステータス：** $(if [ "$smoke_test_failed" = false ]; then echo "✅ デプロイ成功"; else echo "❌ デプロイ失敗 - ロールバック検討"; fi)
EOF
else
  cat > "$ROLLOUT_STATUS_FILE" <<EOF
# Deployment Rollout Status

**Environment:** $DEPLOY_ENV
**Deployment URL:** $DEPLOY_URL
**Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Deployed By:** ${USER:-unknown}
**Git Commit:** $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
**Git Branch:** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

## Smoke Test Results

| Test | Status |
|------|--------|
| Health Endpoint | $(curl -f -s --max-time 5 "$DEPLOY_URL/health" > /dev/null 2>&1 && echo "✅ Pass" || echo "❌ Fail") |
| API Endpoints | $(curl -f -s --max-time 5 "$DEPLOY_URL/api/status" > /dev/null 2>&1 && echo "✅ Pass" || echo "❌ Fail") |
| Database Connectivity | $(curl -f -s --max-time 5 "$DEPLOY_URL/api/db-check" > /dev/null 2>&1 && echo "✅ Pass" || echo "❌ Fail") |

## Rollback Procedure

If issues are detected, rollback using:

\`\`\`bash
# Vercel
vercel rollback <deployment-url>

# Kubernetes
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Docker / Docker Compose
docker-compose down && git checkout <previous-commit> && docker-compose up -d

# Heroku
heroku releases:rollback -a <app-name>
\`\`\`

## Monitoring

- **Logs:** \`kubectl logs -f deployment/<name>\` or check your logging service
- **Metrics:** Check Datadog/Grafana/CloudWatch dashboards
- **Errors:** Monitor Sentry/error tracking service
- **Performance:** Check response times and error rates

## Next Steps

- [ ] Monitor error rates for next 30 minutes
- [ ] Check user-facing features manually
- [ ] Verify analytics/tracking is working
- [ ] Announce deployment in team channel
- [ ] Update release notes

---

**Status:** $(if [ "$smoke_test_failed" = false ]; then echo "✅ Deployment Successful"; else echo "❌ Deployment Failed - Consider Rollback"; fi)
EOF
fi

if [ "$LANG" = "ja" ]; then
  echo "✅ ロールアウトステータスレポートを生成：$ROLLOUT_STATUS_FILE"
else
  echo "✅ Rollout status report generated: $ROLLOUT_STATUS_FILE"
fi

cat "$ROLLOUT_STATUS_FILE"

# Send notification (if Slack webhook is configured)
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  if [ "$LANG" = "ja" ]; then
    echo "→ Slack通知を送信中..."
  else
    echo "→ Sending Slack notification..."
  fi

  STATUS_EMOJI=$(if [ "$smoke_test_failed" = false ]; then echo ":white_check_mark:"; else echo ":x:"; fi)
  if [ "$LANG" = "ja" ]; then
    STATUS_TEXT=$(if [ "$smoke_test_failed" = false ]; then echo "成功"; else echo "失敗"; fi)
  else
    STATUS_TEXT=$(if [ "$smoke_test_failed" = false ]; then echo "Successful"; else echo "Failed"; fi)
  fi

  if [ "$LANG" = "ja" ]; then
    curl -X POST "$SLACK_WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"$STATUS_EMOJI デプロイ $STATUS_TEXT\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*デプロイ $STATUS_TEXT*\n*環境:* $DEPLOY_ENV\n*URL:* $DEPLOY_URL\n*コミット:* $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')\"}}]}" \
      > /dev/null 2>&1 || echo "⚠️  Slack通知の送信に失敗しました"
  else
    curl -X POST "$SLACK_WEBHOOK_URL" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"$STATUS_EMOJI Deployment $STATUS_TEXT\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"*Deployment $STATUS_TEXT*\n*Environment:* $DEPLOY_ENV\n*URL:* $DEPLOY_URL\n*Commit:* $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')\"}}]}" \
      > /dev/null 2>&1 || echo "⚠️  Failed to send Slack notification"
  fi
fi

# Voice notification (Theo announces deployment status)
VOICE_SCRIPT="$(dirname "$0")/../mcp-servers/play-voice.sh"
if [ -f "$VOICE_SCRIPT" ]; then
  if [ "$smoke_test_failed" = false ]; then
    "$VOICE_SCRIPT" "theo" "deployment" 2>/dev/null || true
  fi
fi

# Auto-commit deployment verification results (Theo)
AUTO_COMMIT_SCRIPT="$(dirname "$0")/../mcp-servers/auto-commit.sh"
if [ -f "$AUTO_COMMIT_SCRIPT" ] && [ -x "$AUTO_COMMIT_SCRIPT" ] && [ "$smoke_test_failed" = false ]; then
  "$AUTO_COMMIT_SCRIPT" \
    "chore" \
    "to track deployment state" \
    "Complete post-deployment verification (smoke tests, rollout status)" \
    "Theo" 2>/dev/null || true
fi

# Record deployment milestone to Memory Bank
if [ "$smoke_test_failed" = false ]; then
  RECORD_MILESTONE_SCRIPT="$(dirname "$0")/../.orchestra/scripts/record-milestone.sh"
  if [ -f "$RECORD_MILESTONE_SCRIPT" ] && [ -x "$RECORD_MILESTONE_SCRIPT" ]; then
    if [ "$LANG" = "ja" ]; then
      echo "→ デプロイマイルストーンを記録中..."
    else
      echo "→ Recording deployment milestone..."
    fi

    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    DEPLOY_MILESTONE="Deploy to $DEPLOY_ENV"
    DEPLOY_DESCRIPTION="Deployed commit $COMMIT_HASH to $DEPLOY_ENV environment at $DEPLOY_URL"

    "$RECORD_MILESTONE_SCRIPT" \
      "$DEPLOY_MILESTONE" \
      "$DEPLOY_DESCRIPTION" \
      "chore" \
      "${USER:-unknown}" 2>/dev/null || true

    # Update deployment history in Memory Bank
    MEMORY_BANK_PATH="$HOME/.memory-bank/orchestra/progress.md"
    if [ -f "$MEMORY_BANK_PATH" ]; then
      # Check if Deployment History section exists
      if ! grep -q "## Deployment History" "$MEMORY_BANK_PATH"; then
        cat >> "$MEMORY_BANK_PATH" <<EOF

## Deployment History

| Date | Environment | Commit | Status |
|------|-------------|--------|--------|
EOF
      fi

      # Add deployment entry
      DEPLOY_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
      DEPLOY_ENTRY="| $DEPLOY_DATE | $DEPLOY_ENV | $COMMIT_HASH | ✅ Success |"

      # Insert after table header
      awk -v entry="$DEPLOY_ENTRY" '
        /## Deployment History/ {
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

      if [ "$LANG" = "ja" ]; then
        echo "✅ デプロイ履歴を記録しました"
      else
        echo "✅ Deployment history recorded"
      fi
    fi
  fi
fi

# Exit with error if smoke tests failed
if [ "$smoke_test_failed" = true ]; then
  if [ "$LANG" = "ja" ]; then
    echo "❌ スモークテストが失敗しました！デプロイのロールバックを検討してください。"
  else
    echo "❌ Smoke tests failed! Consider rolling back the deployment."
  fi
  exit 1
fi

if [ "$LANG" = "ja" ]; then
  echo "✅ 全てのデプロイ後チェックが通過しました！"
else
  echo "✅ All post-deployment checks passed!"
fi
