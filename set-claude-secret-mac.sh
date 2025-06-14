#!/bin/bash

# Mac用 Claude認証情報設定スクリプト
# Windows版との違い：
# - Keychainから認証情報を直接取得
# - REPLモードでのClaude起動（エラー回避）
# - Macに最適化された処理

set -e  # エラー時に終了

echo "=== Claude認証情報設定スクリプト (Mac版) ==="

# 2-1 & 2-2: Claude CodeをREPLモードで起動・終了（エラー時は諦める）
echo "Step 1: Claude Codeの起動を試行中..."
if command -v claude &> /dev/null; then
    echo "Claude Codeを一時的に起動してkeychainの更新を確認..."
    # バックグラウンドで起動し、すぐに終了
    timeout 10s claude --help > /dev/null 2>&1 || true
    echo "Claude Code起動チェック完了"
else
    echo "⚠️  Claude Codeコマンドが見つかりません。手動で認証を確認してください。"
fi

# 2-3: credentials.jsonのサンプルテンプレート
CREDENTIALS_TEMPLATE='{
  "claudeAiOauth": {
    "accessToken": "ACCESS_TOKEN_PLACEHOLDER",
    "refreshToken": "REFRESH_TOKEN_PLACEHOLDER", 
    "expiresAt": EXPIRES_AT_PLACEHOLDER,
    "scopes": ["user:inference", "user:profile"],
    "isMax": true
  }
}'

# 2-4: Keychainから認証情報を取得してcredentials.jsonを作成
echo "Step 2: Keychainから認証情報を取得中..."

# Claude Code-credentialsからJSONデータを取得
KEYCHAIN_DATA=""
if KEYCHAIN_DATA=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null); then
    echo "✓ Keychainから認証情報を取得しました"
    
    # .claudeディレクトリの作成
    mkdir -p "$HOME/.claude"
    
    # 取得したJSONデータをそのまま保存
    echo "$KEYCHAIN_DATA" > "$HOME/.claude/credentials.json"
    echo "✓ $HOME/.claude/credentials.json を作成しました"
    
    # 内容確認
    if command -v jq &> /dev/null; then
        echo "認証情報の確認:"
        echo "  Access Token: $(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.accessToken' | cut -c1-20)..."
        echo "  Expires At: $(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.expiresAt')"
    fi
else
    echo "❌ Keychainから認証情報を取得できませんでした"
    echo "Claude Codeで一度ログインしてください: claude"
    exit 1
fi

# 2-5: GitHub Secretsの設定（エラー回避版）
echo "Step 3: GitHub Secretsの設定中..."

# jqの存在確認
if ! command -v jq &> /dev/null; then
    echo "❌ jqが見つかりません。インストールしてください: brew install jq"
    exit 1
fi

# GitHub CLIの確認
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLIが見つかりません。インストールしてください: brew install gh"
    exit 1
fi

# 認証情報の抽出
ACCESS_TOKEN=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.accessToken')
REFRESH_TOKEN=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.refreshToken')
EXPIRES_AT=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.expiresAt')

# 抽出確認
if [[ "$ACCESS_TOKEN" == "null" || "$REFRESH_TOKEN" == "null" || "$EXPIRES_AT" == "null" ]]; then
    echo "❌ 認証情報の抽出に失敗しました"
    exit 1
fi

# リポジトリリスト
REPOS=(
    "code-base-ts-backend-curiox"
    "anthropic-api-backend"
    "jcfinance-customer"
    "jcfinance-backend"
    "jcfinance-admin"
    "europe_chartered_bank_backend"
    "europe_chartered_bank_customer"
    "europe_chartered_bank_admin"
    "forbes_private_bank"
    "forbes_private_bank_functions"
    "forbes_private_bank_admin"
    "line_database"
)

# GitHub Secretsの設定（エラー処理付き）
SUCCESS_COUNT=0
TOTAL_COUNT=${#REPOS[@]}

for REPO in "${REPOS[@]}"; do
    echo "設定中: Gnagano/$REPO"
    
    # 各シークレットを個別に設定（エラー時も継続）
    if gh secret set CLAUDE_ACCESS_TOKEN -R "Gnagano/$REPO" --body "$ACCESS_TOKEN" 2>/dev/null; then
        echo "  ✓ ACCESS_TOKEN設定完了"
    else
        echo "  ❌ ACCESS_TOKEN設定失敗"
        continue
    fi
    
    if gh secret set CLAUDE_REFRESH_TOKEN -R "Gnagano/$REPO" --body "$REFRESH_TOKEN" 2>/dev/null; then
        echo "  ✓ REFRESH_TOKEN設定完了"
    else
        echo "  ❌ REFRESH_TOKEN設定失敗"
        continue
    fi
    
    if gh secret set CLAUDE_EXPIRES_AT -R "Gnagano/$REPO" --body "$EXPIRES_AT" 2>/dev/null; then
        echo "  ✓ EXPIRES_AT設定完了"
        ((SUCCESS_COUNT++))
    else
        echo "  ❌ EXPIRES_AT設定失敗"
        continue
    fi
    
    echo "  ✅ $REPO 完了"
    echo ""
done

echo "=== 処理完了 ==="
echo "成功: $SUCCESS_COUNT/$TOTAL_COUNT リポジトリ"
echo ""
echo "設定されたファイル:"
echo "  📁 $HOME/.claude/credentials.json"
echo ""
echo "設定されたGitHub Secrets:"
echo "  🔑 CLAUDE_ACCESS_TOKEN"
echo "  🔑 CLAUDE_REFRESH_TOKEN" 
echo "  🔑 CLAUDE_EXPIRES_AT"
echo ""

if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
    echo "🎉 すべてのリポジトリで設定が完了しました！"
else
    echo "⚠️  一部のリポジトリで設定に失敗しました。GitHub CLIの認証を確認してください。"
fi
