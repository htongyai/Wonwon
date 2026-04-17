import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class RegistrationTrendChart extends StatelessWidget {
  final Map<DateTime, int> shopTrend;
  final Map<DateTime, int> userTrend;

  const RegistrationTrendChart({
    Key? key,
    required this.shopTrend,
    required this.userTrend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
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
                FontAwesomeIcons.chartLine,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Growth Trends',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildLegendItem('Shops', const Color(0xFF3B82F6)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Users', const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child:
                shopTrend.isEmpty && userTrend.isEmpty
                    ? Center(child: Text('no_data_available'.tr(context)))
                    : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: const Color(0xFFE2E8F0),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      value.toInt(),
                                    );
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('MM/dd').format(date),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          if (shopTrend.isNotEmpty)
                            LineChartBarData(
                              spots:
                                  shopTrend.entries.map((entry) {
                                    return FlSpot(
                                      entry.key.millisecondsSinceEpoch
                                          .toDouble(),
                                      entry.value.toDouble(),
                                    );
                                  }).toList(),
                              isCurved: true,
                              color: const Color(0xFF3B82F6),
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFF3B82F6),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              ),
                            ),
                          if (userTrend.isNotEmpty)
                            LineChartBarData(
                              spots:
                                  userTrend.entries.map((entry) {
                                    return FlSpot(
                                      entry.key.millisecondsSinceEpoch
                                          .toDouble(),
                                      entry.value.toDouble(),
                                    );
                                  }).toList(),
                              isCurved: true,
                              color: const Color(0xFF10B981),
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFF10B981),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
