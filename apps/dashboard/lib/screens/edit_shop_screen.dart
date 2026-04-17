import 'package:flutter/material.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/app_colors.dart';
import 'package:shared/constants/app_text_styles.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:wonwon_dashboard/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_dashboard/widgets/section_title.dart';
import 'package:shared/utils/responsive_size.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/services/shop_service.dart';

class EditShopScreen extends StatefulWidget {
  final RepairShop shop;

  const EditShopScreen({Key? key, required this.shop}) : super(key: key);

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _buildingNameController = TextEditingController();
  final _soiController = TextEditingController();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _lineIdController = TextEditingController();
  final _facebookPageController = TextEditingController();
  final _otherContactsController = TextEditingController();
  final _notesOrConditionsController = TextEditingController();
  final _usualOpeningTimeController = TextEditingController();
  final _usualClosingTimeController = TextEditingController();
  final _instagramPageController = TextEditingController();
  final _buildingFloorController = TextEditingController();
  String? _selectedProvince;

  // Image variables
  Uint8List? _selectedImageBytes;
  List<String> _existingPhotos = [];
  // Removed unused fields: _imageError, _isProcessingImage

  List<String> _selectedCategories = [];
  final List<String> _availableCategories = [
    'clothing',
    'footwear',
    'watch',
    'bag',
    'electronics',
    'appliance',
  ];

  // Sub-services editing
  Map<String, List<String>> _selectedSubServices = {};

  final Map<String, TextEditingController> _hoursControllers = {
    'Monday': TextEditingController(),
    'Tuesday': TextEditingController(),
    'Wednesday': TextEditingController(),
    'Thursday': TextEditingController(),
    'Friday': TextEditingController(),
    'Saturday': TextEditingController(),
    'Sunday': TextEditingController(),
  };

  // New controllers for separate opening and closing times
  final Map<String, TextEditingController> _openingTimeControllers = {
    'Monday': TextEditingController(),
    'Tuesday': TextEditingController(),
    'Wednesday': TextEditingController(),
    'Thursday': TextEditingController(),
    'Friday': TextEditingController(),
    'Saturday': TextEditingController(),
    'Sunday': TextEditingController(),
  };

  final Map<String, TextEditingController> _closingTimeControllers = {
    'Monday': TextEditingController(),
    'Tuesday': TextEditingController(),
    'Wednesday': TextEditingController(),
    'Thursday': TextEditingController(),
    'Friday': TextEditingController(),
    'Saturday': TextEditingController(),
    'Sunday': TextEditingController(),
  };

  // Payment methods
  List<String> _selectedPaymentMethods = [];
  final List<String> _availablePaymentMethods = ['cash', 'card', 'qr', 'bank_transfer', 'true_money', 'line_pay'];

  // Other options
  bool _requiresPurchase = false;
  bool _tryOnAreaAvailable = false;
  String _priceRange = '฿';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _savedSuccessfully = false;

  // Store initial values for comparison
  late String _initialName;
  late String _initialDescription;
  late String _initialAddress;
  late String _initialArea;
  late String _initialLatitude;
  late String _initialLongitude;
  late String _initialPhone;
  late String _initialBuildingNumber;
  late String _initialBuildingName;
  late String _initialSoi;
  late String _initialDistrict;
  late String _initialLandmark;
  late String _initialLineId;
  late String _initialFacebookPage;
  late String _initialOtherContacts;
  late String _initialNotesOrConditions;
  late String _initialInstagramPage;
  late String _initialBuildingFloor;
  late List<String> _initialCategories;
  late List<String> _initialPaymentMethods;
  late bool _initialRequiresPurchase;
  late bool _initialTryOnAreaAvailable;
  late String _initialPriceRange;
  late List<String> _initialExistingPhotos;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final shop = widget.shop;

    // Basic information
    _nameController.text = shop.name;
    _descriptionController.text = shop.description;
    _addressController.text = shop.address;
    _areaController.text = shop.area;
    _latitudeController.text = shop.latitude.toString();
    _longitudeController.text = shop.longitude.toString();

    // Contact information
    _phoneController.text = shop.phoneNumber ?? '';
    _buildingNumberController.text = shop.buildingNumber ?? '';
    _buildingNameController.text = shop.buildingName ?? '';
    _soiController.text = shop.soi ?? '';
    _districtController.text = shop.district ?? '';
    _landmarkController.text = shop.landmark ?? '';
    _lineIdController.text = shop.lineId ?? '';
    _facebookPageController.text = shop.facebookPage ?? '';
    _otherContactsController.text = shop.otherContacts ?? '';
    _notesOrConditionsController.text = shop.notesOrConditions ?? '';
    _usualOpeningTimeController.text = shop.usualOpeningTime ?? '';
    _instagramPageController.text = shop.instagramPage ?? '';
    _buildingFloorController.text = shop.buildingFloor ?? '';
    _selectedProvince = shop.province;

