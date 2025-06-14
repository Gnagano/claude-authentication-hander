#!/bin/bash

# Claude認証情報設定スクリプト - Universal Wrapper
# 自動OS判定機能付き

set -e

echo "🔍 OS環境を判定中..."

# OS判定関数
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macOS"
            ;;
        Linux*)
            # WSL判定
            if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
                echo "WSL"
            else
                echo "Linux"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# シンボリックリンクを解決してスクリプトの実際の場所を取得
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # シンボリックリンクの場合
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # 相対パスの場合は絶対パスに変換
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# バックアップ方法1: BASH_SOURCEが使えない場合
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
fi

# バックアップ方法2: 実行可能ファイルのパスから推測
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -d "$SCRIPT_DIR" ]]; then
    # which コマンドでスクリプトの場所を特定
    WHICH_RESULT="$(which set-claude-secret 2>/dev/null || echo "")"
    if [[ -n "$WHICH_RESULT" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "$WHICH_RESULT")" && pwd -P)"
    else
        SCRIPT_DIR="$(pwd)"
    fi
fi

# デバッグモード（環境変数 DEBUG=1 で有効化）
if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "📂 スクリプトディレクトリ: $SCRIPT_DIR"
    echo "📋 利用可能なファイル:"
    ls -la "$SCRIPT_DIR"/*.sh 2>/dev/null || echo "  ⚠️  .shファイルが見つかりません"
fi

# OS判定実行
OS_TYPE=$(detect_os)
echo "🖥️  検出されたOS: $OS_TYPE"

# 対応するスクリプトを実行
case "$OS_TYPE" in
    "macOS")
        echo "🍎 Mac用スクリプトを実行します..."
        MAC_SCRIPT="$SCRIPT_DIR/set-claude-secret-mac.sh"
        if [[ "${DEBUG:-0}" == "1" ]]; then
            echo "🔍 探しているファイル: $MAC_SCRIPT"
        fi
        if [[ -f "$MAC_SCRIPT" ]]; then
            exec "$MAC_SCRIPT" "$@"
        else
            echo "❌ Mac用スクリプト (set-claude-secret-mac.sh) が見つかりません"
            echo "📂 現在のディレクトリ: $(pwd)"
            echo "📂 スクリプトディレクトリ: $SCRIPT_DIR"
            echo "💡 DEBUG=1 でより詳細な情報を表示できます"
            exit 1
        fi
        ;;
    "WSL")
        echo "🐧 WSL環境を検出しました。Windows用スクリプトを実行します..."
        if [[ -f "$SCRIPT_DIR/set-claude-secret-windows.sh" ]]; then
            exec "$SCRIPT_DIR/set-claude-secret-windows.sh" "$@"
        else
            echo "❌ Windows用スクリプト (set-claude-secret-windows.sh) が見つかりません"
            exit 1
        fi
        ;;
    "Linux")
        echo "🐧 Linux環境を検出しました"
        echo "現在、純粋なLinux環境用のスクリプトは提供されていません。"
        echo ""
        echo "🔧 以下のオプションから選択してください："
        echo "1. Windows版スクリプトを試す (WSLと同様の環境の場合)"
        echo "2. Mac版スクリプトをベースに手動設定"
        echo ""
        if [[ -f "$SCRIPT_DIR/set-claude-secret-windows.sh" ]]; then
            echo "Windows版スクリプトを試しますか？ (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "🪟 Windows版スクリプトを実行します..."
                exec "$SCRIPT_DIR/set-claude-secret-windows.sh" "$@"
            fi
        fi
        echo "手動設定が必要です。詳細はREADMEを参照してください。"
        exit 1
        ;;
    "Windows")
        echo "🪟 Windows用スクリプトを実行します..."
        if [[ -f "$SCRIPT_DIR/set-claude-secret-windows.sh" ]]; then
            exec "$SCRIPT_DIR/set-claude-secret-windows.sh" "$@"
        else
            echo "❌ Windows用スクリプト (set-claude-secret-windows.sh) が見つかりません"
            exit 1
        fi
        ;;
    *)
        echo "❌ サポートされていないOS環境です: $OS_TYPE"
        echo ""
        echo "🔧 手動での設定が必要です："
        echo "1. Claude Codeで認証"
        echo "2. credentials.jsonを手動作成"
        echo "3. GitHub Secretsを手動設定"
        exit 1
        ;;
esac
