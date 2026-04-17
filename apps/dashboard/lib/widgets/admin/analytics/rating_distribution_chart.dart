import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class RatingDistributionChart extends StatelessWidget {
  final Map<int, int> data;

  const RatingDistributionChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
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
              FaIcon(
                FontAwesomeIcons.star,
                color: const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Rating Distribution',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                data.isEmpty
                    ? Center(child: Text('no_data_available'.tr(context)))
                    : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            data.values.isEmpty
                                ? 10
                                : data.values
                                        .reduce((a, b) => a > b ? a : b)
                                        .toDouble() *
                                    1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => const Color(0xFF1E293B),
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                'n_reviews_count'.tr(context).replaceAll('{count}', '${rod.toY.toInt()}'),
                                GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(value.toInt(), (
                                      index,
                                    ) {
                                      return const FaIcon(
                                        FontAwesomeIcons.star,
                                        size: 8,
                                        color: Color(0xFFF59E0B),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups:
                            data.entries.map((entry) {
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFF59E0B),
                                        const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 24,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
