#!/bin/bash
#
# GitHub Projects Populator Script (using GitHub CLI)
#
# This script creates GitHub issues from user stories and adds them to a project board.
# It uses the GitHub CLI (gh) for authentication and API access.
#
# Prerequisites:
#   1. Install GitHub CLI: https://cli.github.com/
#   2. Authenticate: gh auth login
#   3. Install 'gh-project' extension: gh extension install mislav/gh-project
#
# Usage:
#   ./populate_github_project.sh <owner> <repo> <project_number>
#
# Example:
#   ./populate_github_project.sh NeoSkosana floDoc-v3 6
#

set -e

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <owner> <repo> [project_number]"
    echo ""
    echo "Example:"
    echo "  $0 NeoSkosana floDoc-v3 6"
    echo ""
    echo "Prerequisites:"
    echo "  - GitHub CLI installed (gh)"
    echo "  - gh auth login completed"
    echo "  - gh extension install mislav/gh-project"
    exit 1
fi

OWNER="$1"
REPO="$2"
PROJECT_NUMBER="${3:-6}"  # Default to 6 if not provided

# File paths
EPIC_FILE="/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/prd/6-epic-details.md"
SUMMARY_FILE="/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/backlog/github_project_summary.md"
LOG_FILE="/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/backlog/populate_log.txt"

# Check dependencies
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install it from https://cli.github.com/"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI. Run 'gh auth login' first."
    exit 1
fi

echo "=========================================="
echo "GitHub Projects Populator"
echo "=========================================="
echo "Owner: $OWNER"
echo "Repo: $REPO"
echo "Project: #$PROJECT_NUMBER"
echo "Input: $EPIC_FILE"
echo "=========================================="
echo ""

# Check if epic file exists
if [ ! -f "$EPIC_FILE" ]; then
    echo "❌ Epic file not found: $EPIC_FILE"
    exit 1
fi

# Create temporary files
TEMP_STORIES="/tmp/stories_list.txt"
TEMP_ISSUES="/tmp/created_issues.txt"

# Extract stories from epic file
echo "📖 Extracting stories from epic details..."
grep -E "^### Story [0-9]" "$EPIC_FILE" > "$TEMP_STORIES"

STORY_COUNT=$(wc -l < "$TEMP_STORIES")
echo "✅ Found $STORY_COUNT stories"
echo ""

# Initialize summary
echo "# GitHub Project - User Stories Summary" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "**Generated:** $(date)" >> "$SUMMARY_FILE"
echo "**Total Stories:** $STORY_COUNT" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "## Stories Created" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "| # | Title | Status | Priority | Epic | Effort | Risk | Issue URL |" >> "$SUMMARY_FILE"
echo "|---|-------|--------|----------|------|--------|------|-----------|" >> "$SUMMARY_FILE"

# Counter for tracking
COUNTER=0
CREATED=0
SKIPPED=0

