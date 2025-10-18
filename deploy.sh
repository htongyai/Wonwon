#!/bin/bash

# Deployment router script
# Usage: ./deploy.sh [admin|user|both]

if [ "$1" == "admin" ]; then
    echo "🔧 Deploying Admin Portal to /admin folder..."
    ./deploy_admin.sh
elif [ "$1" == "user" ]; then
    echo "👥 Deploying User Portal to /app folder..."
    ./deploy_user.sh
elif [ "$1" == "both" ]; then
    echo "🚀 Deploying Both Portals..."
    ./deploy_both.sh
else
    echo "❌ Please specify deployment target:"
    echo "   ./deploy.sh admin   - Deploy to /admin folder"
    echo "   ./deploy.sh user    - Deploy to /app folder"
    echo "   ./deploy.sh both    - Deploy both portals"
    exit 1
fi
