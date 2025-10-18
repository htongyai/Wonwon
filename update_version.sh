#!/bin/bash

# Script to update version numbers across the app
# Usage: ./update_version.sh [new_version]
# Example: ./update_version.sh 1.0.77

if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide a version number"
    echo "Usage: ./update_version.sh [new_version]"
    echo "Example: ./update_version.sh 1.0.77"
    exit 1
fi

NEW_VERSION=$1

echo "🔄 Updating app version to $NEW_VERSION..."

# Update pubspec.yaml
echo "📝 Updating pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# Update web/index.html
echo "📝 Updating web/index.html..."
sed -i.bak "s/const APP_VERSION = '.*';/const APP_VERSION = '$NEW_VERSION';/" web/index.html

# Clean up backup files
rm -f pubspec.yaml.bak web/index.html.bak

echo "✅ Version updated successfully!"
echo "📋 Updated files:"
echo "   - pubspec.yaml: version: $NEW_VERSION"
echo "   - web/index.html: APP_VERSION = '$NEW_VERSION'"
echo ""
echo "🚀 Ready to build and deploy!"
