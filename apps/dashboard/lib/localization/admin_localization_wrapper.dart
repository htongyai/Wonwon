import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension on String to handle admin-specific translation logic.
/// Dashboard always uses English translations.
extension AdminLocalizedString on String {
  /// Translate the string key - always returns English for dashboard.
  Future<String> trAdmin(BuildContext context) async {
    try {
      final englishLocalizations = AppLocalizations(const Locale('en'));
      await englishLocalizations.load();
      return englishLocalizations.translate(this);
    } catch (e) {
      return this;
    }
  }

  /// Synchronous version - uses current localization context.
  String trAdminSync(BuildContext context) {
    return AppLocalizations.of(context).translate(this);
  }
}

/// Widget wrapper that forces English localization for the admin dashboard.
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
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: child,
    );
  }
}
