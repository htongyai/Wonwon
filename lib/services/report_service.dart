import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShopReport {
  final String id;
  final String shopId;
  final String reason;
  final String details;
  final DateTime createdAt;
  final String userId;
  final bool resolved;

  ShopReport({
    required this.id,
    required this.shopId,
    required this.reason,
    required this.details,
    required this.createdAt,
    this.userId = 'anonymous',
    this.resolved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'reason': reason,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'resolved': resolved,
    };
  }

  factory ShopReport.fromJson(Map<String, dynamic> json) {
    return ShopReport(
      id: json['id'],
      shopId: json['shopId'],
      reason: json['reason'],
      details: json['details'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      resolved: json['resolved'],
    );
  }
}

class ReportService {
  static const String _reportsKey = 'shop_reports';

  // Add a new report
  Future<void> addReport(ShopReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getStringList(_reportsKey) ?? [];

    // Convert the report to JSON
    final reportJson = jsonEncode(report.toJson());

    // Add to the list
    reportsJson.add(reportJson);

    // Save back to SharedPreferences
    await prefs.setStringList(_reportsKey, reportsJson);
  }

  // Get all reports
  Future<List<ShopReport>> getAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getStringList(_reportsKey) ?? [];

    // Convert JSON strings to ShopReport objects
    return reportsJson.map((jsonStr) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ShopReport.fromJson(json);
    }).toList();
  }

  // Get reports by shop ID
  Future<List<ShopReport>> getReportsByShopId(String shopId) async {
    final reports = await getAllReports();
    return reports.where((report) => report.shopId == shopId).toList();
  }

  // Mark a report as resolved
  Future<void> resolveReport(String reportId) async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getStringList(_reportsKey) ?? [];

    // Convert all reports
    final reports =
        reportsJson.map((jsonStr) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          return ShopReport.fromJson(json);
        }).toList();

    // Find and update the specific report
    for (int i = 0; i < reports.length; i++) {
      if (reports[i].id == reportId) {
        // Create a new report with resolved = true
        final updatedReport = ShopReport(
          id: reports[i].id,
          shopId: reports[i].shopId,
          reason: reports[i].reason,
          details: reports[i].details,
          createdAt: reports[i].createdAt,
          userId: reports[i].userId,
          resolved: true,
        );

        // Update the reports list
        reportsJson[i] = jsonEncode(updatedReport.toJson());
        break;
      }
    }

    // Save back to SharedPreferences
    await prefs.setStringList(_reportsKey, reportsJson);
  }
}