    // Categories
    _selectedCategories = List.from(shop.categories);

    // Sub-services
    _selectedSubServices = Map.from(shop.subServices.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    ));

    // Payment methods
    _selectedPaymentMethods = List.from(shop.paymentMethods ?? []);

    // Other options
    _requiresPurchase = shop.requiresPurchase;
    _tryOnAreaAvailable = shop.tryOnAreaAvailable ?? false;
    _priceRange = shop.priceRange;

    // Hours
    _initializeHours();

    // Photos
    _existingPhotos = List.from(shop.photos);

    // Store initial values
    _initialName = _nameController.text;
    _initialDescription = _descriptionController.text;
    _initialAddress = _addressController.text;
    _initialArea = _areaController.text;
    _initialLatitude = _latitudeController.text;
    _initialLongitude = _longitudeController.text;
    _initialPhone = _phoneController.text;
    _initialBuildingNumber = _buildingNumberController.text;
    _initialBuildingName = _buildingNameController.text;
    _initialSoi = _soiController.text;
    _initialDistrict = _districtController.text;
    _initialLandmark = _landmarkController.text;
    _initialLineId = _lineIdController.text;
    _initialFacebookPage = _facebookPageController.text;
    _initialOtherContacts = _otherContactsController.text;
    _initialNotesOrConditions = _notesOrConditionsController.text;
    _initialInstagramPage = _instagramPageController.text;
    _initialBuildingFloor = _buildingFloorController.text;
    _initialCategories = List.from(_selectedCategories);
    _initialPaymentMethods = List.from(_selectedPaymentMethods);
    _initialRequiresPurchase = _requiresPurchase;
    _initialTryOnAreaAvailable = _tryOnAreaAvailable;
    _initialPriceRange = _priceRange;
    _initialExistingPhotos = List.from(_existingPhotos);
  }

  void _initializeHours() {
    final shop = widget.shop;
    const dayToShortKey = {
      'Monday': 'mon',
      'Tuesday': 'tue',
      'Wednesday': 'wed',
      'Thursday': 'thu',
      'Friday': 'fri',
      'Saturday': 'sat',
      'Sunday': 'sun',
    };

    for (final entry in dayToShortKey.entries) {
      final day = entry.key;
      final shortKey = entry.value;
      // Support both short keys (mon) and legacy full keys (monday/Monday)
      final hours = shop.hours[shortKey]
          ?? shop.hours[day.toLowerCase()]
          ?? shop.hours[day]
          ?? 'Closed';
      if (hours != 'Closed') {
        final parts = hours.split(' - ');
        if (parts.length == 2) {
          _openingTimeControllers[day]?.text = parts[0].trim();
          _closingTimeControllers[day]?.text = parts[1].trim();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _buildingNumberController.dispose();
    _buildingNameController.dispose();
    _soiController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _lineIdController.dispose();
    _facebookPageController.dispose();
    _otherContactsController.dispose();
    _notesOrConditionsController.dispose();
    _usualOpeningTimeController.dispose();
    _usualClosingTimeController.dispose();
    _instagramPageController.dispose();
    _buildingFloorController.dispose();

    for (final controller in _hoursControllers.values) {
      controller.dispose();
    }
    for (final controller in _openingTimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _closingTimeControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_savedSuccessfully) return false;
    return _nameController.text != _initialName ||
        _descriptionController.text != _initialDescription ||
        _addressController.text != _initialAddress ||
        _areaController.text != _initialArea ||
        _latitudeController.text != _initialLatitude ||
        _longitudeController.text != _initialLongitude ||
        _phoneController.text != _initialPhone ||
        _buildingNumberController.text != _initialBuildingNumber ||
        _buildingNameController.text != _initialBuildingName ||
        _soiController.text != _initialSoi ||
        _districtController.text != _initialDistrict ||
        _landmarkController.text != _initialLandmark ||
        _lineIdController.text != _initialLineId ||
        _facebookPageController.text != _initialFacebookPage ||
        _otherContactsController.text != _initialOtherContacts ||
        _notesOrConditionsController.text != _initialNotesOrConditions ||
        _instagramPageController.text != _initialInstagramPage ||
        _buildingFloorController.text != _initialBuildingFloor ||
        !_listEquals(_selectedCategories, _initialCategories) ||
        !_listEquals(_selectedPaymentMethods, _initialPaymentMethods) ||
        _requiresPurchase != _initialRequiresPurchase ||
        _tryOnAreaAvailable != _initialTryOnAreaAvailable ||
        _priceRange != _initialPriceRange ||
        !_listEquals(_existingPhotos, _initialExistingPhotos) ||
        _selectedImageBytes != null;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  Future<void> _handleBackButton() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'admin_edit_shop'.tr(context),
          style: AppTextStyles.heading.copyWith(color: AppColors.text),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _handleBackButton,
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveShop,
              child: Text(
                'save'.tr(context),
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: ResponsiveSize.getScaledPadding(
                        const EdgeInsets.all(16.0),
                      ),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBasicInformationSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildLocationSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildContactSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildCategoriesSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildHoursSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildPaymentSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildPhotosSection(),
                              SizedBox(height: ResponsiveSize.getHeight(2)),
                              _buildOptionsSection(),
                              SizedBox(height: ResponsiveSize.getHeight(4)),
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    ),
    );
  }

  Widget _buildBasicInformationSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'basic_information'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          _buildTextField(
            controller: _nameController,
            label: 'shop_name_field'.tr(context),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'please_enter_shop_name'.tr(context);
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _descriptionController,
            label: 'description_field'.tr(context),
            maxLines: 3,
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _addressController,
            label: 'address_field'.tr(context),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'please_enter_address'.tr(context);
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _areaController,
            label: 'area_field'.tr(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'location_section'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latitudeController,
                  decoration: InputDecoration(
                    labelText: 'latitude_label_short'.tr(context),
                    hintText: '13.7563',
                    prefixIcon: Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'coord_helper_lat_full'.tr(context),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(2)),
              Expanded(
                child: TextField(
                  controller: _longitudeController,
                  decoration: InputDecoration(
                    labelText: 'longitude_label_short'.tr(context),
                    hintText: '100.5018',
                    prefixIcon: Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'coord_helper_lng_full'.tr(context),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map),
              label: Text('pick_location_on_map'.tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'contact_information'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          _buildTextField(
            controller: _phoneController,
            label: 'phone_field'.tr(context),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(controller: _lineIdController, label: 'line_field'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _facebookPageController,
            label: 'facebook_field'.tr(context),
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _instagramPageController,
            label: 'instagram_field'.tr(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'service_categories_title'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                    selectedColor: AppConstants.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'opening_hours'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          ...[
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ].map((day) => _buildDayHours(day)).toList(),
        ],
      ),
    );
  }

  String _localizedDay(String day) {
    switch (day) {
      case 'Monday': return 'monday'.tr(context);
      case 'Tuesday': return 'tuesday'.tr(context);
      case 'Wednesday': return 'wednesday'.tr(context);
      case 'Thursday': return 'thursday'.tr(context);
      case 'Friday': return 'friday'.tr(context);
      case 'Saturday': return 'saturday'.tr(context);
      case 'Sunday': return 'sunday'.tr(context);
      default: return day;
    }
  }

  Widget _buildDayHours(String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _localizedDay(day),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _openingTimeControllers[day] ?? TextEditingController(),
                    label: 'open_label'.tr(context),
                    hintText: '09:00',
                  ),
                ),
                const SizedBox(width: 8),
                const Text('-'),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _closingTimeControllers[day] ?? TextEditingController(),
                    label: 'close_label'.tr(context),
                    hintText: '18:00',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'payment_methods'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          ..._availablePaymentMethods.map((method) => CheckboxListTile(
            title: Text(method.tr(context)),
            value: _selectedPaymentMethods.contains(method),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedPaymentMethods.add(method);
                } else {
                  _selectedPaymentMethods.remove(method);
                }
              });
            },
          )),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'photos'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          if (_existingPhotos.isNotEmpty) ...[
            Text('existing_photos'.tr(context)),
            SizedBox(height: ResponsiveSize.getHeight(1)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _existingPhotos.map((photo) {
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(photo),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _existingPhotos.remove(photo);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
            SizedBox(height: ResponsiveSize.getHeight(2)),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: Text('add_photo'.tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'options'.tr(context)),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          CheckboxListTile(
            title: Text('requires_purchase'.tr(context)),
            value: _requiresPurchase,
            onChanged: (value) {
              setState(() {
                _requiresPurchase = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text('try_on_area_checkbox'.tr(context)),
            value: _tryOnAreaAvailable,
            onChanged: (value) {
              setState(() {
                _tryOnAreaAvailable = value ?? false;
              });
            },
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          DropdownButtonFormField<String>(
            value: _priceRange,
            decoration: InputDecoration(
              labelText: 'price_range_label'.tr(context),
              border: OutlineInputBorder(),
            ),
            items:
                ['฿', '฿฿', '฿฿฿'].map((range) {
                  return DropdownMenuItem(value: range, child: Text(range));
                }).toList(),
            onChanged: (value) {
              setState(() {
                _priceRange = value ?? '฿';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveShop,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child:
            _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: ResponsiveSize.getScaledPadding(const EdgeInsets.all(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (!mounted) return;
    if (result != null && result is LatLng) {
      setState(() {
        _latitudeController.text = result.latitude.toString();
        _longitudeController.text = result.longitude.toString();
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          // Processing image
        });

        Uint8List? compressedImage;
        if (kIsWeb) {
          compressedImage = await image.readAsBytes();
        } else {
          compressedImage = await FlutterImageCompress.compressWithList(
            await image.readAsBytes(),
            quality: 80,
          );
        }

        if (!mounted) return;
        setState(() {
          _selectedImageBytes = compressedImage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      appLog('Error picking image: $e');
    }
  }

  Future<void> _saveShop() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload new image if selected
      String? newImageUrl;
      if (_selectedImageBytes != null) {
        newImageUrl = await _uploadImage(_selectedImageBytes!);
      }

      // Prepare hours — use short keys ('mon','tue',...) consistently
      Map<String, String> hours = {};
      const dayToShortKey = {
        'Monday': 'mon',
        'Tuesday': 'tue',
        'Wednesday': 'wed',
        'Thursday': 'thu',
        'Friday': 'fri',
        'Saturday': 'sat',
        'Sunday': 'sun',
      };
      for (final entry in dayToShortKey.entries) {
        final dayName = entry.key;
        final key = entry.value;
        final openingTime = _openingTimeControllers[dayName]?.text.trim() ?? '';
        final closingTime = _closingTimeControllers[dayName]?.text.trim() ?? '';

        if (openingTime.isNotEmpty && closingTime.isNotEmpty) {
          hours[key] = '$openingTime - $closingTime';
        } else {
          hours[key] = 'Closed';
        }
      }

      // Prepare photos
      List<String> photos = List.from(_existingPhotos);
      if (newImageUrl != null) {
        photos.add(newImageUrl);
      }

      // Update shop data
      final updatedShop = RepairShop(
        id: widget.shop.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        area: _areaController.text.trim(),
        categories: _selectedCategories,
        rating: widget.shop.rating,
        amenities: widget.shop.amenities,
        hours: hours,
        closingDays: widget.shop.closingDays,
        latitude: double.tryParse(_latitudeController.text) ?? 0.0,
        longitude: double.tryParse(_longitudeController.text) ?? 0.0,
        durationMinutes: widget.shop.durationMinutes,
        requiresPurchase: _requiresPurchase,
        photos: photos,
        priceRange: _priceRange,
        features: widget.shop.features,
        approved: widget.shop.approved,
        irregularHours: widget.shop.irregularHours,
        subServices: _selectedSubServices,
        buildingNumber: _buildingNumberController.text.trim(),
        buildingName: _buildingNameController.text.trim(),
        soi: _soiController.text.trim(),
        district: _districtController.text.trim(),
        province: _selectedProvince,
        landmark: _landmarkController.text.trim(),
        lineId: _lineIdController.text.trim(),
        facebookPage: _facebookPageController.text.trim(),
        otherContacts: _otherContactsController.text.trim(),
        paymentMethods: _selectedPaymentMethods.isNotEmpty ? _selectedPaymentMethods : null,
        tryOnAreaAvailable: _tryOnAreaAvailable,
        notesOrConditions: _notesOrConditionsController.text.trim(),
        usualOpeningTime: _usualOpeningTimeController.text.trim(),
        instagramPage: _instagramPageController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        buildingFloor: _buildingFloorController.text.trim(),
      );

      // Save to Firestore
      final shopService = ShopService();
      final success = await shopService.updateShop(updatedShop);
      if (!success) throw Exception('Failed to update shop');

      if (mounted) {
        _savedSuccessfully = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('shop_updated_success'.tr(context)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      appLog('Error updating shop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_updating_shop_msg'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String> _uploadImage(Uint8List imageBytes) async {
    final fileName =
        'shop_${widget.shop.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('shop_photos/$fileName');

    final uploadTask = ref.putData(imageBytes);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
