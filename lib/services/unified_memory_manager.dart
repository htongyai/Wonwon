import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Unified memory management system that consolidates all memory-related functionality
class UnifiedMemoryManager {
  static final UnifiedMemoryManager _instance =
      UnifiedMemoryManager._internal();
  factory UnifiedMemoryManager() => _instance;
  UnifiedMemoryManager._internal();

  // Core components
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Memory tracking
  final Map<String, WeakReference<Object>> _weakReferences = HashMap();
  final Map<String, DateTime> _lastAccess = HashMap();
  final Map<String, MemoryPriority> _priorities = HashMap();

  // Widget lifecycle tracking
  final Map<String, WidgetLifecycleInfo> _widgetStates = HashMap();

  // Image cache tracking
  final Map<String, ImageCacheInfo> _imageCacheInfo = HashMap();

  // Timers and monitoring
  Timer? _cleanupTimer;
  Timer? _memoryPressureTimer;
  bool _isMonitoring = false;

  // Configuration
  static const Duration cleanupInterval = Duration(minutes: 3);
  static const Duration memoryPressureCheckInterval = Duration(minutes: 1);
  static const Duration maxInactiveTime = Duration(minutes: 20);
  static const int maxWeakReferences = 500;
  static const int maxImageCacheEntries = 100;
  static const double memoryPressureThreshold = 0.8; // 80% memory usage

  /// Initialize the unified memory manager
  Future<void> initialize() async {
    if (_isMonitoring) return;

    appLog('UnifiedMemoryManager: Initializing...');

    _isMonitoring = true;

    // Start cleanup timer
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _performCleanup());

    // Start memory pressure monitoring
    _memoryPressureTimer = Timer.periodic(
      memoryPressureCheckInterval,
      (_) => _checkMemoryPressure(),
    );

    _performanceMonitor.startOperation('unified_memory_monitoring');

