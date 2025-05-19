import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    // Load the language JSON file from the "lang" folder
    String jsonString = await rootBundle.loadString(
      'assets/lang/${locale.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  // This method will be called from every widget that needs a localized text
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Singleton factory
  static final AppLocalizations _instance = AppLocalizations(
    const Locale('en'),
  );
  factory AppLocalizations.instance() => _instance;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of the supported language codes here
    return ['en', 'th'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually occurs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocalizationsService {
  static const String LANGUAGE_CODE = 'languageCode';

  // Private constructor
  AppLocalizationsService._();

  static final AppLocalizationsService _instance = AppLocalizationsService._();

  // Singleton access
  factory AppLocalizationsService() => _instance;

  static final StreamController<Locale> _controller =
      StreamController<Locale>.broadcast();
  Stream<Locale> get localeStream => _controller.stream;

  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString(LANGUAGE_CODE) ?? 'en';
    return Locale(languageCode);
  }

  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_CODE, languageCode);
    _controller.add(Locale(languageCode));
  }

  void dispose() {
    _controller.close();
  }
}
