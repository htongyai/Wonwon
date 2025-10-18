import 'package:flutter/material.dart';

class ResponsiveSize {
  static MediaQueryData? _mediaQueryData;
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double blockSizeHorizontal = 0;
  static double blockSizeVertical = 0;
  static double _safeAreaHorizontal = 0;
  static double _safeAreaVertical = 0;
  static double safeBlockHorizontal = 0;
  static double safeBlockVertical = 0;
  static double textScaleFactor = 1.0;
  static double fontSize = 14.0;
  static bool _isInitialized = false;

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData!.padding.left + _mediaQueryData!.padding.right;
    _safeAreaVertical =
        _mediaQueryData!.padding.top + _mediaQueryData!.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    textScaleFactor = _mediaQueryData!.textScaleFactor;
    fontSize = safeBlockHorizontal * 4; // Base font size
    _isInitialized = true;
  }

  // Ensure initialization before accessing values
  static void _ensureInitialized(BuildContext? context) {
    if (!_isInitialized && context != null) {
      init(context);
    }
  }

  // Get responsive width based on screen size
  static double getWidth(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  // Get responsive height based on screen size
  static double getHeight(double percentage) {
    return blockSizeVertical * percentage;
  }

  // Get responsive font size based on screen size
  static double getFontSize(double size) {
    return fontSize * (size / 14); // Using 14 as base size
  }

  // Get responsive font size based on container width
  static double getResponsiveFontSize(double baseSize, double containerWidth) {
    // Base font size calculation
    double responsiveSize = baseSize;

    // Adjust based on container width
    if (containerWidth < 200) {
      responsiveSize = baseSize * 0.7; // Small containers
    } else if (containerWidth < 300) {
      responsiveSize = baseSize * 0.85; // Medium containers
    } else if (containerWidth < 400) {
      responsiveSize = baseSize * 1.0; // Normal containers
    } else if (containerWidth < 500) {
      responsiveSize = baseSize * 1.1; // Large containers
    } else {
      responsiveSize = baseSize * 1.2; // Extra large containers
    }

    // Ensure minimum and maximum sizes
    return responsiveSize.clamp(10.0, 24.0);
  }

  // Check if device is a tablet
  static bool isTablet([BuildContext? context]) {
    _ensureInitialized(context);
    return screenWidth > mobileBreakpoint && screenWidth <= tabletBreakpoint;
  }

  // Check if device is desktop
  static bool isDesktop([BuildContext? context]) {
    _ensureInitialized(context);
    return screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;
  }

  // Check if device is large desktop
  static bool isLargeDesktop([BuildContext? context]) {
    _ensureInitialized(context);
    return screenWidth > desktopBreakpoint;
  }

  // Check if device is mobile
  static bool isMobile([BuildContext? context]) {
    _ensureInitialized(context);
    return screenWidth <= mobileBreakpoint;
  }

  // Check if device is in landscape mode
  static bool isLandscape([BuildContext? context]) {
    _ensureInitialized(context);
    return _mediaQueryData!.orientation == Orientation.landscape;
  }

  // Get device type as string
  static String getDeviceType([BuildContext? context]) {
    _ensureInitialized(context);
    if (isMobile()) return 'mobile';
    if (isTablet()) return 'tablet';
    if (isDesktop()) return 'desktop';
    if (isLargeDesktop()) return 'large_desktop';
    return 'unknown';
  }

  // Get appropriate max width for content container
  static double getMaxContentWidth([BuildContext? context]) {
    _ensureInitialized(context);
    if (isMobile()) return screenWidth;
    if (isTablet()) return 768;
    if (isDesktop()) return 1200;
    if (isLargeDesktop()) return 1400;
    return screenWidth;
  }

  // Check if should show desktop layout
  static bool shouldShowDesktopLayout([BuildContext? context]) {
    _ensureInitialized(context);
    return screenWidth > tabletBreakpoint;
  }

  // Get appropriate padding for different screen sizes
  static EdgeInsets getResponsivePadding([BuildContext? context]) {
    _ensureInitialized(context);
    if (isMobile()) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet()) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Get appropriate spacing for different screen sizes
  static double getResponsiveSpacing() {
    if (isMobile()) return 8.0;
    if (isTablet()) return 12.0;
    return 16.0;
  }

  // Get padding that scales with screen size
  static EdgeInsets getScaledPadding(EdgeInsets padding) {
    return EdgeInsets.only(
      left: getWidth(padding.left / blockSizeHorizontal),
      right: getWidth(padding.right / blockSizeHorizontal),
      top: getHeight(padding.top / blockSizeVertical),
      bottom: getHeight(padding.bottom / blockSizeVertical),
    );
  }

  // Get desktop-specific layout constraints
  static BoxConstraints getDesktopConstraints() {
    return BoxConstraints(
      maxWidth: getMaxContentWidth(),
      minHeight: screenHeight * 0.8,
    );
  }
}
