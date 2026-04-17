import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';
  String _selectedTimeRange = '7d';
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  Map<String, String> _getActivityFilters(BuildContext context) => {
    'all': 'filter_all_activities'.tr(context),
    'user': 'filter_user_activities'.tr(context),
    'shop': 'filter_shop_activities'.tr(context),
    'review': 'filter_review_activities'.tr(context),
    'admin': 'filter_admin_activities'.tr(context),
    'system': 'filter_system_activities'.tr(context),
  };

  Map<String, String> _getTimeRanges(BuildContext context) => {
    '1d': 'time_range_last_24h'.tr(context),
    '7d': 'time_range_last_7d'.tr(context),
    '30d': 'time_range_last_30d'.tr(context),
    '90d': 'time_range_last_90d'.tr(context),
  };

  @override
  void initState() {
    super.initState();
    _loadActivityLog();
  }

  Future<void> _loadActivityLog() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final now = DateTime.now();
      final days =
          _selectedTimeRange == '1d'
              ? 1
              : _selectedTimeRange == '7d'
              ? 7
              : _selectedTimeRange == '30d'
              ? 30
              : 90;
      final startDate = now.subtract(Duration(days: days));

      // Fetch real activity logs from Firestore
      final activities = await _fetchRealActivityLogs(startDate, now);

      if (!mounted) return;
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_to_load_activity'.tr(context).replaceAll('{error}', e.toString()))),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRealActivityLogs(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Fetch real activity logs from the activity_logs collection
      Query query = _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      // Apply filter if not 'all'
      if (_selectedFilter != 'all') {
        query = query.where('type', isEqualTo: _selectedFilter);
      }

      final snapshot = await query.limit(500).get();

      final activities =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();

      return activities;
    } catch (e) {
      appLog('Error fetching activity logs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.listCheck,
              color: const Color(0xFF1E293B),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'activity_log_label'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            onPressed: _loadActivityLog,
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildActivityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterChips()),
          const SizedBox(width: 16),
          _buildTimeRangeDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children:
          _getActivityFilters(context).entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = entry.key;
                });
                _loadActivityLog();
              },
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildTimeRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        items:
            _getTimeRanges(context).entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTimeRange = value;
            });
            _loadActivityLog();
          }
        },
      ),
    );
  }

  Widget _buildActivityList() {
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'no_activities_found'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'activities_empty_subtitle'.tr(context),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'unknown';
    final timestamp = activity['timestamp'] as Timestamp?;

    return InkWell(
      onTap: () => _showActivityDetails(activity),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getActivityTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: FaIcon(
                  _getActivityIcon(type),
                  color: _getActivityTypeColor(type),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity['title'] ?? 'unknown_activity'.tr(context),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getActivityTypeColor(type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getActivityTypeColor(type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['description'] ?? 'no_description'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp != null
                            ? DateFormat(
                              'MMM dd, yyyy HH:mm',
                            ).format(timestamp.toDate())
                            : 'unknown_time'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      if (activity['metadata'] != null) ...[
                        const SizedBox(width: 16),
                        ...((activity['metadata'] as Map<String, dynamic>)
                            .entries
                            .take(2)
                            .map((entry) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF64748B,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            })),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: min(600, MediaQuery.of(context).size.width - 32),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getActivityTypeColor(
                          activity['type'],
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: FaIcon(
                          _getActivityIcon(activity['type']),
                          color: _getActivityTypeColor(activity['type']),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'activity_details_title'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Flexible(child: _buildActivityDetailsContent(activity)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityDetailsContent(Map<String, dynamic> activity) {
    final timestamp = activity['timestamp'] as Timestamp?;
    final metadata = activity['metadata'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'unknown_activity'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity['description'] ?? 'no_description'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'activity_information'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('id_label'.tr(context), activity['id'] ?? 'unknown'.tr(context)),
                _buildDetailRow('type_label'.tr(context), activity['type']),
                _buildDetailRow('action_label'.tr(context), activity['action']),
                _buildDetailRow(
                  'timestamp_label'.tr(context),
                  timestamp != null
                      ? DateFormat(
                        'MMM dd, yyyy HH:mm:ss',
                      ).format(timestamp.toDate())
                      : 'unknown'.tr(context),
                ),

                if (activity.containsKey('userId'))
                  _buildDetailRow('user_id_label'.tr(context), activity['userId']),
                if (activity.containsKey('userName'))
                  _buildDetailRow('user_name_label'.tr(context), activity['userName']),
                if (activity.containsKey('userEmail'))
                  _buildDetailRow('user_email_label'.tr(context), activity['userEmail']),
                if (activity.containsKey('shopId'))
                  _buildDetailRow('shop_id_label'.tr(context), activity['shopId']),
                if (activity.containsKey('shopName'))
                  _buildDetailRow('shop_name_label'.tr(context), activity['shopName']),
                if (activity.containsKey('reviewId'))
                  _buildDetailRow('review_id_label'.tr(context), activity['reviewId']),
              ],
            ),
          ),

          if (metadata.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_additional_information'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...metadata.entries.map((entry) {
                    return _buildDetailRow(
                      entry.key,
                      entry.value?.toString() ?? 'not_available'.tr(context),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'user':
        return FontAwesomeIcons.user;
      case 'shop':
        return FontAwesomeIcons.store;
      case 'review':
        return FontAwesomeIcons.star;
      case 'admin':
        return FontAwesomeIcons.userShield;
      case 'system':
        return FontAwesomeIcons.server;
      default:
        return FontAwesomeIcons.circleInfo;
    }
  }

  Color _getActivityTypeColor(String? type) {
    switch (type) {
      case 'user':
        return const Color(0xFF3B82F6);
      case 'shop':
        return const Color(0xFF10B981);
      case 'review':
        return const Color(0xFFF59E0B);
      case 'admin':
        return const Color(0xFFEF4444);
      case 'system':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
