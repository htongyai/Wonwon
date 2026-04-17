import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class AreaDistributionChart extends StatelessWidget {
  final Map<String, int> data;

  const AreaDistributionChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
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
                FontAwesomeIcons.mapLocationDot,
                color: const Color(0xFF06B6D4),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Geographic Distribution',
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
                              final area = data.keys.elementAt(groupIndex);
                              return BarTooltipItem(
                                '$area\n${'n_shops'.tr(context).replaceAll('{count}', '${rod.toY.toInt()}')}',
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
                                final index = value.toInt();
                                if (index >= 0 && index < data.keys.length) {
                                  final area = data.keys.elementAt(index);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      area.length > 8
                                          ? '${area.substring(0, 8)}...'
                                          : area,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
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
                            data.entries.toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final dataEntry = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: dataEntry.value.toDouble(),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF06B6D4),
                                        const Color(
                                          0xFF06B6D4,
                                        ).withValues(alpha: 0.7),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 20,
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
