#!/bin/bash

# Setup deployment dependencies

echo "🔧 Setting up deployment environment..."

# Check if Hugo is available
if ! command -v hugo >/dev/null 2>&1; then
    echo "❌ Hugo not found. Please install Hugo first:"
    echo "   https://gohugo.io/installation/"
    exit 1
fi

HUGO_VERSION=$(hugo version)
echo "✅ Hugo found: $HUGO_VERSION"

# Check rsync
if ! command -v rsync >/dev/null 2>&1; then
    echo "❌ rsync not found. Please install rsync"
    exit 1
else
    echo "✅ rsync found"
fi

# Check SSH access to the deploy host (key-based auth via ~/.ssh/config)
if [ -f .env ]; then
    source .env
fi
SSH_HOST="${SSH_HOST:-web3-vps}"
if ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_HOST" "echo ok" >/dev/null 2>&1; then
    echo "✅ SSH access to $SSH_HOST confirmed"
else
    echo "❌ Could not SSH into $SSH_HOST. Check your ~/.ssh/config entry and key."
    exit 1
fi

echo ""
echo "🎉 Setup complete! You can now run:"
echo "   ./quick-deploy.sh    # Deploy the site"
