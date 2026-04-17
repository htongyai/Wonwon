import 'package:flutter/material.dart';

abstract class OptimizedWidget extends StatefulWidget {
  const OptimizedWidget({super.key});

  @override
  OptimizedWidgetState createState();
}

abstract class OptimizedWidgetState<T extends OptimizedWidget> extends State<T>
    with AutomaticKeepAliveClientMixin {
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildOptimized(context);
  }

  Widget buildOptimized(BuildContext context);

  @override
  void setState(VoidCallback fn) {
    if (!_isDisposed) {
      super.setState(fn);
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

/// ListView with RepaintBoundary per item. Takes pre-built [children];
/// all children are built when this widget builds. Use only for small lists.
/// For long lists use [OptimizedListView.builder] from performance_utils.
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
      itemBuilder: (context, index) => RepaintBoundary(
        child: children[index],
      ),
    );
  }
}

/// GridView with RepaintBoundary per item. Takes pre-built [children];
/// use only for small lists. For long lists use GridView.builder with
/// RepaintBoundary in itemBuilder or OptimizedGridView.builder from performance_utils.
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
      itemBuilder: (context, index) => RepaintBoundary(
        child: children[index],
      ),
    );
  }
}
