import 'package:flutter/foundation.dart';

/// Web-specific configuration and utilities
class WebConfig {
  static const String appTitle = 'WonWon Repair Finder';
  static const String appDescription =
      'Find and connect with repair shops in your area';

  // Deployment mode configuration
  static const bool forceAdminMode = bool.fromEnvironment('FORCE_ADMIN_MODE', defaultValue: false);
  static const bool forceUserMode = bool.fromEnvironment('FORCE_USER_MODE', defaultValue: false);
  static const String deploymentMode = String.fromEnvironment('DEPLOYMENT_MODE', defaultValue: 'auto');

  // Web-specific settings
  static const bool enableServiceWorker = true;
  static const bool enablePWA = true;
  static const int maxCacheSize = 50; // MB

  // Performance settings for web
  static const int webImageCacheSize = 100;
  static const Duration webCacheDuration = Duration(hours: 24);

  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Check if running on mobile web
  static bool get isMobileWeb {
    if (!kIsWeb) return false;
    // This is a simplified check - in a real app you'd use a proper user agent parser
    return false; // For now, assume desktop web
  }

  // Deployment mode getters
  static bool get isAdminOnlyDeployment => forceAdminMode || deploymentMode == 'admin';
  static bool get isUserOnlyDeployment => forceUserMode || deploymentMode == 'user';
  static bool get isAutoModeDeployment => !forceAdminMode && !forceUserMode && deploymentMode == 'auto';

  // Get app title based on deployment mode
  static String getAppTitle() {
    if (isAdminOnlyDeployment) return '$appTitle - Admin Portal';
    if (isUserOnlyDeployment) return '$appTitle - User Portal';
    return appTitle;
  }

  // Get appropriate image quality for web
  static int getImageQuality() {
    return isWeb ? 85 : 95; // Lower quality for web to reduce bandwidth
  }

  // Get appropriate cache size for platform
  static int getCacheSize() {
    return isWeb ? 50 : 100; // Smaller cache for web
  }

  // Web-specific error handling
  static void handleWebError(dynamic error, StackTrace stackTrace) {
    if (kDebugMode) {
      print('Web Error: $error');
      print('Stack Trace: $stackTrace');
    }

    // In production, you might want to send this to a logging service
    // like Firebase Crashlytics or Sentry
  }

  // Web-specific performance optimizations
  static Map<String, dynamic> getWebOptimizations() {
    return {
      'preloadImages': true,
      'lazyLoadImages': true,
      'compressImages': true,
      'enableCaching': true,
      'minifyAssets': !kDebugMode,
    };
  }
}

/// Web-specific utilities
class WebUtils {
  /// Check if the browser supports a specific feature
  static bool supportsFeature(String feature) {
    // This would typically use dart:html to check browser capabilities
    // For now, return true for common features
    switch (feature) {
      case 'localStorage':
      case 'sessionStorage':
      case 'indexedDB':
      case 'webGL':
      case 'canvas':
        return true;
      default:
        return false;
    }
  }

  /// Get browser information (simplified)
  static Map<String, String> getBrowserInfo() {
    return {
      'userAgent': 'Unknown', // Would use dart:html in real implementation
      'platform': 'Web',
      'language': 'en-US',
    };
  }

  /// Optimize image URL for web
  static String optimizeImageUrl(String url, {int? width, int? height}) {
    if (!WebConfig.isWeb) return url;

    // Add query parameters for image optimization
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);

    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    params['q'] = WebConfig.getImageQuality().toString();

    return uri.replace(queryParameters: params).toString();
  }

  /// Handle web-specific navigation
  static void updateBrowserTitle(String title) {
    if (kIsWeb) {
      // In a real implementation, you'd use dart:html
      // html.document.title = title;
    }
  }

  /// Handle web-specific meta tags
  static void updateMetaTags({
    String? description,
    String? keywords,
    String? author,
  }) {
    if (!kIsWeb) return;

    // In a real implementation, you'd use dart:html to update meta tags
    // This is important for SEO in web apps
  }
}

/// Web-specific constants
class WebConstants {
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  // Web-specific colors (might differ from mobile)
  static const int primaryColorWeb = 0xFF8B4513; // Brown
  static const int secondaryColorWeb = 0xFFF5F5DC; // Beige

  // Web-specific fonts
  static const String primaryFontWeb = 'Roboto';
  static const String secondaryFontWeb = 'Open Sans';

  // API endpoints (might be different for web)
  static const String webApiBaseUrl = 'https://api.wonwon.app';
  static const String webSocketUrl = 'wss://ws.wonwon.app';

  // Web-specific feature flags
  static const bool enableWebAnalytics = true;
  static const bool enableWebPush = true;
  static const bool enableWebShare = true;
}

/// Web performance monitoring
class WebPerformance {
  static final Map<String, DateTime> _startTimes = {};

  static void startMeasurement(String name) {
    _startTimes[name] = DateTime.now();
  }

  static Duration? endMeasurement(String name) {
    final startTime = _startTimes.remove(name);
    if (startTime != null) {
      return DateTime.now().difference(startTime);
    }
    return null;
  }

  static void logWebVitals() {
    if (!kIsWeb || !kDebugMode) return;

    // In a real implementation, you'd measure:
    // - First Contentful Paint (FCP)
    // - Largest Contentful Paint (LCP)
    // - First Input Delay (FID)
    // - Cumulative Layout Shift (CLS)
  }
}
