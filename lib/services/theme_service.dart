import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static const ThemeMode _defaultTheme = ThemeMode.system;

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeString = prefs.getString(_themeKey);
    if (themeString == null) return _defaultTheme;

    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == themeString,
      orElse: () => _defaultTheme,
    );
  }
}
