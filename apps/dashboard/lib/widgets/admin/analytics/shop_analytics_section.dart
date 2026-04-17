import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/shop_stats.dart';
import 'package:shared/services/shop_analytics_service.dart';
import 'package:shared/utils/app_logger.dart';

/// Displays per-shop analytics: metric cards, daily trend line chart,
/// and an engagement breakdown bar chart.
class ShopAnalyticsSection extends StatefulWidget {
  final String shopId;

  const ShopAnalyticsSection({Key? key, required this.shopId}) : super(key: key);

  @override
  State<ShopAnalyticsSection> createState() => _ShopAnalyticsSectionState();
}

class _ShopAnalyticsSectionState extends State<ShopAnalyticsSection> {
  ShopStats? _stats;
  bool _isLoading = true;
  String _period = '30d';

  int get _days {
    switch (_period) {
      case '7d':
        return 7;
      case '90d':
        return 90;
      default:
        return 30;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ShopAnalyticsService().getStats(widget.shopId, days: _days);
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (e) {
      appLog('Error loading shop analytics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changePeriod(String period) {
    if (_period == period) return;
    setState(() => _period = period);
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _buildHeader(),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_stats != null) ...[
            _buildMetricCards(),
            const SizedBox(height: 24),
            _buildTrendChart(),
            const SizedBox(height: 24),
            _buildEngagementBreakdown(),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No analytics data available',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header with period selector ─────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        FaIcon(FontAwesomeIcons.chartLine, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Shop Analytics',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        _periodButton('7d'),
        const SizedBox(width: 4),
        _periodButton('30d'),
        const SizedBox(width: 4),
        _periodButton('90d'),
      ],
    );
  }

  Widget _periodButton(String period) {
    final isSelected = _period == period;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _changePeriod(period),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            period,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ── Metric cards row ────────────────────────────────────────────────────

  Widget _buildMetricCards() {
    final stats = _stats!;
    final period = stats.periodTotals;

    final metrics = [
      _MetricData('Views', stats.totalViews, period['views'] ?? 0,
          FontAwesomeIcons.eye, const Color(0xFF3B82F6)),
      _MetricData('Saves', stats.totalSaves, period['saves'] ?? 0,
          FontAwesomeIcons.bookmark, const Color(0xFFF59E0B)),
      _MetricData('Directions', stats.totalDirections, period['directions'] ?? 0,
          FontAwesomeIcons.diamondTurnRight, const Color(0xFF10B981)),
      _MetricData('Contacts', stats.totalContacts, period['contacts'] ?? 0,
          FontAwesomeIcons.phone, const Color(0xFF8B5CF6)),
      _MetricData('Shares', stats.totalShares, period['shares'] ?? 0,
          FontAwesomeIcons.shareNodes, const Color(0xFFEC4899)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics.map((m) => _buildMiniCard(m)).toList(),
    );
  }

  Widget _buildMiniCard(_MetricData data) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(data.icon, size: 14, color: data.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatNumber(data.lifetime),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatNumber(data.period)} this period',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Daily views trend line chart ────────────────────────────────────────

  Widget _buildTrendChart() {
    final daily = _stats!.dailyStats;
    if (daily.isEmpty) return const SizedBox.shrink();

    final maxViews = daily.fold<int>(0, (max, d) => d.views > max ? d.views : max);
    final maxY = (maxViews == 0 ? 10 : maxViews * 1.2).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Views',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: (_days <= 7 ? 1 : (_days <= 30 ? 7 : 14)).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= daily.length) return const SizedBox.shrink();
                      return Text(
                        DateFormat('d/M').format(daily[idx].date),
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (daily.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    daily.length,
                    (i) => FlSpot(i.toDouble(), daily[i].views.toDouble()),
                  ),
                  isCurved: true,
                  color: const Color(0xFF3B82F6),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: _days <= 14,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF3B82F6),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final idx = spot.x.toInt();
                    final d = daily[idx];
                    return LineTooltipItem(
                      '${DateFormat('MMM d').format(d.date)}\n${d.views} views',
                      GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Engagement breakdown bar chart ──────────────────────────────────────

  Widget _buildEngagementBreakdown() {
    final period = _stats!.periodTotals;
    final items = [
      _BarItem('Views', period['views'] ?? 0, const Color(0xFF3B82F6)),
      _BarItem('Saves', period['saves'] ?? 0, const Color(0xFFF59E0B)),
      _BarItem('Directions', period['directions'] ?? 0, const Color(0xFF10B981)),
      _BarItem('Contacts', period['contacts'] ?? 0, const Color(0xFF8B5CF6)),
      _BarItem('Shares', period['shares'] ?? 0, const Color(0xFFEC4899)),
      _BarItem('Reviews', period['reviews'] ?? 0, const Color(0xFFEF4444)),
    ];
    final maxVal = items.fold<int>(1, (max, i) => i.value > max ? i.value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Breakdown',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: maxVal > 0 ? (item.value / maxVal).clamp(0.0, 1.0) : 0,
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                child: Text(
                  _formatNumber(item.value),
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// Private data classes
class _MetricData {
  final String label;
  final int lifetime;
  final int period;
  final IconData icon;
  final Color color;
  _MetricData(this.label, this.lifetime, this.period, this.icon, this.color);
}

class _BarItem {
  final String label;
  final int value;
  final Color color;
  _BarItem(this.label, this.value, this.color);
}
