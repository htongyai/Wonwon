import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize ResponsiveSize if needed
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    // Increase height by 5% (from 6% to 11% of screen height)
    final navBarHeight = ResponsiveSize.getHeight(7);

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _NavBarPatternPainter(
                color: AppConstants.primaryColor.withOpacity(0.03),
              ),
            ),
          ),

          // Bottom nav items
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use the available height to scale icons and text
                final availableHeight = constraints.maxHeight;

                // Calculate icon and text sizes based on height
                final iconSize = availableHeight * 0.3; // 30% of height
                final textSize = availableHeight * 0.16; // 12% of height
                final dotSize = availableHeight * 0.05; // 5% of height
                final topIndicatorHeight =
                    availableHeight * 0.04; // 4% of height

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context,
                      0,
                      FontAwesomeIcons.house,
                      'home',
                      availableHeight,
                      iconSize,
                      textSize,
                      dotSize,
                      topIndicatorHeight,
                    ),
                    _buildNavItem(
                      context,
                      1,
                      FontAwesomeIcons.mapLocationDot,
                      'search',
                      availableHeight,
                      iconSize,
                      textSize,
                      dotSize,
                      topIndicatorHeight,
                    ),
                    _buildNavItem(
                      context,
                      2,
                      FontAwesomeIcons.bookmark,
                      'saved_locations',
                      availableHeight,
                      iconSize,
                      textSize,
                      dotSize,
                      topIndicatorHeight,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String labelKey,
    double availableHeight,
    double iconSize,
    double textSize,
    double dotSize,
    double topIndicatorHeight,
  ) {
    final isSelected = currentIndex == index;

    // Calculate spacings based on available height
    final verticalPadding = availableHeight * 0.05; // 5% of available height
    final spaceBetween = availableHeight * 0.06; // 6% of available height

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top indicator for selected tab
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: topIndicatorHeight,
            width: ResponsiveSize.getWidth(8),
            margin: EdgeInsets.only(
              bottom: verticalPadding,
              top: verticalPadding / 2,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppConstants.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // Main navigation item container
          Container(
            width: ResponsiveSize.getWidth(25),
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon sized based on available height
                FaIcon(
                  icon,
                  size: isSelected ? iconSize * 1.1 : iconSize,
                  color:
                      isSelected ? AppConstants.primaryColor : Colors.grey[500],
                ),
                SizedBox(height: spaceBetween),
                Text(
                  labelKey.tr(context),
                  style: GoogleFonts.montserrat(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: textSize,
                    color:
                        isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey[500],
                  ),
                ),

                // Dot indicator
                SizedBox(height: spaceBetween * 0.7),
                // AnimatedContainer(
                //   duration: const Duration(milliseconds: 300),
                //   height: dotSize,
                //   width: isSelected ? dotSize * 5 : 0,
                //   decoration: BoxDecoration(
                //     color: AppConstants.primaryColor,
                //     borderRadius: BorderRadius.circular(5),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the subtle pattern in the nav bar background
class _NavBarPatternPainter extends CustomPainter {
  final Color color;

  _NavBarPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw small dots in a grid pattern (reduced density)
    final dotSize = 1.5;
    final spacing = 25.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }

    // Draw fewer larger dots for variety
    final accentPaint =
        Paint()
          ..color = color.withOpacity(0.06)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.5),
      5,
      accentPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.5),
      6,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
