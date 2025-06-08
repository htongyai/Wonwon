import 'package:flutter/material.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/services/memory_manager.dart';

class WidgetLifecycleManager {
  static final WidgetLifecycleManager _instance =
      WidgetLifecycleManager._internal();
  factory WidgetLifecycleManager() => _instance;
  WidgetLifecycleManager._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final MemoryManager _memoryManager = MemoryManager();
  final Map<String, WidgetLifecycleState> _widgetStates = {};

  void registerWidget(String key, Widget widget) {
    _widgetStates[key] = WidgetLifecycleState(
      key: key,
      widget: widget,
      lastAccess: DateTime.now(),
    );
    _memoryManager.registerObject(key, widget);
  }

  void updateWidgetState(String key, WidgetLifecycleState state) {
    _widgetStates[key] = state;
    _memoryManager.registerObject(key, state.widget);
  }

  WidgetLifecycleState? getWidgetState(String key) {
    final state = _widgetStates[key];
    if (state != null) {
      state.lastAccess = DateTime.now();
    }
    return state;
  }

  void unregisterWidget(String key) {
    _widgetStates.remove(key);
    _memoryManager.unregisterObject(key);
  }

  void onWidgetInit(String key) {
    _performanceMonitor.startOperation('widget_init_$key');
  }

  void onWidgetDispose(String key) {
    _performanceMonitor.endOperation('widget_init_$key');
    unregisterWidget(key);
  }

  void onWidgetBuild(String key) {
    _performanceMonitor.startOperation('widget_build_$key');
  }

  void onWidgetBuildComplete(String key) {
    _performanceMonitor.endOperation('widget_build_$key');
  }

  void onWidgetUpdate(String key) {
    _performanceMonitor.startOperation('widget_update_$key');
  }

  void onWidgetUpdateComplete(String key) {
    _performanceMonitor.endOperation('widget_update_$key');
  }
}

class WidgetLifecycleState {
  final String key;
  final Widget widget;
  DateTime lastAccess;

  WidgetLifecycleState({
    required this.key,
    required this.widget,
    required this.lastAccess,
  });
}

class LifecycleManagedWidget extends StatefulWidget {
  final Widget child;
  final String lifecycleKey;

  const LifecycleManagedWidget({
    super.key,
    required this.child,
    required this.lifecycleKey,
  });

  @override
  State<LifecycleManagedWidget> createState() => _LifecycleManagedWidgetState();
}

class _LifecycleManagedWidgetState extends State<LifecycleManagedWidget> {
  final _lifecycleManager = WidgetLifecycleManager();

  @override
  void initState() {
    super.initState();
    _lifecycleManager.onWidgetInit(widget.lifecycleKey);
    _lifecycleManager.registerWidget(widget.lifecycleKey, widget);
  }

  @override
  void dispose() {
    _lifecycleManager.onWidgetDispose(widget.lifecycleKey);
    super.dispose();
  }

  @override
  void didUpdateWidget(LifecycleManagedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lifecycleManager.onWidgetUpdate(widget.lifecycleKey);
    _lifecycleManager.updateWidgetState(
      widget.lifecycleKey,
      WidgetLifecycleState(
        key: widget.lifecycleKey,
        widget: widget,
        lastAccess: DateTime.now(),
      ),
    );
    _lifecycleManager.onWidgetUpdateComplete(widget.lifecycleKey);
  }

  @override
  Widget build(BuildContext context) {
    _lifecycleManager.onWidgetBuild(widget.lifecycleKey);
    final result = widget.child;
    _lifecycleManager.onWidgetBuildComplete(widget.lifecycleKey);
    return result;
  }
}

class LifecycleAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final String lifecycleKey;

  const LifecycleAwareBuilder({
    super.key,
    required this.builder,
    required this.lifecycleKey,
  });

  @override
  Widget build(BuildContext context) {
    return LifecycleManagedWidget(
      lifecycleKey: lifecycleKey,
      child: builder(context),
    );
  }
}
