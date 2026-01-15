#!/bin/bash
#
# Setup script to configure GitHub token for the populator
#
# This script saves your GitHub token to your shell profile
# so you don't need to enter it every time.
#

echo "=========================================="
echo "GitHub Token Setup"
echo "=========================================="
echo ""

# Check if token is provided
if [ -z "$1" ]; then
    echo "❌ No token provided!"
    echo ""
    echo "Usage:"
    echo "  ./setup_github_token.sh ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo ""
    echo "Get your token from:"
    echo "  https://github.com/settings/tokens/new"
    echo ""
    echo "Required scopes:"
    echo "  - repo (Full control of private repositories)"
    echo "  - project (Full control of projects)"
    echo "  - workflow (Update GitHub Action workflows)"
    exit 1
fi

TOKEN="$1"

# Validate token format
if [[ ! "$TOKEN" =~ ^ghp_ ]]; then
    echo "⚠️  Warning: Token doesn't look like a GitHub Personal Access Token"
    echo "   Tokens should start with 'ghp_'"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Detect shell
SHELL_NAME=$(basename "$SHELL")
PROFILE_FILE=""

case "$SHELL_NAME" in
    bash)
        PROFILE_FILE="$HOME/.bashrc"
        ;;
    zsh)
        PROFILE_FILE="$HOME/.zshrc"
        ;;
    fish)
        PROFILE_FILE="$HOME/.config/fish/config.fish"
        ;;
    *)
        PROFILE_FILE="$HOME/.bashrc"
        ;;
esac

echo "Detected shell: $SHELL_NAME"
echo "Profile file: $PROFILE_FILE"
echo ""

# Check if GITHUB_TOKEN already exists
if grep -q "GITHUB_TOKEN" "$PROFILE_FILE" 2>/dev/null; then
    echo "⚠️  GITHUB_TOKEN already exists in $PROFILE_FILE"
    echo "   Updating existing entry..."
    # Remove existing GITHUB_TOKEN line
    sed -i '/^export GITHUB_TOKEN=/d' "$PROFILE_FILE"
fi

# Add token to profile
echo "" >> "$PROFILE_FILE"
echo "# GitHub Token for FloDoc Populator" >> "$PROFILE_FILE"
echo "export GITHUB_TOKEN=\"$TOKEN\"" >> "$PROFILE_FILE"

echo "✅ Token saved to $PROFILE_FILE"
echo ""

# Reload profile
echo "Reloading profile..."
source "$PROFILE_FILE" 2>/dev/null || true

# Verify
if [ -n "$GITHUB_TOKEN" ] || [ -n "$(grep "GITHUB_TOKEN" "$PROFILE_FILE" 2>/dev/null)" ]; then
    echo "✅ Token configured successfully!"
    echo ""
    echo "You can now run the populator without specifying the token:"
    echo ""
    echo "  cd docs/backlog"
    echo "  python3 populate_github_api.py --owner NeoSkosana --repo floDoc-v3 --project 6"
    echo ""
    echo "Or in one line:"
    echo ""
    echo "  python3 docs/backlog/populate_github_api.py --owner NeoSkosana --repo floDoc-v3 --project 6"
    echo ""
else
    echo "❌ Failed to save token. Please add manually to $PROFILE_FILE:"
    echo ""
    echo "  export GITHUB_TOKEN=\"$TOKEN\""
fi
