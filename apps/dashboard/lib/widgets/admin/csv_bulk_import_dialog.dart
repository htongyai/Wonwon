import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/services/google_maps_link_service.dart';
import 'package:shared/services/shop_service.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:uuid/uuid.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';
import 'package:wonwon_dashboard/widgets/admin/shop_data_warnings.dart';

/// Dialog for bulk-importing shops from a CSV file containing Google Maps links.
///
/// Flow:
/// 1. Upload → parse CSV → show link count
/// 2. Process each link through [GoogleMapsLinkService]
/// 3. Show results summary with warnings for missing data
class CsvBulkImportDialog extends StatefulWidget {
  const CsvBulkImportDialog({Key? key}) : super(key: key);

  @override
  State<CsvBulkImportDialog> createState() => _CsvBulkImportDialogState();
}

enum _ImportPhase { upload, processing, results }

class _CsvBulkImportDialogState extends State<CsvBulkImportDialog> {
  final GoogleMapsLinkService _linkService = GoogleMapsLinkService();
  final ShopService _shopService = ShopService();
  final ScrollController _logScrollController = ScrollController();

  _ImportPhase _phase = _ImportPhase.upload;

  // Upload phase
  List<String> _extractedUrls = [];
  String? _fileName;
  String? _uploadError;
  bool _autoApprove = false;

  // Processing phase
  int _processedCount = 0;
  int _totalCount = 0;
  final List<String> _logEntries = [];
  bool _isCancelled = false;
  bool _isImporting = false;

  // Results phase
  final List<_ImportedShopResult> _results = [];
  int get _successCount => _results.where((r) => r.success).length;
  int get _failedCount => _results.where((r) => !r.success).length;
  int get _warningCount =>
      _results.where((r) => r.success && r.warnings.isNotEmpty).length;

