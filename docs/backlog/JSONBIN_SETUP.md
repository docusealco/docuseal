# JSONBin Setup Guide for Shared Kanban Board

## 🎯 What is JSONBin?

JSONBin is a free service that lets you store JSON data in the cloud and update it via API calls. This allows your Kanban board state to be **shared across all users** in real-time.

## 📋 Setup Steps (5 minutes)

### Step 1: Sign Up for JSONBin

1. Go to **https://jsonbin.io/**
2. Click **Sign Up** (free tier available)
3. Verify your email address
4. Log in to your dashboard

### Step 2: Get Your API Key

1. After logging in, click on your profile icon (top right)
2. Select **"API Keys"**
3. Copy your **Master Key** (starts with `$2b$`)
4. Keep this key secure - don't share it publicly!

### Step 3: Create a New Bin

**Option A: Create via Dashboard (Easiest)**

1. Click **"Create Bin"** on your dashboard
2. In the content area, paste this initial data:
```json
{
  "1.1": "backlog",
  "1.2": "backlog",
  "1.3": "backlog",
  "2.1": "backlog",
  "2.2": "backlog",
  "2.3": "backlog",
  "2.4": "backlog",
  "2.5": "backlog",
  "2.6": "backlog",
  "2.7": "backlog",
  "2.8": "backlog",
  "3.1": "backlog",
  "3.2": "backlog",
  "3.3": "backlog",
  "3.4": "backlog",
  "4.1": "backlog",
  "4.2": "backlog",
  "4.3": "backlog",
  "4.4": "backlog",
  "4.5": "backlog",
  "4.6": "backlog",
  "4.7": "backlog",
  "4.8": "backlog",
  "4.9": "backlog",
  "4.10": "backlog",
  "5.1": "backlog",
  "5.2": "backlog",
  "5.3": "backlog",
  "5.4": "backlog",
  "5.5": "backlog",
  "6.1": "backlog",
  "6.2": "backlog",
  "7.1": "backlog",
  "7.2": "backlog",
  "7.3": "backlog",
  "7.4": "backlog",
  "7.5": "backlog",
  "8.0": "backlog",
  "8.0.1": "backlog",
  "8.5": "backlog",
  "8.6": "backlog",
  "8.7": "backlog"
}
```
3. Click **"Create"**
4. Copy the **Bin ID** from the URL (e.g., `abc123xyz`)

**Option B: Create via API (Advanced)**

Use the "Create New Bin" button in the Kanban board config modal.

### Step 4: Configure the Kanban Board

1. Open `stories-kanban-shared.html`
2. Click the **"Config"** button (⚙️)
3. Paste your **API Key** and **Bin ID**
4. Click **"Save Configuration"**
5. The board will automatically load the shared state

## 🚀 Deploying to tiiny.host

### Option 1: Upload Shared Version

```bash
# Upload stories-kanban-shared.html to tiiny.host
# This version requires JSONBin configuration
```

### Option 2: Upload with Pre-configured API Key (Advanced)

⚠️ **SECURITY WARNING**: Only do this if you control access to the board!

1. Edit `stories-kanban-shared.html`
2. Find the `config` object in the script
3. Add your API key and Bin ID:
```javascript
let config = {
    apiKey: 'YOUR_API_KEY_HERE',
    binId: 'YOUR_BIN_ID_HERE'
};
```
4. Save and upload to tiiny.host
5. Users won't need to configure anything

## 💡 Usage Tips

### For Team Leaders

1. **Share the URL** with your team
2. **Everyone can drag and drop** stories
3. **Changes sync automatically** when you click Save
4. **Refresh the page** to see others' changes

### For Daily Standups

1. Open the board on a shared screen
2. Move stories as team members report progress
3. Click **Save** after the meeting
4. Everyone sees the updated board

### For Sprint Planning

1. Start with all stories in **Backlog**
2. Drag stories to **To Do** for the sprint
3. Assign stories to team members (use the View button to add notes)
4. Save and share the URL

## 🔒 Security Considerations

### API Key Security

- **Never commit** your API key to public repositories
- **Use environment variables** for production deployments
- **Consider using a proxy** for API calls in production
- **Rotate your API key** if it's exposed

### Access Control

JSONBin free tier doesn't offer access control. For sensitive projects:

1. **Use a private bin** (paid feature)
2. **Implement a backend proxy** that handles authentication
3. **Use JWT tokens** for user authentication

## 💰 Pricing

JSONBin offers:
- **Free tier**: 10,000 requests/month, 100MB storage
- **Pro tier**: $15/month, unlimited requests
- **Enterprise**: Custom pricing

For most teams, the **free tier is sufficient** for Kanban board usage.

## 🔄 Sync Flow

```
User A moves story → Local state updated → Click Save → API call to JSONBin
                                                              ↓
User B refreshes page ← API call to JSONBin ← State saved to cloud
```

## 🐛 Troubleshooting

### "No config" error
- Click **Config** and enter your API Key and Bin ID
- Make sure you're using the correct Bin ID

### "Failed to load from cloud" error
- Check your API Key is correct
- Verify the Bin ID exists
- Check your internet connection
- Try refreshing the page

### Changes not saving
- Click **Save** button (not just drag and drop)
- Check sync status shows "Synced"
- Look for error messages in the browser console

### Multiple users seeing different states
- Each user needs to click **Refresh** to see latest changes
- Changes only sync when **Save** is clicked
- Consider implementing auto-refresh every 30 seconds

## 📊 Monitoring Usage

1. Go to your JSONBin dashboard
2. Click on your bin
3. View **Request Count** and **Last Updated**
4. Monitor for unusual activity

## 🎯 Alternative: Self-Hosted Backend

If you need more control, consider:

1. **Firebase Firestore** (free tier available)
2. **Supabase** (free tier available)
3. **Your own API** with Rails backend
4. **WebSocket server** for real-time sync

## 📚 Example: Firebase Alternative

If you prefer Firebase over JSONBin:

```javascript
// Firebase configuration
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// Save to Firebase
async function saveToFirebase() {
    await db.collection('kanban').doc('board').set(storyStates);
}

// Load from Firebase
async function loadFromFirebase() {
    const doc = await db.collection('kanban').doc('board').get();
    if (doc.exists) {
        storyStates = doc.data();
    }
}
```

## 🎉 Success!

Once configured, your Kanban board will:
- ✅ Sync across all users
- ✅ Persist state in the cloud
- ✅ Allow real-time collaboration
- ✅ Work from any device
- ✅ Update instantly when saved

---

**Need help?** Contact your team lead or check JSONBin documentation at https://docs.jsonbin.io/

**Generated:** 2026-01-15
