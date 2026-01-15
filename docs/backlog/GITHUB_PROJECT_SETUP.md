# GitHub Projects Populator - Setup & Usage Guide

This document explains how to use the scripts to populate your GitHub Projects board with user stories from the FloDoc backlog.

## Overview

You have two options for populating your GitHub project board:

1. **Python Script** (`populate_github_project.py`) - Uses GitHub API directly
2. **Shell Script** (`populate_github_project.sh`) - Uses GitHub CLI (recommended for simplicity)

## Prerequisites

### Option 1: Python Script (GitHub API)

1. **GitHub Personal Access Token**
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate a new token with these scopes:
     - `repo` (Full control of private repositories)
     - `project` (Access to project boards)
   - Save the token securely

2. **Python Dependencies**
   ```bash
   pip install requests
   ```

### Option 2: Shell Script (GitHub CLI) - RECOMMENDED

1. **Install GitHub CLI**
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update
   sudo apt install gh

   # macOS
   brew install gh

   # Or download from: https://cli.github.com/
   ```

2. **Authenticate with GitHub**
   ```bash
   gh auth login
   ```
   - Select: GitHub.com
   - Select: HTTPS
   - Select: Yes (authenticate with Git)
   - Select: Login with a web browser
   - Copy the authentication code and complete in browser

3. **Install gh-project extension**
   ```bash
   gh extension install mislav/gh-project
   ```

## Usage

### Using Shell Script (Recommended)

1. **Make the script executable**
   ```bash
   chmod +x docs/backlog/populate_github_project.sh
   ```

2. **Run the script**
   ```bash
   ./docs/backlog/populate_github_project.sh <owner> <repo> [project_number]
   ```

   **Example:**
   ```bash
   ./docs/backlog/populate_github_project.sh NeoSkosana floDoc-v3 6
   ```

   **Parameters:**
   - `<owner>`: Your GitHub username or organization name
   - `<repo>`: Your repository name
   - `[project_number]`: Your project number (from URL: `https://github.com/users/NeoSkosana/projects/6` → number is `6`)

3. **What the script does:**
   - Parses all 42 stories from `docs/prd/6-epic-details.md`
   - Creates a GitHub issue for each story
   - Adds labels (epic, priority, risk, status, portal type)
   - Adds issues to your project board
   - Generates a summary file: `docs/backlog/github_project_summary.md`

### Using Python Script

1. **Run the script**
   ```bash
   python docs/backlog/populate_github_project.py \
     --token YOUR_GITHUB_TOKEN \
     --owner NeoSkosana \
     --repo floDoc-v3 \
     --project 6
   ```

2. **Dry run (test without creating issues)**
   ```bash
   python docs/backlog/populate_github_project.py \
     --token YOUR_GITHUB_TOKEN \
     --owner NeoSkosana \
     --repo floDoc-v3 \
     --dry-run
   ```

## Project Board Configuration

Your GitHub project board should be configured with these columns:

1. **Todo** - Stories not yet started
2. **In Progress** - Stories being worked on
3. **In Review** - Stories awaiting review
4. **Done** - Completed stories

### Setting Up Custom Fields (Optional)

For better organization, you can add custom fields to your project:

1. **Priority** (Single Select)
   - Critical
   - High
   - Medium
   - Low

2. **Epic** (Single Select)
   - Phase 1 - Foundation
   - Phase 2 - Backend Logic
   - Phase 3 - API Layer
   - Phase 4 - Admin Portal
   - Phase 5 - Student Portal
   - Phase 6 - Sponsor Portal
   - Phase 7 - Testing & QA
   - Phase 8 - Infrastructure & Documentation

3. **Portal** (Single Select)
   - Admin
   - Student
   - Sponsor
   - Backend
   - QA
   - Infrastructure

4. **Risk Level** (Single Select)
   - Low
   - Medium
   - High

## Generated Output

### Summary File

The script generates `docs/backlog/github_project_summary.md` with:

