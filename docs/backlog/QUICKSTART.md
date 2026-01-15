# Quick Start Guide - FloDoc Stories Presentation

## 🚀 Quick Launch

### ⭐⭐ NEW: Interactive Kanban Board (BEST CHOICE)

**Option 1: Open Kanban Board**
```bash
# Navigate to the backlog directory
cd docs/backlog

# Open the Kanban board
xdg-open stories-kanban.html

# Or on macOS
open stories-kanban.html
```

**Option 2: Serve Kanban Board**
```bash
cd docs/backlog
python3 -m http.server 8000
# Then open: http://localhost:8000/stories-kanban.html
```

### ⭐ Enhanced Viewer with Navigation Panel

**Option 3: Open Enhanced Viewer**
```bash
cd docs/backlog
xdg-open stories-viewer-enhanced.html
```

**Option 4: Serve Enhanced Viewer**
```bash
python3 -m http.server 8000
# Then open: http://localhost:8000/stories-viewer-enhanced.html
```

### Alternative: Original Full-Screen Presentation

**Option 5: Open Original Presentation**
```bash
cd docs/backlog
xdg-open stories-presentation.html
```

**Option 6: Serve Original Presentation**
```bash
python3 -m http.server 8000
# Then open: http://localhost:8000/stories-presentation.html
```

### Quick Reference

**Option 7: Just Read the Summary**
```bash
cat docs/backlog/STORIES_SUMMARY.md
# or
less docs/backlog/STORIES_SUMMARY.md
```

## 📊 What You'll See

### Presentation Website (`stories-presentation.html`)
- **42 full-viewport slides** - one per user story
- **Professional design** with gradient background
- **Keyboard navigation** - Arrow keys or Space
- **Progress bar** - Shows completion percentage
- **Clean layout** - User Story, Background, Acceptance Criteria per slide

### Summary Document (`STORIES_SUMMARY.md`)
- **Quick reference** with all 42 stories
- **User stories only** - Easy to scan
- **Markdown format** - Works in any editor

## 🎯 Navigation Controls

| Action | Keyboard | Mouse |
|--------|----------|-------|
| Next slide | `→` or `Space` | Click "Next" button |
| Previous slide | `←` | Click "Previous" button |
| First/Last | - | Use buttons |

## 📋 Story Breakdown

| Phase | Stories | Focus |
|-------|---------|-------|
| **1. Foundation** | 3 | Database & Models |
| **2. Backend Logic** | 8 | Workflows & Business Logic |
| **3. API Layer** | 4 | REST APIs & Webhooks |
| **4. Admin Portal** | 10 | TP/TP Portal UI |
| **5. Student Portal** | 5 | Student-facing UI |
| **6. Sponsor Portal** | 2 | Sponsor-facing UI |
| **7. Testing & QA** | 5 | Quality assurance |
| **8. Infrastructure** | 4 | Deployment & Docs |

**Total: 42 stories**

## ⏱️ Time Estimates

Each story is designed for **4-hour implementation windows**:
- Small stories: 1-2 hours
- Medium stories: 3-4 hours
- Large stories: 4+ hours (may need splitting)

## 🔄 Regeneration

If the source document changes:

```bash
cd docs/backlog
python3 generate_presentation.py
```

This will regenerate both `stories-presentation.html` and `STORIES_SUMMARY.md`.

## 📁 Files in This Directory

```
docs/backlog/
├── README.md                    # This overview
├── QUICKSTART.md               # This quick start guide
├── stories-presentation.html   # The presentation (118KB)
├── STORIES_SUMMARY.md          # Quick reference (11KB)
└── generate_presentation.py    # Regeneration script (14KB)
```

## 🎯 Next Steps

1. **Review** all stories in the presentation
2. **Prioritize** stories for Sprint 1
3. **Create branches** following BMAD workflow
4. **Implement** with QA gates
5. **Merge** to master after approval

## 💡 Pro Tips

- **Use full-screen mode** in your browser for best experience
- **Bookmark** the presentation for quick access
- **Print** STORIES_SUMMARY.md for team meetings
- **Share** the HTML file with stakeholders for review

## 🐛 Troubleshooting

**HTML won't open?**
- Ensure file extension is `.html`
- Try a different browser
- Check file permissions: `chmod 644 stories-presentation.html`

**Content looks wrong?**
- Regenerate: `python3 generate_presentation.py`
- Check source: `cat ../prd/6-epic-details.md | head -100`

**Want to see a specific story?**
- Use Ctrl+F in the summary document
- Navigate to slide number in presentation

---

**Generated:** 2026-01-15
**Source:** `docs/prd/6-epic-details.md` (832KB)
**Stories:** 42
**Total Time Estimate:** ~168 hours (42 stories × 4 hours)
