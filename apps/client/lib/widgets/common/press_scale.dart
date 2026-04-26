import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a child in a cozy press-scale feedback (scales to 0.97 on press,
/// springs back on release). Replaces the default Material ripple for
/// contexts where ink-splash feels too corporate.
///
/// Use around shop cards, featured cards, CTA buttons that want a warmer
/// tactile response.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleTo;
  final Duration duration;

  const PressScale({
    Key? key,
    required this.child,
    this.onTap,
    this.scaleTo = 0.97,
    this.duration = const Duration(milliseconds: 140),
  }) : super(key: key);

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : _onTapDown,
      onTapUp: widget.onTap == null ? null : _onTapUp,
      onTapCancel: widget.onTap == null ? null : _onTapCancel,
      onTap: widget.onTap == null ? null : _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * (1.0 - widget.scaleTo));
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
