import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';

/// Branded snackbar utility for consistent success / error / info toasts.
///
/// Usage:
///   BrandedSnackBar.success(context, 'Shop saved');
///   BrandedSnackBar.error(context, 'Something went wrong');
///   BrandedSnackBar.info(context, 'Took 5 seconds');
class BrandedSnackBar {
  BrandedSnackBar._();

  static void success(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.white,
      background: const Color(0xFF22C55E),
    );
  }

  static void error(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      iconColor: Colors.white,
      background: const Color(0xFFEF4444),
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      iconColor: Colors.white,
      background: AppConstants.primaryColor,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color background,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        elevation: 4,
        backgroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 2400),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
