#!/bin/bash

# Read Claude credentials from ~/.claude/.credentials.json
CREDENTIALS_FILE="$HOME/.claude/.credentials.json"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  macOS: brew install jq"
    exit 1
fi

# Check if claude command is available
if ! command -v claude &> /dev/null; then
    echo "Error: claude command not found. Please install Claude CLI first."
    exit 1
fi

# Always run claude first to ensure fresh credentials
echo "Opening Claude to ensure credentials are up to date..."

# Run claude in background and capture its PID
claude &
CLAUDE_PID=$!

# Wait for Claude to fully start and generate credentials
echo "Waiting for Claude to initialize and generate credentials..."
sleep 15

# Send interrupt signal to close Claude
kill -INT $CLAUDE_PID 2>/dev/null || true

# Wait a bit more for cleanup
sleep 5

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "Error: Credentials file not found at $CREDENTIALS_FILE"
    echo "Please run 'claude' manually and ensure you're logged in."
    exit 1
fi

echo "Claude credentials are ready!"

# Extract tokens using jq (JSON parser)
ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken' "$CREDENTIALS_FILE")
REFRESH_TOKEN=$(jq -r '.claudeAiOauth.refreshToken' "$CREDENTIALS_FILE")
EXPIRES_AT=$(jq -r '.claudeAiOauth.expiresAt' "$CREDENTIALS_FILE")

# Verify tokens were extracted successfully
if [ "$ACCESS_TOKEN" = "null" ] || [ "$REFRESH_TOKEN" = "null" ] || [ "$EXPIRES_AT" = "null" ]; then
    echo "Error: Failed to extract credentials from $CREDENTIALS_FILE"
    exit 1
fi

echo "Successfully loaded credentials from $CREDENTIALS_FILE"

# List of repositories
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

# Set secrets for each repository
for REPO in "${REPOS[@]}"; do
    echo "Setting secrets for $REPO..."
    gh secret set CLAUDE_ACCESS_TOKEN -R Gnagano/$REPO --body "$ACCESS_TOKEN"
    gh secret set CLAUDE_REFRESH_TOKEN -R Gnagano/$REPO --body "$REFRESH_TOKEN"
    gh secret set CLAUDE_EXPIRES_AT -R Gnagano/$REPO --body "$EXPIRES_AT"
    echo "✓ Completed $REPO"
    echo
done

echo "All secrets have been set successfully!"
