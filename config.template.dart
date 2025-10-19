/// Configuration Template for Wonwonw2 App
///
/// This file serves as a template for environment-specific configuration.
/// Copy this file to config.dart and fill in your actual API keys.
///
/// IMPORTANT: Never commit config.dart to version control!

class Config {
  // Firebase Configuration
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY_HERE';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID_HERE';
  static const String firebaseAppId = 'YOUR_FIREBASE_APP_ID_HERE';
  static const String firebaseMessagingSenderId =
      'YOUR_FIREBASE_MESSAGING_SENDER_ID_HERE';

  // Google Maps Configuration
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Analytics Configuration
  static const String analyticsApiKey = 'YOUR_ANALYTICS_API_KEY_HERE';

  // Environment
  static const String environment =
      'development'; // development, staging, production

  // Base URLs
  static const String baseUrl = 'https://your-api-url.com';

  // Feature Flags
  static const bool enableDebugLogging = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
}
