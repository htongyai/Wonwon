import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFFc3c130); // Green accent
  static const errorColor = Colors.red;
  static const successColor = Color(0xFFc3c130); // Green accent

  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultIconSize = 24.0;

  static InputDecoration getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool isValid = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(
        prefixIcon,
        color: isValid ? successColor : primaryColor,
      ),
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        vertical: defaultPadding,
        horizontal: defaultPadding,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  static BoxDecoration getAnimatedInputDecoration({required bool isValid}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(defaultBorderRadius),
      border: Border.all(
        color: isValid ? successColor : Colors.grey.shade300,
        width: isValid ? 2 : 1,
      ),
    );
  }

  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
    );
  }

  static TextStyle getTitleStyle() {
    return const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    );
  }

  static TextStyle getSubtitleStyle() {
    return TextStyle(fontSize: 16, color: Colors.grey[600]);
  }
}
