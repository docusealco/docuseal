# FloDoc User Stories - Presentation Backlog

This directory contains a presentation-style website that displays all user stories from the FloDoc enhancement project.

## Files

### 📄 `stories-kanban.html` (130KB) ⭐⭐ **NEW - BEST CHOICE**
Interactive Kanban board for story management with drag-and-drop.

**Features:**
- **5 columns**: Backlog, To Do, In Progress, Review, Done
- **Drag & drop** stories between columns
- **Real-time state persistence** (localStorage)
- **Search functionality** across all stories
- **Story details modal** with full content
- **Progress tracking** with statistics
- **Save/Reset** functionality
- **FloDoc design system** with purple theme
- **Keyboard shortcuts** (Escape to close modal)

### 📄 `stories-viewer-enhanced.html` (120KB)
Enhanced presentation with left navigation panel and main content area.

**Features:**
- **Left navigation panel** with all stories organized by phase
- **Main content area** for viewing selected story details
- **Search functionality** to find stories quickly
- **Expandable phases** for easy navigation
- **Keyboard navigation** (Arrow keys, Space, Escape)
- **Mobile responsive** with hamburger menu
- **Professional design** following FloDoc design system

### 📄 `stories-presentation.html` (117KB)
The original presentation website with 42 full-viewport slides.

**Features:**
- Full-screen slides for each story
- Navigation: Arrow keys, buttons, or swipe
- Progress bar showing completion
- Clean, professional design

### 📄 `STORIES_SUMMARY.md` (11KB)
Quick reference guide with all stories in markdown format.

### 📄 `generate_presentation.py` (14KB)
Python script that parses the epic details and generates the presentation.

### 📄 `populate_github_project.py` (8KB)
Python script to populate GitHub Projects board with user stories.

### 📄 `populate_github_project.sh` (5KB)
Shell script (recommended) to populate GitHub Projects board using GitHub CLI.

### 📄 `GITHUB_PROJECT_SETUP.md` (8KB)
Complete setup and usage guide for GitHub Projects integration.

## GitHub Projects Integration ⭐ NEW

Automatically populate your GitHub project board with all 42 user stories!

### Quick Start (Recommended)

```bash
# 1. Install GitHub CLI (if not already installed)
#    https://cli.github.com/

# 2. Authenticate
gh auth login

# 3. Install gh-project extension
gh extension install mislav/gh-project

# 4. Run the populator
./populate_github_project.sh NeoSkosana floDoc-v3 6
```

**What you get:**
- ✅ 42 GitHub issues created (one per story)
- ✅ Issues added to your project board automatically
- ✅ Labels applied (epic, priority, risk, portal type)
- ✅ Summary file generated with all story details

**See `GITHUB_PROJECT_SETUP.md` for detailed instructions.**

## How to Use

### View the Presentation

**Option 1: Open in Browser**
```bash
# Navigate to the backlog directory
cd docs/backlog

# Open in your default browser
open stories-presentation.html
# or
xdg-open stories-presentation.html
# or simply double-click the file
```

**Option 2: Serve Locally**
```bash
# Python 3
python3 -m http.server 8000

# Then open: http://localhost:8000/stories-presentation.html
```

### Navigation

- **Next Slide**: `→` Arrow key, `Space`, or click "Next" button
- **Previous Slide**: `←` Arrow key or click "Previous" button
- **Progress**: Top bar shows completion percentage
- **Counter**: Shows current slide / total slides

### Story Structure

Each slide contains:

1. **User Story**: The "As a... I want... So that..." format
2. **Background**: Context and rationale for the story
3. **Acceptance Criteria**: Functional, UI/UX, Integration, Security, and Quality requirements

## Story Breakdown by Epic

### Phase 1: Foundation (3 stories)
- 1.1: Database Schema Extension
- 1.2: Core Models Implementation
- 1.3: Authorization Layer Extension

### Phase 2: Backend Logic (8 stories)
- 2.1: Cohort Creation & Management
- 2.2: TP Signing Phase Logic (High Risk - Prototype First)
- 2.3: Student Enrollment Management
- 2.4: Sponsor Review Workflow
- 2.5: TP Review & Finalization
- 2.6: Excel Export for Cohort Data
- 2.7: Audit Log & Compliance
- 2.8: Cohort State Machine & Workflow Orchestration

