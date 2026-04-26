import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:shared/services/google_maps_link_service.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Data returned to the caller when the user accepts the imported values.
class GoogleMapsImportResult {
  final GoogleMapsLinkResult parsed;
  final Uint8List? photoBytes;

  const GoogleMapsImportResult({required this.parsed, this.photoBytes});
}

/// Modal dialog that walks the user through pasting a Google Maps URL,
/// previewing the extracted data (name, address, coords, photo), and
/// confirming the import.
///
/// Returns a [GoogleMapsImportResult] if the user accepts; `null` on cancel.
class GoogleMapsImportDialog extends StatefulWidget {
  const GoogleMapsImportDialog({Key? key}) : super(key: key);

  @override
  State<GoogleMapsImportDialog> createState() => _GoogleMapsImportDialogState();
}

class _GoogleMapsImportDialogState extends State<GoogleMapsImportDialog> {
  final _urlController = TextEditingController();
  final Dio _photoDio = Dio();
  bool _isLoading = false;
  String? _error;
  GoogleMapsLinkResult? _result;
  Uint8List? _photoBytes;
  int? _photoIndex;

  @override
  void dispose() {
    _urlController.dispose();
    _photoDio.close();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text == null) return;
      setState(() => _urlController.text = data!.text!);
    } catch (_) {}
  }

  Future<void> _import() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!GoogleMapsLinkService.isGoogleMapsUrl(url)) {
      setState(() => _error = 'import_not_a_maps_url'.tr(context));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _photoBytes = null;
      _photoIndex = null;
    });
    try {
      final parsed = await GoogleMapsLinkService().parseUrl(url);
      if (!mounted) return;
      if (parsed == null) {
        setState(() {
          _isLoading = false;
          _error = 'import_parse_failed'.tr(context);
        });
        return;
      }
      // Attempt to download the first photo URL if available.
      Uint8List? photoBytes;
      int? photoIndex;
      if (parsed.photoUrls != null && parsed.photoUrls!.isNotEmpty) {
        for (int i = 0; i < parsed.photoUrls!.length; i++) {
          final bytes = await _downloadPhoto(parsed.photoUrls![i]);
          if (bytes != null) {
            photoBytes = bytes;
            photoIndex = i;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _result = parsed;
        _photoBytes = photoBytes;
        _photoIndex = photoIndex;
        _isLoading = false;
      });
    } catch (e) {
      appLog('Maps import error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'import_parse_failed'.tr(context);
      });
    }
  }

  Future<Uint8List?> _downloadPhoto(String url) async {
    try {
      final resp = await _photoDio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      final data = resp.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    } catch (e) {
      appLog('Photo download failed ($url): $e');
      return null;
    }
  }

  void _accept() {
    if (_result == null) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(GoogleMapsImportResult(
      parsed: _result!,
      photoBytes: _photoBytes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              _header(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: _body(context),
                ),
              ),
              if (_result != null) _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('import_from_maps'.tr(context),
                    style: EditorialTypography.displayMedium
                        .copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  'import_subtitle'.tr(context),
                  style: EditorialTypography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'import_url_hint'.tr(context),
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppConstants.primaryColor, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              onPressed: _pasteFromClipboard,
              tooltip: 'paste'.tr(context),
            ),
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _import,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.search_rounded, size: 16),
            label: Text(
              _isLoading
                  ? 'import_loading'.tr(context)
                  : 'import_fetch'.tr(context),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBox(_error!),
        ],
        if (_result != null) ...[
          const SizedBox(height: 20),
          _preview(context, _result!),
        ],
      ],
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EcoPalette.terracotta.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EcoPalette.terracotta.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: EcoPalette.terracotta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 12,
                color: EcoPalette.terracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context, GoogleMapsLinkResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF22C55E), size: 18),
            const SizedBox(width: 6),
            Text(
              'import_found_fields'
                  .tr(context)
                  .replaceFirst('{n}', '${r.extractedFieldCount}'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Soft warning if the imported coords fall outside the
        // Thailand bounding box. We never block the import — the
        // admin might legitimately add a non-Thai shop — but a
        // visible heads-up catches the common mistake of pasting
        // a wrong link.
        if (!GoogleMapsLinkService.isInsideThailandBounds(
            r.latitude, r.longitude)) ...[
          _geoFenceWarning(context),
          const SizedBox(height: 12),
        ],
        // Photo preview
        if (_photoBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _photoBytes!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          if (_photoIndex != null && _photoIndex! > 0) ...[
            const SizedBox(height: 6),
            Text(
              'import_photo_fallback'
                  .tr(context)
                  .replaceFirst('{n}', '${_photoIndex! + 1}'),
              style: EditorialTypography.caption,
            ),
          ],
          const SizedBox(height: 14),
        ] else if (r.photoUrls != null && r.photoUrls!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'import_photo_download_failed'.tr(context),
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        // Extracted fields
        if (r.placeName != null)
          _field(Icons.storefront_rounded, 'shop_name_label'.tr(context),
              r.placeName!),
        if (r.fullAddress != null)
          _field(Icons.location_on_rounded, 'address'.tr(context),
              r.fullAddress!),
        _field(Icons.pin_drop_rounded, 'location_label'.tr(context),
            '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}'),
        if (r.phoneNumber != null)
          _field(Icons.phone_rounded, 'phone'.tr(context), r.phoneNumber!),
        if (r.website != null)
          _field(Icons.language_rounded, 'website'.tr(context), r.website!),
      ],
    );
  }

  /// Soft "outside Thailand" warning shown above the extracted
  /// fields when the imported coordinates fall outside the loose
  /// Thailand bounding box. Yellow/amber so it reads as a heads-up
  /// rather than the red error treatment used for parse failures.
  Widget _geoFenceWarning(BuildContext context) {
    const amberFg = Color(0xFFB45309); // tailwind amber-700
    const amberBg = Color(0xFFFEF3C7); // tailwind amber-100
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? amberFg.withValues(alpha: 0.18) : amberBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: amberFg.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: amberFg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'import_outside_thailand_warning'.tr(context),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFCD34D) : amberFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: EcoPalette.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: EditorialTypography.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: EcoPalette.inkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('cancel'.tr(context)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _accept,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(
                'import_use_data'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
