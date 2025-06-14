#!/bin/bash

# Claude Authentication Setup Script for Mac
# Differences from Windows version:
# - Direct keychain integration for credential retrieval
# - Optimized REPL mode Claude startup (with error handling)
# - Mac-optimized processing

set -e  # Exit on error

echo "=== Claude Authentication Setup Script (Mac Version) ==="

# Step 1 & 2: Try to start and stop Claude Code in REPL mode (skip if errors occur)
echo "Step 1: Attempting to start Claude Code..."
if command -v claude &> /dev/null; then
    echo "Temporarily starting Claude Code to check keychain updates..."
    # Start in background and terminate immediately
    timeout 10s claude --help > /dev/null 2>&1 || true
    echo "Claude Code startup check completed"
else
    echo "⚠️  Claude Code command not found. Please verify authentication manually."
fi

# Step 3: credentials.json sample template
CREDENTIALS_TEMPLATE='{
  "claudeAiOauth": {
    "accessToken": "ACCESS_TOKEN_PLACEHOLDER",
    "refreshToken": "REFRESH_TOKEN_PLACEHOLDER", 
    "expiresAt": EXPIRES_AT_PLACEHOLDER,
    "scopes": ["user:inference", "user:profile"],
    "isMax": true
  }
}'

# Step 4: Retrieve authentication info from Keychain and create credentials.json
echo "Step 2: Retrieving authentication information from Keychain..."

# Get JSON data from Claude Code-credentials
KEYCHAIN_DATA=""
if KEYCHAIN_DATA=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null); then
    echo "✓ Retrieved authentication information from Keychain"
    
    # Create .claude directory
    mkdir -p "$HOME/.claude"
    
    # Save the retrieved JSON data directly
    echo "$KEYCHAIN_DATA" > "$HOME/.claude/credentials.json"
    echo "✓ Created $HOME/.claude/credentials.json"
    
    # Verify content if jq is available
    if command -v jq &> /dev/null; then
        echo "Authentication information verification:"
        echo "  Access Token: $(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.accessToken' | cut -c1-20)..."
        echo "  Expires At: $(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.expiresAt')"
    fi
else
    echo "❌ Failed to retrieve authentication information from Keychain"
    echo "Please log in with Claude Code first: claude"
    exit 1
fi

# Step 5: Set GitHub Secrets (error-resistant version)
echo "Step 3: Setting GitHub Secrets..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq not found. Please install it: brew install jq"
    exit 1
fi

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Please install it: brew install gh"
    exit 1
fi

# Extract authentication information
ACCESS_TOKEN=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.accessToken')
REFRESH_TOKEN=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.refreshToken')
EXPIRES_AT=$(echo "$KEYCHAIN_DATA" | jq -r '.claudeAiOauth.expiresAt')

# Verify extraction
if [[ "$ACCESS_TOKEN" == "null" || "$REFRESH_TOKEN" == "null" || "$EXPIRES_AT" == "null" ]]; then
    echo "❌ Failed to extract authentication information"
    exit 1
fi

# Repository list
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

# Set GitHub Secrets (with error handling)
SUCCESS_COUNT=0
TOTAL_COUNT=${#REPOS[@]}

for REPO in "${REPOS[@]}"; do
    echo "Setting up: Gnagano/$REPO"
    
    # Set each secret individually (continue on error)
    if gh secret set CLAUDE_ACCESS_TOKEN -R "Gnagano/$REPO" --body "$ACCESS_TOKEN" 2>/dev/null; then
        echo "  ✓ ACCESS_TOKEN setup completed"
    else
        echo "  ❌ ACCESS_TOKEN setup failed"
        continue
    fi
    
    if gh secret set CLAUDE_REFRESH_TOKEN -R "Gnagano/$REPO" --body "$REFRESH_TOKEN" 2>/dev/null; then
        echo "  ✓ REFRESH_TOKEN setup completed"
    else
        echo "  ❌ REFRESH_TOKEN setup failed"
        continue
    fi
    
    if gh secret set CLAUDE_EXPIRES_AT -R "Gnagano/$REPO" --body "$EXPIRES_AT" 2>/dev/null; then
        echo "  ✓ EXPIRES_AT setup completed"
        ((SUCCESS_COUNT++))
    else
        echo "  ❌ EXPIRES_AT setup failed"
        continue
    fi
    
    echo "  ✅ $REPO completed"
    echo ""
done

echo "=== Processing Complete ==="
echo "Success: $SUCCESS_COUNT/$TOTAL_COUNT repositories"
echo ""
echo "Files configured:"
echo "  📁 $HOME/.claude/credentials.json"
echo ""
echo "GitHub Secrets configured:"
echo "  🔑 CLAUDE_ACCESS_TOKEN"
echo "  🔑 CLAUDE_REFRESH_TOKEN" 
echo "  🔑 CLAUDE_EXPIRES_AT"
echo ""

if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
    echo "🎉 Setup completed for all repositories!"
else
    echo "⚠️  Setup failed for some repositories. Please check GitHub CLI authentication."
fi
