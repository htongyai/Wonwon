#!/bin/bash

echo "🚀 Deploying both Admin and User portals to separate subdomains..."

# Make scripts executable
chmod +x deploy_admin.sh
chmod +x deploy_user.sh

# Deploy admin portal
echo "1️⃣ Deploying Admin Portal..."
./deploy_admin.sh

echo ""
echo "2️⃣ Deploying User Portal..."
./deploy_user.sh

echo ""
echo "🎉 Both deployments completed!"
echo "🔧 Admin Portal: https://admin.fixwonwon.com"
echo "👥 User Portal: https://app.fixwonwon.com"
