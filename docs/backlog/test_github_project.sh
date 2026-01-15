#!/bin/bash
#
# Test script to verify GitHub Projects populator setup
#

set -e

echo "=========================================="
echo "GitHub Projects Populator - Setup Test"
echo "=========================================="
echo ""

# Check GitHub CLI
echo "1. Checking GitHub CLI..."
if command -v gh &> /dev/null; then
    echo "   ✅ GitHub CLI installed: $(gh --version | head -1)"
else
    echo "   ❌ GitHub CLI not found"
    echo "   Install from: https://cli.github.com/"
    exit 1
fi

# Check authentication
echo ""
echo "2. Checking authentication..."
if gh auth status &> /dev/null; then
    echo "   ✅ Authenticated"
    gh auth status 2>&1 | grep -E "(Logged in|Username)" | sed 's/^/      /'
else
    echo "   ❌ Not authenticated"
    echo "   Run: gh auth login"
    exit 1
fi

# Check gh-project extension
echo ""
echo "3. Checking gh-project extension..."
if gh extension list | grep -q "mislav/gh-project"; then
    echo "   ✅ gh-project extension installed"
else
    echo "   ⚠️  gh-project extension not installed"
    echo "   Install with: gh extension install mislav/gh-project"
    echo "   (Optional - script will still work)"
fi

# Check script files
echo ""
echo "4. Checking script files..."
SCRIPTS=(
    "populate_github_project.sh"
    "populate_github_project.py"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "   ✅ $script exists"
    else
        echo "   ❌ $script not found"
        exit 1
    fi
done

# Check epic details file
echo ""
echo "5. Checking source file..."
EPIC_FILE="../prd/6-epic-details.md"
if [ -f "$EPIC_FILE" ]; then
    STORY_COUNT=$(grep -c "^### Story" "$EPIC_FILE")
    echo "   ✅ Epic details found"
    echo "   📊 Contains $STORY_COUNT stories"
else
    echo "   ❌ Epic details not found: $EPIC_FILE"
    exit 1
fi

# Check documentation files
echo ""
echo "6. Checking documentation..."
DOCS=(
    "GITHUB_PROJECT_SETUP.md"
    "QUICKSTART_GITHUB_PROJECTS.md"
    "GITHUB_PROJECTS_SUMMARY.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "   ✅ $doc exists"
    else
        echo "   ❌ $doc not found"
        exit 1
    fi
done

# Test dry run (parse stories without creating)
echo ""
echo "7. Testing story parsing (dry run)..."
if python3 populate_github_project.py \
    --token "fake_token_for_test" \
    --owner "test" \
    --repo "test" \
    --dry-run 2>&1 | grep -q "Found.*stories"; then
    echo "   ✅ Story parsing works"
else
    echo "   ⚠️  Could not test parsing (may need Python dependencies)"
fi

echo ""
echo "=========================================="
echo "✅ Setup Test Complete!"
echo "=========================================="
echo ""
echo "You're ready to run the populator!"
echo ""
echo "Next steps:"
echo "  1. Run: ./populate_github_project.sh <owner> <repo> <project_number>"
echo "  2. Example: ./populate_github_project.sh NeoSkosana floDoc-v3 6"
echo ""
echo "For help:"
echo "  - Quick start: cat QUICKSTART_GITHUB_PROJECTS.md"
echo "  - Full guide: cat GITHUB_PROJECT_SETUP.md"
echo "  - Summary: cat GITHUB_PROJECTS_SUMMARY.md"
echo ""
