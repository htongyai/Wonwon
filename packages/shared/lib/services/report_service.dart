import 'package:cloud_firestore/cloud_firestore.dart';

class ShopReport {
  final String id;
  final String shopId;
  final String reason;
  final String correctInfo;
  final String additionalDetails;
  final DateTime createdAt;
  final String userId;
  final bool resolved;

  ShopReport({
    required this.id,
    required this.shopId,
    required this.reason,
    required this.correctInfo,
    required this.additionalDetails,
    required this.createdAt,
    this.userId = 'anonymous',
    this.resolved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'reason': reason,
      'correctInfo': correctInfo,
      'additionalDetails': additionalDetails,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'resolved': resolved,
    };
  }

  factory ShopReport.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final createdAtVal = json['createdAt'];
    if (createdAtVal == null) {
      parsedDate = DateTime.now();
    } else if (createdAtVal is Timestamp) {
      parsedDate = createdAtVal.toDate();
    } else if (createdAtVal is String) {
      parsedDate = DateTime.tryParse(createdAtVal) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ShopReport(
      id: json['id']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      correctInfo: json['correctInfo']?.toString() ?? '',
      additionalDetails: json['additionalDetails']?.toString() ?? '',
      createdAt: parsedDate,
      userId: json['userId']?.toString() ?? 'anonymous',
      resolved: json['resolved'] as bool? ?? false,
    );
  }
}

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'report';

  // Add a new report to Firestore
  Future<void> addReport(ShopReport report) async {
    if (report.shopId.trim().isEmpty) {
      throw ArgumentError('Report must reference a valid shop');
    }

    await _firestore
        .collection(_collection)
        .doc(report.id)
        .set(report.toJson());
  }

  // Get all reports from Firestore
  Future<List<ShopReport>> getAllReports() async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .orderBy('createdAt', descending: true)
            .limit(200)
            .get();
    return snapshot.docs.map((doc) => ShopReport.fromJson(doc.data())).toList();
  }

  // Get reports by shop ID from Firestore
  Future<List<ShopReport>> getReportsByShopId(String shopId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('shopId', isEqualTo: shopId)
            .limit(50)
            .get();

    // Sort in memory to avoid composite index requirement
    final reports =
        snapshot.docs.map((doc) => ShopReport.fromJson(doc.data())).toList();
    reports.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    ); // Sort by createdAt descending
    return reports;
  }

  // Mark a report as resolved in Firestore
  Future<void> resolveReport(String reportId) async {
    await _firestore.collection(_collection).doc(reportId).update({
      'resolved': true,
    });
  }
}
