# hooks/before_pr.sh
#!/usr/bin/env bash
set -euo pipefail

# Get language setting from environment
LANG="${ORCHESTRA_LANGUAGE:-en}"

if [ "$LANG" = "ja" ]; then
  echo "[before_pr] リント/型チェック/テスト/シークレット/SBOM実行中..."
else
  echo "[before_pr] Running lint/type/tests/secret/sbom..."
fi

# Sync documentation to Memory Bank before PR
SYNC_SCRIPT="$(dirname "$0")/../.orchestra/scripts/sync-to-memory-bank.sh"
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
  if [ "$LANG" = "ja" ]; then
    echo ""
    echo "[before_pr] Memory Bankへドキュメントを同期中..."
  else
    echo ""
    echo "[before_pr] Syncing documentation to Memory Bank..."
  fi

  if "$SYNC_SCRIPT"; then
    if [ "$LANG" = "ja" ]; then
      echo "✅ Memory Bank同期完了"
    else
      echo "✅ Memory Bank sync completed"
    fi
  else
    if [ "$LANG" = "ja" ]; then
      echo "⚠️  Memory Bank同期が失敗しましたが、PR作成は続行します"
    else
      echo "⚠️  Memory Bank sync failed, but continuing with PR creation"
    fi
  fi
  echo ""
fi

# Detect project type and run appropriate checks
if [ -f "package.json" ]; then
  if [ "$LANG" = "ja" ]; then
    echo "→ ESLint実行中..."
  else
    echo "→ Running ESLint..."
  fi

  npx eslint . --ext .js,.jsx,.ts,.tsx --max-warnings 0 || {
    if [ "$LANG" = "ja" ]; then
      echo "❌ ESLintが失敗しました。PR作成前にリントエラーを修正してください。"
    else
      echo "❌ ESLint failed. Please fix linting errors before creating PR."
    fi
    exit 1
  }

  if [ "$LANG" = "ja" ]; then
    echo "→ TypeScriptコンパイラ実行中..."
  else
    echo "→ Running TypeScript compiler..."
  fi

  npx tsc --noEmit || {
    if [ "$LANG" = "ja" ]; then
      echo "❌ TypeScriptコンパイルが失敗しました。PR作成前に型エラーを修正してください。"
    else
      echo "❌ TypeScript compilation failed. Please fix type errors before creating PR."
    fi
    exit 1
  }

  if [ "$LANG" = "ja" ]; then
    echo "→ テスト実行中..."
  else
    echo "→ Running tests..."
  fi

  npm test -- --passWithNoTests || {
    if [ "$LANG" = "ja" ]; then
      echo "❌ テストが失敗しました。PR作成前に全てのテストが通ることを確認してください。"
    else
      echo "❌ Tests failed. Please ensure all tests pass before creating PR."
    fi
    exit 1
  }
fi

if [ -f "pytest.ini" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
  if [ "$LANG" = "ja" ]; then
    echo "→ pytest実行中..."
  else
    echo "→ Running pytest..."
  fi

  pytest --maxfail=1 --disable-warnings -q || {
    if [ "$LANG" = "ja" ]; then
      echo "❌ Pytestが失敗しました。PR作成前に失敗したテストを修正してください。"
    else
      echo "❌ Pytest failed. Please fix failing tests before creating PR."
    fi
    exit 1
  }
fi

# Secret scanning with TruffleHog
if command -v trufflehog &> /dev/null; then
  if [ "$LANG" = "ja" ]; then
    echo "→ TruffleHogシークレットスキャン実行中..."
  else
    echo "→ Running TruffleHog secret scan..."
  fi

  trufflehog git file://. --since-commit HEAD~1 --only-verified --fail || {
    if [ "$LANG" = "ja" ]; then
      echo "❌ シークレットが検出されました！PR作成前にシークレットを削除してください。"
    else
      echo "❌ Secret detected! Please remove secrets before creating PR."
    fi
    exit 1
  }
else
  if [ "$LANG" = "ja" ]; then
    echo "⚠️  TruffleHogがインストールされていません。シークレットスキャンをスキップします。インストール：brew install trufflehog"
  else
    echo "⚠️  TruffleHog not installed. Skipping secret scan. Install: brew install trufflehog"
  fi
fi

# SBOM generation and vulnerability scanning with Syft + Grype
if command -v syft &> /dev/null && command -v grype &> /dev/null; then
  if [ "$LANG" = "ja" ]; then
    echo "→ SyftでSBOM生成中..."
  else
    echo "→ Generating SBOM with Syft..."
  fi

  syft dir:. -o cyclonedx-json > sbom.json

  if [ "$LANG" = "ja" ]; then
    echo "→ Grypeで脆弱性スキャン中..."
  else
    echo "→ Scanning vulnerabilities with Grype..."
  fi

  grype sbom:sbom.json --fail-on medium || {
    if [ "$LANG" = "ja" ]; then
      echo "❌ 脆弱性が検出されました！PR作成前にセキュリティ問題に対処してください。"
    else
      echo "❌ Vulnerabilities detected! Please address security issues before creating PR."
    fi
    exit 1
  }
else
  if [ "$LANG" = "ja" ]; then
    echo "⚠️  Syft/Grypeがインストールされていません。SBOM & 脆弱性スキャンをスキップします。"
    echo "   インストール：brew install syft grype"
  else
    echo "⚠️  Syft/Grype not installed. Skipping SBOM & vulnerability scan."
    echo "   Install: brew install syft grype"
  fi
fi

# Voice notification (Eden announces QA completion)
VOICE_SCRIPT="$(dirname "$0")/../mcp-servers/play-voice.sh"
if [ -f "$VOICE_SCRIPT" ]; then
  "$VOICE_SCRIPT" "eden" "pre-PR checks" 2>/dev/null || true
fi

if [ "$LANG" = "ja" ]; then
  echo "✅ 全てのPR前チェックが通過しました！"
else
  echo "✅ All pre-PR checks passed!"
fi

# Auto-commit QA validation results (Eden)
AUTO_COMMIT_SCRIPT="$(dirname "$0")/../mcp-servers/auto-commit.sh"
if [ -f "$AUTO_COMMIT_SCRIPT" ] && [ -x "$AUTO_COMMIT_SCRIPT" ]; then
  "$AUTO_COMMIT_SCRIPT" \
    "test" \
    "to ensure code quality" \
    "Pass pre-PR quality checks (lint, type, test, secrets, vulnerabilities)" \
    "Eden" 2>/dev/null || true
fi
