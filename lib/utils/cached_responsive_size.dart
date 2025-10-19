import 'package:flutter/material.dart';
import '../constants/responsive_breakpoints.dart';
import '../constants/design_tokens.dart';

/// Cached responsive size utility for better performance
/// Caches calculations to avoid repeated computations
class CachedResponsiveSize {
  static final Map<String, dynamic> _cache = <String, dynamic>{};
  static double _lastScreenWidth = 0;
  static double _lastScreenHeight = 0;

  // Cache keys
  static const String _widthKey = 'width';
  static const String _heightKey = 'height';
  static const String _fontSizeKey = 'fontSize';
  static const String _paddingKey = 'padding';
  static const String _sidebarWidthKey = 'sidebarWidth';
  static const String _navBarHeightKey = 'navBarHeight';

  /// Initialize with context and cache basic values
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Only update cache if screen size changed
    if (_lastScreenWidth != screenWidth || _lastScreenHeight != screenHeight) {
      _lastScreenWidth = screenWidth;
      _lastScreenHeight = screenHeight;

      // Clear cache when screen size changes
      _cache.clear();

      // Cache basic values
      _cache[_widthKey] = screenWidth;
      _cache[_heightKey] = screenHeight;
    }
  }

  /// Get cached screen width
  static double getScreenWidth() => _cache[_widthKey] ?? 0;

  /// Get cached screen height
  static double getScreenHeight() => _cache[_heightKey] ?? 0;

  /// Get cached responsive font size
  static double getCachedFontSize(double baseSize) {
    final key = '${_fontSizeKey}_$baseSize';
    return _cache.putIfAbsent(
      key,
      () => DesignTokens.getResponsiveFontSize(baseSize, getScreenWidth()),
    );
  }

  /// Get cached responsive padding
  static EdgeInsets getCachedPadding() {
    const key = _paddingKey;
    if (_cache.containsKey(key)) {
      return _cache[key] as EdgeInsets;
    }
    final padding = DesignTokens.getResponsivePadding(getScreenWidth());
    _cache[key] = padding;
    return padding;
  }

  /// Get cached sidebar width
  static double getCachedSidebarWidth() {
    const key = _sidebarWidthKey;
    return _cache.putIfAbsent(
      key,
      () => DesignTokens.getResponsiveSidebarWidth(getScreenWidth()),
    );
  }

  /// Get cached navigation bar height
  static double getCachedNavBarHeight() {
    const key = _navBarHeightKey;
    return _cache.putIfAbsent(
      key,
      () => DesignTokens.getResponsiveNavBarHeight(getScreenHeight()),
    );
  }

  /// Get cached device type
  static String getCachedDeviceType() {
    const key = 'deviceType';
    if (_cache.containsKey(key)) {
      return _cache[key] as String;
    }
    final deviceType = ResponsiveBreakpoints.getDeviceType(getScreenWidth());
    _cache[key] = deviceType;
    return deviceType;
  }

  /// Check if should show desktop layout (cached)
  static bool shouldShowDesktopLayout() {
    const key = 'shouldShowDesktop';
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    final shouldShow = ResponsiveBreakpoints.shouldShowDesktopLayout(
      getScreenWidth(),
    );
    _cache[key] = shouldShow;
    return shouldShow;
  }

  /// Check if should show tablet layout (cached)
  static bool shouldShowTabletLayout() {
    const key = 'shouldShowTablet';
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    final shouldShow = ResponsiveBreakpoints.shouldShowTabletLayout(
      getScreenWidth(),
    );
    _cache[key] = shouldShow;
    return shouldShow;
  }

  /// Check if is mobile (cached)
  static bool isMobile() {
    const key = 'isMobile';
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    final isMobile = ResponsiveBreakpoints.isMobile(getScreenWidth());
    _cache[key] = isMobile;
    return isMobile;
  }

  /// Check if is tablet (cached)
  static bool isTablet() {
    const key = 'isTablet';
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    final isTablet = ResponsiveBreakpoints.isTablet(getScreenWidth());
    _cache[key] = isTablet;
    return isTablet;
  }

  /// Check if is desktop (cached)
  static bool isDesktop() {
    const key = 'isDesktop';
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    final isDesktop = ResponsiveBreakpoints.isDesktop(getScreenWidth());
    _cache[key] = isDesktop;
    return isDesktop;
  }

  /// Check if is large desktop (cached)
  static bool isLargeDesktop() {
    const key = 'isLargeDesktop';
    if (_cache.containsKey(key)) {
      return _cache[key] as bool;
    }
    final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(
      getScreenWidth(),
    );
    _cache[key] = isLargeDesktop;
    return isLargeDesktop;
  }

  /// Clear cache (useful for testing or memory management)
  static void clearCache() {
    _cache.clear();
    _lastScreenWidth = 0;
    _lastScreenHeight = 0;
  }

  /// Get cache size (for debugging)
  static int getCacheSize() => _cache.length;

  /// Get cache keys (for debugging)
  static List<String> getCacheKeys() => _cache.keys.toList();
}
