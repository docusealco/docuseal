# FloDoc Stories Kanban Board

## 🎯 Overview

The **Kanban Board** is an interactive story management tool that allows you to visually organize and track all 42 FloDoc user stories across 5 workflow columns.

## 📊 Columns

| Column | Color | Purpose |
|--------|-------|---------|
| **Backlog** | Gray | Stories not yet started |
| **To Do** | Yellow | Stories ready to be worked on |
| **In Progress** | Blue | Stories currently being developed |
| **Review** | Red | Stories awaiting QA/review |
| **Done** | Green | Completed stories |

## 🎨 Features

### Core Functionality
- ✅ **Drag & Drop**: Move stories between columns by dragging
- ✅ **State Persistence**: Your board state is saved automatically in browser storage
- ✅ **Search**: Find stories by number, title, epic, or content
- ✅ **Story Details**: Click "View" to see full story information in a modal
- ✅ **Quick Actions**: Move stories to next column with one click
- ✅ **Progress Tracking**: Real-time statistics showing total and completed stories

### Design
- ✅ **FloDoc Design System**: Purple (#784DC7) theme
- ✅ **Visual Indicators**: Priority badges, effort tags, epic names
- ✅ **Responsive**: Works on desktop and tablet
- ✅ **Keyboard Friendly**: Escape to close modals

## 🚀 How to Use

### Opening the Board
```bash
cd docs/backlog
xdg-open stories-kanban.html
```

### Basic Operations

1. **View a Story**: Click the "View" button on any card
2. **Move a Story**: Drag a card to a different column
3. **Quick Move**: Click the "→" button to move to the next column
4. **Search**: Type in the search box to filter stories
5. **Save**: Click "Save" to persist your current board state
6. **Reset**: Click "Reset" to move all stories back to Backlog

### Workflow Example

```
Backlog → To Do → In Progress → Review → Done
```

1. Start with all stories in **Backlog**
2. Move stories to **To Do** when planning Sprint 1
3. Drag to **In Progress** when development starts
4. Move to **Review** when ready for QA
5. Complete by moving to **Done**

## 💾 Data Persistence

- **Automatic Save**: Board state saves to browser localStorage after each change
- **Manual Save**: Use the "Save" button to explicitly save
- **Reset**: Use "Reset" to clear all progress and start fresh
- **No Server Required**: All data stays in your browser

## 🎨 Design System

The Kanban board follows the FloDoc design system:

- **Primary Color**: `#784DC7` (Purple)
- **Column Colors**: Match FloDoc status indicators
- **Typography**: Segoe UI / System fonts
- **Shadows**: Subtle elevation with purple tint
- **Radius**: 7.5px for cards, 12px for columns

## 📱 Responsive Design

- **Desktop**: Full 5-column layout
- **Tablet**: Scrollable horizontal board
- **Mobile**: Optimized for touch interactions

## 🎯 Use Cases

### Sprint Planning
1. Move stories from Backlog to To Do
2. Prioritize within To Do column
3. Start development by moving to In Progress

### Daily Standups
1. Review In Progress column
2. Move completed work to Review
3. Discuss blockers visually

### Sprint Review
1. Filter by Done column
2. Review all completed stories
3. Generate summary from completed work

### Backlog Grooming
1. Search for specific stories
2. View details to understand requirements
3. Reorganize based on new priorities

## 🔧 Technical Details

### Storage
- **Key**: `flodoc-kanban-state`
- **Format**: JSON object mapping story numbers to column IDs
- **Example**: `{"1.1": "done", "1.2": "progress", ...}`

### State Structure
```javascript
{
  "1.1": "backlog",
  "1.2": "todo",
  "1.3": "progress",
  "2.1": "review",
  "2.2": "done"
}
```

### Events
- `dragstart`: Story picked up
- `dragover`: Hovering over column
- `drop`: Story dropped in column
- `click`: View story details

## 📚 Related Files

- `stories-kanban.html` - The Kanban board application
- `stories-viewer-enhanced.html` - Alternative viewer with navigation
- `stories-presentation.html` - Original full-screen slides
- `STORIES_SUMMARY.md` - Quick story reference
- `STORIES_INDEX.md` - Complete story index

## 🚀 Deployment

### Local Development
```bash
python3 -m http.server 8000
# Access: http://localhost:8000/stories-kanban.html
```

### GitHub Pages
1. Push to GitHub repository
2. Enable GitHub Pages
3. Access: `https://username.github.io/repo/stories-kanban.html`

### Netlify
1. Drag `stories-kanban.html` to Netlify Drop
2. Get instant URL
3. Share with team

### CodePen
1. Copy HTML content
2. Paste into CodePen
3. Save and share link

## 🎯 Tips

1. **Use with Team**: Share your screen during planning meetings
2. **Save Frequently**: Click Save before closing browser
3. **Search First**: Use search to find stories quickly
4. **Keyboard Shortcuts**: Use Escape to close modals
5. **Mobile Friendly**: Works great on tablets for standups

## 🐛 Troubleshooting

**Stories not dragging?**
- Ensure you're dragging the card body, not buttons
- Try refreshing the page

**State not saving?**
- Check browser localStorage is enabled
- Try manual Save button

**Search not working?**
- Clear search box to show all stories
- Check for typos

**Modal won't close?**
- Click outside the modal
- Press Escape key

---

**Generated:** 2026-01-15
**Stories:** 42
**Columns:** 5
**File Size:** 130KB
