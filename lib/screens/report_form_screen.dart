import 'package:flutter/material.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/report_service.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class ReportFormScreen extends StatefulWidget {
  final String shopId;
  final VoidCallback? onReportSubmitted;
  const ReportFormScreen({
    Key? key,
    required this.shopId,
    this.onReportSubmitted,
  }) : super(key: key);

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  String _selectedReason = '';
  String _correctInfo = '';
  String _details = '';
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  late final List<String> reasonOptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reasonOptions = [
      'report_reason_address'.tr(context),
      'report_reason_hours'.tr(context),
      'report_reason_closed'.tr(context),
      'report_reason_contact'.tr(context),
      'report_reason_services'.tr(context),
      'report_reason_nonexistent'.tr(context),
      'report_reason_other'.tr(context),
    ];
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
    });
    // Get the current user ID if logged in
    String userId = 'anonymous';
    try {
      final authService = AuthService();
      final uid = await authService.getUserId();
      if (uid != null && uid.isNotEmpty) {
        userId = uid;
      }
    } catch (_) {}
    final report = ShopReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopId: widget.shopId,
      reason: _selectedReason,
      correctInfo: _correctInfo,
      additionalDetails: _details,
      createdAt: DateTime.now(),
      userId: userId,
    );
    await ReportService().addReport(report);
    setState(() {
      _isSubmitting = false;
    });
    widget.onReportSubmitted?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('report_incorrect'.tr(context)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'whats_incorrect'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    reasonOptions
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(
                              reason,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value ?? '';
                  });
                },
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'report_reason_required'.tr(context)
                            : null,
                hint: Text('report_select_reason'.tr(context)),
              ),
              const SizedBox(height: 16),
              Text(
                'report_correct_info'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'report_correct_info_hint'.tr(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _correctInfo = value;
                  });
                },
                validator:
                    (value) =>
                        (value == null || value.isEmpty)
                            ? 'Please enter the correct information'
                            : null,
              ),
              const SizedBox(height: 16),
              Text(
                'report_additional_details'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'report_details_hint'.tr(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _details = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator()
                          : Text('submit'.tr(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
