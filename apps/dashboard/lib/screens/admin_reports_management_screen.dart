import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';
import 'package:wonwon_dashboard/widgets/optimized_screen.dart';
import 'package:shared/services/report_service.dart';
import 'package:intl/intl.dart';

class AdminReportsManagementScreen extends OptimizedScreen {
  const AdminReportsManagementScreen({Key? key}) : super(key: key);

  @override
  OptimizedLoadingScreen<AdminReportsManagementScreen> createState() =>
      _AdminReportsManagementScreenState();
}

class _AdminReportsManagementScreenState
    extends OptimizedLoadingScreen<AdminReportsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReportService _reportService = ReportService();

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, pending, resolved
  String _typeFilter = 'all';
  String _sortBy = 'createdAt';
  bool _sortAscending = false;

  final Map<String, String> _shopNameCache = {};
  final Map<String, String> _userNameCache = {};
  final Set<String> _pendingShopFetches = {};
  final Set<String> _pendingUserFetches = {};

  final List<String> _reportTypes = [
    'Inappropriate Content',
    'Spam',
    'Incorrect Information',
    'Harassment',
    'Copyright Violation',
    'Other',
  ];

  void _prefetchNames(List<Map<String, dynamic>> reports) {
    final shopIds = <String>{};
    final userIds = <String>{};
    for (final report in reports) {
      final shopId = (report['shopId'] ?? '').toString();
      final userId = (report['userId'] ?? '').toString();
      if (shopId.isNotEmpty &&
          !_shopNameCache.containsKey(shopId) &&
          !_pendingShopFetches.contains(shopId)) {
        shopIds.add(shopId);
      }
      if (userId.isNotEmpty &&
          !_userNameCache.containsKey(userId) &&
          !_pendingUserFetches.contains(userId)) {
        userIds.add(userId);
      }
    }
    if (shopIds.isEmpty && userIds.isEmpty) return;
    _pendingShopFetches.addAll(shopIds);
    _pendingUserFetches.addAll(userIds);
    for (final id in shopIds) {
      _firestore.collection('shops').doc(id).get().then((doc) {
        if (!mounted) return;
        final name = (doc.data()?['name'] ?? '').toString();
        safeSetState(() {
          _shopNameCache[id] = name.isNotEmpty ? name : id;
          _pendingShopFetches.remove(id);
        });
      }).catchError((_) {
        if (!mounted) return;
        safeSetState(() {
          _shopNameCache[id] = id;
          _pendingShopFetches.remove(id);
        });
      });
    }
    for (final id in userIds) {
      _firestore.collection('users').doc(id).get().then((doc) {
        if (!mounted) return;
        final data = doc.data();
        final name = (data?['name'] ?? data?['displayName'] ?? data?['email'] ?? '').toString();
        safeSetState(() {
          _userNameCache[id] = name.isNotEmpty ? name : id;
          _pendingUserFetches.remove(id);
        });
      }).catchError((_) {
        if (!mounted) return;
        safeSetState(() {
          _userNameCache[id] = id;
          _pendingUserFetches.remove(id);
        });
      });
    }
  }

  String _shopLabelFor(String id) {
    if (id.isEmpty) return '';
    return _shopNameCache[id] ?? (id.length > 10 ? '${id.substring(0, 6)}…' : id);
  }

  String _userLabelFor(String id) {
    if (id.isEmpty) return '';
    return _userNameCache[id] ?? (id.length > 10 ? '${id.substring(0, 6)}…' : id);
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Text(
            'admin_reports_issues_management'.tr(context),
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
          ),
        ),

        // Filters and Search
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    onChanged: (value) { safeSetState(() { _searchQuery = value; }); },
                    decoration: InputDecoration(
                      hintText: 'admin_search_reports'.tr(context),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(labelText: 'admin_status'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('admin_all_status'.tr(context))),
                          DropdownMenuItem(value: 'pending', child: Text('admin_pending'.tr(context))),
                          DropdownMenuItem(value: 'resolved', child: Text('admin_resolved'.tr(context))),
                        ],
                        onChanged: (value) { safeSetState(() { _statusFilter = value!; }); },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _typeFilter,
                        decoration: InputDecoration(labelText: 'admin_type'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('admin_all_types'.tr(context))),
                          ..._reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(_translateReportType(context, type)))),
                        ],
                        onChanged: (value) { safeSetState(() { _typeFilter = value!; }); },
                      )),
                    ])
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      SizedBox(width: constraints.maxWidth * 0.48, child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(labelText: 'admin_status'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('admin_all_status'.tr(context))),
                          DropdownMenuItem(value: 'pending', child: Text('admin_pending'.tr(context))),
                          DropdownMenuItem(value: 'resolved', child: Text('admin_resolved'.tr(context))),
                        ],
                        onChanged: (value) { safeSetState(() { _statusFilter = value!; }); },
                      )),
                      SizedBox(width: constraints.maxWidth * 0.48, child: DropdownButtonFormField<String>(
                        value: _typeFilter,
                        decoration: InputDecoration(labelText: 'admin_type'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('admin_all_types'.tr(context))),
                          ..._reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(_translateReportType(context, type)))),
                        ],
                        onChanged: (value) { safeSetState(() { _typeFilter = value!; }); },
                      )),
                    ]),
                ],
              );
            },
          ),
        ),

        // Reports List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('report').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('admin_error_prefix'.tr(context).replaceAll('{error}', '${snapshot.error}')));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Process and filter reports
              final reports =
                  snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['docId'] = doc.id;
                    return data;
                  }).toList();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _prefetchNames(reports);
              });

              final filteredReports = _filterReports(reports);
              _sortReports(filteredReports);

              return _buildReportsList(filteredReports);
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterReports(
    List<Map<String, dynamic>> reports,
  ) {
    return reports.where((report) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final description =
            (report['description'] ?? '').toString().toLowerCase();
        final type = (report['type'] ?? '').toString().toLowerCase();
        if (!description.contains(query) && !type.contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != 'all') {
        final isResolved = report['resolved'] == true;
        if (_statusFilter == 'pending' && isResolved) return false;
        if (_statusFilter == 'resolved' && !isResolved) return false;
      }

      // Type filter
      if (_typeFilter != 'all') {
        if (report['type'] != _typeFilter) return false;
      }

      return true;
    }).toList();
  }

  void _sortReports(List<Map<String, dynamic>> reports) {
    reports.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'createdAt':
          final aDate =
              a['createdAt'] is Timestamp
                  ? (a['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
          final bDate =
              b['createdAt'] is Timestamp
                  ? (b['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
          comparison = aDate.compareTo(bDate);
          break;
        case 'type':
          comparison = (a['type'] ?? '').toString().compareTo(
            (b['type'] ?? '').toString(),
          );
          break;
        default:
          final aDate =
              a['createdAt'] is Timestamp
                  ? (a['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
          final bDate =
              b['createdAt'] is Timestamp
                  ? (b['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
          comparison = aDate.compareTo(bDate);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.flag, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'admin_no_reports_found'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'admin_no_reports_match_filters'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<Map<String, dynamic>> reports) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: reports.length,
      itemBuilder: (context, index) => _buildReportCard(reports[index]),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isResolved = report['resolved'] == true;
    final createdAt =
        report['createdAt'] is Timestamp
            ? (report['createdAt'] as Timestamp).toDate()
            : DateTime.now();
    final type = report['type'] ?? 'Other';
    final description = report['description'] ?? 'admin_no_description_provided'.tr(context);
    final shopId = report['shopId'] ?? '';
    final userId = report['userId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isResolved
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _translateReportType(context, type),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(type),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isResolved
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isResolved ? 'admin_resolved_label'.tr(context) : 'admin_pending_label'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isResolved
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (shopId.isNotEmpty) ...[
                        FaIcon(
                          FontAwesomeIcons.store,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'admin_shop_label_prefix'.tr(context).replaceAll('{name}', _shopLabelFor(shopId)),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (userId.isNotEmpty) ...[
                        FaIcon(
                          FontAwesomeIcons.user,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'admin_user_label_prefix'.tr(context).replaceAll('{name}', _userLabelFor(userId)),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _viewReportDetails(report),
                      icon: const FaIcon(FontAwesomeIcons.eye, size: 16),
                      tooltip: 'admin_view_details'.tr(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF3B82F6,
                        ).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isResolved)
                      IconButton(
                        onPressed: () => _resolveReport(report),
                        icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                        tooltip: 'admin_mark_as_resolved'.tr(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFF10B981),
                        ),
                      ),
                    if (!isResolved) const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteReport(report),
                      icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                      tooltip: 'admin_delete_report'.tr(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFEF4444,
                        ).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _translateReportType(BuildContext context, String type) {
    switch (type) {
      case 'Inappropriate Content':
        return 'admin_report_type_inappropriate_content'.tr(context);
      case 'Spam':
        return 'admin_report_type_spam'.tr(context);
      case 'Incorrect Information':
        return 'admin_report_type_incorrect_information'.tr(context);
      case 'Harassment':
        return 'admin_report_type_harassment'.tr(context);
      case 'Copyright Violation':
        return 'admin_report_type_copyright_violation'.tr(context);
      case 'Other':
        return 'admin_report_type_other'.tr(context);
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Inappropriate Content':
        return const Color(0xFFEF4444);
      case 'Spam':
        return const Color(0xFFF59E0B);
      case 'Incorrect Information':
        return const Color(0xFF3B82F6);
      case 'Harassment':
        return const Color(0xFF8B5CF6);
      case 'Copyright Violation':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _viewReportDetails(Map<String, dynamic> report) {
    final createdAt =
        report['createdAt'] is Timestamp
            ? (report['createdAt'] as Timestamp).toDate()
            : DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: min(600, MediaQuery.of(context).size.width * 0.95),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'admin_report_details'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(context, 'admin_type'.tr(context), _translateReportType(context, report['type'] ?? 'Other')),
                  _buildDetailRow(
                    context,
                    'admin_status'.tr(context),
                    report['resolved'] == true ? 'admin_resolved'.tr(context) : 'admin_pending'.tr(context),
                  ),
                  _buildDetailRow(
                    context,
                    'admin_submitted'.tr(context),
                    DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
                  ),
                  _buildDetailRow(
                    context,
                    'admin_shop_id'.tr(context),
                    (() {
                      final id = (report['shopId'] ?? '').toString();
                      if (id.isEmpty) return 'N/A';
                      final name = _shopNameCache[id];
                      return name != null && name != id ? '$name ($id)' : id;
                    })(),
                  ),
                  _buildDetailRow(
                    context,
                    'admin_user_id'.tr(context),
                    (() {
                      final id = (report['userId'] ?? '').toString();
                      if (id.isEmpty) return 'N/A';
                      final name = _userNameCache[id];
                      return name != null && name != id ? '$name ($id)' : id;
                    })(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'admin_description_label'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      report['description'] ?? 'admin_no_description_provided'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('admin_close'.tr(context)),
                      ),
                      if (report['resolved'] != true) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _resolveReport(report);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                          ),
                          child: Text('admin_mark_as_resolved'.tr(context)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
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

  void _resolveReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('resolve_report'.tr(context)),
            content: Text(
              'admin_resolve_report_confirm'.tr(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: Text('resolve_button'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setLoading(true, message: 'admin_resolving_report'.tr(context));

    try {
      await _reportService.resolveReport(report['docId']);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('admin_report_marked_resolved'.tr(context)),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('admin_error_resolving_report'.tr(context).replaceAll('{error}', '$e')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  void _deleteReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('admin_delete_report'.tr(context)),
            content: Text(
              'admin_delete_report_confirm'.tr(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('delete'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setLoading(true, message: 'admin_deleting_report'.tr(context));

    try {
      await _firestore.collection('report').doc(report['docId']).delete();
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('admin_report_deleted'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('admin_error_deleting_report'.tr(context).replaceAll('{error}', '$e')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false);
    }
  }
}
