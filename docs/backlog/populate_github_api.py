#!/usr/bin/env python3
"""
GitHub Projects Populator using GitHub API directly.

This script creates issues and adds them to a GitHub project board
using the GitHub REST API and GraphQL API.

Usage:
    # Using environment variable (recommended)
    export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    python populate_github_api.py --owner NeoSkosana --repo floDoc-v3 --project 6

    # Or using command-line argument
    python populate_github_api.py --token "ghp_xxxxxxxxx..." --owner NeoSkosana --repo floDoc-v3 --project 6

Requirements:
    - GitHub Personal Access Token with:
        - repo scope (for creating issues)
        - project scope (for adding to project board)
    - Project number (found in GitHub project URL)
"""

import argparse
import os
import requests
import time
from pathlib import Path
from typing import List, Dict, Optional


class GitHubAPIPopulator:
    """Populates GitHub Projects board using GitHub API directly."""

    def __init__(self, token: str, owner: str, repo: str, project_number: int):
        self.token = token
        self.owner = owner
        self.repo = repo
        self.project_number = project_number
        self.base_url = "https://api.github.com"
        self.graphql_url = "https://api.github.com/graphql"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github.v3+json",
        }
        self.project_node_id = None

    def get_project_node_id(self) -> Optional[str]:
        """Get the project node ID using GraphQL."""
        query = """
        query($owner: String!, $repo: String!, $number: Int!) {
            repository(owner: $owner, name: $repo) {
                project(number: $number) {
                    id
                }
            }
        }
        """
        variables = {
            "owner": self.owner,
            "repo": self.repo,
            "number": self.project_number,
        }

        response = requests.post(
            self.graphql_url,
            json={"query": query, "variables": variables},
            headers=self.headers,
        )

        if response.status_code == 200:
            data = response.json()
            project = data.get("data", {}).get("repository", {}).get("project")
            if project:
                self.project_node_id = project["id"]
                return project["id"]

        # Try alternative: Get project from organization/user
        query2 = """
        query($organization: String!, $number: Int!) {
            organization(login: $organization) {
                project(number: $number) {
                    id
                }
            }
        }
        """
        variables2 = {
            "organization": self.owner,
            "number": self.project_number,
        }

        response2 = requests.post(
            self.graphql_url,
            json={"query": query2, "variables": variables2},
            headers=self.headers,
        )

        if response2.status_code == 200:
            data = response2.json()
            org_data = data.get("data")
            if org_data:
                org = org_data.get("organization")
                if org:
                    project = org.get("project")
                    if project:
                        self.project_node_id = project["id"]
                        return project["id"]

        return None

    def get_issue_node_id(self, issue_number: int) -> Optional[str]:
        """Get the issue node ID using GraphQL."""
        query = """
        query($owner: String!, $repo: String!, $number: Int!) {
            repository(owner: $owner, name: $repo) {
                issue(number: $number) {
                    id
                }
            }
        }
        """
        variables = {
            "owner": self.owner,
            "repo": self.repo,
            "number": issue_number,
        }

        response = requests.post(
            self.graphql_url,
            json={"query": query, "variables": variables},
            headers=self.headers,
        )

        if response.status_code == 200:
            data = response.json()
            issue = data.get("data", {}).get("repository", {}).get("issue")
            if issue:
                return issue["id"]

        return None

    def add_issue_to_project(self, issue_node_id: str) -> bool:
        """Add an issue to the project board using GraphQL."""
        if not self.project_node_id:
            return False

        mutation = """
        mutation($projectId: ID!, $contentId: ID!) {
            addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
                item {
                    id
                }
            }
        }
        """
        variables = {
            "projectId": self.project_node_id,
            "contentId": issue_node_id,
        }

        response = requests.post(
            self.graphql_url,
            json={"query": mutation, "variables": variables},
            headers=self.headers,
        )

        if response.status_code == 200:
            data = response.json()
            if "errors" in data:
                print(f"   ⚠️  GraphQL error: {data['errors']}")
                return False
            return True

        return False

    def create_issue(self, story: Dict) -> Optional[Dict]:
        """Create a GitHub issue for a story."""
        url = f"{self.base_url}/repos/{self.owner}/{self.repo}/issues"

        # Build the issue body
        body_parts = []

        # User Story section
        if story.get('user_story'):
            body_parts.append("## 📖 User Story\n")
            body_parts.append(story['user_story'])
            body_parts.append("")

        # Background section
        if story.get('background'):
            body_parts.append("## 📋 Background\n")
            body_parts.append(story['background'])
            body_parts.append("")

        # Acceptance Criteria section
        if story.get('acceptance'):
            body_parts.append("## ✅ Acceptance Criteria\n")
            body_parts.append(story['acceptance'])
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
            issue = response.json()
            print(f"   ✅ Created issue #{issue['number']}")
            return issue
        else:
            print(f"   ❌ Failed to create issue: {response.status_code}")
            print(f"      Response: {response.text}")
            return None

    def _get_labels(self, story: Dict) -> List[str]:
        """Generate labels based on story metadata."""
        labels = []

        # Story label
        labels.append(f"story:{story['number']}")

        # Epic label - normalize
        epic = story['epic']
        epic_label = epic.lower().replace(" ", "-").replace("&", "").replace("---", "-")
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

        # Portal/type labels based on title
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

    def parse_stories(self, file_path: Path) -> List[Dict]:
        """Parse stories from epic details markdown file."""
        import re

        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Split by stories
        story_pattern = r'### Story ([\d.]+): (.+?)\n\n(.*?)(?=\n### Story [\d.]+:|$)'
        matches = re.findall(story_pattern, content, re.DOTALL)

        stories = []
        for story_num, title, body in matches:
            # Extract metadata
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
            })

        return stories

    def create_all_issues(self, stories: List[Dict]) -> List[Dict]:
        """Create all issues and add to project."""
        created_issues = []

        print(f"\n📝 Creating {len(stories)} issues...\n")

        for i, story in enumerate(stories, 1):
            print(f"[{i}/{len(stories)}] Processing Story {story['number']}: {story['title']}")

            issue = self.create_issue(story)
            if issue:
                created_issues.append(issue)

                # Add to project board
                if self.project_node_id:
                    print(f"   Adding to project #{self.project_number}...")
                    issue_node_id = self.get_issue_node_id(issue['number'])
                    if issue_node_id:
                        if self.add_issue_to_project(issue_node_id):
                            print(f"   ✅ Added to project")
                        else:
                            print(f"   ⚠️  Could not add to project")
                    else:
                        print(f"   ⚠️  Could not get issue node ID")
                else:
                    print(f"   ⚠️  Project node ID not available")

            # Rate limiting
            time.sleep(0.5)

        return created_issues

    def generate_summary(self, stories: List[Dict], created_issues: List[Dict], output_path: Path):
        """Generate a summary markdown file."""
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# GitHub Project - User Stories Summary\n\n")
            f.write(f"**Generated:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Total Stories:** {len(stories)}\n")
            f.write(f"**Issues Created:** {len(created_issues)}\n\n")

            f.write("## Stories Created\n\n")
            f.write("| # | Title | Status | Priority | Epic | Effort | Risk | Issue URL |\n")
            f.write("|---|-------|--------|----------|------|--------|------|-----------|\n")

            for i, story in enumerate(stories):
                issue = created_issues[i] if i < len(created_issues) else None
                if issue:
                    url = issue['html_url']
                    f.write(f"| {story['number']} | **{story['title']}** | {story['status']} | {story['priority']} | {story['epic']} | {story['effort']} | {story['risk']} | [Link]({url}) |\n")
                else:
                    f.write(f"| {story['number']} | **{story['title']}** | {story['status']} | {story['priority']} | {story['epic']} | {story['effort']} | {story['risk']} | ❌ Failed |\n")

            f.write("\n## Quick Reference\n\n")
            for i, story in enumerate(stories):
                issue = created_issues[i] if i < len(created_issues) else None
                f.write(f"### {story['number']}: {story['title']}\n\n")
                f.write(f"**Status:** {story['status']} | **Priority:** {story['priority']} | **Epic:** {story['epic']}\n\n")
                if issue:
                    f.write(f"**Issue:** [{issue['html_url']}]({issue['html_url']})\n\n")
                f.write("**User Story:**\n")
                f.write(story['user_story'])
                f.write("\n\n---\n\n")

        print(f"\n✅ Summary generated: {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Populate GitHub Projects board with user stories using GitHub API"
    )
    parser.add_argument(
        "--token",
        help="GitHub Personal Access Token (defaults to GITHUB_TOKEN env var)"
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
        type=int,
        required=True,
        help="GitHub Project number"
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

    args = parser.parse_args()

    # Get token from args or environment variable
    token = args.token or os.environ.get("GITHUB_TOKEN")
    if not token:
        print("❌ No token provided!")
        print("   Either:")
        print("   1. Set GITHUB_TOKEN environment variable:")
        print("      export GITHUB_TOKEN=\"ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"")
        print("   2. Or use --token argument:")
        print("      --token \"ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"")
        return

    # Parse stories
    input_file = Path(args.input)
    if not input_file.exists():
        print(f"❌ Input file not found: {input_file}")
        return

    print(f"📖 Parsing stories from: {input_file}")
    populator = GitHubAPIPopulator(
        token=token,
        owner=args.owner,
        repo=args.repo,
        project_number=args.project
    )

    stories = populator.parse_stories(input_file)
    print(f"✅ Found {len(stories)} stories\n")

    # Get project node ID
    print(f"🔍 Getting project node ID for project #{args.project}...")
    project_id = populator.get_project_node_id()
    if project_id:
        print(f"✅ Project node ID: {project_id}\n")
    else:
        print(f"⚠️  Could not get project node ID. Issues will be created but not added to project.\n")

    # Create issues
    created_issues = populator.create_all_issues(stories)

    # Generate summary
    populator.generate_summary(stories, created_issues, Path(args.output))

    print(f"\n{'='*60}")
    print(f"✅ Complete!")
    print(f"   Created {len(created_issues)} issues")
    print(f"   Summary: {args.output}")
    print(f"{'='*60}")

    print(f"\n📋 Next Steps:")
    print(f"   1. Review created issues at: https://github.com/{args.owner}/{args.repo}/issues")
    print(f"   2. Add issues to project board: https://github.com/users/{args.owner}/projects/{args.project}")
    print(f"   3. Review summary: {args.output}")


if __name__ == '__main__':
    main()
