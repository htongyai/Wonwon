import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/models/repair_record.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/models/repair_sub_service.dart';
import 'package:shared/mixins/auth_state_mixin.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_client/screens/repair_celebration_screen.dart';

class LogRepairScreen extends StatefulWidget {
  final RepairShop shop;
  const LogRepairScreen({Key? key, required this.shop}) : super(key: key);

  @override
  State<LogRepairScreen> createState() => _LogRepairScreenState();
}

class _LogRepairScreenState extends State<LogRepairScreen> with AuthStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  final _durationDaysController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
  int? _satisfactionRating;
  String? _selectedCategory;
  String? _selectedSubService;
  Map<String, List<RepairSubService>> _subServices = {};

  // Photo state — up to 3 photos per repair log
  final List<_PhotoSlot> _photos = [];
  static const int _maxPhotos = 3;

  List<String> get _availableCategories {
    final shopCats = widget.shop.categories;
    final allCats = _subServices.keys.toList();
    if (shopCats.isNotEmpty) {
      final matched = shopCats.where((c) => allCats.contains(c)).toList();
      if (matched.isNotEmpty) return matched;
    }
    return allCats;
  }

  @override
  void initState() {
    super.initState();
    _subServices = RepairSubService.getSubServices();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _durationDaysController.dispose();
    _durationHoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Fetches the number of repair records the user has logged this calendar
  /// year. Used by the celebration screen for the "N repairs this year" line.
  Future<int> _fetchYearRepairCount(String uid) async {
    try {
      final startOfYear = DateTime(DateTime.now().year, 1, 1);
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('repairRecords')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .count()
          .get();
      return snap.count ?? 1;
    } catch (_) {
      return 1;
    }
  }

  Duration? _parsedDuration() {
    final days = int.tryParse(_durationDaysController.text.trim()) ?? 0;
    final hours = int.tryParse(_durationHoursController.text.trim()) ?? 0;
    if (days == 0 && hours == 0) return null;
    return Duration(days: days, hours: hours);
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    HapticFeedback.selectionClick();
    try {
      final picker = ImagePicker();
      final picked = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text('take_photo'.tr(context)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text('choose_from_library'.tr(context)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (picked == null) return;
      final XFile? file = await picker.pickImage(
        source: picked,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photos.add(_PhotoSlot(bytes: bytes)));
    } catch (e) {
      appLog('Photo pick failed: $e');
    }
  }

  Future<List<String>> _uploadPhotos(String uid, String recordId) async {
    final urls = <String>[];
    for (int i = 0; i < _photos.length; i++) {
      final slot = _photos[i];
      if (slot.bytes == null) continue;
      try {
        final ref = FirebaseStorage.instance.ref(
          'users/$uid/repairRecords/$recordId/photo_$i.jpg',
        );
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(slot.bytes!, metadata);
        urls.add(await ref.getDownloadURL());
      } catch (e) {
        appLog('Photo upload failed: $e');
      }
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedDate == null ||
        _selectedCategory == null ||
        _selectedSubService == null) {
      return;
    }

    if (!isLoggedIn || currentUser == null) return;
    final currentUserUid = currentUser?.uid;
    if (currentUserUid == null) return;
    setState(() => _isSubmitting = true);

    final recordId = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .collection('repairRecords')
        .doc()
        .id;

    // Upload photos first so we can store URLs with the record.
    final photoUrls = await _uploadPhotos(currentUserUid, recordId);

    final record = RepairRecord(
      id: recordId,
      shopId: widget.shop.id,
      shopName: widget.shop.name,
      itemFixed: _itemController.text.trim(),
      price: _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text)
          : null,
      date: _selectedDate!,
      duration: _parsedDuration(),
      notes: _notesController.text.trim(),
      satisfactionRating: _satisfactionRating,
      category: _selectedCategory!,
      subService: _selectedSubService!,
      photos: photoUrls,
    );
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('repairRecords')
          .doc(record.id)
          .set(record.toMap());
      if (mounted) {
        _submittedSuccessfully = true;
        AnalyticsService.safeLog(
            () => AnalyticsService().logLogRepair(widget.shop.id));

        // Fetch this year's repair count for the celebration screen.
        final yearTotal = await _fetchYearRepairCount(currentUserUid);

        if (!mounted) return;
        // Push the celebration screen, then return to the previous screen
        // with `true` to signal success.
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RepairCelebrationScreen(
              record: record,
              totalYearRepairs: yearTotal,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_generic'
                .tr(context)
                .replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool get _hasUnsavedChanges {
    if (_submittedSuccessfully) return false;
    return _itemController.text.isNotEmpty ||
        _priceController.text.isNotEmpty ||
        _durationDaysController.text.isNotEmpty ||
        _durationHoursController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _selectedDate != null ||
        _selectedCategory != null ||
        _selectedSubService != null ||
        _satisfactionRating != null ||
        _photos.isNotEmpty;
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('log_repair'.tr(context)),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: ResponsiveBreakpoints.mobile),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    _buildShopCard(),
                    const SizedBox(height: 24),
                    _buildCategoryField(),
                    if (_selectedCategory != null) ...[
                      const SizedBox(height: 16),
                      _buildSubServiceField(),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: 'item_fixed'.tr(context),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'field_required'.tr(context)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'price_thb'.tr(context),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildDurationFields(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'notes'.tr(context),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                    const SizedBox(height: 20),
                    _buildPhotosSection(),
                    const SizedBox(height: 20),
                    _buildSatisfactionSection(),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pieces ────────────────────────────────────────────────────────────────

  Widget _buildShopCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.shop.name,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.shop.address.isNotEmpty)
            _infoRow(Icons.location_on, widget.shop.address),
          if (widget.shop.area.isNotEmpty)
            _infoRow(Icons.place_outlined, widget.shop.area),
          if (widget.shop.phoneNumber != null &&
              widget.shop.phoneNumber!.isNotEmpty)
            _infoRow(Icons.phone_outlined, widget.shop.phoneNumber!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'category_form_label'.tr(context),
        border: const OutlineInputBorder(),
      ),
      value: _selectedCategory,
      items: _availableCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text('category_$category'.tr(context)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _selectedSubService = null;
        });
      },
      validator: (value) =>
          value == null ? 'please_select_category'.tr(context) : null,
    );
  }

  Widget _buildSubServiceField() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedCategory),
      decoration: InputDecoration(
        labelText: 'service_form_label'.tr(context),
        border: const OutlineInputBorder(),
      ),
      value: _selectedSubService,
      items: (_subServices[_selectedCategory] ?? []).map((s) {
        return DropdownMenuItem(
          value: s.id,
          child: Text('subservice_${s.categoryId}_${s.id}'.tr(context)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedSubService = value);
      },
      validator: (value) =>
          value == null ? 'please_select_service'.tr(context) : null,
    );
  }

  Widget _buildDateField() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _selectedDate == null
                  ? 'repair_date'.tr(context)
                  : '${'repair_date'.tr(context)}: ${DateFormat('yyyy-MM-dd').format(_selectedDate!.toLocal())}',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null && mounted) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text('select_date'.tr(context)),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'duration_label'.tr(context),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _durationDaysController,
                decoration: InputDecoration(
                  labelText: 'duration_days_only'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _durationHoursController,
                decoration: InputDecoration(
                  labelText: 'duration_hours_only'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'repair_photos'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_photos.length}/$_maxPhotos',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._photos.asMap().entries.map((entry) => _photoTile(entry.key)),
              if (_photos.length < _maxPhotos) _addPhotoTile(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoTile(int index) {
    final theme = Theme.of(context);
    final slot = _photos[index];
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: slot.bytes != null
                ? Image.memory(slot.bytes!, fit: BoxFit.cover)
                : Container(color: theme.colorScheme.surfaceContainerHighest),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _photos.removeAt(index)),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickPhoto,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_rounded,
                  color: AppConstants.primaryColor, size: 24),
              const SizedBox(height: 4),
              Text(
                'add_photo'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSatisfactionSection() {
    final theme = Theme.of(context);
    final labels = [
      'satisfaction_bad',
      'satisfaction_poor',
      'satisfaction_ok',
      'satisfaction_good',
      'satisfaction_great',
    ];
    final emojis = ['😞', '😕', '😐', '🙂', '🤩'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'satisfaction_question'.tr(context),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final selected = _satisfactionRating == index + 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: index == 2 ? 0 : 2,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _satisfactionRating = index + 1);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppConstants.primaryColor.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppConstants.primaryColor
                              : theme.dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index].tr(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppConstants.primaryColor
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'submit_repair'.tr(context),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Holds the bytes of a selected photo before upload.
class _PhotoSlot {
  final Uint8List? bytes;
  _PhotoSlot({this.bytes});
}

/// Silence an unused-import lint on web-only builds.
// ignore: unused_element
const bool _isWebPlatform = kIsWeb;
