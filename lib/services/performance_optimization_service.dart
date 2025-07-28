import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Cache for storing data
  final Map<String, dynamic> _cache = HashMap();
  final Map<String, DateTime> _cacheTimestamps = HashMap();
  final Map<String, Timer> _cacheTimers = HashMap();

  // Cache configuration
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const int _maxCacheSize = 100;

  // Performance monitoring
  final Map<String, Stopwatch> _operationTimers = HashMap();
  final Map<String, List<Duration>> _operationHistory = HashMap();

  // Prefetch queue
  final Queue<String> _prefetchQueue = Queue();
  bool _isPrefetching = false;

  /// Cache data with optional expiration
  void cacheData(String key, dynamic data, {Duration? expiration}) {
    final expiry = expiration ?? _defaultCacheDuration;

    // Remove old cache entry if exists
    _removeCacheEntry(key);

    // Add new cache entry
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Set up automatic cleanup
    _cacheTimers[key] = Timer(expiry, () => _removeCacheEntry(key));

    // Enforce cache size limit
    _enforceCacheSizeLimit();

    appLog('Cached data for key: $key (expires in ${expiry.inSeconds}s)');
  }

  /// Get cached data if available and not expired
  T? getCachedData<T>(String key) {
    if (!_cache.containsKey(key)) {
      return null;
    }

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) {
      _removeCacheEntry(key);
      return null;
    }

    // Check if cache is expired
    if (DateTime.now().difference(timestamp) > _defaultCacheDuration) {
      _removeCacheEntry(key);
      return null;
    }

    final data = _cache[key];
    if (data is T) {
      appLog('Cache hit for key: $key');
      return data;
    }

    return null;
  }

  /// Remove specific cache entry
  void _removeCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheTimers[key]?.cancel();
    _cacheTimers.remove(key);
  }

  /// Enforce cache size limit by removing oldest entries
  void _enforceCacheSizeLimit() {
    if (_cache.length <= _maxCacheSize) return;

    // Sort by timestamp and remove oldest entries
    final sortedEntries =
        _cacheTimestamps.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove = _cache.length - _maxCacheSize;
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      _removeCacheEntry(key);
    }

    appLog('Cache size limit enforced, removed $entriesToRemove entries');
  }

  /// Clear all cached data
  void clearCache() {
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheTimers.clear();
    appLog('Cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'keys': _cache.keys.toList(),
    };
  }

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationTimers[operationName] = Stopwatch()..start();
    appLog('Started operation: $operationName');
  }

  /// End timing an operation and record the duration
  Duration endOperation(String operationName) {
    final timer = _operationTimers[operationName];
    if (timer == null) {
      appLog('Warning: No timer found for operation: $operationName');
      return Duration.zero;
    }

    timer.stop();
    final duration = timer.elapsed;
    _operationTimers.remove(operationName);

    // Record operation history
    _operationHistory.putIfAbsent(operationName, () => []);
    _operationHistory[operationName]!.add(duration);

    // Keep only last 10 measurements
    if (_operationHistory[operationName]!.length > 10) {
      _operationHistory[operationName]!.removeAt(0);
    }

    appLog(
      'Operation completed: $operationName (${duration.inMilliseconds}ms)',
    );
    return duration;
  }

  /// Get operation performance statistics
  Map<String, dynamic> getOperationStats(String operationName) {
    final history = _operationHistory[operationName];
    if (history == null || history.isEmpty) {
      return {'operation': operationName, 'measurements': 0};
    }

    final sorted = List<Duration>.from(history)..sort();
    final avg =
        history.fold<Duration>(Duration.zero, (a, b) => a + b) ~/
        history.length;

    return {
      'operation': operationName,
      'measurements': history.length,
      'average': avg.inMilliseconds,
      'min': sorted.first.inMilliseconds,
      'max': sorted.last.inMilliseconds,
      'median': sorted[sorted.length ~/ 2].inMilliseconds,
    };
  }

  /// Get all operation statistics
  Map<String, Map<String, dynamic>> getAllOperationStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final operation in _operationHistory.keys) {
      stats[operation] = getOperationStats(operation);
    }
    return stats;
  }

  /// Add operation to prefetch queue
  void queuePrefetch(String operationKey) {
    if (!_prefetchQueue.contains(operationKey)) {
      _prefetchQueue.add(operationKey);
      appLog('Queued prefetch: $operationKey');
    }
  }

  /// Process prefetch queue
  Future<void> processPrefetchQueue(
    Future<void> Function(String) prefetchFunction,
  ) async {
    if (_isPrefetching || _prefetchQueue.isEmpty) return;

    _isPrefetching = true;
    appLog(
      'Starting prefetch queue processing (${_prefetchQueue.length} items)',
    );

    try {
      while (_prefetchQueue.isNotEmpty) {
        final operationKey = _prefetchQueue.removeFirst();
        try {
          await prefetchFunction(operationKey);
          appLog('Prefetch completed: $operationKey');
        } catch (e) {
          appLog('Prefetch failed: $operationKey - $e');
        }

        // Small delay to prevent overwhelming the system
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isPrefetching = false;
      appLog('Prefetch queue processing completed');
    }
  }

  /// Optimize list rendering with pagination
  List<T> getPaginatedData<T>(List<T> data, int page, int pageSize) {
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, data.length);

    if (startIndex >= data.length) {
      return [];
    }

    return data.sublist(startIndex, endIndex);
  }

  /// Debounce function calls
  Timer? _debounceTimer;
  void debounce(VoidCallback callback, Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  DateTime? _lastThrottleCall;
  bool throttle(VoidCallback callback, Duration delay) {
    final now = DateTime.now();
    if (_lastThrottleCall == null ||
        now.difference(_lastThrottleCall!) >= delay) {
      _lastThrottleCall = now;
      callback();
      return true;
    }
    return false;
  }

  /// Optimize image loading
  String getOptimizedImageUrl(String originalUrl, {int? width, int? height}) {
    // Add image optimization parameters if supported by your image service
    if (width != null || height != null) {
      final params = <String>[];
      if (width != null) params.add('w=$width');
      if (height != null) params.add('h=$height');

      final separator = originalUrl.contains('?') ? '&' : '?';
      return '$originalUrl$separator${params.join('&')}';
    }

    return originalUrl;
  }

  /// Memory management
  void optimizeMemory() {
    // Clear old cache entries
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultCacheDuration) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _removeCacheEntry(key);
    }

    if (keysToRemove.isNotEmpty) {
      appLog(
        'Memory optimization: removed ${keysToRemove.length} expired cache entries',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    clearCache();
    _debounceTimer?.cancel();
    _operationTimers.clear();
    _operationHistory.clear();
    _prefetchQueue.clear();
  }
}

// Extension for easy access
extension PerformanceOptimization on Object {
  PerformanceOptimizationService get performance =>
      PerformanceOptimizationService();
}
