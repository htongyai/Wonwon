import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension on String to simplify translation lookup in widgets
/// Allows using the more readable 'some_key'.tr(context) syntax
/// instead of AppLocalizations.of(context).translate('some_key')
extension LocalizedString on String {
  /// Translate the string key to the current locale
  /// Example usage: 'welcome_message'.tr(context)
  String tr(BuildContext context) {
    return AppLocalizations.of(context).translate(this);
  }
}

/// Widget that wraps a child with a StreamBuilder to react to locale changes
/// This allows the child widget to rebuild when the app language changes
/// without requiring manual state management in each screen
class AppLocalizationsWrapper extends StatelessWidget {
  // The child widget that will be rebuilt when locale changes
  final Widget child;

  const AppLocalizationsWrapper({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Locale>(
      // Listen for changes to the app locale
      stream: AppLocalizationsService().localeStream,
      builder: (context, snapshot) {
        // Return the child widget which will rebuild when locale changes
        return child;
      },
    );
  }
}
