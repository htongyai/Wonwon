import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/report_service.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';
import 'package:wonwonw2/services/analytics_service.dart';

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

class _ReportFormScreenState extends State<ReportFormScreen>
    with AuthStateMixin {
  String _selectedReason = '';
  String _correctInfo = '';
  String _details = '';
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
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
    } catch (e) {
      debugPrint('Error getting user ID: $e');
    }
    final report = ShopReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopId: widget.shopId,
      reason: _selectedReason,
      correctInfo: _correctInfo,
      additionalDetails: _details,
      createdAt: DateTime.now(),
      userId: userId,
    );
    try {
      await ReportService().addReport(report);
      AnalyticsService.safeLog(() => AnalyticsService().logSubmitReport(widget.shopId));
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      _submittedSuccessfully = true;
      widget.onReportSubmitted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('report_submitted'.tr(context)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_occurred'.tr(context)}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool get _hasUnsavedChanges {
    if (_submittedSuccessfully) return false;
    return _selectedReason.isNotEmpty ||
        _correctInfo.isNotEmpty ||
        _details.isNotEmpty;
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'discard_changes'.tr(context),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        content: Text(
          'discard_changes_message'.tr(context),
          style: GoogleFonts.montserrat(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'keep_editing'.tr(context),
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'discard'.tr(context),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog();
        if (shouldDiscard && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('report_incorrect'.tr(context)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                                ? 'report_correct_info_required'.tr(context)
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
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('submit'.tr(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
