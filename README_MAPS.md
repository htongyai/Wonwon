# Setting Up Google Maps in WonWon Repair Finder

This guide explains how to set up Google Maps in the WonWon Repair Finder app.

## Getting a Google Maps API Key

1. Visit the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to "APIs & Services" > "Library"
4. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API (for web)
5. Go to "APIs & Services" > "Credentials"
6. Click "Create Credentials" > "API Key"
7. Your new API key will be displayed. Copy it.
8. (Optional but recommended) Restrict the API key to only the platforms and APIs you're using

## Setting Up API Key on Different Platforms

### Android

1. Open `android/app/src/main/AndroidManifest.xml`
2. Find the line:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

### iOS

1. Open `ios/Runner/Info.plist`
2. Find the line:
   ```xml
   <key>GMSAPIKey</key>
   <string>YOUR_GOOGLE_MAPS_API_KEY</string>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

### Web

1. Open `web/index.html`
2. Find the line:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

## Securing Your API Key

For production apps, it's important to secure your API key:

1. In Google Cloud Console, go to "APIs & Services" > "Credentials"
2. Select your API key and click "Edit"
3. Under "Application restrictions":
   - For Android: Add your package name and SHA-1 signing certificate
   - For iOS: Add your bundle identifier
   - For Web: Add HTTP referrers to restrict domains

## Troubleshooting

If the map doesn't appear:
1. Check if the API key is correctly set up in all platform files
2. Ensure all required APIs are enabled in the Google Cloud Console
3. For Android, check if the package name matches the one registered in the API key restrictions
4. For iOS, check if the bundle identifier matches the one registered in the API key restrictions

## Note on Billing

Google Maps Platform requires a billing account. There's a $200 monthly free credit, which is typically sufficient for development and small-scale applications. Monitor your usage in the Google Cloud Console. 