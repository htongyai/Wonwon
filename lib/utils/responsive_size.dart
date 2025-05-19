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
    return screenWidth > 600;
  }

  // Check if device is in landscape mode
  static bool isLandscape() {
    return _mediaQueryData.orientation == Orientation.landscape;
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
}
