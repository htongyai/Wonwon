import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';

class PerformanceLoadingWidget extends StatefulWidget {
  final String? message;
  final Widget? customWidget;
  final bool showProgress;
  final double size;
  final Color? color;
  final Duration animationDuration;

  const PerformanceLoadingWidget({
    Key? key,
    this.message,
    this.customWidget,
    this.showProgress = true,
    this.size = 40.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<PerformanceLoadingWidget> createState() =>
      _PerformanceLoadingWidgetState();
}

class _PerformanceLoadingWidgetState extends State<PerformanceLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.customWidget != null)
            widget.customWidget!
          else
            AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController,
                _rotateController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: widget.color ?? AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(widget.size / 2),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.color ?? AppConstants.primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child:
                          widget.showProgress
                              ? const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                              : const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                    ),
                  ),
                );
              },
            ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonLoadingWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;

  const SkeletonLoadingWidget({
    Key? key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
    this.color,
  }) : super(key: key);

  @override
  State<SkeletonLoadingWidget> createState() => _SkeletonLoadingWidgetState();
}

class _SkeletonLoadingWidgetState extends State<SkeletonLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value, 0),
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class ProgressiveLoadingWidget extends StatefulWidget {
  final List<String> loadingSteps;
  final Future<void> Function() onLoadComplete;
  final Widget Function() onComplete;
  final Duration stepDelay;

  const ProgressiveLoadingWidget({
    Key? key,
    required this.loadingSteps,
    required this.onLoadComplete,
    required this.onComplete,
    this.stepDelay = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<ProgressiveLoadingWidget> createState() =>
      _ProgressiveLoadingWidgetState();
}

class _ProgressiveLoadingWidgetState extends State<ProgressiveLoadingWidget>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late AnimationController _stepController;
  late Animation<double> _stepAnimation;

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _stepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stepController, curve: Curves.easeInOut),
    );

    _startLoading();
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _startLoading() async {
    try {
      for (int i = 0; i < widget.loadingSteps.length; i++) {
        if (mounted) {
          setState(() {
            _currentStep = i;
          });
          _stepController.forward();
        }
        await Future.delayed(widget.stepDelay);
      }

      await widget.onLoadComplete();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading content',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _currentStep = 0;
                });
                _startLoading();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isLoading) {
      return widget.onComplete();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.build, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 32),

            // Loading text
            Text(
              'Loading...',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkColor,
              ),
            ),

            const SizedBox(height: 32),

            // Loading steps
            Column(
              children:
                  widget.loadingSteps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isCompleted = index < _currentStep;
                    final isCurrent = index == _currentStep;

                    return AnimatedBuilder(
                      animation: _stepAnimation,
                      builder: (context, child) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color:
                                      isCompleted
                                          ? Colors.green
                                          : isCurrent
                                          ? AppConstants.primaryColor
                                          : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:
                                    isCompleted
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                        : isCurrent
                                        ? const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                step,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color:
                                      isCompleted
                                          ? Colors.grey[600]
                                          : isCurrent
                                          ? AppConstants.darkColor
                                          : Colors.grey[400],
                                  fontWeight:
                                      isCurrent
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),

            const SizedBox(height: 32),

            // Progress indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptimizedLoadingList extends StatefulWidget {
  final Future<List<dynamic>> Function() dataLoader;
  final Widget Function(BuildContext, dynamic) itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final int pageSize;
  final bool enablePagination;

  const OptimizedLoadingList({
    Key? key,
    required this.dataLoader,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.enablePagination = true,
  }) : super(key: key);

  @override
  State<OptimizedLoadingList> createState() => _OptimizedLoadingListState();
}

class _OptimizedLoadingListState extends State<OptimizedLoadingList> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _items = [];
        _hasMoreData = true;
      });
    }

    if (!_hasMoreData && !refresh) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final newItems = await widget.dataLoader();

      if (mounted) {
        setState(() {
          if (refresh) {
            _items = newItems;
          } else {
            _items.addAll(newItems);
          }
          _isLoading = false;
          _hasMoreData = newItems.length >= widget.pageSize;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadData(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_isLoading && _items.isEmpty) {
      return const PerformanceLoadingWidget(
        message: 'Loading content...',
        size: 50,
      );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(refresh: true),
      child: ListView.builder(
        itemCount: _items.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_hasMoreData) {
              _loadData();
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}
