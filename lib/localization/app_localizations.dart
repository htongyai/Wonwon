// Import necessary packages for localization support
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main localization class responsible for loading and providing translations
/// Loads language strings from JSON files in assets/lang directory
class AppLocalizations {
  // The locale this instance is providing translations for
  final Locale locale;

  AppLocalizations(this.locale);

  /// Helper method to easily access localization from any widget
  /// Usage: AppLocalizations.of(context).translate('key')
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Static delegate that will be used in the app's localization delegates
  /// This connects the app to the localization system
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Map to store the loaded translations
  late Map<String, String> _localizedStrings;

  /// Load the localization data from JSON files
  /// Returns true when loading is complete
  Future<bool> load() async {
    try {
      // Load the language JSON file from the "lang" folder
      String jsonString = await rootBundle.loadString(
        'assets/lang/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Convert all values to strings
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      // Fallback to English if the requested locale fails
      if (locale.languageCode != 'en') {
        try {
          String jsonString = await rootBundle.loadString(
            'assets/lang/en.json',
          );
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings = jsonMap.map((key, value) {
            return MapEntry(key, value.toString());
          });
          return true;
        } catch (fallbackError) {
          // If even English fails, use empty map with key fallback
          _localizedStrings = {};
          return true;
        }
      } else {
        // If English itself fails, use empty map
        _localizedStrings = {};
        return true;
      }
    }
  }

  /// Translate a key to the corresponding string in the current locale
  /// If the key is not found, returns the key itself as fallback
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Singleton instance for global access
  static final AppLocalizations _instance = AppLocalizations(
    const Locale('th'),
  );
  factory AppLocalizations.instance() => _instance;
}

/// Delegate class that creates AppLocalizations instances
/// This is used by Flutter's localization system
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // List of supported language codes
    // Add new languages here when supporting additional translations
    return ['en', 'th'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Create and load a new AppLocalizations instance for the requested locale
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Service to manage locale changes throughout the app
/// Provides methods to get/set the app's locale and notifies listeners of changes
class AppLocalizationsService {
  // Key for storing the language preference
  static const String LANGUAGE_CODE = 'languageCode';

  // Private constructor for singleton pattern
  AppLocalizationsService._();

  // Singleton instance
  static final AppLocalizationsService _instance = AppLocalizationsService._();

  // Factory constructor to return the singleton instance
  factory AppLocalizationsService() => _instance;

  // Stream controller for broadcasting locale changes
  static final StreamController<Locale> _controller =
      StreamController<Locale>.broadcast();

  // Public stream that widgets can listen to for locale changes
  Stream<Locale> get localeStream => _controller.stream;

  /// Get the user's preferred locale from persistent storage
  /// Defaults to Thai ('th') if not set
  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString(LANGUAGE_CODE) ?? 'th';
    return Locale(languageCode);
  }

  /// Set a new locale and notify all listeners
  /// Persists the selection to SharedPreferences
  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_CODE, languageCode);
    _controller.add(Locale(languageCode));
  }

  /// Close the stream controller when the service is no longer needed
  void dispose() {
    _controller.close();
  }
}
