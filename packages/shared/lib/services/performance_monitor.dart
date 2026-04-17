import 'dart:async';
import 'dart:developer' as developer;

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  static const int _maxMeasurementsPerOperation = 200;

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _measurements = {};
  final Map<String, int> _frameDrops = {};
  Timer? _frameMonitor;
  int _lastFrameTime = 0;

  void startOperation(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }

  void endOperation(String operationName, [Duration? duration]) {
    final timer = _timers[operationName];
    if (timer != null) {
      timer.stop();
      final list = _measurements.putIfAbsent(operationName, () => <Duration>[]);
      list.add(timer.elapsed);
      if (list.length > _maxMeasurementsPerOperation) {
        list.removeRange(0, list.length - _maxMeasurementsPerOperation);
      }
      _timers.remove(operationName);
    } else if (duration != null) {
      final list = _measurements.putIfAbsent(operationName, () => <Duration>[]);
      list.add(duration);
      if (list.length > _maxMeasurementsPerOperation) {
        list.removeRange(0, list.length - _maxMeasurementsPerOperation);
      }
    }
  }

  void recordError(String operationName, dynamic error) {
    developer.log(
      'Error in operation: $operationName',
      name: 'PerformanceMonitor',
      error: error.toString(),
    );
  }

  void startFrameMonitoring() {
    _frameMonitor?.cancel();
    _frameMonitor = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastFrameTime > 0) {
        final frameTime = now - _lastFrameTime;
        if (frameTime > 16) {
          // 60 FPS = ~16ms per frame; cap size to avoid unbounded growth
          if (_frameDrops.length >= 500) {
            final keys = _frameDrops.keys.toList()..sort();
            for (var i = 0; i < 250; i++) {
              _frameDrops.remove(keys[i]);
            }
          }
          _frameDrops[DateTime.now().toString()] = frameTime;
        }
      }
      _lastFrameTime = now;
    });
  }

  void stopFrameMonitoring() {
    _frameMonitor?.cancel();
    _frameMonitor = null;
  }

  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};

    // Calculate average durations
    _measurements.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
        metrics[operation] = {
          'average_duration_ms': avg.inMilliseconds,
          'min_duration_ms': durations
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a < b ? a : b),
          'max_duration_ms': durations
              .map((d) => d.inMilliseconds)
              .reduce((a, b) => a > b ? a : b),
          'count': durations.length,
        };
      }
    });

    // Add frame drop metrics
    metrics['frame_drops'] = {
      'count': _frameDrops.length,
      'details': _frameDrops,
    };

    return metrics;
  }

  void logPerformanceMetrics() {
    final metrics = getPerformanceMetrics();
    developer.log(
      'Performance Metrics',
      name: 'PerformanceMonitor',
      error: metrics.toString(),
    );
  }

  void reset() {
    _timers.clear();
    _measurements.clear();
    _frameDrops.clear();
    _lastFrameTime = 0;
  }
}
