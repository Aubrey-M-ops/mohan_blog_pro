#!/bin/bash

# Quick Deploy Script for limohan.me
# For daily blog updates after initial setup

set -e

# Load deployment config from .env (not committed to git)
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "❌ .env not found. Copy .env.example to .env and fill in the values."
    exit 1
fi

: "${SSH_HOST:?SSH_HOST not set in .env}"
: "${WEB_ROOT:?WEB_ROOT not set in .env}"

echo "🚀 Quick deployment to limohan.me..."

# Build Hugo site
echo "📦 Building site..."
hugo --minify --cleanDestinationDir

# Upload files (uses SSH key auth via ~/.ssh/config host alias)
echo "📤 Uploading to server..."
rsync -avz --delete \
    --exclude '.DS_Store' \
    public/ "${SSH_HOST}:${WEB_ROOT}/"

echo "✅ Deployment completed!"
echo "🌐 Visit: https://limohan.me"
