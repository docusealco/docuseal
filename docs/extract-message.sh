#!/bin/bash

# Extract conversation messages from feature/brand-colors branch to markdown table
# Usage: ./extract_conversation.sh

CLAUDE_DIR="$HOME/.claude/projects/-home-dev-mode-dev-dyict-projects-floDoc-v3"
OUTPUT_FILE="$HOME/dev/dyict-projects/floDoc-v3/docs/conversation-extract-$(date +%Y%m%d-%H%M%S).md"

cd "$CLAUDE_DIR" || exit 1
LATEST=$(ls -t | head -1)

echo "Processing: $LATEST"
echo "Output will be saved to: $OUTPUT_FILE"

# Create markdown header
cat > "$OUTPUT_FILE" << 'EOF'
# Conversation Extract - feature/brand-colors

| Time | Content |
|------|---------|
EOF

# Process the JSONL file
cat "$LATEST" | jq -r '
  select(.gitBranch == "feature/brand-colors" and .message.content != null) |
  "| \(.timestamp) | \(.message.content | gsub("\n"; "<br>") | gsub("\\|"; "\\|")) |"
' >> "$OUTPUT_FILE"

echo ""
echo "✓ Done! Created: $OUTPUT_FILE"
echo ""
echo "Preview (first 20 lines):"
head -20 "$OUTPUT_FILE"
echo ""
echo "To view full file: cat $OUTPUT_FILE"
echo "Or open in editor: code $OUTPUT_FILE"