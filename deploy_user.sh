#!/bin/bash

set -e

echo "👥 Building User Portal from apps/client..."

# Build the client app (new monorepo location)
cd apps/client
flutter pub get
flutter build web --release
cd ../..

# Upload to user subdomain via FTP
echo "📤 Deploying to user subdomain..."
lftp -u htongyai@fixwonwon.com,Stark3963./ ftp://198.54.116.191:21 <<EOF
set ssl:verify-certificate no
mkdir -p app
cd app
mirror -R apps/client/build/web .
quit
EOF

echo "✅ User Portal deployment finished!"
echo "🌐 User portal should be available at: https://app.fixwonwon.com"
