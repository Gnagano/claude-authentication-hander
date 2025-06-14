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

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "Error: Credentials file not found at $CREDENTIALS_FILE"
    echo ""
    echo "Please do one of the following:"
    echo "1. Run 'claude' manually in a separate terminal to generate credentials"
    echo "2. Ensure you're logged into Claude"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "Found Claude credentials at $CREDENTIALS_FILE"

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