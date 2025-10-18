import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Performance optimization utilities
class PerformanceUtils {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _measurements = {};

  /// Start measuring performance for an operation
  static void startMeasurement(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }

  /// End measuring performance for an operation
  static Duration endMeasurement(String operationName) {
    final timer = _timers[operationName];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsed;

      _measurements.putIfAbsent(operationName, () => []).add(duration);
      _timers.remove(operationName);

      if (kDebugMode) {
        appLog('Performance: $operationName took ${duration.inMilliseconds}ms');
      }

      return duration;
    }
    return Duration.zero;
  }

  /// Measure the performance of a function
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startMeasurement(operationName);
    try {
      final result = await operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      rethrow;
    }
  }

  /// Measure the performance of a synchronous function
  static T measureSync<T>(String operationName, T Function() operation) {
    startMeasurement(operationName);
    try {
      final result = operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      rethrow;
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};

    for (final entry in _measurements.entries) {
      final measurements = entry.value;
      if (measurements.isNotEmpty) {
        final totalMs = measurements.fold<int>(
          0,
          (sum, duration) => sum + duration.inMilliseconds,
        );
        final avgMs = totalMs / measurements.length;
        final minMs = measurements
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a < b ? a : b);
        final maxMs = measurements
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a > b ? a : b);

        stats[entry.key] = {
          'count': measurements.length,
          'totalMs': totalMs,
          'avgMs': avgMs.round(),
          'minMs': minMs,
          'maxMs': maxMs,
        };
      }
    }

    return stats;
  }

  /// Clear all measurements
  static void clearStats() {
    _measurements.clear();
    _timers.clear();
  }

  /// Log performance timeline event
  static void logTimelineEvent(String name, Map<String, dynamic>? arguments) {
    if (kDebugMode) {
      developer.Timeline.instantSync(name, arguments: arguments);
    }
  }

  /// Debounce function calls
  static Timer? debounce(
    Duration delay,
    VoidCallback callback, {
    Timer? previousTimer,
  }) {
    previousTimer?.cancel();
    return Timer(delay, callback);
  }

  /// Throttle function calls
  static bool throttle(String key, Duration interval, VoidCallback callback) {
    final now = DateTime.now();
    final lastCall = _lastThrottleCalls[key];

    if (lastCall == null || now.difference(lastCall) >= interval) {
      _lastThrottleCalls[key] = now;
      callback();
      return true;
    }

    return false;
  }

  static final Map<String, DateTime> _lastThrottleCalls = {};
}

/// Widget performance measurement mixin
mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  late final String _widgetName;

  @override
  void initState() {
    super.initState();
    _widgetName = widget.runtimeType.toString();
    PerformanceUtils.startMeasurement('${_widgetName}_initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PerformanceUtils.logTimelineEvent(
      '${_widgetName}_didChangeDependencies',
      null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceUtils.measureSync(
      '${_widgetName}_build',
      () => buildWidget(context),
    );
  }

  /// Override this method instead of build()
  Widget buildWidget(BuildContext context);

  @override
  void dispose() {
    PerformanceUtils.endMeasurement('${_widgetName}_initState');
    super.dispose();
  }
}

/// Performance-optimized ListView builder
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;

  const OptimizedListView.builder({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent ?? 250.0, // Optimized cache extent
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: itemBuilder(context, index));
      },
    );
  }
}

/// Performance-optimized GridView builder
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? cacheExtent;

  const OptimizedGridView.builder({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      cacheExtent: cacheExtent ?? 250.0,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: itemBuilder(context, index));
      },
    );
  }
}

/// Lazy loading widget for expensive operations
class LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final Duration delay;

  const LazyWidget({
    Key? key,
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  Widget? _child;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWidget();
  }

  void _loadWidget() {
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _child = widget.builder();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return _child ?? const SizedBox.shrink();
  }
}

/// Memory-efficient image cache
class OptimizedImageCache {
  static final Map<String, ImageProvider> _cache = {};
  static const int _maxCacheSize = 50;

  static ImageProvider getImage(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    final imageProvider = NetworkImage(url);
    _cache[url] = imageProvider;
    return imageProvider;
  }

  static void clearCache() {
    _cache.clear();
  }

  static int get cacheSize => _cache.length;
}

/// Performance monitoring widget
class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceMonitorWidget({
    Key? key,
    required this.child,
    this.showOverlay = false,
  }) : super(key: key);

  @override
  State<PerformanceMonitorWidget> createState() =>
      _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  Timer? _updateTimer;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay && kDebugMode) {
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _stats = PerformanceUtils.getStats();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay || !kDebugMode) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Performance Stats',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ..._stats.entries.take(5).map((entry) {
                  final stats = entry.value as Map<String, dynamic>;
                  return Text(
                    '${entry.key}: ${stats['avgMs']}ms',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