- Total story count
- Stories grouped by epic/phase
- Quick reference table with all metadata
- Links to created issues

### Issue Format

Each issue includes:

```
[Story Number] Story Title

## 📖 User Story
[User story text]

## 📋 Background
[Background context]

## ✅ Acceptance Criteria
[Acceptance criteria]

## 📝 Tasks / Subtasks
[Task list if available]

## 📊 Metadata
- Story Number: X.X
- Epic: [Epic name]
- Priority: [Priority]
- Estimated Effort: [Effort]
- Risk Level: [Risk]
- Status: [Status]
```

### Labels Applied

Each issue gets these labels:

- `story:X.X` - Story number
- `epic:[epic-name]` - Phase/epic identifier
- `priority:[priority]` - Priority level
- `risk:[risk]` - Risk level
- `status:[status]` - Current status
- `portal:[portal-type]` - Portal type (admin/student/sponsor/backend/qa/infrastructure)

## Troubleshooting

### Authentication Issues

**Problem:** `gh auth status` shows not authenticated

**Solution:**
```bash
gh auth login
# Follow the interactive prompts
```

### Permission Issues

**Problem:** `gh issue create` fails with permission error

**Solution:**
- Ensure your token has `repo` scope
- Verify you have write access to the repository
- Check that the repository exists and is accessible

### Project Add Issues

**Problem:** Cannot add issues to project board

**Solution:**
- Verify project number is correct
- Ensure you have admin access to the project
- Try adding manually via GitHub UI
- The script will still create issues even if project add fails

### Rate Limiting

**Problem:** GitHub API rate limit exceeded

**Solution:**
- The script includes a 1-second delay between requests
- For 42 stories, this takes ~1 minute
- If you hit limits, wait 60 minutes and try again
- Consider using a personal access token with higher rate limits

## Manual Project Board Setup

If the script cannot automatically add issues to your project, you can do it manually:

1. Go to your project board: `https://github.com/users/<owner>/projects/<number>`
2. Click "Add items"
3. Search for issues by title: `[1.1]`, `[1.2]`, etc.
4. Drag and drop issues into appropriate columns

## Customization

### Modifying Issue Body

Edit the `create_issue()` method in `populate_github_project.py` to change the issue format.

### Changing Labels

Edit the `_get_labels()` method to customize label generation.

### Filtering Stories

To create only specific stories, modify the script to filter by:
- Epic/Phase
- Priority
- Portal type
- Risk level

## Example Workflow

```bash
# 1. Authenticate with GitHub CLI
gh auth login

# 2. Run the populator script
./docs/backlog/populate_github_project.sh NeoSkosana floDoc-v3 6

# 3. Review the summary
cat docs/backlog/github_project_summary.md

# 4. Go to your project board
# https://github.com/users/NeoSkosana/projects/6

# 5. Organize issues into columns (Todo, In Progress, Done)

# 6. Start working on Story 1.1 (Database Schema Extension)
```

## Next Steps

After populating the project board:

1. **Review all stories** - Ensure they're correctly categorized
2. **Prioritize work** - Assign stories to sprints or milestones
3. **Start with Phase 1** - Foundation stories (1.1, 1.2, 1.3)
4. **Create branches** - Use `git checkout -b story/1.1-database-schema` for each story
5. **Follow the development workflow** - See CLAUDE.md for BMad Core cycle

## Additional Resources

- **Story Details**: `docs/prd/6-epic-details.md`
- **Story Index**: `docs/backlog/STORIES_INDEX.md`
- **Story Summary**: `docs/backlog/STORIES_SUMMARY.md`
- **Presentation**: `docs/backlog/stories-presentation.html`
- **Project Board**: `https://github.com/users/NeoSkosana/projects/6`

## Support

For issues with the scripts:
1. Check the troubleshooting section above
2. Review the script output/logs
3. Verify all prerequisites are installed
4. Check GitHub API status: https://www.githubstatus.com/

---

**Generated:** 2026-01-15
**Version:** 1.0
