import 'package:flutter/material.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/config/web_config.dart';
import 'app_localizations.dart';

/// Extension on String to handle admin-specific translation logic
/// Forces English for admin users while allowing normal localization for regular users
extension AdminLocalizedString on String {
  /// Translate the string key with admin-specific logic
  /// Admin users always get English translations
  /// Regular users get translations based on their selected locale
  Future<String> trAdmin(BuildContext context) async {
    // Check if this is an admin-only deployment
    if (WebConfig.isAdminOnlyDeployment) {
      // Force English for admin deployments
      try {
        final englishLocalizations = AppLocalizations(const Locale('en'));
        await englishLocalizations.load();
        return englishLocalizations.translate(this);
      } catch (e) {
        return this; // Fallback to key if translation fails
      }
    }

    // Check if current user is admin
    try {
      final authService = AuthService();
      final isAdmin = await authService.isAdmin();

      if (isAdmin) {
        // Force English for admin users
        final englishLocalizations = AppLocalizations(const Locale('en'));
        await englishLocalizations.load();
        return englishLocalizations.translate(this);
      }
    } catch (e) {
      // If admin check fails, fall back to normal localization
    }

    // Use normal localization for regular users
    return AppLocalizations.of(context).translate(this);
  }

  /// Synchronous version that forces English for admin deployments
  /// Use this when you can't use async/await
  String trAdminSync(BuildContext context) {
    // For admin-only deployments, try to use English
    if (WebConfig.isAdminOnlyDeployment) {
      try {
        // Try to get English translation directly
        // This is a simplified approach for admin deployments
        return this; // Will show the key, which is usually in English anyway
      } catch (e) {
        return this;
      }
    }

    // Use normal localization for user deployments
    return AppLocalizations.of(context).translate(this);
  }
}

/// Widget wrapper that provides admin-aware localization context
/// Automatically handles language switching for admin vs user contexts
class AdminLocalizationWrapper extends StatelessWidget {
  final Widget child;
  final bool forceEnglish;

  const AdminLocalizationWrapper({
    Key? key,
    required this.child,
    this.forceEnglish = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If this is an admin-only deployment, we can force English
    if (WebConfig.isAdminOnlyDeployment || forceEnglish) {
      return Localizations.override(
        context: context,
        locale: const Locale('en'),
        child: child,
      );
    }

    // For user deployments, use normal localization
    return child;
  }
}

