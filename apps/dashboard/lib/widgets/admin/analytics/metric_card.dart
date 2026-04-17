import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsMetric {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? trend;

  AnalyticsMetric({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
  });
}

class MetricCard extends StatelessWidget {
  final AnalyticsMetric metric;

  const MetricCard({
    Key? key,
    required this.metric,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(metric.icon, color: metric.color, size: 20),
                ),
              ),
              const Spacer(),
              if (metric.trend != null && metric.trend != 0.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        metric.trend! > 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        metric.trend! > 0
                            ? FontAwesomeIcons.arrowTrendUp
                            : FontAwesomeIcons.arrowTrendDown,
                        size: 12,
                        color:
                            metric.trend! > 0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${metric.trend!.abs().toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              metric.trend! > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            metric.value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          if (metric.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              metric.subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
