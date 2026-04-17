import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class ApprovalStatusChart extends StatelessWidget {
  final int approvedShops;
  final int pendingShops;

  const ApprovalStatusChart({
    Key? key,
    required this.approvedShops,
    required this.pendingShops,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = approvedShops + pendingShops;

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
                FontAwesomeIcons.checkCircle,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Shop Approval Status',
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
                total == 0
                    ? Center(child: Text('no_data_available'.tr(context)))
                    : Column(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  value: approvedShops.toDouble(),
                                  title:
                                      '${(approvedShops / total * 100).toStringAsFixed(1)}%',
                                  color: const Color(0xFF10B981),
                                  radius: 80,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: pendingShops.toDouble(),
                                  title:
                                      '${(pendingShops / total * 100).toStringAsFixed(1)}%',
                                  color: const Color(0xFFF59E0B),
                                  radius: 80,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatusLegend(
                              'Approved',
                              approvedShops,
                              const Color(0xFF10B981),
                            ),
                            _buildStatusLegend(
                              'Pending',
                              pendingShops,
                              const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
