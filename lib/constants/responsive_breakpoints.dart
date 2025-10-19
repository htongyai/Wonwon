/// Standardized breakpoint system for responsive design
/// Focuses on main screen sizes: mobile, tablet, desktop, large desktop
class ResponsiveBreakpoints {
  // Main breakpoints
  static const double mobile = 600; // Mobile devices
  static const double tablet = 768; // Tablet portrait
  static const double desktop = 1024; // Desktop and tablet landscape
  static const double largeDesktop = 1400; // Large desktop screens

  // Helper methods for device detection
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) =>
      width >= desktop && width < largeDesktop;
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  // Get device type as string
  static String getDeviceType(double width) {
    if (isMobile(width)) return 'mobile';
    if (isTablet(width)) return 'tablet';
    if (isDesktop(width)) return 'desktop';
    if (isLargeDesktop(width)) return 'large_desktop';
    return 'unknown';
  }

  // Check if should show desktop layout
  static bool shouldShowDesktopLayout(double width) => width >= desktop;

  // Check if should show tablet layout
  static bool shouldShowTabletLayout(double width) =>
      width >= mobile && width < desktop;
}
