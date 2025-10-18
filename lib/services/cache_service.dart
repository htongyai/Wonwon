import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Optimized caching service with memory and persistent storage
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Memory cache
  final Map<String, CacheItem> _memoryCache = HashMap();
  final Map<String, Timer> _expirationTimers = HashMap();

  // Cache configuration
  static const int _maxMemoryCacheSize = 200;
  static const Duration _defaultExpiration = Duration(minutes: 15);

  // Persistent storage
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      // Clean up expired persistent cache
      await _cleanupExpiredPersistentCache();

      appLog('CacheService: Initialized successfully');
    } catch (e) {
      appLog('CacheService: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Store data in cache with optional expiration
  Future<void> set<T>(
    String key,
    T data, {
    Duration? expiration,
    bool persistent = false,
    CachePriority priority = CachePriority.normal,
  }) async {
    final exp = expiration ?? _defaultExpiration;
    final expiresAt = DateTime.now().add(exp);

    // Store in memory cache
    _setMemoryCache(key, data, expiresAt, priority);

    // Store in persistent cache if requested
    if (persistent && _isInitialized) {
      await _setPersistentCache(key, data, expiresAt);
    }

    appLog(
      'CacheService: Cached data for key: $key (expires: $expiresAt, persistent: $persistent)',
    );
  }

  /// Get data from cache
  Future<T?> get<T>(String key, {bool checkPersistent = true}) async {
    // Check memory cache first
    final memoryItem = _memoryCache[key];
    if (memoryItem != null && !memoryItem.isExpired) {
      memoryItem.lastAccessed = DateTime.now();
      appLog('CacheService: Cache hit (memory) for key: $key');
      return memoryItem.data as T?;
    }

    // Check persistent cache if enabled
    if (checkPersistent && _isInitialized) {
      final persistentData = await _getPersistentCache<T>(key);
      if (persistentData != null) {
        // Restore to memory cache
        _setMemoryCache(
          key,
          persistentData,
          DateTime.now().add(_defaultExpiration),
          CachePriority.normal,
        );
        appLog('CacheService: Cache hit (persistent) for key: $key');
        return persistentData;
      }
    }

    appLog('CacheService: Cache miss for key: $key');
    return null;
  }

  /// Check if key exists in cache
  bool has(String key) {
    final memoryItem = _memoryCache[key];
    return memoryItem != null && !memoryItem.isExpired;
  }

  /// Remove data from cache
  Future<void> remove(String key) async {
    // Remove from memory cache
    _memoryCache.remove(key);
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);

    // Remove from persistent cache
    if (_isInitialized) {
      await _prefs?.remove('cache_$key');
      await _prefs?.remove('cache_exp_$key');
    }

    appLog('CacheService: Removed cache for key: $key');
  }

  /// Clear all cache
  Future<void> clear() async {
    // Clear memory cache
    _memoryCache.clear();
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();

    // Clear persistent cache
    if (_isInitialized) {
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('cache_')).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }

    appLog('CacheService: All cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final validItems =
        _memoryCache.values.where((item) => !item.isExpired).length;
    final expiredItems = _memoryCache.length - validItems;

    return {
      'memoryItems': _memoryCache.length,
      'validItems': validItems,
      'expiredItems': expiredItems,
      'maxSize': _maxMemoryCacheSize,
      'isInitialized': _isInitialized,
      'lastCleanup': now.toIso8601String(),
    };
  }

  /// Store data in memory cache
  void _setMemoryCache<T>(
    String key,
    T data,
    DateTime expiresAt,
    CachePriority priority,
  ) {
    // Enforce cache size limit
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _evictLeastRecentlyUsed();
    }

    // Cancel existing timer
    _expirationTimers[key]?.cancel();

    // Create cache item
    final item = CacheItem<T>(
      data: data,
      expiresAt: expiresAt,
      priority: priority,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );

    _memoryCache[key] = item;

    // Set expiration timer
    final timeToExpire = expiresAt.difference(DateTime.now());
    if (timeToExpire.isNegative == false) {
      _expirationTimers[key] = Timer(timeToExpire, () {
        _memoryCache.remove(key);
        _expirationTimers.remove(key);
        appLog('CacheService: Auto-expired cache for key: $key');
      });
    }
  }

  /// Store data in persistent cache
  Future<void> _setPersistentCache<T>(
    String key,
    T data,
    DateTime expiresAt,
  ) async {
    try {
      final jsonData = jsonEncode({'data': data, 'type': T.toString()});

      await _prefs?.setString('cache_$key', jsonData);
      await _prefs?.setInt('cache_exp_$key', expiresAt.millisecondsSinceEpoch);
    } catch (e) {
      appLog('CacheService: Failed to set persistent cache for key $key: $e');
    }
  }

  /// Get data from persistent cache
  Future<T?> _getPersistentCache<T>(String key) async {
    try {
      final jsonData = _prefs?.getString('cache_$key');
      final expirationMs = _prefs?.getInt('cache_exp_$key');

      if (jsonData == null || expirationMs == null) return null;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expirationMs);
      if (DateTime.now().isAfter(expiresAt)) {
        // Remove expired data
        await _prefs?.remove('cache_$key');
        await _prefs?.remove('cache_exp_$key');
        return null;
      }

      final decoded = jsonDecode(jsonData);
      return decoded['data'] as T?;
    } catch (e) {
      appLog('CacheService: Failed to get persistent cache for key $key: $e');
      return null;
    }
  }

  /// Clean up expired persistent cache
  Future<void> _cleanupExpiredPersistentCache() async {
    try {
      final keys =
          _prefs!
              .getKeys()
              .where((key) => key.startsWith('cache_exp_'))
              .toList();
      final now = DateTime.now();

      for (final expKey in keys) {
        final expirationMs = _prefs!.getInt(expKey);
        if (expirationMs != null) {
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(expirationMs);
          if (now.isAfter(expiresAt)) {
            final dataKey = expKey.replaceFirst('cache_exp_', 'cache_');
            await _prefs!.remove(dataKey);
            await _prefs!.remove(expKey);
          }
        }
      }

      appLog('CacheService: Cleaned up expired persistent cache');
    } catch (e) {
      appLog('CacheService: Failed to cleanup persistent cache: $e');
    }
  }

  /// Evict least recently used items from memory cache
  void _evictLeastRecentlyUsed() {
    if (_memoryCache.isEmpty) return;

    // Sort by priority and last accessed time
    final sortedEntries =
        _memoryCache.entries.toList()..sort((a, b) {
          // First sort by priority (lower priority gets evicted first)
          final priorityComparison = a.value.priority.index.compareTo(
            b.value.priority.index,
          );
          if (priorityComparison != 0) return priorityComparison;

          // Then sort by last accessed time (older gets evicted first)
          return a.value.lastAccessed.compareTo(b.value.lastAccessed);
        });

    // Remove the least important items (25% of cache)
    final itemsToRemove = (_maxMemoryCacheSize * 0.25).ceil();
    for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _expirationTimers[key]?.cancel();
      _expirationTimers.remove(key);
    }

    appLog('CacheService: Evicted $itemsToRemove items from memory cache');
  }

  /// Dispose resources
  void dispose() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
    _memoryCache.clear();
    appLog('CacheService: Disposed');
  }
}

/// Cache item wrapper
class CacheItem<T> {
  final T data;
  final DateTime expiresAt;
  final CachePriority priority;
  final DateTime createdAt;
  DateTime lastAccessed;

  CacheItem({
    required this.data,
    required this.expiresAt,
    required this.priority,
    required this.createdAt,
    required this.lastAccessed,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache priority levels
enum CachePriority {
  low, // Can be evicted easily
  normal, // Standard priority
  high, // Important data, evict last
  critical, // Never evict unless expired
}

/// Cache key constants
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String shopsList = 'shops_list';
  static const String savedShops = 'saved_shops';
  static const String categories = 'categories';
  static const String forumTopics = 'forum_topics';
  static const String reviews = 'reviews';
  static const String reports = 'reports';
  static const String appSettings = 'app_settings';

  // Dynamic keys
  static String shopDetail(String shopId) => 'shop_detail_$shopId';
  static String userReviews(String userId) => 'user_reviews_$userId';
  static String shopReviews(String shopId) => 'shop_reviews_$shopId';
  static String forumReplies(String topicId) => 'forum_replies_$topicId';
}