    appLog('UnifiedMemoryManager: Initialized successfully');
  }

  /// Stop monitoring and cleanup
  void dispose() {
    _isMonitoring = false;
    _cleanupTimer?.cancel();
    _memoryPressureTimer?.cancel();
    _cleanupTimer = null;
    _memoryPressureTimer = null;

    _performanceMonitor.endOperation('unified_memory_monitoring');

    _weakReferences.clear();
    _lastAccess.clear();
    _priorities.clear();
    _widgetStates.clear();
    _imageCacheInfo.clear();

    appLog('UnifiedMemoryManager: Disposed');
  }

  // ============================================================================
  // OBJECT MEMORY MANAGEMENT
  // ============================================================================

  /// Register an object for memory tracking
  void registerObject(
    String key,
    Object object, {
    MemoryPriority priority = MemoryPriority.normal,
  }) {
    // Enforce size limits
    if (_weakReferences.length >= maxWeakReferences) {
      _performCleanup();
    }

    _weakReferences[key] = WeakReference(object);
    _lastAccess[key] = DateTime.now();
    _priorities[key] = priority;

    // Record metric if method exists
    // _performanceMonitor.recordMetric('memory_objects_registered', _weakReferences.length);
  }

  /// Get a registered object
  T? getObject<T extends Object>(String key) {
    final ref = _weakReferences[key];
    if (ref?.target != null) {
      _lastAccess[key] = DateTime.now();
      return ref!.target as T?;
    }
    return null;
  }

  /// Unregister an object
  void unregisterObject(String key) {
    _weakReferences.remove(key);
    _lastAccess.remove(key);
    _priorities.remove(key);
  }

  // ============================================================================
  // WIDGET LIFECYCLE MANAGEMENT
  // ============================================================================

  /// Register a widget for lifecycle tracking
  void registerWidget(
    String key,
    Widget widget, {
    MemoryPriority priority = MemoryPriority.normal,
  }) {
    _widgetStates[key] = WidgetLifecycleInfo(
      key: key,
      widget: widget,
      createdAt: DateTime.now(),
      lastAccess: DateTime.now(),
      priority: priority,
    );

    // Also register in object tracking
    registerObject(key, widget, priority: priority);

    _performanceMonitor.startOperation('widget_lifecycle_$key');
  }

  /// Update widget state
  void updateWidgetState(String key, Widget widget) {
    final existing = _widgetStates[key];
    if (existing != null) {
      existing.widget = widget;
      existing.lastAccess = DateTime.now();
      existing.updateCount++;
    }
  }

  /// Unregister a widget
  void unregisterWidget(String key) {
    _widgetStates.remove(key);
    unregisterObject(key);
    _performanceMonitor.endOperation('widget_lifecycle_$key');
  }

  /// Track widget build events
  void onWidgetBuild(String key) {
    final info = _widgetStates[key];
    if (info != null) {
      info.buildCount++;
      info.lastAccess = DateTime.now();
    }
  }

  // ============================================================================
  // IMAGE CACHE MANAGEMENT
  // ============================================================================

  /// Register image cache information
  void registerImageCache(
    String url,
    int sizeBytes, {
    MemoryPriority priority = MemoryPriority.normal,
  }) {
    if (_imageCacheInfo.length >= maxImageCacheEntries) {
      _cleanupImageCache();
    }

    _imageCacheInfo[url] = ImageCacheInfo(
      url: url,
      sizeBytes: sizeBytes,
      cachedAt: DateTime.now(),
      lastAccess: DateTime.now(),
      priority: priority,
    );
  }

  /// Update image access time
  void onImageAccessed(String url) {
    final info = _imageCacheInfo[url];
    if (info != null) {
      info.lastAccess = DateTime.now();
      info.accessCount++;
    }
  }

  /// Get image cache statistics
  ImageCacheStats getImageCacheStats() {
    final totalSize = _imageCacheInfo.values.fold<int>(
      0,
      (sum, info) => sum + info.sizeBytes,
    );

    return ImageCacheStats(
      totalEntries: _imageCacheInfo.length,
      totalSizeBytes: totalSize,
      averageSizeBytes:
          _imageCacheInfo.isNotEmpty ? totalSize ~/ _imageCacheInfo.length : 0,
    );
  }

  // ============================================================================
  // CLEANUP AND OPTIMIZATION
  // ============================================================================

  /// Perform regular cleanup
  void _performCleanup() {
    _performanceMonitor.startOperation('memory_cleanup');

    final now = DateTime.now();
    final keysToRemove = <String>[];

    // Cleanup weak references
    _weakReferences.forEach((key, ref) {
      final lastAccess = _lastAccess[key] ?? now;
      final priority = _priorities[key] ?? MemoryPriority.normal;
      final maxAge = _getMaxAgeForPriority(priority);

      if (ref.target == null || now.difference(lastAccess) > maxAge) {
        keysToRemove.add(key);
      }
    });

    // Remove expired entries
    for (final key in keysToRemove) {
      _weakReferences.remove(key);
      _lastAccess.remove(key);
      _priorities.remove(key);
    }

    // Cleanup widget states
    _cleanupWidgetStates();

    // Cleanup image cache
    _cleanupImageCache();

    _performanceMonitor.endOperation('memory_cleanup');
    _logMemoryStats();
  }

  /// Cleanup widget states
  void _cleanupWidgetStates() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _widgetStates.forEach((key, info) {
      final maxAge = _getMaxAgeForPriority(info.priority);
      if (now.difference(info.lastAccess) > maxAge) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _widgetStates.remove(key);
    }
  }

  /// Cleanup image cache information
  void _cleanupImageCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _imageCacheInfo.forEach((url, info) {
      final maxAge = _getMaxAgeForPriority(info.priority);
      if (now.difference(info.lastAccess) > maxAge) {
        keysToRemove.add(url);
      }
    });

    for (final url in keysToRemove) {
      _imageCacheInfo.remove(url);
    }
  }

  /// Check for memory pressure and take action
  void _checkMemoryPressure() {
    // This is a simplified check - in production you might use more sophisticated methods
    final totalObjects =
        _weakReferences.length + _widgetStates.length + _imageCacheInfo.length;
    final maxObjects = maxWeakReferences + 200 + maxImageCacheEntries;

    final pressure = totalObjects / maxObjects;

    if (pressure > memoryPressureThreshold) {
      appLog(
        'UnifiedMemoryManager: Memory pressure detected ($pressure), performing aggressive cleanup',
      );
      _performAggressiveCleanup();
    }
  }

  /// Perform aggressive cleanup under memory pressure
  void _performAggressiveCleanup() {
    _performanceMonitor.startOperation('aggressive_memory_cleanup');

    // Remove low priority items first
    _cleanupByPriority(MemoryPriority.low);

    // If still under pressure, remove normal priority items
    final totalObjects =
        _weakReferences.length + _widgetStates.length + _imageCacheInfo.length;
    final maxObjects = maxWeakReferences + 200 + maxImageCacheEntries;

    if (totalObjects / maxObjects > memoryPressureThreshold) {
      _cleanupByPriority(MemoryPriority.normal);
    }

    _performanceMonitor.endOperation('aggressive_memory_cleanup');
  }

  /// Cleanup items by priority
  void _cleanupByPriority(MemoryPriority priority) {
    // Cleanup weak references
    final keysToRemove = <String>[];
    _priorities.forEach((key, p) {
      if (p == priority) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _weakReferences.remove(key);
      _lastAccess.remove(key);
      _priorities.remove(key);
    }

    // Cleanup widget states
    final widgetKeysToRemove = <String>[];
    _widgetStates.forEach((key, info) {
      if (info.priority == priority) {
        widgetKeysToRemove.add(key);
      }
    });

    for (final key in widgetKeysToRemove) {
      _widgetStates.remove(key);
    }

    // Cleanup image cache
    final imageKeysToRemove = <String>[];
    _imageCacheInfo.forEach((url, info) {
      if (info.priority == priority) {
        imageKeysToRemove.add(url);
      }
    });

    for (final url in imageKeysToRemove) {
      _imageCacheInfo.remove(url);
    }
  }

  /// Get maximum age based on priority
  Duration _getMaxAgeForPriority(MemoryPriority priority) {
    switch (priority) {
      case MemoryPriority.critical:
        return const Duration(hours: 2);
      case MemoryPriority.high:
        return const Duration(hours: 1);
      case MemoryPriority.normal:
        return maxInactiveTime;
      case MemoryPriority.low:
        return const Duration(minutes: 10);
    }
  }

  /// Log memory statistics
  void _logMemoryStats() {
    final stats = {
      'weak_references': _weakReferences.length,
      'active_references':
          _weakReferences.values.where((ref) => ref.target != null).length,
      'widget_states': _widgetStates.length,
      'image_cache_entries': _imageCacheInfo.length,
      'total_image_cache_size': _imageCacheInfo.values.fold<int>(
        0,
        (sum, info) => sum + info.sizeBytes,
      ),
    };

    developer.log('Unified Memory Stats: $stats', name: 'UnifiedMemoryManager');

    // Record metrics for performance monitoring if method exists
    // _performanceMonitor.recordMetric('memory_weak_references', _weakReferences.length);
    // _performanceMonitor.recordMetric('memory_widget_states', _widgetStates.length);
    // _performanceMonitor.recordMetric('memory_image_cache_entries', _imageCacheInfo.length);
  }

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Get comprehensive memory statistics
  MemoryStats getMemoryStats() {
    return MemoryStats(
      weakReferences: _weakReferences.length,
      activeReferences:
          _weakReferences.values.where((ref) => ref.target != null).length,
      widgetStates: _widgetStates.length,
      imageCacheStats: getImageCacheStats(),
      isMonitoring: _isMonitoring,
    );
  }

  /// Force cleanup (useful for testing or manual optimization)
  void forceCleanup() {
    _performCleanup();
  }

  /// Force aggressive cleanup
  void forceAggressiveCleanup() {
    _performAggressiveCleanup();
  }
}

