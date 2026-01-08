#!/bin/bash

# FloDoc Ngrok Testing Script
# This script starts Rails with ngrok for public testing of email workflows

set -e

echo "🚀 Starting FloDoc with Ngrok for Public Testing"
echo "================================================"

# Check if ngrok is installed
if ! command -v ~/bin/ngrok &> /dev/null; then
    echo "❌ Ngrok not found. Please install it first."
    echo "   Run: curl -s https://ngrok-agent.s3.amazonaws.com/ngrok/latest/linux-amd64.tgz | tar -xzf - && mv ngrok ~/bin/"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    echo "✅ Loading environment variables from .env"
    source .env
else
    echo "❌ .env file not found"
    exit 1
fi

# Check if ngrok auth token is set
if [ "$NGROK_AUTH_TOKEN" = "your_ngrok_auth_token_here" ] || [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo "❌ Ngrok auth token not configured"
    echo ""
    echo "To set up ngrok:"
    echo "1. Go to https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "2. Sign up for a free account and get your auth token"
    echo "3. Run: ~/bin/ngrok config add-authtoken YOUR_TOKEN_HERE"
    echo "4. Or add NGROK_AUTH_TOKEN=your_token to your .env file"
    echo ""
    echo "Once you have your token, update .env with:"
    echo "NGROK_AUTH_TOKEN=your_actual_token_here"
    exit 1
fi

echo "✅ Ngrok auth token found"

# Kill any existing ngrok processes
echo "🧹 Cleaning up existing processes..."
pkill -f "ngrok http" 2>/dev/null || true
sleep 2

# Start Rails server in background
echo "🚀 Starting Rails server on port 3001..."
bin/rails server -b 0.0.0.0 -p 3001 &
RAILS_PID=$!
echo "   Rails PID: $RAILS_PID"

# Wait for Rails to start
echo "⏳ Waiting for Rails to start..."
sleep 10

# Check if Rails is running
if ! curl -s http://localhost:3001 > /dev/null; then
    echo "❌ Rails failed to start"
    kill $RAILS_PID 2>/dev/null || true
    exit 1
fi

echo "✅ Rails is running on http://localhost:3001"

# Start ngrok
echo "🚀 Starting ngrok tunnel..."
~/bin/ngrok http 3001 > /dev/null &
NGROK_PID=$!
echo "   Ngrok PID: $NGROK_PID"

# Wait for ngrok to establish connection
echo "⏳ Waiting for ngrok tunnel to establish..."
sleep 8

# Get ngrok URL
echo "📡 Fetching ngrok public URL..."
NGROK_URL=$(~/bin/ngrok api tunnels list 2>/dev/null | grep -o '"public_url":"[^"]*"' | cut -d'"' -f4 | head -1)

if [ -z "$NGROK_URL" ]; then
    echo "❌ Failed to get ngrok URL. Trying alternative method..."
    # Alternative method to get URL
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*"' | cut -d'"' -f4 | head -1)
fi

if [ -z "$NGROK_URL" ]; then
    echo "⚠️  Could not automatically retrieve ngrok URL"
    echo "   You can manually check: http://localhost:4040"
    echo "   Or run: ~/bin/ngrok api tunnels list"
    NGROK_URL="https://your-ngrok-url.ngrok.io"  # Placeholder
else
    echo "✅ Ngrok tunnel established: $NGROK_URL"
fi

# Update APP_URL in environment
echo "🔄 Updating APP_URL to: $NGROK_URL"
export APP_URL="$NGROK_URL"

# Update .env file for future runs
if grep -q "APP_URL=" .env; then
    sed -i "s|APP_URL=.*|APP_URL=$NGROK_URL|" .env
else
    echo "APP_URL=$NGROK_URL" >> .env
fi

# Restart Rails with new APP_URL
echo "🔄 Restarting Rails with updated APP_URL..."
kill $RAILS_PID 2>/dev/null || true
sleep 2

bin/rails server -b 0.0.0.0 -p 3001 &
NEW_RAILS_PID=$!
echo "   New Rails PID: $NEW_RAILS_PID"

sleep 5

echo ""
echo "🎉 SETUP COMPLETE!"
echo "=================="
echo ""
echo "📱 Your FloDoc app is now publicly accessible!"
echo ""
echo "🏠 Local URL:  http://localhost:3001"
echo "🌐 Public URL: $NGROK_URL"
echo ""
echo "📧 Email links will use: $NGROK_URL"
echo ""
echo "🔗 Test the workflow:"
echo "   1. Go to: $NGROK_URL/templates"
echo "   2. Upload a PDF and create a template"
echo "   3. Add recipients and send test email"
echo "   4. Check your email and click the link"
echo "   5. Test from any device - even your phone!"
echo ""
echo "📊 Monitor ngrok dashboard: http://localhost:4040"
echo ""
echo "🛑 To stop everything: pkill -f 'rails server' && pkill -f 'ngrok http'"
echo ""
echo "📝 Next steps:"
echo "   - Get your ngrok auth token from https://dashboard.ngrok.com"
echo "   - Update .env with: NGROK_AUTH_TOKEN=your_token"
echo "   - Run this script again for automatic setup"
echo ""

# Keep script running and show status
echo "Press Ctrl+C to stop everything..."
wait