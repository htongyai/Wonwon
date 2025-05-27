import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconHelper {
  static IconData getIconFromString(String iconPath, {double? size}) {
    switch (iconPath) {
      case 'FontAwesomeIcons.shirt':
        return FontAwesomeIcons.shirt;
      case 'FontAwesomeIcons.shoePrints':
        return FontAwesomeIcons.shoePrints;
      case 'FontAwesomeIcons.clock':
        return FontAwesomeIcons.clock;
      case 'FontAwesomeIcons.briefcase':
        return FontAwesomeIcons.briefcase;
      case 'FontAwesomeIcons.blender':
        return FontAwesomeIcons.blender;
      case 'FontAwesomeIcons.laptop':
        return FontAwesomeIcons.laptop;
      case 'FontAwesomeIcons.screwdriverWrench':
        return FontAwesomeIcons.screwdriverWrench;
      case 'FontAwesomeIcons.gear':
        return FontAwesomeIcons.gear;
      default:
        return FontAwesomeIcons.screwdriverWrench; // Default icon
    }
  }

  static Widget getCategoryIcon(
    String iconPath, {
    double size = 24.0,
    Color? color,
    Color backgroundColor = Colors.white,
    double padding = 8.0,
    bool withBackground = true,
  }) {
    final IconData iconData = getIconFromString(iconPath);

    if (withBackground) {
      return Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FaIcon(iconData, size: size, color: color),
      );
    } else {
      return FaIcon(iconData, size: size, color: color);
    }
  }

  static Widget getSafeIcon(
    IconData fontAwesomeIcon,
    IconData fallbackIcon, {
    double size = 24.0,
    Color? color,
  }) {
    try {
      // Try to use FontAwesome icon
      return FaIcon(fontAwesomeIcon, size: size, color: color);
    } catch (e) {
      // Fallback to Material icon if FontAwesome fails
      return Icon(fallbackIcon, size: size, color: color);
    }
  }
}
