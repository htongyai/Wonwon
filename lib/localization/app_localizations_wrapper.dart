import 'package:flutter/material.dart';
import 'app_localizations.dart';

// Extension to make string translation easier
extension LocalizedString on String {
  String tr(BuildContext context) {
    return AppLocalizations.of(context).translate(this);
  }
}

// Wrapper for static access without context
class AppLocalizationsWrapper extends StatelessWidget {
  final Widget child;

  const AppLocalizationsWrapper({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Locale>(
      stream: AppLocalizationsService().localeStream,
      builder: (context, snapshot) {
        return child;
      },
    );
  }
}
