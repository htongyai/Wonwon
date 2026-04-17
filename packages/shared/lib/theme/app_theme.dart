import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static const primaryColor = AppConstants.primaryColor;
  static const errorColor = Colors.red;
  static const successColor = AppConstants.primaryColor;

  static const double defaultBorderRadius = AppConstants.cardBorderRadius;
  static const double defaultPadding = AppConstants.defaultPadding;
  static const double defaultIconSize = 24.0;

  // Cached GoogleFonts TextStyles -- reuse instead of calling GoogleFonts on every build
  static final TextStyle montserrat = GoogleFonts.montserrat();
  static final TextStyle montserratBold = GoogleFonts.montserrat(fontWeight: FontWeight.bold);
  static final TextStyle montserrat12 = GoogleFonts.montserrat(fontSize: 12);
  static final TextStyle montserrat14 = GoogleFonts.montserrat(fontSize: 14);
  static final TextStyle montserrat16 = GoogleFonts.montserrat(fontSize: 16);
  static final TextStyle montserrat18 = GoogleFonts.montserrat(fontSize: 18);
  static final TextStyle montserrat20 = GoogleFonts.montserrat(fontSize: 20);
  static final TextStyle montserrat24 = GoogleFonts.montserrat(fontSize: 24);
  static final TextStyle montserrat14Bold = GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold);
  static final TextStyle montserrat16Bold = GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold);
  static final TextStyle montserrat18Bold = GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold);
  static final TextStyle montserrat20Bold = GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold);
  static final TextStyle montserrat24Bold = GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold);
  static final TextStyle montserrat14Grey = GoogleFonts.montserrat(fontSize: 14, color: Colors.grey);
  static final TextStyle inter = GoogleFonts.inter();
  static final TextStyle inter14 = GoogleFonts.inter(fontSize: 14);
  static final TextStyle inter14Bold = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);
  static final TextStyle inter16 = GoogleFonts.inter(fontSize: 16);
  static final TextStyle inter28Bold = GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700);

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
