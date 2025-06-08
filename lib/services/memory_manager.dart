import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:wonwonw2/services/performance_monitor.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final Map<String, WeakReference<Object>> _weakReferences = {};
  final Map<String, DateTime> _lastAccess = {};
  Timer? _cleanupTimer;
  bool _isMonitoring = false;

  static const Duration cleanupInterval = Duration(minutes: 5);
  static const Duration maxInactiveTime = Duration(minutes: 30);
  static const int maxWeakReferences = 1000;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _cleanup());
    _performanceMonitor.startOperation('memory_monitoring');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _performanceMonitor.endOperation('memory_monitoring');
  }

  void registerObject(String key, Object object) {
    if (_weakReferences.length >= maxWeakReferences) {
      _cleanup();
    }

    _weakReferences[key] = WeakReference(object);
    _lastAccess[key] = DateTime.now();
  }

  Object? getObject(String key) {
    final ref = _weakReferences[key];
    if (ref != null) {
      _lastAccess[key] = DateTime.now();
      return ref.target;
    }
    return null;
  }

  void unregisterObject(String key) {
    _weakReferences.remove(key);
    _lastAccess.remove(key);
  }

  void _cleanup() {
    _performanceMonitor.startOperation('memory_cleanup');

    final now = DateTime.now();
    final keysToRemove = <String>[];

    _weakReferences.forEach((key, ref) {
      if (ref.target == null ||
          now.difference(_lastAccess[key] ?? now) > maxInactiveTime) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _weakReferences.remove(key);
      _lastAccess.remove(key);
    }

    _performanceMonitor.endOperation('memory_cleanup');
    _logMemoryStats();
  }

  void _logMemoryStats() {
    final stats = {
      'total_references': _weakReferences.length,
      'active_references':
          _weakReferences.values.where((ref) => ref.target != null).length,
      'inactive_references':
          _weakReferences.values.where((ref) => ref.target == null).length,
    };

    developer.log(
      'Memory Stats',
      name: 'MemoryManager',
      error: stats.toString(),
    );
  }

  void dispose() {
    stopMonitoring();
    _weakReferences.clear();
    _lastAccess.clear();
  }
}

class MemoryManagedWidget extends StatefulWidget {
  final Widget child;
  final String? memoryKey;

  const MemoryManagedWidget({super.key, required this.child, this.memoryKey});

  @override
  State<MemoryManagedWidget> createState() => _MemoryManagedWidgetState();
}

class _MemoryManagedWidgetState extends State<MemoryManagedWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.memoryKey != null) {
      MemoryManager().registerObject(widget.memoryKey!, widget);
    }
  }

  @override
  void dispose() {
    if (widget.memoryKey != null) {
      MemoryManager().unregisterObject(widget.memoryKey!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MemoryAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final String? memoryKey;

  const MemoryAwareBuilder({super.key, required this.builder, this.memoryKey});

  @override
  Widget build(BuildContext context) {
    return MemoryManagedWidget(memoryKey: memoryKey, child: builder(context));
  }
}
