import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizationsService {
  static const String _languageKey = 'language_code';
  static const String _defaultLanguage = 'th';

  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }
}
