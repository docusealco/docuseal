# Quick Start - GitHub Projects Populator

## 🚀 One-Command Setup (Recommended)

```bash
# From the project root
cd docs/backlog && ./populate_github_project.sh NeoSkosana floDoc-v3 6
```

## 📋 Prerequisites (5 minutes)

### 1. Install GitHub CLI
```bash
# macOS
brew install gh

# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh
```

### 2. Authenticate
```bash
gh auth login
# Follow the browser prompts
```

### 3. Install Extension
```bash
gh extension install mislav/gh-project
```

## 🎯 Run the Script

```bash
# Make executable (first time only)
chmod +x docs/backlog/populate_github_project.sh

# Run it
./docs/backlog/populate_github_project.sh NeoSkosana floDoc-v3 6
```

**Parameters:**
- `NeoSkosana` - Your GitHub username
- `floDoc-v3` - Your repository name
- `6` - Your project number (from URL)

## 📊 What Happens

1. **Parses** all 42 stories from `docs/prd/6-epic-details.md`
2. **Creates** GitHub issues for each story
3. **Adds** labels (epic, priority, risk, portal type)
4. **Adds** issues to your project board
5. **Generates** summary file: `docs/backlog/github_project_summary.md`

## 🎨 Issue Format

Each issue contains:
```
[1.1] Database Schema Extension

## 📖 User Story
As a system architect, I want to create the database schema...

## 📋 Background
Based on the PRD analysis, we need three new tables...

## ✅ Acceptance Criteria
Functional:
1. ✅ All three tables created with correct schema
...

## 📊 Metadata
- Story Number: 1.1
- Epic: Phase 1 - Foundation
- Priority: Critical
- Estimated Effort: 2-3 days
- Risk Level: Low
- Status: Draft
```

## 🏷️ Labels Applied

- `story:1.1` - Story identifier
- `epic:phase-1-foundation` - Epic/phase
- `priority:critical` - Priority level
- `risk:low` - Risk level
- `status:draft` - Current status
- `portal:backend` - Portal type

## 🔍 Troubleshooting

### Problem: `gh: command not found`
**Solution:** Install GitHub CLI from https://cli.github.com/

### Problem: Not authenticated
**Solution:** Run `gh auth login`

### Problem: Cannot add to project
**Solution:** Add issues manually via GitHub UI (issues are still created)

### Problem: Permission denied on script
**Solution:** `chmod +x docs/backlog/populate_github_project.sh`

## 📝 Manual Alternative (Python)

If you prefer Python or don't have GitHub CLI:

```bash
# Install dependencies
pip install requests

# Run with token
python docs/backlog/populate_github_project.py \
  --token YOUR_GITHUB_TOKEN \
  --owner NeoSkosana \
  --repo floDoc-v3 \
  --project 6
```

Get token from: GitHub → Settings → Developer settings → Personal access tokens

## 📂 Files Created

| File | Description |
|------|-------------|
| `github_project_summary.md` | Complete story reference with links |
| GitHub Issues (42) | Individual story issues |
| Project Board Cards | Visual kanban cards |

## 🎯 Next Steps

1. **Review** the summary file: `cat docs/backlog/github_project_summary.md`
2. **Visit** your project: `https://github.com/users/NeoSkosana/projects/6`
3. **Organize** issues into columns (Todo, In Progress, Done)
4. **Start** with Story 1.1 (Database Schema Extension)
5. **Follow** the BMad workflow in CLAUDE.md

## 📚 More Info

- **Full Guide:** `docs/backlog/GITHUB_PROJECT_SETUP.md`
- **Story Index:** `docs/backlog/STORIES_INDEX.md`
- **Story Summary:** `docs/backlog/STORIES_SUMMARY.md`
- **Presentation:** `docs/backlog/stories-presentation.html`

---

**Need help?** Check the full guide at `docs/backlog/GITHUB_PROJECT_SETUP.md`
