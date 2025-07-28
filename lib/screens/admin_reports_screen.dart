import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../utils/responsive_size.dart';
import '../widgets/section_title.dart';
import '../widgets/performance_loading_widget.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _sortBy = 'createdAt';
  bool _sortAscending = false;
  String _statusFilter = 'all'; // 'all', 'pending', 'resolved', 'dismissed'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'User Reports',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppConstants.darkColor,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.darkColor),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveSize.getScaledPadding(const EdgeInsets.all(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filters Section
            SectionTitle(text: 'Search & Filters'),
            SizedBox(height: ResponsiveSize.getHeight(2)),
            _buildSearchAndFilters(),
            SizedBox(height: ResponsiveSize.getHeight(3)),

            // Reports Section
            SectionTitle(text: 'Reports'),
            SizedBox(height: ResponsiveSize.getHeight(2)),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('report').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  appLog('Error loading reports: ${snapshot.error}');
                  return _buildErrorState();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Process reports
                final Map<String, dynamic> uniqueReports = {};

                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Handle Timestamp conversion
                  if (data['createdAt'] == null) {
                    data['createdAt'] = DateTime.now().toIso8601String();
                  } else if (data['createdAt'] is Timestamp) {
                    data['createdAt'] =
                        (data['createdAt'] as Timestamp)
                            .toDate()
                            .toIso8601String();
                  }

                  // Deduplicate by ID
                  if (!uniqueReports.containsKey(doc.id)) {
                    uniqueReports[doc.id] = {'id': doc.id, ...data};
                  }
                }

                final allReports = uniqueReports.values.toList();
                appLog('Total unique reports: ${allReports.length}');

                // Apply status filter
                final statusFilteredReports =
                    _statusFilter == 'all'
                        ? allReports
                        : allReports.where((report) {
                          final resolved = report['resolved'] ?? false;
                          String status = 'pending';
                          if (resolved) {
                            status = 'resolved';
                          } else if (report['dismissed'] == true) {
                            status = 'dismissed';
                          }
                          return status == _statusFilter;
                        }).toList();

                // Apply search filter
                final filteredReports =
                    _searchQuery.isEmpty
                        ? statusFilteredReports
                        : statusFilteredReports.where((report) {
                          final query = _searchQuery.toLowerCase();
                          final reason =
                              report['reason']?.toString().toLowerCase() ?? '';
                          final additionalDetails =
                              report['additionalDetails']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          final correctInfo =
                              report['correctInfo']?.toString().toLowerCase() ??
                              '';
                          final resolvedByName =
                              report['resolvedByName']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';

                          return reason.contains(query) ||
                              additionalDetails.contains(query) ||
                              correctInfo.contains(query) ||
                              resolvedByName.contains(query);
                        }).toList();

                // Apply sorting
                filteredReports.sort((a, b) {
                  int comparison = 0;
                  switch (_sortBy) {
                    case 'title':
                      comparison = (a['reason'] ?? '').toString().compareTo(
                        (b['reason'] ?? '').toString(),
                      );
                      break;
                    case 'status':
                      final resolvedA = a['resolved'] ?? false;
                      final resolvedB = b['resolved'] ?? false;
                      comparison = resolvedA.toString().compareTo(
                        resolvedB.toString(),
                      );
                      break;
                    case 'createdAt':
                      final dateA =
                          DateTime.tryParse(a['createdAt'] ?? '') ??
                          DateTime.now();
                      final dateB =
                          DateTime.tryParse(b['createdAt'] ?? '') ??
                          DateTime.now();
                      comparison = dateA.compareTo(dateB);
                      break;
                    case 'reporterName':
                      comparison = (a['resolvedByName'] ?? '')
                          .toString()
                          .compareTo((b['resolvedByName'] ?? '').toString());
                      break;
                    default:
                      final dateA =
                          DateTime.tryParse(a['createdAt'] ?? '') ??
                          DateTime.now();
                      final dateB =
                          DateTime.tryParse(b['createdAt'] ?? '') ??
                          DateTime.now();
                      comparison = dateA.compareTo(dateB);
                  }
                  return _sortAscending ? comparison : -comparison;
                });

                appLog(
                  'Filtered and sorted reports: ${filteredReports.length}',
                );

                return _buildReportsList(filteredReports);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return _buildSettingsCard(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppConstants.primaryColor),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          // Filters row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                      DropdownMenuItem(
                        value: 'dismissed',
                        child: Text('Dismissed'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sort by
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'createdAt',
                        child: Text('Date Created'),
                      ),
                      DropdownMenuItem(value: 'title', child: Text('Reason')),
                      DropdownMenuItem(value: 'status', child: Text('Status')),
                      DropdownMenuItem(
                        value: 'reporterName',
                        child: Text('Reporter'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value ?? 'createdAt';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sort direction
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppConstants.primaryColor,
                  ),
                  tooltip:
                      _sortAscending ? 'Sort Descending' : 'Sort Ascending',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<dynamic> reports) {
    return Column(
      children: reports.map((report) => _buildReportCard(report)).toList(),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final resolved = report['resolved'] ?? false;
    String status = 'pending';
    if (resolved) {
      status = 'resolved';
    } else if (report['dismissed'] == true) {
      status = 'dismissed';
    }
    final createdAt =
        DateTime.tryParse(report['createdAt'] ?? '') ?? DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(2)),
      child: _buildSettingsCard(
        child: Column(
          children: [
            ListTile(
              contentPadding: ResponsiveSize.getScaledPadding(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.report_problem,
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              title: Text(
                report['reason']?.toString() ?? 'No Reason',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Reporter: ${report['resolvedByName']?.toString() ?? 'Anonymous'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (report['shopId'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Shop ID: ${report['shopId']}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (report['additionalDetails'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Details: ${report['additionalDetails']}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
              onTap: () => _viewReportDetails(report),
            ),
            const Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    'View',
                    Icons.visibility,
                    AppConstants.primaryColor,
                    () => _viewReportDetails(report),
                  ),
                  _buildActionButton(
                    'Resolve',
                    Icons.check_circle,
                    Colors.green,
                    () => _resolveReport(report),
                  ),
                  _buildActionButton(
                    'Dismiss',
                    Icons.cancel,
                    Colors.orange,
                    () => _dismissReport(report),
                  ),
                  _buildActionButton(
                    'Delete',
                    Icons.delete,
                    Colors.red,
                    () => _deleteReport(report),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _viewReportDetails(Map<String, dynamic> report) {
    final resolved = report['resolved'] ?? false;
    String status = 'Pending';
    if (resolved) {
      status = 'Resolved';
    } else if (report['dismissed'] == true) {
      status = 'Dismissed';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Report Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Reason',
                    report['reason']?.toString() ?? 'No Reason',
                  ),
                  _buildDetailRow(
                    'Additional Details',
                    report['additionalDetails']?.toString() ??
                        'No Additional Details',
                  ),
                  _buildDetailRow(
                    'Correct Info',
                    report['correctInfo']?.toString() ?? 'No Correct Info',
                  ),
                  _buildDetailRow(
                    'Reporter',
                    report['resolvedByName']?.toString() ?? 'Anonymous',
                  ),
                  _buildDetailRow(
                    'Shop ID',
                    report['shopId']?.toString() ?? 'Unknown Shop',
                  ),
                  _buildDetailRow('Status', status),
                  _buildDetailRow(
                    'Resolved By ID',
                    report['resolvedById']?.toString() ?? 'Not Resolved',
                  ),
                  if (report['createdAt'] != null)
                    _buildDetailRow(
                      'Created',
                      DateFormat('MMM dd, yyyy HH:mm').format(
                        DateTime.tryParse(report['createdAt']) ??
                            DateTime.now(),
                      ),
                    ),
                  if (report['userId'] != null)
                    _buildDetailRow(
                      'User ID',
                      report['userId']?.toString() ?? 'Unknown',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.montserrat(fontSize: 14)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _resolveReport(Map<String, dynamic> report) {
    _updateReportStatus(report['id'], 'resolved');
  }

  void _dismissReport(Map<String, dynamic> report) {
    _updateReportStatus(report['id'], 'dismissed');
  }

  void _deleteReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Report'),
            content: Text(
              'Are you sure you want to delete this report? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _firestore.collection('report').doc(report['id']).delete();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _updateReportStatus(String reportId, String status) {
    Map<String, dynamic> updateData = {
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status == 'resolved') {
      updateData['resolved'] = true;
    } else if (status == 'dismissed') {
      updateData['dismissed'] = true;
    }

    _firestore.collection('report').doc(reportId).update(updateData);
  }

  Widget _buildLoadingState() {
    return const PerformanceLoadingWidget(
      message: 'Loading reports...',
      size: 50,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading reports',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Force rebuild
              });
            },
            child: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no user reports to display.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
