import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:shared/models/repair_record.dart';
import 'package:shared/utils/repair_impact.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Hero-style impact card. Shown on the profile screen above the repair
/// records list. The headline metric is CO₂ saved, rendered in a large
/// display serif — the number *is* the moment.
class ImpactCard extends StatelessWidget {
  final List<RepairRecord> records;

  const ImpactCard({Key? key, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totals = RepairImpact.totals(records);
    if (totals.isZero) return const SizedBox.shrink();

    final driveKm = RepairImpact.drivingEquivalentKm(totals.co2Kg);
    final driveAnalogy = driveKm > 0
        ? 'impact_drive_equivalent'
            .tr(context)
            .replaceFirst('{km}', driveKm.toString())
        : '';

    // The editorial palette (cream surface, warm taupe ink) is
    // designed for light mode. In dark mode we swap to a deep
    // cocoa surface and lighter ink so the card stops shouting
    // "I forgot to follow the theme switch."
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1F1B14) : EcoPalette.surfaceLight;
    final hairline = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : EcoPalette.hairline;
    final secondaryInk =
        isDark ? Colors.white.withValues(alpha: 0.72) : EcoPalette.inkSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LeafIcon(color: EcoPalette.leaf),
              const SizedBox(width: 8),
              Text(
                'impact_eyebrow'.tr(context),
                style: EditorialTypography.eyebrowLeaf,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Headline metric
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: totals.co2Kg < 10
                      ? totals.co2Kg.toStringAsFixed(1)
                      : totals.co2Kg.round().toString(),
                  style: EditorialTypography.metricLarge,
                ),
                TextSpan(
                  text: '  kg CO₂',
                  style: EditorialTypography.displayMedium.copyWith(
                    color: secondaryInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'impact_saved_label'.tr(context),
            style: EditorialTypography.body.copyWith(
              color: secondaryInk,
            ),
          ),
          if (driveAnalogy.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              driveAnalogy,
              style: EditorialTypography.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(height: 1, color: hairline),
          const SizedBox(height: 16),
          // Secondary metrics: items, money, shops
          Row(
            children: [
              Expanded(
                child: _SecondaryMetric(
                  value: '${totals.items}',
                  label: 'impact_items_saved'.tr(context),
                ),
              ),
              Expanded(
                child: _SecondaryMetric(
                  value: '฿${_formatMoney(totals.moneyBaht)}',
                  label: 'impact_money_saved'.tr(context),
                ),
              ),
              Expanded(
                child: _SecondaryMetric(
                  value: '${totals.shopsSupported}',
                  label: 'impact_shops_supported'.tr(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.round().toString();
  }
}

class _SecondaryMetric extends StatelessWidget {
  final String value;
  final String label;
  const _SecondaryMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: EditorialTypography.displayMedium.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: EditorialTypography.caption,
          maxLines: 2,
        ),
      ],
    );
  }
}

/// Tiny hand-drawn-feeling leaf mark.
class _LeafIcon extends StatelessWidget {
  final Color color;
  const _LeafIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: CustomPaint(painter: _LeafPainter(color: color)),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();
    // Simple leaf silhouette
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(size.width, size.height * 0.1, size.width * 0.95,
        size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.55, size.height, size.width * 0.05,
        size.height * 0.6);
    path.quadraticBezierTo(0, size.height * 0.1, size.width * 0.5, 0);
    path.close();
    canvas.drawPath(path, p);

    // Midrib
    final mid = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.85),
      mid,
    );
  }

  @override
  bool shouldRepaint(covariant _LeafPainter old) => old.color != color;
}
