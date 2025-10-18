#!/bin/bash

echo "🔧 Building Admin Portal..."

# Auto-increment version (optional - comment out if you want to manage versions manually)
# CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
# NEW_VERSION=$(echo $CURRENT_VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
# ./update_version.sh $NEW_VERSION

# Build the web app with admin-only mode
flutter build web --release --dart-define=FORCE_ADMIN_MODE=true --dart-define=DEPLOYMENT_MODE=admin

# Upload to admin subdomain via FTP
echo "📤 Deploying to admin subdomain..."
lftp -u htongyai@fixwonwon.com,Stark3963./ ftp://198.54.116.191:21 <<EOF
set ssl:verify-certificate no
cd admin
mirror -R build/web .
quit
EOF

echo "✅ Admin Portal deployment finished!"
echo "🌐 Admin portal should be available at: https://admin.fixwonwon.com"