// ============================================================================
// ENUMS AND DATA CLASSES
// ============================================================================

enum MemoryPriority {
  critical, // Never cleanup unless absolutely necessary
  high, // Cleanup after 1 hour of inactivity
  normal, // Cleanup after 20 minutes of inactivity (default)
  low, // Cleanup after 10 minutes of inactivity
}

class WidgetLifecycleInfo {
  final String key;
  Widget widget;
  final DateTime createdAt;
  DateTime lastAccess;
  final MemoryPriority priority;
  int buildCount = 0;
  int updateCount = 0;

  WidgetLifecycleInfo({
    required this.key,
    required this.widget,
    required this.createdAt,
    required this.lastAccess,
    required this.priority,
  });
}

class ImageCacheInfo {
  final String url;
  final int sizeBytes;
  final DateTime cachedAt;
  DateTime lastAccess;
  final MemoryPriority priority;
  int accessCount = 0;

  ImageCacheInfo({
    required this.url,
    required this.sizeBytes,
    required this.cachedAt,
    required this.lastAccess,
    required this.priority,
  });
}

class ImageCacheStats {
  final int totalEntries;
  final int totalSizeBytes;
  final int averageSizeBytes;

  const ImageCacheStats({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.averageSizeBytes,
  });
}

class MemoryStats {
  final int weakReferences;
  final int activeReferences;
  final int widgetStates;
  final ImageCacheStats imageCacheStats;
  final bool isMonitoring;

  const MemoryStats({
    required this.weakReferences,
    required this.activeReferences,
    required this.widgetStates,
    required this.imageCacheStats,
    required this.isMonitoring,
  });
}

// ============================================================================
// WIDGET HELPERS
// ============================================================================

/// A widget that automatically manages its memory lifecycle
class MemoryManagedWidget extends StatefulWidget {
  final Widget child;
  final String? memoryKey;
  final MemoryPriority priority;

  const MemoryManagedWidget({
    super.key,
    required this.child,
    this.memoryKey,
    this.priority = MemoryPriority.normal,
  });

  @override
  State<MemoryManagedWidget> createState() => _MemoryManagedWidgetState();
}

class _MemoryManagedWidgetState extends State<MemoryManagedWidget> {
  late final String _effectiveKey;
  final _memoryManager = UnifiedMemoryManager();

  @override
  void initState() {
    super.initState();
    _effectiveKey = widget.memoryKey ?? 'widget_${widget.hashCode}';
    _memoryManager.registerWidget(
      _effectiveKey,
      widget,
      priority: widget.priority,
    );
  }

  @override
  void didUpdateWidget(MemoryManagedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _memoryManager.updateWidgetState(_effectiveKey, widget);
  }

  @override
  void dispose() {
    _memoryManager.unregisterWidget(_effectiveKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _memoryManager.onWidgetBuild(_effectiveKey);
    return widget.child;
  }
}

/// A builder that provides memory-aware widget construction
class MemoryAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final String? memoryKey;
  final MemoryPriority priority;

  const MemoryAwareBuilder({
    super.key,
    required this.builder,
    this.memoryKey,
    this.priority = MemoryPriority.normal,
  });

  @override
  Widget build(BuildContext context) {
    return MemoryManagedWidget(
      memoryKey: memoryKey,
      priority: priority,
      child: builder(context),
    );
  }
}
