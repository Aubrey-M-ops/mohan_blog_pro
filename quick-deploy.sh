#!/bin/bash

# Quick Deploy Script for limohan.me
# For daily blog updates after initial setup

set -e

SERVER_IP="107.173.187.190"
USERNAME="root"
PASSWORD="***REMOVED***"
WEB_ROOT="/var/www/html"

echo "🚀 Quick deployment to limohan.me..."

# Build Hugo site
echo "📦 Building site..."
hugo --minify --cleanDestinationDir

# Upload files
echo "📤 Uploading to server..."
if command -v sshpass >/dev/null 2>&1; then
    sshpass -p "$PASSWORD" rsync -avz --delete \
        --exclude '.DS_Store' \
        public/ ${USERNAME}@${SERVER_IP}:${WEB_ROOT}/
else
    rsync -avz --delete public/ ${USERNAME}@${SERVER_IP}:${WEB_ROOT}/
fi

echo "✅ Deployment completed!"
echo "🌐 Visit: https://limohan.me"