# Read stories and create issues
while IFS= read -r line; do
    COUNTER=$((COUNTER + 1))

    # Extract story number and title
    STORY_NUM=$(echo "$line" | sed -E 's/### Story ([0-9.]+): .*/\1/')
    STORY_TITLE=$(echo "$line" | sed -E 's/### Story [0-9.]+: //')

    echo "[$COUNTER/$STORY_COUNT] Processing Story $STORY_NUM: $STORY_TITLE"

    # Extract story details from epic file
    # Get the section for this story
    STORY_SECTION=$(awk -v num="### Story $STORY_NUM:" '
        $0 ~ num {flag=1; next}
        /^### Story/ && flag {flag=0}
        flag {print}
    ' "$EPIC_FILE")

    # Extract metadata
    STATUS=$(echo "$STORY_SECTION" | grep -E "^\*\*Status\*\*:" | sed 's/\*\*Status\*\*: //' | head -1 || echo "Draft")
    PRIORITY=$(echo "$STORY_SECTION" | grep -E "^\*\*Priority\*\*:" | sed 's/\*\*Priority\*\*: //' | head -1 || echo "Medium")
    EPIC=$(echo "$STORY_SECTION" | grep -E "^\*\*Epic\*\*:" | sed 's/\*\*Epic\*\*: //' | head -1 || echo "General")
    EFFORT=$(echo "$STORY_SECTION" | grep -E "^\*\*Estimated Effort\*\*:" | sed 's/\*\*Estimated Effort\*\*: //' | head -1 || echo "Unknown")
    RISK=$(echo "$STORY_SECTION" | grep -E "^\*\*Risk Level\*\*:" | sed 's/\*\*Risk Level\*\*: //' | head -1 || echo "Low")

    # Extract user story
    USER_STORY=$(echo "$STORY_SECTION" | awk '/#### User Story/,/#### Background/' | sed '1d;$d' | sed '/^$/d' | head -20)

    # Build body
    BODY="## 📖 User Story

$USER_STORY

## 📊 Metadata

- **Story Number**: $STORY_NUM
- **Epic**: $EPIC
- **Priority**: $PRIORITY
- **Estimated Effort**: $EFFORT
- **Risk Level**: $RISK
- **Status**: $STATUS

---
*Generated from epic details*"

    # Create labels - normalize to match created labels
    EPIC_LABEL=$(echo "$EPIC" | sed 's/Phase /phase-/' | sed 's/ - /-/' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]' | sed 's/---*/-/g')
    STATUS_LABEL=$(echo "$STATUS" | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]')

    LABELS=(
        "story:$STORY_NUM"
        "epic:$EPIC_LABEL"
        "priority:$(echo "$PRIORITY" | tr '[:upper:]' '[:lower:]')"
        "risk:$(echo "$RISK" | tr '[:upper:]' '[:lower:]')"
        "status:$STATUS_LABEL"
    )

    # Add portal labels based on title
    TITLE_LOWER=$(echo "$STORY_TITLE" | tr '[:upper:]' '[:lower:]')
    if echo "$TITLE_LOWER" | grep -qE "(admin|tp|training provider)"; then
        LABELS+=("portal:admin")
    elif echo "$TITLE_LOWER" | grep -qE "(student)"; then
        LABELS+=("portal:student")
    elif echo "$TITLE_LOWER" | grep -qE "(sponsor)"; then
        LABELS+=("portal:sponsor")
    elif echo "$TITLE_LOWER" | grep -qE "(database|model|api|backend)"; then
        LABELS+=("type:backend")
    elif echo "$TITLE_LOWER" | grep -qE "(testing|qa|audit|security)"; then
        LABELS+=("type:qa")
    elif echo "$TITLE_LOWER" | grep -qE "(infrastructure|deployment|docs)"; then
        LABELS+=("type:infrastructure")
    fi

    # Build label string for gh CLI
    LABEL_STR=$(IFS=,; echo "${LABELS[*]}")

    # Create the issue
    TITLE="[$STORY_NUM] $STORY_TITLE"

    echo "   Creating issue..."
    ISSUE_URL=$(gh issue create \
        --repo "$OWNER/$REPO" \
        --title "$TITLE" \
        --body "$BODY" \
        --label "$LABEL_STR" 2>&1 || echo "")

    if [ -n "$ISSUE_URL" ]; then
        echo "   ✅ Created: $ISSUE_URL"
        CREATED=$((CREATED + 1))

        # Add to summary
        echo "| $STORY_NUM | $STORY_TITLE | $STATUS | $PRIORITY | $EPIC | $EFFORT | $RISK | [Link]($ISSUE_URL) |" >> "$SUMMARY_FILE"

        # Add to project if project number provided
        if [ -n "$PROJECT_NUMBER" ]; then
            echo "   Adding to project #$PROJECT_NUMBER..."
            # Extract issue number from URL
            ISSUE_NUM=$(echo "$ISSUE_URL" | sed 's/.*\///')

            # Try to add to project using gh project extension
            if gh project item-add "$PROJECT_NUMBER" --repo "$OWNER/$REPO" --issue "$ISSUE_NUM" 2>/dev/null; then
                echo "   ✅ Added to project"
            else
                echo "   ⚠️  Could not add to project (may need extension or different method)"
            fi
        fi

        # Rate limiting
        sleep 1
    else
        echo "   ❌ Failed to create issue"
        SKIPPED=$((SKIPPED + 1))
    fi

    echo ""

done < "$TEMP_STORIES"

# Final summary
echo "=========================================="
echo "✅ Complete!"
echo "=========================================="
echo "Created: $CREATED issues"
echo "Skipped: $SKIPPED issues"
echo "Total: $STORY_COUNT stories"
echo ""
echo "Summary file: $SUMMARY_FILE"
echo "=========================================="

# Cleanup
rm -f "$TEMP_STORIES" "$TEMP_ISSUES"

# Show next steps
echo ""
echo "📋 Next Steps:"
echo "   1. Review created issues at: https://github.com/$OWNER/$REPO/issues"
echo "   2. Add issues to project board: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
echo "   3. Review summary: $SUMMARY_FILE"
echo ""
