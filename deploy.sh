#!/bin/bash

# 1. Build the web app
flutter build web --release

# 2. Upload via FTP
lftp -u htongyai@augmaimaginarium.com,Volta3963./ ftp://ftp.augmaimaginarium.com <<EOF
set ssl:verify-certificate no
mirror -R build/web .
quit
EOF

echo "✅ Deployment finished!"
