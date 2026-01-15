#!/usr/bin/env python3
"""
Script to populate GitHub Projects board with user stories from the backlog.

This script reads stories from the epic details markdown file and creates
GitHub issues (cards) in the specified project board.

Usage:
    python populate_github_project.py --token <github_token> --project <project_id> --owner <owner> --repo <repo>

Requirements:
    - GitHub Personal Access Token with:
        - repo scope (for creating issues)
        - project scope (for adding to project board)
    - Project ID (found in GitHub project URL)
    - Owner and repository name

Note: This script uses the GitHub GraphQL API for project board operations.
"""

import re
import argparse
import requests
from pathlib import Path
from typing import List, Dict, Optional


class GitHubProjectPopulator:
    """Populates GitHub Projects board with user stories."""

    def __init__(self, token: str, owner: str, repo: str, project_id: str):
        self.token = token
        self.owner = owner
        self.repo = repo
        self.project_id = project_id
        self.base_url = "https://api.github.com"
        self.graphql_url = "https://api.github.com/graphql"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github.v3+json",
        }

    def parse_stories(self, file_path: Path) -> List[Dict]:
        """Parse stories from epic details markdown file."""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Split by stories - looking for ### Story X.X: pattern
        story_pattern = r'### Story ([\d.]+): (.+?)\n\n(.*?)(?=\n### Story [\d.]+:|$)'
        matches = re.findall(story_pattern, content, re.DOTALL)

        stories = []
        for story_num, title, body in matches:
            # Extract Status, Priority, Epic, Estimated Effort, Risk Level
            status_match = re.search(r'\*\*Status\*\*: (.+)', body)
            priority_match = re.search(r'\*\*Priority\*\*: (.+)', body)
            epic_match = re.search(r'\*\*Epic\*\*: (.+)', body)
            effort_match = re.search(r'\*\*Estimated Effort\*\*: (.+)', body)
            risk_match = re.search(r'\*\*Risk Level\*\*: (.+)', body)

            # Extract User Story
            user_story_match = re.search(r'#### User Story\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
            user_story = user_story_match.group(1).strip() if user_story_match else ""

            # Extract Background
            background_match = re.search(r'#### Background\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
            background = background_match.group(1).strip() if background_match else ""

            # Extract Acceptance Criteria
            acceptance_match = re.search(r'#### Acceptance Criteria\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
            acceptance = acceptance_match.group(1).strip() if acceptance_match else ""

            # Extract Tasks/Subtasks if present
            tasks_match = re.search(r'#### Tasks / Subtasks\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
            tasks = tasks_match.group(1).strip() if tasks_match else ""

            stories.append({
                'number': story_num,
                'title': title,
                'status': status_match.group(1).strip() if status_match else "Draft",
                'priority': priority_match.group(1).strip() if priority_match else "Medium",
                'epic': epic_match.group(1).strip() if epic_match else "General",
                'effort': effort_match.group(1).strip() if effort_match else "Unknown",
                'risk': risk_match.group(1).strip() if risk_match else "Low",
                'user_story': user_story,
                'background': background,
                'acceptance': acceptance,
                'tasks': tasks,
            })

        return stories

    def create_issue(self, story: Dict) -> Optional[Dict]:
        """Create a GitHub issue for a story."""
        url = f"{self.base_url}/repos/{self.owner}/{self.repo}/issues"

        # Build the issue body
        body_parts = []

        # User Story section
        if story['user_story']:
            body_parts.append("## 📖 User Story\n")
            body_parts.append(story['user_story'])
            body_parts.append("")

        # Background section
        if story['background']:
            body_parts.append("## 📋 Background\n")
            body_parts.append(story['background'])
            body_parts.append("")

        # Acceptance Criteria section
        if story['acceptance']:
            body_parts.append("## ✅ Acceptance Criteria\n")
            body_parts.append(story['acceptance'])
            body_parts.append("")

        # Tasks/Subtasks section
        if story['tasks']:
            body_parts.append("## 📝 Tasks / Subtasks\n")
            body_parts.append(story['tasks'])
            body_parts.append("")

        # Metadata section
        body_parts.append("## 📊 Metadata\n")
        body_parts.append(f"- **Story Number**: {story['number']}")
        body_parts.append(f"- **Epic**: {story['epic']}")
        body_parts.append(f"- **Priority**: {story['priority']}")
        body_parts.append(f"- **Estimated Effort**: {story['effort']}")
        body_parts.append(f"- **Risk Level**: {story['risk']}")
        body_parts.append(f"- **Status**: {story['status']}")

        issue_data = {
            "title": f"[{story['number']}] {story['title']}",
            "body": "\n".join(body_parts),
            "labels": self._get_labels(story),
        }

        response = requests.post(url, headers=self.headers, json=issue_data)

        if response.status_code == 201:
            print(f"✅ Created issue: {story['number']} - {story['title']}")
            return response.json()
        else:
            print(f"❌ Failed to create issue {story['number']}: {response.status_code}")
            print(f"   Response: {response.text}")
            return None

    def _get_labels(self, story: Dict) -> List[str]:
        """Generate labels based on story metadata."""
        labels = []

        # Epic-based labels
        epic_label = story['epic'].replace(" ", "-").lower()
        labels.append(f"epic:{epic_label}")

        # Priority label
        priority_label = story['priority'].lower()
        labels.append(f"priority:{priority_label}")

        # Risk label
        risk_label = story['risk'].lower()
        labels.append(f"risk:{risk_label}")

        # Status label
        status_label = story['status'].lower().replace(" ", "-")
        labels.append(f"status:{status_label}")

        # Portal-based labels (inferred from title)
        title_lower = story['title'].lower()
        if any(word in title_lower for word in ['admin', 'tp', 'training provider']):
            labels.append("portal:admin")
        elif any(word in title_lower for word in ['student']):
            labels.append("portal:student")
        elif any(word in title_lower for word in ['sponsor']):
            labels.append("portal:sponsor")
        elif any(word in title_lower for word in ['database', 'model', 'api', 'backend']):
            labels.append("type:backend")
        elif any(word in title_lower for word in ['testing', 'qa', 'audit', 'security']):
            labels.append("type:qa")
        elif any(word in title_lower for word in ['infrastructure', 'deployment', 'docs']):
            labels.append("type:infrastructure")

        return labels

    def add_issue_to_project(self, issue: Dict, column: str = "Todo") -> bool:
        """Add an issue to the GitHub project board."""
        # Note: This uses the older Projects v2 API which requires project node ID
        # For simplicity, we'll use the REST API with project card endpoint

        issue_id = issue['number']

        # Try to add to project using GraphQL (Projects v2)
        query = """
        mutation($projectId: ID!, $contentId: ID!) {
            addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
                item {
                    id
                }
            }
        }
        """

        # Get the issue node ID (GraphQL ID)
        # For now, we'll skip this step and just create the issue
        # The user can manually add issues to the project board

        print(f"   Note: Issue {issue_id} created. Add to project manually via GitHub UI.")
        return True

    def create_issues_batch(self, stories: List[Dict]) -> List[Dict]:
        """Create all issues in batch."""
        created_issues = []

        print(f"\n📝 Creating {len(stories)} issues...\n")

        for story in stories:
            issue = self.create_issue(story)
            if issue:
                created_issues.append(issue)
                # Small delay to avoid rate limiting
                import time
                time.sleep(0.5)

        return created_issues

    def generate_summary(self, stories: List[Dict], output_path: Path):
        """Generate a summary markdown file with all stories."""
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# GitHub Project - User Stories Summary\n\n")
            f.write(f"**Total Stories:** {len(stories)}\n\n")
            f.write("## Stories by Phase\n\n")

            # Group by epic
            epics = {}
            for story in stories:
                epic = story['epic']
                if epic not in epics:
                    epics[epic] = []
                epics[epic].append(story)

            for epic, epic_stories in sorted(epics.items()):
                f.write(f"### {epic}\n\n")
                f.write("| # | Title | Priority | Risk | Effort |\n")
                f.write("|---|-------|----------|------|--------|\n")
                for story in epic_stories:
                    f.write(f"| {story['number']} | **{story['title']}** | {story['priority']} | {story['risk']} | {story['effort']} |\n")
                f.write("\n")

            f.write("## Quick Reference\n\n")
            for story in stories:
                f.write(f"### {story['number']}: {story['title']}\n\n")
                f.write(f"**Status:** {story['status']} | **Priority:** {story['priority']} | **Epic:** {story['epic']}\n\n")
                f.write("**User Story:**\n")
                f.write(story['user_story'])
                f.write("\n\n---\n\n")

        print(f"✅ Summary generated: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Populate GitHub Projects board with user stories"
    )
    parser.add_argument(
        "--token",
        required=True,
        help="GitHub Personal Access Token"
    )
    parser.add_argument(
        "--owner",
        required=True,
        help="GitHub repository owner (username or org)"
    )
    parser.add_argument(
        "--repo",
        required=True,
        help="GitHub repository name"
    )
    parser.add_argument(
        "--project",
        help="GitHub Project ID (optional - for adding to project board)"
    )
    parser.add_argument(
        "--input",
        default="/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/prd/6-epic-details.md",
        help="Path to epic details markdown file"
    )
    parser.add_argument(
        "--output",
        default="/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/backlog/github_project_summary.md",
        help="Path to output summary markdown file"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse stories without creating GitHub issues"
    )

    args = parser.parse_args()

    # Parse stories
    input_file = Path(args.input)
    if not input_file.exists():
        print(f"❌ Input file not found: {input_file}")
        return

    print(f"📖 Parsing stories from: {input_file}")
    populator = GitHubProjectPopulator(
        token=args.token,
        owner=args.owner,
        repo=args.repo,
        project_id=args.project or ""
    )

    stories = populator.parse_stories(input_file)
    print(f"✅ Found {len(stories)} stories\n")

    if args.dry_run:
        print("🔍 Dry run mode - showing stories that would be created:\n")
        for story in stories:
            print(f"  [{story['number']}] {story['title']}")
            print(f"      Epic: {story['epic']}, Priority: {story['priority']}, Risk: {story['risk']}")
            print()
        return

    # Create issues
    created_issues = populator.create_issues_batch(stories)

    # Generate summary
    populator.generate_summary(stories, Path(args.output))

    print(f"\n{'='*60}")
    print(f"✅ Complete!")
    print(f"   Created {len(created_issues)} issues")
    print(f"   Summary: {args.output}")
    print(f"{'='*60}")

    if args.project:
        print(f"\n⚠️  Note: Issues created but not added to project board.")
        print(f"   To add issues to project, use GitHub UI or update script to use GraphQL API.")
        print(f"   Project ID: {args.project}")


if __name__ == '__main__':
    main()
