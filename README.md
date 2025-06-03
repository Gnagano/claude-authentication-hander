# claude-authentication-hander
Claude Authentication Handler - A utility for handling authentication workflows with Claude

## Prerequisites
Before running this script, make sure you have:

1. **Claude CLI installed and authenticated** - You must be logged in to Claude
2. **GitHub CLI (gh) installed and authenticated** - Required for setting repository secrets
3. **jq installed** - JSON parser for extracting credentials
   - Ubuntu/Debian: `sudo apt-get install jq`
   - macOS: `brew install jq`
   - Windows: Download from [jqlang.github.io](https://jqlang.github.io/jq/)

⚠️ **Important**: You must have an active Claude login session before running this script. Run `claude` manually first to ensure you're properly authenticated.

## Usage
Run the script using:
```bash
./set-claude-secret.sh
```

The script will:
1. Launch Claude CLI to ensure fresh credentials
2. Extract authentication tokens from `~/.claude/.credentials.json`
3. Set the following GitHub secrets for all configured repositories:
   - `CLAUDE_ACCESS_TOKEN`
   - `CLAUDE_REFRESH_TOKEN`
   - `CLAUDE_EXPIRES_AT`
