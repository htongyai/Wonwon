import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Mixin that provides automatic resource disposal for StatefulWidgets
mixin WidgetDisposalMixin<T extends StatefulWidget> on State<T> {
  // Resource tracking
  final List<StreamSubscription> _subscriptions = [];
  final List<AnimationController> _animationControllers = [];
  final List<TextEditingController> _textControllers = [];
  final List<ScrollController> _scrollControllers = [];
  final List<TabController> _tabControllers = [];
  final List<Timer> _timers = [];
  final List<VoidCallback> _customDisposers = [];

  // Memory management
  final UnifiedMemoryManager _memoryManager = UnifiedMemoryManager();
  late final String _widgetKey;

  @override
  void initState() {
    super.initState();
    _widgetKey = '${widget.runtimeType}_$hashCode';
    _memoryManager.registerWidget(_widgetKey, widget);

    // Call the custom initialization
    onInitState();
  }

  @override
  void dispose() {
    // Dispose all tracked resources
    _disposeAllResources();

    // Unregister from memory manager
    _memoryManager.unregisterWidget(_widgetKey);

    // Call custom disposal
    onDispose();

    super.dispose();
  }

  /// Override this method instead of initState
  void onInitState() {}

  /// Override this method instead of dispose
  void onDispose() {}

  // ============================================================================
  // RESOURCE REGISTRATION METHODS
  // ============================================================================

  /// Register a StreamSubscription for automatic disposal
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Register an AnimationController for automatic disposal
  void registerAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
  }

  /// Register a TextEditingController for automatic disposal
  void registerTextController(TextEditingController controller) {
    _textControllers.add(controller);
  }

  /// Register a ScrollController for automatic disposal
  void registerScrollController(ScrollController controller) {
    _scrollControllers.add(controller);
  }

  /// Register a TabController for automatic disposal
  void registerTabController(TabController controller) {
    _tabControllers.add(controller);
  }

  /// Register a Timer for automatic disposal
  void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Register a custom disposer function
  void registerCustomDisposer(VoidCallback disposer) {
    _customDisposers.add(disposer);
  }

  // ============================================================================
  // CONVENIENCE METHODS
  // ============================================================================

  /// Create and register a StreamSubscription
  StreamSubscription<T> listenToStream<T>(
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    registerSubscription(subscription);
    return subscription;
  }

  /// Create and register an AnimationController
  AnimationController createAnimationController({
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    TickerProvider? vsync,
  }) {
    final controller = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      animationBehavior: animationBehavior,
      vsync: vsync ?? this as TickerProvider,
    );
    registerAnimationController(controller);
    return controller;
  }

  /// Create and register a TextEditingController
  TextEditingController createTextController({String? text}) {
    final controller = TextEditingController(text: text);
    registerTextController(controller);
    return controller;
  }

  /// Create and register a ScrollController
  ScrollController createScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String? debugLabel,
  }) {
    final controller = ScrollController(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
    );
    registerScrollController(controller);
    return controller;
  }

  /// Create and register a Timer
  Timer createTimer(Duration duration, VoidCallback callback) {
    final timer = Timer(duration, callback);
    registerTimer(timer);
    return timer;
  }

  /// Create and register a periodic Timer
  Timer createPeriodicTimer(Duration period, void Function(Timer) callback) {
    final timer = Timer.periodic(period, callback);
    registerTimer(timer);
    return timer;
  }

  // ============================================================================
  // MEMORY MANAGEMENT HELPERS
  // ============================================================================

  /// Register an object with the memory manager
  void registerObject(
    String key,
    Object object, {
    MemoryPriority priority = MemoryPriority.normal,
  }) {
    _memoryManager.registerObject(key, object, priority: priority);
  }

  /// Get an object from the memory manager
  U? getObject<U extends Object>(String key) {
    return _memoryManager.getObject<U>(key);
  }

  /// Unregister an object from the memory manager
  void unregisterObject(String key) {
    _memoryManager.unregisterObject(key);
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Dispose all tracked resources
  void _disposeAllResources() {
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        try {
          subscription.cancel();
        } catch (e) {
          appLog('WidgetDisposalMixin: Error canceling subscription: $e');
        }
      }
      _subscriptions.clear();

      // Dispose animation controllers
      for (final controller in _animationControllers) {
        try {
          controller.dispose();
        } catch (e) {
          appLog(
            'WidgetDisposalMixin: Error disposing animation controller: $e',
          );
        }
      }
      _animationControllers.clear();

      // Dispose text controllers
      for (final controller in _textControllers) {
        try {
          controller.dispose();
        } catch (e) {
          appLog('WidgetDisposalMixin: Error disposing text controller: $e');
        }
      }
      _textControllers.clear();

      // Dispose scroll controllers
      for (final controller in _scrollControllers) {
        try {
          controller.dispose();
        } catch (e) {
          appLog('WidgetDisposalMixin: Error disposing scroll controller: $e');
        }
      }
      _scrollControllers.clear();

      // Dispose tab controllers
      for (final controller in _tabControllers) {
        try {
          controller.dispose();
        } catch (e) {
          appLog('WidgetDisposalMixin: Error disposing tab controller: $e');
        }
      }
      _tabControllers.clear();

      // Cancel timers
      for (final timer in _timers) {
        try {
          timer.cancel();
        } catch (e) {
          appLog('WidgetDisposalMixin: Error canceling timer: $e');
        }
      }
      _timers.clear();

      // Call custom disposers
      for (final disposer in _customDisposers) {
        try {
          disposer();
        } catch (e) {
          appLog('WidgetDisposalMixin: Error calling custom disposer: $e');
        }
      }
      _customDisposers.clear();
    } catch (e) {
      appLog('WidgetDisposalMixin: Error during resource disposal: $e');
    }
  }
}

