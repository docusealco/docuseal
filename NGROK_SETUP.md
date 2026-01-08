# Ngrok Setup for FloDoc Testing

This guide explains how to make your FloDoc app accessible to other devices for testing email workflows.

## Quick Start

### 1. Get Ngrok Auth Token
1. Go to [ngrok.com](https://ngrok.com) and sign up for a free account
2. Go to your dashboard: https://dashboard.ngrok.com/get-started/your-authtoken
3. Copy your auth token

### 2. Configure Ngrok
Run this command with your token:
```bash
~/bin/ngrok config add-authtoken YOUR_TOKEN_HERE
```

Or add to your `.env` file:
```bash
NGROK_AUTH_TOKEN=your_token_here
```

### 3. Start Testing
Run the automated setup script:
```bash
./start_with_ngrok.sh
```

This script will:
- Start Rails on port 3001
- Create a public ngrok tunnel
- Update your APP_URL automatically
- Show you the public URL

## Manual Testing (Alternative)

If you already have Rails running, just start ngrok:
```bash
./start_ngrok_only.sh
```

## How It Works

### The Complete Workflow

1. **Start the system:**
   ```bash
   ./start_with_ngrok.sh
   ```

2. **You'll see output like:**
   ```
   🎉 SETUP COMPLETE!
   ==================

   📱 Your FloDoc app is now publicly accessible!

   🏠 Local URL:  http://localhost:3001
   🌐 Public URL: https://abc123.ngrok.io

   📧 Email links will use: https://abc123.ngrok.io
   ```

3. **Test the email workflow:**
   - Go to `https://abc123.ngrok.io/templates`
   - Upload a PDF and create a template
   - Add recipient email addresses
   - Click "Send" to send invitation emails
   - Check your email inbox
   - Click the invitation link from **any device** (phone, tablet, another computer)

4. **The recipient will see:**
   - The document filling interface
   - Fields mapped from your PDF
   - A form they can complete and sign
   - Submit button to complete the workflow

### Email Links Format
When you send invitations, the links will look like:
```
https://abc123.ngrok.io/s/abc123def456
```

Anyone with this link can access the document, regardless of their location (as long as they have internet).

## Security Notes

⚠️ **Important Security Considerations:**

1. **Only for testing** - Never use ngrok for production or sensitive documents
2. **Public access** - Anyone with the link can access your documents
3. **Temporary** - Ngrok URLs change every time you restart
4. **Rate limits** - Free tier has limitations (6 hours per tunnel, 20 connections/minute)

## Troubleshooting

### Ngrok auth token error
```
❌ Ngrok auth token not configured
```
**Solution:** Add your token to `.env` or run the ngrok auth command

### Rails not starting
```
❌ Rails failed to start
```
**Solution:** Check if port 3001 is available: `lsof -i :3001`

### Can't access from other devices
```
Connection refused
```
**Solution:** Make sure you're using the ngrok URL (https://xxx.ngrok.io), not localhost

### Email links not working
```
This site can't be reached
```
**Solution:** Check that ngrok is running: `~/bin/ngrok api tunnels list`

## Files Created

- `start_with_ngrok.sh` - Complete automated setup
- `start_ngrok_only.sh` - Quick ngrok starter
- `NGROK_SETUP.md` - This guide
- Updated `.env` with ngrok configuration

## Next Steps

Once you have ngrok working:
1. Test the complete 3-party workflow
2. Verify email delivery and link functionality
3. Test from different devices (phone, tablet, etc.)
4. Check that document filling works correctly
5. Verify submission completion notifications

## Cleanup

To stop everything:
```bash
pkill -f "rails server"
pkill -f "ngrok http"
```

## Need Help?

Check the ngrok dashboard for live traffic monitoring:
http://localhost:4040

This shows all requests going through your tunnel in real-time.