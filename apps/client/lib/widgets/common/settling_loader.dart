import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';

/// A warmer, less clinical alternative to [CircularProgressIndicator].
/// Shows a quietly pulsing leaf dot + a specific phrase ("Finding nearby
/// repairers…") that signals what we're waiting for.
///
/// Use at the top of lists, not as a centered full-screen spinner.
class SettlingLoader extends StatefulWidget {
  final String message;
  final double dotSize;

  const SettlingLoader({
    Key? key,
    required this.message,
    this.dotSize = 10,
  }) : super(key: key);

  @override
  State<SettlingLoader> createState() => _SettlingLoaderState();
}

class _SettlingLoaderState extends State<SettlingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              final scale = 0.75 + 0.35 * t;
              final opacity = 0.45 + 0.55 * t;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: const BoxDecoration(
                      color: EcoPalette.leaf,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: EditorialTypography.body.copyWith(
              fontStyle: FontStyle.italic,
              color: EcoPalette.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
