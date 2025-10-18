import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/widgets/optimized_screen.dart';
import 'package:wonwonw2/services/report_service.dart';
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

  final List<String> _reportTypes = [
    'Inappropriate Content',
    'Spam',
    'Incorrect Information',
    'Harassment',
    'Copyright Violation',
    'Other',
  ];

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
          child: Row(
            children: [
              Text(
                'Reports & Issues Management',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('report')
                        .where('resolved', isEqualTo: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  final count =
                      snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          count > 0
                              ? const Color(0xFFEF4444).withOpacity(0.1)
                              : const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count Pending Reports',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            count > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                      ),
                    ),
                  );
                },
              ),
            ],
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
          child: Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) {
                    safeSetState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _statusFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Type Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _typeFilter,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Types'),
                    ),
                    ..._reportTypes.map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    ),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _typeFilter = value!;
                    });
                  },
                ),
              ),
            ],
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
                return Center(child: Text('Error: ${snapshot.error}'));
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
            'No reports found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No reports match your current filters',
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
    final description = report['description'] ?? 'No description provided';
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
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFEF4444).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    type,
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
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isResolved ? 'RESOLVED' : 'PENDING',
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
                if (shopId.isNotEmpty) ...[
                  FaIcon(
                    FontAwesomeIcons.store,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Shop ID: $shopId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
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
                  Text(
                    'User ID: $userId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _viewReportDetails(report),
                      icon: const FaIcon(FontAwesomeIcons.eye, size: 16),
                      tooltip: 'View Details',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF3B82F6,
                        ).withOpacity(0.1),
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isResolved)
                      IconButton(
                        onPressed: () => _resolveReport(report),
                        icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                        tooltip: 'Mark as Resolved',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF10B981,
                          ).withOpacity(0.1),
                          foregroundColor: const Color(0xFF10B981),
                        ),
                      ),
                    if (!isResolved) const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteReport(report),
                      icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                      tooltip: 'Delete Report',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFEF4444,
                        ).withOpacity(0.1),
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
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Report Details',
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
                  _buildDetailRow('Type', report['type'] ?? 'Other'),
                  _buildDetailRow(
                    'Status',
                    report['resolved'] == true ? 'Resolved' : 'Pending',
                  ),
                  _buildDetailRow(
                    'Submitted',
                    DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
                  ),
                  _buildDetailRow('Shop ID', report['shopId'] ?? 'N/A'),
                  _buildDetailRow('User ID', report['userId'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  Text(
                    'Description:',
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
                      report['description'] ?? 'No description provided',
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
                        child: const Text('Close'),
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
                          child: const Text('Mark as Resolved'),
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

  Widget _buildDetailRow(String label, String value) {
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
            title: const Text('Resolve Report'),
            content: const Text(
              'Are you sure you want to mark this report as resolved?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: const Text('Resolve'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Resolving report...');

      try {
        await _reportService.resolveReport(report['docId']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report has been marked as resolved'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resolving report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  void _deleteReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Report'),
            content: const Text(
              'Are you sure you want to delete this report? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Deleting report...');

      try {
        await _firestore.collection('report').doc(report['docId']).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report has been deleted'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }
}