### Phase 3: API Layer (4 stories)
- 3.1: RESTful Cohort Management API
- 3.2: Webhook Events for Workflow State Changes
- 3.3: Student API (Ad-hoc Token-Based Access)
- 3.4: API Documentation & Versioning

### Phase 4: Admin Portal (10 stories)
- 4.1: Cohort Management Dashboard
- 4.2: Cohort Creation & Bulk Import
- 4.3: Cohort Detail Overview
- 4.4: TP Signing Interface
- 4.5: Student Management View
- 4.6: Sponsor Portal Dashboard
- 4.7: Sponsor Portal - Bulk Document Signing
- 4.8: Sponsor Portal - Progress Tracking & State Management
- 4.9: Sponsor Portal - Token Renewal & Session Management
- 4.10: TP Portal - Cohort Status Monitoring & Analytics

### Phase 5: Student Portal (5 stories)
- 5.1: Student Portal - Document Upload Interface
- 5.2: Student Portal - Form Filling & Field Completion
- 5.3: Student Portal - Progress Tracking & Save Draft
- 5.4: Student Portal - Submission Confirmation & Status
- 5.5: Student Portal - Email Notifications & Reminders

### Phase 6: Sponsor Portal (2 stories)
- 6.1: Sponsor Portal - Cohort Dashboard & Bulk Signing Interface
- 6.2: Sponsor Portal - Email Notifications & Reminders

### Phase 7: Testing & QA (5 stories)
- 7.1: End-to-End Workflow Testing
- 7.2: Mobile Responsiveness Testing
- 7.3: Performance Testing (50+ Students)
- 7.4: Security Audit & Penetration Testing
- 7.5: User Acceptance Testing

### Phase 8: Infrastructure & Documentation (4 stories)
- 8.0: Development Infrastructure Setup (Local Docker)
- 8.0.1: Management Demo Readiness & Validation
- 8.5: User Communication & Training Materials
- 8.6: In-App User Documentation & Help System
- 8.7: Knowledge Transfer & Operations Documentation

## Regenerating the Presentation

If the source document changes, regenerate the presentation:

```bash
cd docs/backlog
python3 generate_presentation.py
```

## Design Notes

- **Time Limit**: Each story is designed for 4-hour implementation windows
- **Viewport**: Each slide uses full viewport for focused reading
- **Mobile Responsive**: Works on tablets and phones
- **No External Dependencies**: Pure HTML/CSS/JS, works offline
- **Keyboard Navigation**: Accessible via keyboard only

## Next Steps

1. Review all stories in the presentation
2. Prioritize stories for implementation
3. Create individual story branches following BMAD workflow
4. Implement stories with QA gates
5. Merge to master after approval

## GitHub Projects Output

After running the populator script, you'll get:

### Generated Files

1. **`github_project_summary.md`** - Complete story reference with:
   - All 42 stories organized by epic
   - Metadata (priority, risk, effort, status)
   - Links to GitHub issues
   - Quick reference tables

2. **GitHub Issues** - 42 issues created in your repository with:
   - Full story details (User Story, Background, Acceptance Criteria)
   - Metadata in issue body
   - Labels for filtering and organization

3. **Project Board Cards** - Issues added to your project board:
   - Ready to drag between columns
   - Visual progress tracking
   - Team collaboration

### Example Issue Title
```
[1.1] Database Schema Extension
```

### Labels Applied
- `epic:phase-1-foundation`
- `priority:critical`
- `risk:low`
- `status:draft`
- `portal:backend`
- `story:1.1`

## Contact

For questions about specific stories, refer to the original epic details:
- Source: `docs/prd/6-epic-details.md`
- Total size: 832KB
- Total stories: 42

For GitHub Projects integration help:
- Guide: `docs/backlog/GITHUB_PROJECT_SETUP.md`
- Scripts: `populate_github_project.sh` (recommended) or `populate_github_project.py`
