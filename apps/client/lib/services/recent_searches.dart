import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's recent search queries locally (SharedPreferences).
///
/// Kept small (max [maxItems]) and deduplicated. Most recent first.
class RecentSearches {
  RecentSearches._();
  static final RecentSearches _instance = RecentSearches._();
  factory RecentSearches() => _instance;

  static const String _prefsKey = 'recent_search_queries';
  static const int maxItems = 6;

  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefsKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = List<String>.from(prefs.getStringList(_prefsKey) ?? []);
      // Remove existing occurrence (case-insensitive) so we bubble to top.
      current.removeWhere((x) => x.toLowerCase() == q.toLowerCase());
      current.insert(0, q);
      while (current.length > maxItems) current.removeLast();
      await prefs.setStringList(_prefsKey, current);
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> remove(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = List<String>.from(prefs.getStringList(_prefsKey) ?? []);
      current.removeWhere((x) => x.toLowerCase() == query.toLowerCase());
      await prefs.setStringList(_prefsKey, current);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