  /// Max file size: 5 MB
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _isCancelled = true;
    _logScrollController.dispose();
    super.dispose();
  }

  // ── Phase 1: File Upload ─────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      if (!mounted) return;

      final file = result.files.first;
      if (file.bytes == null) {
        setState(() => _uploadError = 'csv_import_invalid_file'.tr(context));
        return;
      }

      // Reject files over 5 MB
      if (file.bytes!.length > _maxFileSizeBytes) {
        setState(() => _uploadError = 'csv_import_file_too_large'.tr(context));
        return;
      }

      // Decode and strip UTF-8 BOM (common in Excel exports)
      var content = utf8.decode(file.bytes!);
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }

      // Normalize Windows line endings → \n
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      final csvTable = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(content);

      // Extract unique Google Maps URLs from all cells
      final urlSet = <String>{};
      final urls = <String>[];
      for (final row in csvTable) {
        for (final cell in row) {
          final text = cell.toString().trim();
          if (text.isNotEmpty && GoogleMapsLinkService.isGoogleMapsUrl(text)) {
            if (urlSet.add(text)) {
              urls.add(text);
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _extractedUrls = urls;
        _uploadError =
            urls.isEmpty ? 'csv_import_no_links'.tr(context) : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = 'csv_import_invalid_file'.tr(context));
      appLog('CSV pick error: $e');
    }
  }

  // ── Phase 2: Processing ──────────────────────────────────────────────

  Future<void> _startImport() async {
    if (_isImporting) return;
    _isImporting = true;

    setState(() {
      _phase = _ImportPhase.processing;
      _totalCount = _extractedUrls.length;
      _processedCount = 0;
      _logEntries.clear();
      _results.clear();
      _isCancelled = false;
    });

    for (int i = 0; i < _extractedUrls.length; i++) {
      if (_isCancelled || !mounted) {
        _addLog('--- ${'csv_import_cancelled'.tr(context)} ---');
        break;
      }

      final url = _extractedUrls[i];
      final rowNum = i + 1;

      try {
        _addLog('[$rowNum/${_extractedUrls.length}] ${'csv_import_extracting'.tr(context)}...');

        final result = await _linkService.parseUrl(url);
        if (!mounted) break;

        if (result == null) {
          _addLog(
              '[$rowNum] ${'csv_import_failed_extract'.tr(context)}');
          _results.add(_ImportedShopResult(
            rowNumber: rowNum,
            url: url,
            success: false,
            errorMessage: 'csv_import_failed_extract'.tr(context),
          ));
        } else {
          // Build and save the shop
          final shop = _buildShopFromResult(result);
          final saved = await _shopService.addShop(shop);
          if (!mounted) break;

          if (saved) {
            final warnings = ShopDataWarnings.getWarnings(shop);
            _addLog(
              '[$rowNum] ${result.placeName ?? 'Shop'} — ${'csv_import_added'.tr(context)}'
              '${warnings.isNotEmpty ? ' (${warnings.length} ${'csv_import_warnings_short'.tr(context)})' : ''}',
            );
            _results.add(_ImportedShopResult(
              rowNumber: rowNum,
              url: url,
              success: true,
              shopName: shop.name,
              warnings: warnings,
            ));
          } else {
            _addLog('[$rowNum] ${result.placeName ?? 'Shop'} — ${'csv_import_save_failed'.tr(context)}');
            _results.add(_ImportedShopResult(
              rowNumber: rowNum,
              url: url,
              success: false,
              errorMessage: 'csv_import_save_failed'.tr(context),
            ));
          }
        }
      } catch (e) {
        _addLog('[$rowNum] Error: $e');
        _results.add(_ImportedShopResult(
          rowNumber: rowNum,
          url: url,
          success: false,
          errorMessage: e.toString(),
        ));
      }

      if (mounted) setState(() => _processedCount = i + 1);

      // Rate-limit: 1.5s between API calls to avoid Google Places throttling
      if (i < _extractedUrls.length - 1 && !_isCancelled) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    _isImporting = false;
    if (mounted) setState(() => _phase = _ImportPhase.results);
  }

  void _addLog(String message) {
    if (!mounted) return;
    setState(() => _logEntries.add(message));
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  RepairShop _buildShopFromResult(GoogleMapsLinkResult result) {
    final shopId = const Uuid().v4();

    // Build hours map
    final hours = <String, String>{};
    if (result.openingHours != null) {
      const dayMapping = {
        1: 'mon',
        2: 'tue',
        3: 'wed',
        4: 'thu',
        5: 'fri',
        6: 'sat',
        0: 'sun',
      };
      for (final entry in result.openingHours!.entries) {
        final dayKey = dayMapping[entry.key];
        if (dayKey == null) continue;
        final period = entry.value;
        if (!period.isClosed) {
          hours[dayKey] =
              '${period.openTimeFormatted} - ${period.closeTimeFormatted}';
        }
      }
    }

    return RepairShop(
      id: shopId,
      name: result.placeName ?? 'Unnamed Shop',
      description: '',
      address: result.fullAddress ?? '',
      area: result.district ?? result.province ?? '',
      categories: result.matchedCategories ?? [],
      rating: 0.0,
      reviewCount: 0,
      latitude: result.latitude,
      longitude: result.longitude,
      hours: hours,
      approved: _autoApprove,
      approvalStatus: _autoApprove ? 'approved' : 'pending',
      timestamp: DateTime.now(),
      phoneNumber: result.phoneNumber,
      district: result.district,
      province: result.province,
      buildingNumber: result.buildingNumber,
      buildingName: result.buildingName,
      soi: result.street,
      landmark: result.landmark,
      otherContacts: result.website,
      photos: result.photoUrls?.take(1).toList() ?? [],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(),
            const Divider(height: 1),
            Flexible(
              child: switch (_phase) {
                _ImportPhase.upload => _buildUploadPhase(),
                _ImportPhase.processing => _buildProcessingPhase(),
                _ImportPhase.results => _buildResultsPhase(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.upload_file_rounded, color: AppConstants.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'csv_import_title'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          if (_phase != _ImportPhase.processing)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              style: IconButton.styleFrom(foregroundColor: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  // ── Upload Phase ─────────────────────────────────────────────────────

  Widget _buildUploadPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF0284C7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'csv_import_instructions'.tr(context),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0369A1),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // File picker area
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _fileName != null
                      ? AppConstants.primaryColor
                      : const Color(0xFFCBD5E1),
                  width: _fileName != null ? 2 : 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _fileName != null
                    ? AppConstants.primaryColor.withAlpha(8)
                    : const Color(0xFFFAFAFA),
              ),
              child: Column(
                children: [
                  Icon(
                    _fileName != null
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_outlined,
                    size: 40,
                    color: _fileName != null
                        ? AppConstants.primaryColor
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fileName ?? 'csv_import_select_file'.tr(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          _fileName != null ? FontWeight.w600 : FontWeight.w400,
                      color: _fileName != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  if (_extractedUrls.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'csv_import_found_links'
                          .tr(context)
                          .replaceAll('{count}', '${_extractedUrls.length}'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Error message
          if (_uploadError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _uploadError!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Auto-approve toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'csv_import_auto_approve'.tr(context),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF475569)),
                  ),
                ),
                Switch(
                  value: _autoApprove,
                  onChanged: (v) => setState(() => _autoApprove = v),
                  activeColor: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Start button
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed:
                  _extractedUrls.isNotEmpty && !_isImporting ? _startImport : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'csv_import_start'.tr(context),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Processing Phase ─────────────────────────────────────────────────

  Widget _buildProcessingPhase() {
    final progress = _totalCount > 0 ? _processedCount / _totalCount : 0.0;

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'csv_import_processing'
                        .tr(context)
                        .replaceAll('{current}', '$_processedCount')
                        .replaceAll('{total}', '$_totalCount'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Log
        Expanded(
          child: Container(
            color: const Color(0xFF1E293B),
            child: ListView.builder(
              controller: _logScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _logEntries.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _logEntries[i],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: _logEntries[i].contains('Error') ||
                            _logEntries[i].contains('failed')
                        ? const Color(0xFFF87171)
                        : _logEntries[i].contains('warning')
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Cancel button
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () => setState(() => _isCancelled = true),
            child: Text(
              'csv_import_cancel'.tr(context),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Results Phase ────────────────────────────────────────────────────

  Widget _buildResultsPhase() {
    return Column(
      children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _summaryCard(
                _successCount,
                'csv_import_success_label'.tr(context),
                const Color(0xFF22C55E),
                Icons.check_circle_rounded,
              ),
              const SizedBox(width: 12),
              _summaryCard(
                _failedCount,
                'csv_import_failed_label'.tr(context),
                const Color(0xFFEF4444),
                Icons.cancel_rounded,
              ),
              const SizedBox(width: 12),
              _summaryCard(
                _warningCount,
                'csv_import_warnings_label'.tr(context),
                const Color(0xFFF59E0B),
                Icons.warning_amber_rounded,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Result list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = _results[i];
              return _resultRow(r);
            },
          ),
        ),
        const Divider(height: 1),

        // Close button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('csv_import_close'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(int count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(_ImportedShopResult r) {
    if (r.success) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: r.warnings.isNotEmpty
              ? const Color(0xFFFFFBEB)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: r.warnings.isNotEmpty
                ? const Color(0xFFFDE68A)
                : const Color(0xFFBBF7D0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              r.warnings.isNotEmpty
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              size: 18,
              color: r.warnings.isNotEmpty
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF22C55E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.shopName ?? 'Shop #${r.rowNumber}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (r.warnings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        r.warnings
                            .map((w) =>
                                ShopDataWarnings.warningLabel(w, context))
                            .join(', '),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '#${r.rowNumber}',
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded,
                size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Row ${r.rowNumber}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (r.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        r.errorMessage!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF991B1B)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Internal result holder for each row processed during import.
class _ImportedShopResult {
  final int rowNumber;
  final String url;
  final bool success;
  final String? shopName;
  final String? errorMessage;
  final List<ShopWarningType> warnings;

  _ImportedShopResult({
    required this.rowNumber,
    required this.url,
    required this.success,
    this.shopName,
    this.errorMessage,
    this.warnings = const [],
  });
}
