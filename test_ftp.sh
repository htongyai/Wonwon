#!/bin/bash

echo "🔍 Testing FTP connection to 198.54.116.191..."

# Test FTP connection
lftp -u htongyai@fixwonwon.com,Stark3963./ ftp://198.54.116.191:21 <<EOF
set ssl:verify-certificate no
ls
pwd
quit
EOF

echo "✅ FTP connection test completed!"
