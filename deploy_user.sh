#!/bin/bash

echo "👥 Building User Portal..."

# Auto-increment version (optional - comment out if you want to manage versions manually)
# CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
# NEW_VERSION=$(echo $CURRENT_VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
# ./update_version.sh $NEW_VERSION

# Build the web app with user-only mode
flutter build web --release --dart-define=FORCE_USER_MODE=true --dart-define=DEPLOYMENT_MODE=user

# Upload to user subdomain via FTP
echo "📤 Deploying to user subdomain..."
lftp -u htongyai@fixwonwon.com,Stark3963./ ftp://198.54.116.191:21 <<EOF
set ssl:verify-certificate no
mkdir -p app
cd app
mirror -R build/web .
quit
EOF

echo "✅ User Portal deployment finished!"
echo "🌐 User portal should be available at: https://app.fixwonwon.com"
