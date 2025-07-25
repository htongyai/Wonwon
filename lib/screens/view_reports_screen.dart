import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/services/auth_service.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final QuerySnapshot reportSnapshot =
          await _firestore
              .collection('report')
              .where('resolved', isEqualTo: false)
              .get();
      setState(() {
        _reports =
            reportSnapshot.docs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'docId': doc.id,
                  },
                )
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
    });
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'view_reports'.tr(context),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
              ? Center(child: Text('no_unresolved_reports'.tr(context)))
              : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return GestureDetector(
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportDetailScreen(report: report),
                        ),
                      );
                      if (changed == true) _refresh();
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  report['reason'] ?? 'no_reason'.tr(context),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  report['createdAt'] != null
                                      ? (report['createdAt'] is String
                                          ? report['createdAt'].split('T').first
                                          : report['createdAt']
                                              .toDate()
                                              .toString()
                                              .split(' ')
                                              .first)
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'correct_information'.tr(context) + ':',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                            Text(report['correctInfo'] ?? '-'),
                            const SizedBox(height: 8),
                            Text(
                              'additional_details'.tr(context) + ':',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                            Text(report['additionalDetails'] ?? '-'),
                            const SizedBox(height: 8),
                            Text(
                              'user_id'.tr(context) +
                                  ': ${report['userId'] ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isProcessing = false;

  Future<void> _setResolved(bool resolved) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      // Get current user info
      final user = FirebaseAuth.instance.currentUser;
      String? userId = user?.uid;
      String? userName = user?.displayName;
      if (userId == null) {
        // fallback to AuthService if needed
        try {
          final authService = AuthService();
          userId = await authService.getUserId();
          userName = await authService.getUserName();
        } catch (_) {}
      }
      final updateData = {
        'resolved': resolved,
        'resolvedById': resolved ? userId : null,
        'resolvedByName': resolved ? userName : null,
      };
      await FirebaseFirestore.instance
          .collection('report')
          .doc(widget.report['docId'])
          .update(updateData);
      Navigator.pop(context, true); // Indicate change to refresh list
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          report['reason'] ?? 'no_reason'.tr(context),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Text(
                        report['createdAt'] != null
                            ? (report['createdAt'] is String
                                ? report['createdAt'].split('T').first
                                : report['createdAt']
                                    .toDate()
                                    .toString()
                                    .split(' ')
                                    .first)
                            : '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correct Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report['correctInfo'] ?? '-',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report['additionalDetails'] ?? '-',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'user_id'.tr(context) + ': ${report['userId'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'resolved'.tr(context) +
                            ': ${report['resolved'] == true ? 'yes'.tr(context) : 'no'.tr(context)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (report['resolvedById'] != null ||
                      report['resolvedByName'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'resolved_by'.tr(context) + ': ',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        if (report['resolvedByName'] != null)
                          Text(
                            '${report['resolvedByName']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        if (report['resolvedById'] != null)
                          Text(
                            ' (${report['resolvedById']})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_isProcessing && report['resolved'] != true)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _setResolved(true),
                          label: const Text(
                            'Resolve',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (!_isProcessing && report['resolved'] == true)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.undo, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _setResolved(false),
                          label: const Text(
                            'Unresolve',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
