import 'package:flutter/material.dart';

/// Bookmark/heart icon with a satisfying scale-bounce when toggled.
/// Drop-in replacement for `Icon(Icons.bookmark)` in save/favorite contexts.
class AnimatedBookmark extends StatefulWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const AnimatedBookmark({
    Key? key,
    required this.isActive,
    this.activeColor = const Color(0xFFFFB800),
    this.inactiveColor = Colors.white,
    this.size = 22,
  }) : super(key: key);

  @override
  State<AnimatedBookmark> createState() => _AnimatedBookmarkState();
}

class _AnimatedBookmarkState extends State<AnimatedBookmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedBookmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Icon(
          widget.isActive ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: widget.isActive ? widget.activeColor : widget.inactiveColor,
          size: widget.size,
        ),
      ),
    );
  }
}
