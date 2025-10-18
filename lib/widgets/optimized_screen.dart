import 'package:flutter/material.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/services/memory_manager.dart';
import 'package:wonwonw2/widgets/error_boundary.dart';

/// Base class for optimized screens with performance monitoring and error handling
abstract class OptimizedScreen extends StatefulWidget {
  final String? debugLabel;
  final bool enablePerformanceMonitoring;
  final bool enableMemoryManagement;

  const OptimizedScreen({
    Key? key,
    this.debugLabel,
    this.enablePerformanceMonitoring = true,
    this.enableMemoryManagement = true,
  }) : super(key: key);

  @override
  OptimizedScreenState createState();
}

abstract class OptimizedScreenState<T extends OptimizedScreen>
    extends State<T> with AutomaticKeepAliveClientMixin {
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final MemoryManager _memoryManager = MemoryManager();
  bool _isDisposed = false;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (widget.enablePerformanceMonitoring) {
      _performanceMonitor.startOperation('${widget.debugLabel ?? widget.runtimeType}_init');
    }

    if (widget.enableMemoryManagement) {
      _memoryManager.registerObject(
        '${widget.debugLabel ?? widget.runtimeType}_screen',
        this,
      );
    }

    onScreenInit();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    if (widget.enablePerformanceMonitoring) {
      _performanceMonitor.endOperation('${widget.debugLabel ?? widget.runtimeType}_init');
    }

    if (widget.enableMemoryManagement) {
      _memoryManager.unregisterObject(
        '${widget.debugLabel ?? widget.runtimeType}_screen',
      );
    }

    onScreenDispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDisposed && widget.enablePerformanceMonitoring) {
      _performanceMonitor.startOperation('${widget.debugLabel ?? widget.runtimeType}_dependencies');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    if (widget.enablePerformanceMonitoring) {
      _performanceMonitor.startOperation('${widget.debugLabel ?? widget.runtimeType}_build');
    }

    return ErrorBoundary(
      fallbackBuilder: (context, error, stackTrace) => _buildErrorWidget(error, stackTrace),
      child: buildOptimizedScreen(context),
    );
  }

  @override
  void setState(VoidCallback fn) {
    if (_isDisposed) return;

    if (widget.enablePerformanceMonitoring) {
      _performanceMonitor.startOperation('${widget.debugLabel ?? widget.runtimeType}_setState');
    }

    super.setState(fn);

    if (widget.enablePerformanceMonitoring) {
      _performanceMonitor.endOperation('${widget.debugLabel ?? widget.runtimeType}_setState');
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDisposed && widget.enablePerformanceMonitoring) {
      _performanceMonitor.startOperation('${widget.debugLabel ?? widget.runtimeType}_update');
      _performanceMonitor.endOperation('${widget.debugLabel ?? widget.runtimeType}_update');
    }
  }

  /// Override this method to build the screen content
  Widget buildOptimizedScreen(BuildContext context);

  /// Override this method for initialization logic
  void onScreenInit() {}

  /// Override this method for cleanup logic
  void onScreenDispose() {}

  /// Build error widget
  Widget _buildErrorWidget(dynamic error, StackTrace? stackTrace) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re sorry, but something went wrong. Please try again later.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Safe setState that checks if widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// Safe async operation that checks if widget is still mounted
  Future<T?> safeAsyncOperation<T>(Future<T> Function() operation) async {
    if (_isDisposed) return null;

    try {
      final result = await operation();
      if (!_isDisposed && mounted) {
        return result;
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        _performanceMonitor.recordError('${widget.debugLabel ?? widget.runtimeType}_async', e);
      }
    }
    return null;
  }
}

/// Optimized screen with loading states
abstract class OptimizedLoadingScreen<T extends OptimizedScreen> extends OptimizedScreenState<T> {
  bool _isLoading = false;
  String? _loadingMessage;
  dynamic _error;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  dynamic get error => _error;
  String? get errorMessage => _errorMessage;

  /// Set loading state
  void setLoading(bool loading, {String? message}) {
    safeSetState(() {
      _isLoading = loading;
      _loadingMessage = message;
      if (loading) {
        _error = null;
        _errorMessage = null;
      }
    });
  }

  /// Set error state
  void setError(dynamic error, {String? message}) {
    safeSetState(() {
      _error = error;
      _errorMessage = message ?? error.toString();
      _isLoading = false;
    });
  }

  /// Clear error state
  void clearError() {
    safeSetState(() {
      _error = null;
      _errorMessage = null;
    });
  }

  @override
  Widget buildOptimizedScreen(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorStateWidget();
    }

    return buildContent(context);
  }

  /// Override this method to build the main content
  Widget buildContent(BuildContext context);

  /// Build loading widget
  Widget _buildLoadingWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_loadingMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _loadingMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorStateWidget() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'An unexpected error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  clearError();
                  onRetry();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Override this method for retry logic
  void onRetry() {}
}