/// Mixin for StatelessWidgets that need memory management
mixin StatelessWidgetMemoryMixin on StatelessWidget {
  /// Register an object with the memory manager
  void registerObject(
    String key,
    Object object, {
    MemoryPriority priority = MemoryPriority.normal,
  }) {
    UnifiedMemoryManager().registerObject(key, object, priority: priority);
  }

  /// Get an object from the memory manager
  U? getObject<U extends Object>(String key) {
    return UnifiedMemoryManager().getObject<U>(key);
  }

  /// Unregister an object from the memory manager
  void unregisterObject(String key) {
    UnifiedMemoryManager().unregisterObject(key);
  }
}

/// Base class for StatefulWidgets with automatic resource management
abstract class ManagedStatefulWidget extends StatefulWidget {
  const ManagedStatefulWidget({super.key});
}

/// Base class for States with automatic resource management
abstract class ManagedState<T extends ManagedStatefulWidget> extends State<T>
    with WidgetDisposalMixin<T> {
  /// Override this instead of initState
  @override
  void onInitState() {
    // Default implementation - override in subclasses
  }

  /// Override this instead of dispose
  @override
  void onDispose() {
    // Default implementation - override in subclasses
  }
}

/// Base class for StatelessWidgets with memory management
abstract class ManagedStatelessWidget extends StatelessWidget
    with StatelessWidgetMemoryMixin {
  const ManagedStatelessWidget({super.key});
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

/// A widget that automatically manages the lifecycle of its child
class AutoManagedWidget extends StatefulWidget {
  final Widget child;
  final String? memoryKey;
  final MemoryPriority priority;
  final List<VoidCallback>? disposers;

  const AutoManagedWidget({
    super.key,
    required this.child,
    this.memoryKey,
    this.priority = MemoryPriority.normal,
    this.disposers,
  });

  @override
  State<AutoManagedWidget> createState() => _AutoManagedWidgetState();
}

class _AutoManagedWidgetState extends State<AutoManagedWidget>
    with WidgetDisposalMixin<AutoManagedWidget> {
  @override
  void onInitState() {
    // Register custom disposers if provided
    if (widget.disposers != null) {
      for (final disposer in widget.disposers!) {
        registerCustomDisposer(disposer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemoryManagedWidget(
      memoryKey: widget.memoryKey,
      priority: widget.priority,
      child: widget.child,
    );
  }
}

// ============================================================================
// CONVENIENCE EXTENSIONS
// ============================================================================

extension WidgetAutoManagement on Widget {
  /// Wrap any widget with automatic resource management
  Widget withAutoManagement({
    String? memoryKey,
    MemoryPriority priority = MemoryPriority.normal,
    List<VoidCallback>? disposers,
  }) {
    return AutoManagedWidget(
      memoryKey: memoryKey,
      priority: priority,
      disposers: disposers,
      child: this,
    );
  }
}
