#!/bin/bash

set -e

echo "🔧 Building Admin Portal from apps/dashboard..."

# Build the dashboard app (new monorepo location)
cd apps/dashboard
flutter pub get
flutter build web --release
cd ../..

# Upload to admin subdomain via FTP
echo "📤 Deploying to admin subdomain..."
lftp -u htongyai@fixwonwon.com,Stark3963./ ftp://198.54.116.191:21 <<EOF
set ssl:verify-certificate no
cd admin
mirror -R apps/dashboard/build/web .
quit
EOF

echo "✅ Admin Portal deployment finished!"
echo "🌐 Admin portal should be available at: https://admin.fixwonwon.com"
