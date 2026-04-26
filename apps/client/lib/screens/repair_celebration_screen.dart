import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:shared/models/repair_record.dart';
import 'package:shared/utils/repair_impact.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Full-screen moment shown after a repair is successfully logged.
/// Celebrates the act in the WonWon voice — quiet, warm, specific.
class RepairCelebrationScreen extends StatefulWidget {
  final RepairRecord record;
  final int totalYearRepairs;

  const RepairCelebrationScreen({
    Key? key,
    required this.record,
    required this.totalYearRepairs,
  }) : super(key: key);

  @override
  State<RepairCelebrationScreen> createState() =>
      _RepairCelebrationScreenState();
}

class _RepairCelebrationScreenState extends State<RepairCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _leafScale;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _leafScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // Celebratory haptic right when the screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.mediumImpact();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final co2 = RepairImpact.co2ForRepair(widget.record);
    final money = RepairImpact.moneySavedForRepair(widget.record);

    return Scaffold(
      backgroundColor: EcoPalette.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Leaf mark — unfurls with a scale animation
              AnimatedBuilder(
                animation: _leafScale,
                builder: (context, child) => Transform.scale(
                  scale: _leafScale.value,
                  child: child,
                ),
                child: _LeafMark(size: 68),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(_contentFade),
                  child: Column(
                    children: [
                      Text(
                        'celebration_eyebrow'.tr(context),
                        style: EditorialTypography.eyebrowLeaf,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'celebration_headline'.tr(context),
                        textAlign: TextAlign.center,
                        style: EditorialTypography.displayLarge,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'celebration_body'
                            .tr(context)
                            .replaceFirst('{item}', widget.record.itemFixed)
                            .replaceFirst('{shop}', widget.record.shopName),
                        textAlign: TextAlign.center,
                        style: EditorialTypography.body.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Impact stats
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: EcoPalette.hairline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                value: _formatCo2(co2),
                                unit: 'kg CO₂',
                                label: 'celebration_not_wasted'.tr(context),
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: EcoPalette.hairline),
                            Expanded(
                              child: _Metric(
                                value: '฿${money.round()}',
                                unit: '',
                                label: 'celebration_kept'.tr(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.totalYearRepairs > 1) ...[
                        const SizedBox(height: 20),
                        Text(
                          'celebration_year_total'
                              .tr(context)
                              .replaceFirst(
                                  '{n}', '${widget.totalYearRepairs}'),
                          textAlign: TextAlign.center,
                          style: EditorialTypography.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _contentFade,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoPalette.leaf,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'celebration_cta'.tr(context),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCo2(double v) {
    if (v < 1) return v.toStringAsFixed(1);
    if (v < 10) return v.toStringAsFixed(1);
    return v.round().toString();
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _Metric({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: EditorialTypography.metricLarge.copyWith(fontSize: 22),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: EditorialTypography.caption.copyWith(
                    color: EcoPalette.inkSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: EditorialTypography.caption,
        ),
      ],
    );
  }
}

/// Simple leaf shape — used as the hero mark on celebration.
class _LeafMark extends StatelessWidget {
  final double size;
  const _LeafMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: EcoPalette.leafWash,
              shape: BoxShape.circle,
            ),
          ),
          CustomPaint(
            size: Size(size * 0.5, size * 0.5),
            painter: _CelebrationLeafPainter(),
          ),
        ],
      ),
    );
  }
}

class _CelebrationLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = EcoPalette.leaf;
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(size.width, size.height * 0.1, size.width * 0.95,
        size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.55, size.height, size.width * 0.05,
        size.height * 0.6);
    path.quadraticBezierTo(0, size.height * 0.1, size.width * 0.5, 0);
    path.close();
    canvas.drawPath(path, p);

    final mid = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      mid,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
