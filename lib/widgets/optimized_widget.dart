import 'package:flutter/material.dart';
import 'package:wonwonw2/services/performance_monitor.dart';

abstract class OptimizedWidget extends StatefulWidget {
  const OptimizedWidget({super.key});

  @override
  OptimizedWidgetState createState();
}

abstract class OptimizedWidgetState<T extends OptimizedWidget> extends State<T>
    with AutomaticKeepAliveClientMixin {
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _performanceMonitor.startOperation('${widget.runtimeType}_init');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _performanceMonitor.endOperation('${widget.runtimeType}_init');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDisposed) {
      _performanceMonitor.startOperation('${widget.runtimeType}_build');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isDisposed) {
      _performanceMonitor.endOperation('${widget.runtimeType}_build');
    }
    return buildOptimized(context);
  }

  Widget buildOptimized(BuildContext context);

  @override
  void setState(VoidCallback fn) {
    if (!_isDisposed) {
      _performanceMonitor.startOperation('${widget.runtimeType}_setState');
      super.setState(fn);
      _performanceMonitor.endOperation('${widget.runtimeType}_setState');
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDisposed) {
      _performanceMonitor.startOperation('${widget.runtimeType}_update');
      _performanceMonitor.endOperation('${widget.runtimeType}_update');
    }
  }
}

class OptimizedBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final bool shouldRebuild;
  final String? debugLabel;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.shouldRebuild = true,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    return shouldRebuild
        ? builder(context)
        : RepaintBoundary(child: builder(context));
  }
}

class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addRepaintBoundaries;
  final bool addAutomaticKeepAlives;

  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addRepaintBoundaries = true,
    this.addAutomaticKeepAlives = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      addRepaintBoundaries: addRepaintBoundaries,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      itemBuilder:
          (context, index) => OptimizedBuilder(
            builder: (_) => children[index],
            shouldRebuild: false,
            debugLabel: 'OptimizedListView_$index',
          ),
    );
  }
}

class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addRepaintBoundaries;
  final bool addAutomaticKeepAlives;

  const OptimizedGridView({
    super.key,
    required this.children,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addRepaintBoundaries = true,
    this.addAutomaticKeepAlives = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: children.length,
      addRepaintBoundaries: addRepaintBoundaries,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      itemBuilder:
          (context, index) => OptimizedBuilder(
            builder: (_) => children[index],
            shouldRebuild: false,
            debugLabel: 'OptimizedGridView_$index',
          ),
    );
  }
}
