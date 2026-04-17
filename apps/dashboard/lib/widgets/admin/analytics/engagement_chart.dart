import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class UserEngagementChart extends StatelessWidget {
  final int activeUsers;
  final int totalUsers;

  const UserEngagementChart({
    Key? key,
    required this.activeUsers,
    required this.totalUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inactiveUsers = totalUsers - activeUsers;

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
                FontAwesomeIcons.userCheck,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'User Engagement',
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
                totalUsers == 0
                    ? Center(child: Text('no_data_available'.tr(context)))
                    : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Engagement Rate: ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              Text(
                                '${(activeUsers / totalUsers * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildEngagementBar(
                                  'Active',
                                  activeUsers,
                                  totalUsers,
                                  const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildEngagementBar(
                                  'Inactive',
                                  inactiveUsers,
                                  totalUsers,
                                  const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: 40,
                  height: 120 * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
