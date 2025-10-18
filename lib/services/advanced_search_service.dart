import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class AdvancedSearchService extends ChangeNotifier {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;
  static const int _maxSuggestions = 8;

  final List<String> _searchHistory = [];
  final List<String> _searchSuggestions = [];
  final Set<String> _popularTerms = {};

  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get searchSuggestions => List.unmodifiable(_searchSuggestions);

  // Initialize the service
  Future<void> initialize() async {
    await _loadSearchHistory();
    _generatePopularTerms();
  }

  // Load search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      _searchHistory.clear();
      _searchHistory.addAll(historyJson);
      appLog('Loaded ${_searchHistory.length} search history items');
    } catch (e) {
      appLog('Error loading search history: $e');
    }
  }

  // Save search history to SharedPreferences
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      appLog('Error saving search history: $e');
    }
  }

  // Add a search term to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty || query.length < 2) return;

    final trimmedQuery = query.trim().toLowerCase();

    // Remove if already exists
    _searchHistory.remove(trimmedQuery);

    // Add to beginning
    _searchHistory.insert(0, trimmedQuery);

    // Keep only max items
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }

    await _saveSearchHistory();
    notifyListeners();
  }

  // Clear search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
    notifyListeners();
  }

  // Remove specific item from history
  Future<void> removeFromHistory(String query) async {
    _searchHistory.remove(query.toLowerCase());
    await _saveSearchHistory();
    notifyListeners();
  }

  // Generate search suggestions based on query
  List<String> generateSuggestions(String query, List<RepairShop> shops) {
    if (query.trim().isEmpty) {
      // Return recent history when no query
      return _searchHistory.take(_maxSuggestions).toList();
    }

    final queryLower = query.toLowerCase();
    final suggestions = <String>{};

    // Add matching history items
    for (final historyItem in _searchHistory) {
      if (historyItem.contains(queryLower) &&
          suggestions.length < _maxSuggestions) {
        suggestions.add(historyItem);
      }
    }

    // Add matching shop names
    for (final shop in shops) {
      if (suggestions.length >= _maxSuggestions) break;

      final shopName = shop.name.toLowerCase();
      if (shopName.contains(queryLower) && !suggestions.contains(shopName)) {
        suggestions.add(shop.name);
      }
    }

    // Add matching categories
    for (final shop in shops) {
      if (suggestions.length >= _maxSuggestions) break;

      for (final category in shop.categories) {
        final categoryLower = category.toLowerCase();
        if (categoryLower.contains(queryLower) &&
            !suggestions.contains(categoryLower)) {
          suggestions.add(category);
        }
      }
    }

    // Add matching areas
    for (final shop in shops) {
      if (suggestions.length >= _maxSuggestions) break;

      final areaLower = shop.area.toLowerCase();
      if (areaLower.contains(queryLower) && !suggestions.contains(areaLower)) {
        suggestions.add(shop.area);
      }
    }

    // Add fuzzy matches if we don't have enough suggestions
    if (suggestions.length < _maxSuggestions) {
      final fuzzyMatches = _getFuzzyMatches(queryLower, shops);
      for (final match in fuzzyMatches) {
        if (suggestions.length >= _maxSuggestions) break;
        suggestions.add(match);
      }
    }

    return suggestions.toList();
  }

  // Get fuzzy matches for typo tolerance
  List<String> _getFuzzyMatches(String query, List<RepairShop> shops) {
    final matches = <String>[];

    // Simple fuzzy matching - check for similar terms
    for (final shop in shops) {
      // Check shop names
      if (_isFuzzyMatch(query, shop.name.toLowerCase())) {
        matches.add(shop.name);
      }

      // Check categories
      for (final category in shop.categories) {
        if (_isFuzzyMatch(query, category.toLowerCase())) {
          matches.add(category);
        }
      }

      // Check areas
      if (_isFuzzyMatch(query, shop.area.toLowerCase())) {
        matches.add(shop.area);
      }
    }

    return matches.take(_maxSuggestions ~/ 2).toList();
  }

  // Simple fuzzy matching algorithm
  bool _isFuzzyMatch(String query, String target) {
    if (query.length < 3 || target.length < 3) return false;

    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(query, target);
    final maxDistance = (query.length * 0.3).round(); // Allow 30% difference

    return distance <= maxDistance && distance > 0;
  }

  // Levenshtein distance calculation for fuzzy matching
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Generate popular search terms from shop data
  void _generatePopularTerms() {
    _popularTerms.clear();

    // Add common categories
    _popularTerms.addAll([
      'phone repair',
      'laptop repair',
      'computer repair',
      'tablet repair',
      'watch repair',
      'gaming console',
      'electronics',
      'mobile',
      'screen replacement',
      'battery replacement',
    ]);
  }

  // Perform fuzzy search on shops
  List<RepairShop> fuzzySearch(String query, List<RepairShop> shops) {
    if (query.trim().isEmpty) return shops;

    final queryLower = query.toLowerCase();
    final results = <RepairShop>[];
    final exactMatches = <RepairShop>[];
    final fuzzyMatches = <RepairShop>[];

    for (final shop in shops) {
      bool isExactMatch = false;

      // Check for exact matches first
      if (_hasExactMatch(queryLower, shop)) {
        exactMatches.add(shop);
        isExactMatch = true;
      }

      // Check for fuzzy matches if no exact match
      if (!isExactMatch && _hasFuzzyMatch(queryLower, shop)) {
        fuzzyMatches.add(shop);
      }
    }

    // Return exact matches first, then fuzzy matches
    results.addAll(exactMatches);
    results.addAll(fuzzyMatches);

    return results;
  }

  // Check if shop has exact match
  bool _hasExactMatch(String query, RepairShop shop) {
    return shop.name.toLowerCase().contains(query) ||
        shop.description.toLowerCase().contains(query) ||
        shop.address.toLowerCase().contains(query) ||
        shop.area.toLowerCase().contains(query) ||
        shop.categories.any((cat) => cat.toLowerCase().contains(query)) ||
        shop.subServices.values.any(
          (services) =>
              services.any((service) => service.toLowerCase().contains(query)),
        ) ||
        (shop.phoneNumber?.toLowerCase().contains(query) ?? false) ||
        (shop.district?.toLowerCase().contains(query) ?? false) ||
        (shop.province?.toLowerCase().contains(query) ?? false) ||
        (shop.landmark?.toLowerCase().contains(query) ?? false);
  }

  // Check if shop has fuzzy match
  bool _hasFuzzyMatch(String query, RepairShop shop) {
    return _isFuzzyMatch(query, shop.name.toLowerCase()) ||
        _isFuzzyMatch(query, shop.area.toLowerCase()) ||
        shop.categories.any((cat) => _isFuzzyMatch(query, cat.toLowerCase()));
  }

  // Get search analytics
  Map<String, dynamic> getSearchAnalytics() {
    final topSearches = <String, int>{};

    for (final term in _searchHistory) {
      topSearches[term] = (topSearches[term] ?? 0) + 1;
    }

    final sortedSearches =
        topSearches.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalSearches': _searchHistory.length,
      'uniqueSearches': topSearches.length,
      'topSearches':
          sortedSearches
              .take(10)
              .map((e) => {'term': e.key, 'count': e.value})
              .toList(),
    };
  }
}
