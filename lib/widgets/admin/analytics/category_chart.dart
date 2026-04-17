import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class ShopCategoryChart extends StatelessWidget {
  final Map<String, int> data;
  final void Function(String category, int count)? onCategoryTap;

  const ShopCategoryChart({
    Key? key,
    required this.data,
    this.onCategoryTap,
  }) : super(key: key);

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

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
                FontAwesomeIcons.tags,
                color: const Color(0xFF8B5CF6),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Shop Categories',
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
                    : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections:
                                  data.entries.map((entry) {
                                    final index = data.keys.toList().indexOf(
                                      entry.key,
                                    );
                                    final total = data.values.fold(
                                      0,
                                      (a, b) => a + b,
                                    );
                                    final percentage =
                                        (entry.value / total * 100);

                                    return PieChartSectionData(
                                      value: entry.value.toDouble(),
                                      title:
                                          '${percentage.toStringAsFixed(1)}%',
                                      color: _colors[index % _colors.length],
                                      radius: 60,
                                      titleStyle: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                data.entries.map((entry) {
                                  final index = data.keys.toList().indexOf(
                                    entry.key,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap:
                                          onCategoryTap != null
                                              ? () => onCategoryTap!(
                                                entry.key,
                                                entry.value,
                                              )
                                              : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    _colors[index %
                                                        _colors.length],
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    entry.key,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                        0xFF1E293B,
                                                      ),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${entry.value} shops',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: const Color(
                                                        0xFF64748B,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
