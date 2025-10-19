#!/bin/bash

# Build script for Wonwonw2 with API key injection
# Usage: ./scripts/build_with_keys.sh [environment]
# Environment: development, staging, production

set -e

ENVIRONMENT=${1:-development}
BUILD_DIR="build/web"

echo "Building Wonwonw2 for $ENVIRONMENT environment..."

# Check if required environment variables are set
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "Error: GOOGLE_MAPS_API_KEY environment variable is not set"
    echo "Please set it with: export GOOGLE_MAPS_API_KEY=your_key_here"
    exit 1
fi

if [ -z "$FIREBASE_API_KEY" ]; then
    echo "Error: FIREBASE_API_KEY environment variable is not set"
    echo "Please set it with: export FIREBASE_API_KEY=your_key_here"
    exit 1
fi

# Build the Flutter web app
echo "Building Flutter web app..."
flutter build web --web-renderer html --release \
    --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
    --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
    --dart-define=ENVIRONMENT="$ENVIRONMENT"

# Replace placeholder API key in index.html
echo "Injecting API keys into web files..."
sed -i.bak "s/YOUR_GOOGLE_MAPS_API_KEY/$GOOGLE_MAPS_API_KEY/g" "$BUILD_DIR/index.html"

# Clean up backup file
rm -f "$BUILD_DIR/index.html.bak"

echo "Build completed successfully!"
echo "Output directory: $BUILD_DIR"
echo "Environment: $ENVIRONMENT"

# Optional: Deploy to Firebase Hosting
if [ "$2" = "deploy" ]; then
    echo "Deploying to Firebase Hosting..."
    firebase deploy --only hosting
fi
