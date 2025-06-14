#!/bin/bash

# Claude Authentication Setup Script - Universal Wrapper
# Auto-detects OS and executes appropriate platform-specific script

set -e

echo "🔍 Detecting OS environment..."

# OS detection function
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macOS"
            ;;
        Linux*)
            # WSL detection
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

# Resolve symbolic links to find the actual script location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # Handle symbolic links
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # Convert relative path to absolute
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# Fallback method 1: Use BASH_SOURCE if available
if [[ -z "$SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
fi

# Fallback method 2: Try to detect from executable path
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -d "$SCRIPT_DIR" ]]; then
    # Use which command to locate script
    WHICH_RESULT="$(which set-claude-secret 2>/dev/null || echo "")"
    if [[ -n "$WHICH_RESULT" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "$WHICH_RESULT")" && pwd -P)"
    else
        SCRIPT_DIR="$(pwd)"
    fi
fi

# Debug mode (enabled with DEBUG=1 environment variable)
if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "📂 Script directory: $SCRIPT_DIR"
    echo "📋 Available files:"
    ls -la "$SCRIPT_DIR"/*.sh 2>/dev/null || echo "  ⚠️  No .sh files found"
fi

# Execute OS detection
OS_TYPE=$(detect_os)
echo "🖥️  Detected OS: $OS_TYPE"

# Execute appropriate script based on detected OS
case "$OS_TYPE" in
    "macOS")
        echo "🍎 Executing Mac script..."
        MAC_SCRIPT="$SCRIPT_DIR/set-claude-secret-mac.sh"
        if [[ "${DEBUG:-0}" == "1" ]]; then
            echo "🔍 Looking for file: $MAC_SCRIPT"
        fi
        if [[ -f "$MAC_SCRIPT" ]]; then
            exec "$MAC_SCRIPT" "$@"
        else
            echo "❌ Mac script (set-claude-secret-mac.sh) not found"
            echo "📂 Current directory: $(pwd)"
            echo "📂 Script directory: $SCRIPT_DIR"
            echo "💡 Use DEBUG=1 for more detailed information"
            exit 1
        fi
        ;;
    "WSL")
        echo "🐧 WSL environment detected. Executing Windows script..."
        if [[ -f "$SCRIPT_DIR/set-claude-secret-windows.sh" ]]; then
            exec "$SCRIPT_DIR/set-claude-secret-windows.sh" "$@"
        else
            echo "❌ Windows script (set-claude-secret-windows.sh) not found"
            exit 1
        fi
        ;;
    "Linux")
        echo "🐧 Linux environment detected"
        echo "Currently, no dedicated Linux script is available."
        echo ""
        echo "🔧 Please choose from the following options:"
        echo "1. Try Windows script (if WSL-like environment)"
        echo "2. Manual setup based on Mac script"
        echo ""
        if [[ -f "$SCRIPT_DIR/set-claude-secret-windows.sh" ]]; then
            echo "Try Windows script? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo "🪟 Executing Windows script..."
                exec "$SCRIPT_DIR/set-claude-secret-windows.sh" "$@"
            fi
        fi
        echo "Manual setup required. Please refer to README for details."
        exit 1
        ;;
    "Windows")
        echo "🪟 Executing Windows script..."
        if [[ -f "$SCRIPT_DIR/set-claude-secret-windows.sh" ]]; then
            exec "$SCRIPT_DIR/set-claude-secret-windows.sh" "$@"
        else
            echo "❌ Windows script (set-claude-secret-windows.sh) not found"
            exit 1
        fi
        ;;
    *)
        echo "❌ Unsupported OS environment: $OS_TYPE"
        echo ""
        echo "🔧 Manual setup required:"
        echo "1. Authenticate with Claude Code"
        echo "2. Manually create credentials.json"
        echo "3. Manually set GitHub Secrets"
        exit 1
        ;;
esac
