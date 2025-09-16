#!/bin/bash

# Setup deployment dependencies

echo "🔧 Setting up deployment environment..."

# Check if sshpass is available
if ! command -v sshpass >/dev/null 2>&1; then
    echo "📦 Installing sshpass..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            brew install sshpass
        else
            echo "❌ Homebrew not found. Please install sshpass manually:"
            echo "   brew install sshpass"
            echo "   or download from: https://sourceforge.net/projects/sshpass/"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y sshpass
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y sshpass
        else
            echo "❌ Please install sshpass manually for your Linux distribution"
        fi
    fi
fi

# Check if Hugo is available
if ! command -v hugo >/dev/null 2>&1; then
    echo "❌ Hugo not found. Please install Hugo first:"
    echo "   https://gohugo.io/installation/"
    exit 1
fi

# Check Hugo version
HUGO_VERSION=$(hugo version)
echo "✅ Hugo found: $HUGO_VERSION"

# Check rsync
if ! command -v rsync >/dev/null 2>&1; then
    echo "❌ rsync not found. Please install rsync"
    exit 1
else
    echo "✅ rsync found"
fi

if command -v sshpass >/dev/null 2>&1; then
    echo "✅ sshpass found"
else
    echo "⚠️  sshpass not found - you'll need to enter passwords manually"
fi

echo ""
echo "🎉 Setup complete! You can now run:"
echo "   ./deploy-https.sh    # Full deployment with HTTPS setup"
echo "   ./quick-deploy.sh    # Quick update (after initial setup)"