import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/models/repair_record.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';
import 'package:shared/models/repair_sub_service.dart';
import 'package:wonwon_dashboard/mixins/auth_state_mixin.dart';
import 'package:shared/services/analytics_service.dart';

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
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
  int? _satisfactionRating;
  String? _selectedCategory;
  String? _selectedSubService;
  Map<String, List<RepairSubService>> _subServices = {};

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
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedDate == null ||
        _selectedCategory == null ||
        _selectedSubService == null)
      return;

    setState(() {
      _isSubmitting = true;
    });
    if (!isLoggedIn || currentUser == null) return;
    final currentUserUid = currentUser?.uid;
    if (currentUserUid == null) return;
    final record = RepairRecord(
      id: FirebaseFirestore.instance.collection('tmp').doc().id,
      shopId: widget.shop.id,
      shopName: widget.shop.name,
      itemFixed: _itemController.text.trim(),
      price:
          _priceController.text.isNotEmpty
              ? double.tryParse(_priceController.text)
              : null,
      date: _selectedDate!,
      duration:
          _durationController.text.isNotEmpty
              ? Duration(days: int.tryParse(_durationController.text) ?? 0)
              : null,
      notes: _notesController.text.trim(),
      satisfactionRating: _satisfactionRating,
      category: _selectedCategory!,
      subService: _selectedSubService!,
    );
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('repairRecords')
          .doc(record.id)
          .set(record.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('repair_logged'.tr(context)),
            backgroundColor: Colors.green,
          ),
        );
        _submittedSuccessfully = true;
        AnalyticsService.safeLog(() => AnalyticsService().logLogRepair(widget.shop.id));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_generic'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _hasUnsavedChanges {
    if (_submittedSuccessfully) return false;
    return _itemController.text.isNotEmpty ||
        _priceController.text.isNotEmpty ||
        _durationController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _selectedDate != null ||
        _selectedCategory != null ||
        _selectedSubService != null ||
        _satisfactionRating != null;
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'discard_changes'.tr(context),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.brown,
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
              style: const TextStyle(color: Colors.brown),
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
        title: Text('log_repair'.tr(context)),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.mobile),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shop.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.shop.address.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.shop.address,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (widget.shop.area.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.place, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.shop.area,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (widget.shop.phoneNumber != null &&
                        widget.shop.phoneNumber!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.shop.phoneNumber ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'category_form_label'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items:
                    _availableCategories.map((category) {
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
                validator:
                    (value) =>
                        value == null ? 'please_select_category'.tr(context) : null,
              ),
              const SizedBox(height: 16),
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCategory),
                  decoration: InputDecoration(
                    labelText: 'service_form_label'.tr(context),
                    border: const OutlineInputBorder(),
                  ),
                  value: _selectedSubService,
                  items:
                      (_subServices[_selectedCategory] ?? []).map((subService) {
                        return DropdownMenuItem(
                          value: subService.id,
                          child: Text(subService.getLocalizedName(context)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubService = value;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'please_select_service'.tr(context) : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: 'item_fixed'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'field_required'.tr(context) : null,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'repair_date'.tr(context)
                            : '${'repair_date'.tr(context)}: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
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
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 20),
                      label: Text('select_date'.tr(context)),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'duration_days'.tr(context),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
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
              const SizedBox(height: 16),
              Text(
                'satisfaction_question'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      color:
                          _satisfactionRating != null &&
                                  index < _satisfactionRating!
                              ? Colors.green
                              : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _satisfactionRating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                        : Text(
                            'submit_repair'.tr(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
