import 'package:flutter/material.dart';

class ResponsiveSize {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;
  static late double fontSize;

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;

    textScaleFactor = _mediaQueryData.textScaleFactor;
    fontSize = safeBlockHorizontal * 4; // Base font size
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

  // Check if device is a tablet
  static bool isTablet() {
    return screenWidth > mobileBreakpoint && screenWidth <= tabletBreakpoint;
  }

  // Check if device is desktop
  static bool isDesktop() {
    return screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;
  }

  // Check if device is large desktop
  static bool isLargeDesktop() {
    return screenWidth > desktopBreakpoint;
  }

  // Check if device is mobile
  static bool isMobile() {
    return screenWidth <= mobileBreakpoint;
  }

  // Check if device is in landscape mode
  static bool isLandscape() {
    return _mediaQueryData.orientation == Orientation.landscape;
  }

  // Get device type as string
  static String getDeviceType() {
    if (isMobile()) return 'mobile';
    if (isTablet()) return 'tablet';
    if (isDesktop()) return 'desktop';
    if (isLargeDesktop()) return 'large_desktop';
    return 'unknown';
  }

  // Get appropriate max width for content container
  static double getMaxContentWidth() {
    if (isMobile()) return screenWidth;
    if (isTablet()) return 768;
    if (isDesktop()) return 1200;
    if (isLargeDesktop()) return 1400;
    return screenWidth;
  }

  // Get appropriate padding for different screen sizes
  static EdgeInsets getResponsivePadding() {
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

  // Check if we should show desktop layout
  static bool shouldShowDesktopLayout() {
    return isDesktop() || isLargeDesktop();
  }
}
