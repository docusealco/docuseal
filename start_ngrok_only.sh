#!/bin/bash

# Quick ngrok starter for when Rails is already running on port 3001

echo "🚀 Starting ngrok tunnel for FloDoc..."
echo "   (Make sure Rails is running on port 3001 first)"

# Kill existing ngrok
pkill -f "ngrok http" 2>/dev/null || true
sleep 2

# Start ngrok
~/bin/ngrok http 3001 &

sleep 5

# Get URL
echo ""
echo "📡 Your public URLs:"
echo "===================="
~/bin/ngrok api tunnels list 2>/dev/null | grep -o '"public_url":"[^"]*"' | cut -d'"' -f4 | while read url; do
    echo "   $url"
done

echo ""
echo "📊 View live traffic: http://localhost:4040"
echo "🛑 Stop: pkill -f 'ngrok http'"