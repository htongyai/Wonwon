import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:wonwonw2/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/section_title.dart';
import 'package:wonwonw2/utils/responsive_size.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({Key? key}) : super(key: key);

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
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

  // Image variables
  Uint8List? _selectedImageBytes;
  String? _imageError;
  bool _isProcessingImage = false;

  List<String> _selectedCategories = [];
  final List<String> _availableCategories = [
    'clothing',
    'footwear',
    'watch',
    'bag',
    'electronics',
    'appliance',
  ];

  // Map to store selected sub-services for each category
  final Map<String, List<String>> _selectedSubServices = {};

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

  // Store actual TimeOfDay objects for time pickers
  final Map<String, TimeOfDay?> _openingTimes = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  final Map<String, TimeOfDay?> _closingTimes = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  // Track which days are closed
  final Map<String, bool> _closedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  // Flag for irregular hours
  bool _hasIrregularHours = false;

  // New flag for "Same time every day"
  bool _sameTimeEveryDay = false;

  bool _isSubmitting = false;

  List<String> _selectedPaymentMethods = [];
  bool _tryOnAreaAvailable = false;

  final List<String> _provinces = [
    'Bangkok',
    'Amnat Charoen',
    'Ang Thong',
    'Bueng Kan',
    'Buri Ram',
    'Chachoengsao',
    'Chai Nat',
    'Chaiyaphum',
    'Chanthaburi',
    'Chiang Mai',
    'Chiang Rai',
    'Chonburi',
    'Chumphon',
    'Kalasin',
    'Kamphaeng Phet',
    'Kanchanaburi',
    'Khon Kaen',
    'Krabi',
    'Lampang',
    'Lamphun',
    'Loei',
    'Lopburi',
    'Mae Hong Son',
    'Maha Sarakham',
    'Mukdahan',
    'Nakhon Nayok',
    'Nakhon Pathom',
    'Nakhon Phanom',
    'Nakhon Ratchasima',
    'Nakhon Sawan',
    'Nakhon Si Thammarat',
    'Nan',
    'Narathiwat',
    'Nong Bua Lamphu',
    'Nong Khai',
    'Nonthaburi',
    'Pathum Thani',
    'Pattani',
    'Phang Nga',
    'Phatthalung',
    'Phayao',
    'Phetchabun',
    'Phetchaburi',
    'Phichit',
    'Phitsanulok',
    'Phra Nakhon Si Ayutthaya',
    'Phrae',
    'Phuket',
    'Prachinburi',
    'Prachuap Khiri Khan',
    'Ranong',
    'Ratchaburi',
    'Rayong',
    'Roi Et',
    'Sa Kaeo',
    'Sakon Nakhon',
    'Samut Prakan',
    'Samut Sakhon',
    'Samut Songkhram',
    'Saraburi',
    'Satun',
    'Sing Buri',
    'Sisaket',
    'Songkhla',
    'Sukhothai',
    'Suphan Buri',
    'Surat Thani',
    'Surin',
    'Tak',
    'Trang',
    'Trat',
    'Ubon Ratchathani',
    'Udon Thani',
    'Uthai Thani',
    'Uttaradit',
    'Yala',
    'Yasothon',
  ];
  String? _selectedProvince;

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

    _hoursControllers.forEach((_, controller) => controller.dispose());
    _openingTimeControllers.forEach((_, controller) => controller.dispose());
    _closingTimeControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'add_shop'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveSize.getScaledPadding(
              const EdgeInsets.all(16.0),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning message
                  Container(
                    padding: ResponsiveSize.getScaledPadding(
                      const EdgeInsets.all(12),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[800]),
                        SizedBox(width: ResponsiveSize.getWidth(3)),
                        Expanded(
                          child: Text(
                            'shop_review_notice'.tr(context),
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(6)),

                  // Introduction
                  Text(
                    'add_shop_directory'.tr(context),
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(6)),

                  // Basic Information Section
                  SectionTitle(text: 'basic_info_label'.tr(context)),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Shop Name
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'shop_name_label'.tr(context),
                    hint: 'shop_name_hint'.tr(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'name_required'.tr(context);
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Description
                  _buildTextFormField(
                    controller: _descriptionController,
                    label: 'shop_description_label'.tr(context),
                    hint: 'enter_description_hint'.tr(context),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Shop Photo Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'shop_photo_label'.tr(context),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(2)),
                      GestureDetector(
                        onTap: _isProcessingImage ? null : _pickAndCropImage,
                        child: Container(
                          width: double.infinity,
                          height: 180, // 6x4 aspect ratio (approximately)
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: _buildImageDisplay(),
                        ),
                      ),
                      if (_imageError != null)
                        Padding(
                          padding: EdgeInsets.only(
                            top: ResponsiveSize.getHeight(2),
                          ),
                          child: Text(
                            _imageError!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(6)),

                  // Categories
                  _buildCategoriesSelector(),
                  SizedBox(height: ResponsiveSize.getHeight(6)),

                  // Location Section
                  SectionTitle(text: 'location_info_label'.tr(context)),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Map Location Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'location_label'.tr(context),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(2)),
                      Row(
                        children: [
                          // Left side: Editable coordinates
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _latitudeController,
                                        decoration: InputDecoration(
                                          labelText: 'Latitude',
                                          hintText: '13.7563',
                                          prefixIcon: Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: AppConstants.primaryColor,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          helperText: 'e.g., 13.7563',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
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
                                          labelText: 'Longitude',
                                          hintText: '100.5018',
                                          prefixIcon: Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: AppConstants.primaryColor,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          helperText: 'e.g., 100.5018',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: true,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveSize.getHeight(1)),
                                Text(
                                  'You can paste coordinates directly or use the map picker below',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: ResponsiveSize.getWidth(3)),
                          // Right side: Select button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _openMapPicker(context),
                              icon: const Icon(Icons.map),
                              label: Text(
                                _latitudeController.text.isEmpty
                                    ? 'select_button'.tr(context)
                                    : 'change_button'.tr(context),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: ResponsiveSize.getScaledPadding(
                                  const EdgeInsets.symmetric(vertical: 16),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(6)),

                  // Additional Location Details
                  _buildTextFormField(
                    controller: _buildingNumberController,
                    label: 'building_number_and_name_label'.tr(context),
                    hint: 'enter_building_number_and_name_hint'.tr(context),
                  ),
                  //    SizedBox(height: ResponsiveSize.getHeight(4)), Building Floor
                  _buildTextFormField(
                    controller: _buildingFloorController,
                    label: 'building_floor_label'.tr(context),
                    hint: 'enter_building_floor_hint'.tr(context),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  _buildTextFormField(
                    controller: _soiController,
                    label: 'soi_label'.tr(context),
                    hint: 'enter_soi_hint'.tr(context),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  _buildTextFormField(
                    controller: _districtController,
                    label: 'district_label'.tr(context),
                    hint: 'enter_district_hint'.tr(context),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    items:
                        _provinces
                            .map(
                              (province) => DropdownMenuItem(
                                value: province,
                                child: Text(province),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'province_label'.tr(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: ResponsiveSize.getScaledPadding(
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'please_select_province'.tr(context)
                                : null,
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  _buildTextFormField(
                    controller: _landmarkController,
                    label: 'landmark_label'.tr(context),
                    hint: 'enter_landmark_hint'.tr(context),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  // Notes or Service Conditions
                  _buildTextFormField(
                    controller: _notesOrConditionsController,
                    label: 'notes_or_conditions_label'.tr(context),
                    hint: 'enter_notes_or_conditions_hint'.tr(context),
                    maxLines: 2,
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  // Contact Channels
                  SectionTitle(text: 'contact_information'.tr(context)),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Line ID (Optional)
                  _buildTextFormField(
                    controller: _lineIdController,
                    label: '${'line_id_label'.tr(context)} (Optional)',
                    hint: 'enter_line_id_hint'.tr(context),
                    prefixIcon: Icon(
                      FontAwesomeIcons.line,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Facebook Page (Optional)
                  _buildTextFormField(
                    controller: _facebookPageController,
                    label: 'facebook_optional_label'.tr(context),
                    hint: 'enter_facebook_url'.tr(context),
                    prefixIcon: Icon(
                      FontAwesomeIcons.facebook,
                      color: Colors.blue,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Instagram Page (Optional)
                  _buildTextFormField(
                    controller: _instagramPageController,
                    label: '${'instagram_label'.tr(context)} (Optional)',
                    hint: 'enter_instagram_url'.tr(context),
                    prefixIcon: Icon(
                      FontAwesomeIcons.instagram,
                      color: Colors.purple,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Other Contacts
                  _buildTextFormField(
                    controller: _otherContactsController,
                    label: '${'other_contacts_label'.tr(context)} (Optional)',
                    hint: 'enter_other_contacts_hint'.tr(context),
                    maxLines: 2,
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(6)),

                  // Payment Methods (multi-select)
                  Text(
                    'select_payment_method'.tr(context),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                              'payment_cash'.tr(context),
                              'payment_card'.tr(context),
                              'payment_qr'.tr(context),
                              'payment_bank_transfer'.tr(context),
                            ]
                            .map(
                              (method) => FilterChip(
                                label: Text(method),
                                selected: _selectedPaymentMethods.contains(
                                  method,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedPaymentMethods.add(method);
                                    } else {
                                      _selectedPaymentMethods.remove(method);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(4)),
                  // Trial Area Available (yes/no)
                  Row(
                    children: [
                      Checkbox(
                        value: _tryOnAreaAvailable,
                        onChanged: (val) {
                          setState(() {
                            _tryOnAreaAvailable = val ?? false;
                          });
                        },
                      ),
                      Text('trial_area_available'.tr(context)),
                    ],
                  ),

                  // Contact Section
                  SizedBox(height: ResponsiveSize.getHeight(4)),

                  // Hours Section
                  SectionTitle(text: 'opening_hours_label'.tr(context)),
                  SizedBox(height: ResponsiveSize.getHeight(2)),

                  // Same time every day checkbox
                  Container(
                    padding: ResponsiveSize.getScaledPadding(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    margin: EdgeInsets.only(
                      bottom: ResponsiveSize.getHeight(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _sameTimeEveryDay,
                          activeColor: AppConstants.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _sameTimeEveryDay = value ?? false;

                              if (_sameTimeEveryDay) {
                                // Get Monday's times
                                final mondayOpeningTime =
                                    _openingTimes['Monday'];
                                final mondayClosingTime =
                                    _closingTimes['Monday'];

                                if (mondayOpeningTime != null &&
                                    mondayClosingTime != null) {
                                  // Apply to all other days that aren't closed
                                  for (final day in _openingTimes.keys) {
                                    if (day != 'Monday' &&
                                        !(_closedDays[day] ?? false)) {
                                      _openingTimes[day] = mondayOpeningTime;
                                      _closingTimes[day] = mondayClosingTime;
                                      _openingTimeControllers[day]!.text =
                                          _openingTimeControllers['Monday']!
                                              .text;
                                      _closingTimeControllers[day]!.text =
                                          _closingTimeControllers['Monday']!
                                              .text;
                                    }
                                  }
                                } else {
                                  // Show a message that Monday's times need to be set first
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please set Monday's opening and closing times first",
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  _sameTimeEveryDay = false;
                                }
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'same_time_every_day'.tr(context),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'use_monday_hours'.tr(context),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Opening Hours
                  _buildOpeningHoursFields(),
                  const SizedBox(height: 16),

                  // Irregular hours checkbox
                  Container(
                    padding: ResponsiveSize.getScaledPadding(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasIrregularHours,
                          activeColor: AppConstants.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _hasIrregularHours = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'irregular_hours_label'.tr(context),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'irregular_hours_hint'.tr(context),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'submit_shop_button'.tr(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIcon: prefixIcon,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoriesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category);
                        _selectedSubServices.remove(category);
                      } else {
                        _selectedCategories.add(category);
                        _selectedSubServices[category] = [];
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppConstants.primaryColor
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppConstants.primaryColor
                                : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getCategoryDisplayName(category),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (_selectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'please_select_at_least_one_category'.tr(context),
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        // Display sub-services for selected categories
        ..._selectedCategories.map((category) {
          final subServices = RepairSubService.getSubServices()[category] ?? [];
          if (subServices.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getCategoryDisplayName(category)} Services',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'select_specific_services_hint'.tr(context),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      subServices.map((subService) {
                        final isSelected =
                            _selectedSubServices[category]?.contains(
                              subService.id,
                            ) ??
                            false;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSubServices[category]?.remove(
                                  subService.id,
                                );
                              } else {
                                _selectedSubServices[category]?.add(
                                  subService.id,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: ResponsiveSize.getScaledPadding(
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppConstants.primaryColor
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppConstants.primaryColor
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  subService.getLocalizedName(context),
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[800],
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'clothing':
        return Icons.checkroom;
      case 'footwear':
        return Icons.shopping_bag;
      case 'watch':
        return Icons.watch;
      case 'bag':
        return Icons.backpack;
      case 'appliance':
        return Icons.blender;
      case 'electronics':
        return Icons.devices;
      default:
        return Icons.category;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'clothing':
        return 'category_clothing'.tr(context);
      case 'footwear':
        return 'category_footwear'.tr(context);
      case 'watch':
        return 'category_watch'.tr(context);
      case 'bag':
        return 'category_bag'.tr(context);
      case 'appliance':
        return 'category_appliance'.tr(context);
      case 'electronics':
        return 'category_electronics'.tr(context);
      default:
        return category.tr(context);
    }
  }

  Widget _buildOpeningHoursFields() {
    return Column(
      children:
          _openingTimeControllers.entries.map((entry) {
            final day = entry.key;
            final openingController = entry.value;
            final closingController = _closingTimeControllers[day]!;
            final isClosed = _closedDays[day] ?? false;
            final isSyncedWithMonday =
                _sameTimeEveryDay &&
                day != 'Monday' &&
                !isClosed &&
                _openingTimeControllers[day]!.text ==
                    _openingTimeControllers['Monday']!.text &&
                _closingTimeControllers[day]!.text ==
                    _closingTimeControllers['Monday']!.text;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day and closed checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          _getDayDisplayName(day),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isClosed,
                        activeColor: AppConstants.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _closedDays[day] = value ?? false;
                            // Clear time fields if closed
                            if (value == true) {
                              openingController.clear();
                              closingController.clear();
                              _openingTimes[day] = null;
                              _closingTimes[day] = null;
                            } else if (_sameTimeEveryDay && day != 'Monday') {
                              // If not closed and "Same time every day" is checked, use Monday's times
                              final mondayOpeningTime = _openingTimes['Monday'];
                              final mondayClosingTime = _closingTimes['Monday'];

                              if (mondayOpeningTime != null &&
                                  mondayClosingTime != null) {
                                _openingTimes[day] = mondayOpeningTime;
                                _closingTimes[day] = mondayClosingTime;
                                _openingTimeControllers[day]!.text =
                                    _openingTimeControllers['Monday']!.text;
                                _closingTimeControllers[day]!.text =
                                    _closingTimeControllers['Monday']!.text;
                              }
                            }
                          });
                        },
                      ),
                      Text(
                        'closed_label'.tr(context),
                        style: TextStyle(
                          color: isClosed ? Colors.red[700] : Colors.grey[800],
                          fontWeight:
                              isClosed ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (isSyncedWithMonday && !isClosed)
                        Padding(
                          padding: EdgeInsets.only(
                            left: ResponsiveSize.getWidth(2),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 14,
                                color: AppConstants.primaryColor,
                              ),
                              SizedBox(width: ResponsiveSize.getWidth(1)),
                              Text(
                                'synced_with_monday'.tr(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Time input fields
                  if (!isClosed)
                    Padding(
                      padding: const EdgeInsets.only(left: 90, top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Opening time field
                          Flexible(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'opening_time_label'.tr(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectTime(context, day, true),
                                  child: Container(
                                    padding: ResponsiveSize.getScaledPadding(
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSyncedWithMonday
                                              ? AppConstants.primaryColor
                                                  .withOpacity(0.05)
                                              : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSyncedWithMonday
                                                ? AppConstants.primaryColor
                                                    .withOpacity(0.3)
                                                : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          openingController.text.isNotEmpty
                                              ? openingController.text
                                              : 'select_time'.tr(context),
                                          style: TextStyle(
                                            color:
                                                openingController.text.isEmpty
                                                    ? Colors.grey[400]
                                                    : Colors.black87,
                                          ),
                                        ),
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Closing time field
                          Flexible(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'closing_time_label'.tr(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectTime(context, day, false),
                                  child: Container(
                                    padding: ResponsiveSize.getScaledPadding(
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSyncedWithMonday
                                              ? AppConstants.primaryColor
                                                  .withOpacity(0.05)
                                              : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSyncedWithMonday
                                                ? AppConstants.primaryColor
                                                    .withOpacity(0.3)
                                                : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          closingController.text.isNotEmpty
                                              ? closingController.text
                                              : 'select_time'.tr(context),
                                          style: TextStyle(
                                            color:
                                                closingController.text.isEmpty
                                                    ? Colors.grey[400]
                                                    : Colors.black87,
                                          ),
                                        ),
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (day != 'Sunday')
                    const Divider(height: 24, thickness: 0.5),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _getDayDisplayName(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'monday'.tr(context);
      case 'tuesday':
        return 'tuesday'.tr(context);
      case 'wednesday':
        return 'wednesday'.tr(context);
      case 'thursday':
        return 'thursday'.tr(context);
      case 'friday':
        return 'friday'.tr(context);
      case 'saturday':
        return 'saturday'.tr(context);
      case 'sunday':
        return 'sunday'.tr(context);
      default:
        return day;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        setState(() {});
        return;
      }

      if (_isProcessingImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_wait_image_processing'.tr(context)),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Create a map of opening hours
      final Map<String, String> hours = {};
      final List<String> closingDays = [];

      _openingTimeControllers.forEach((day, openingController) {
        final closingController = _closingTimeControllers[day]!;
        final isClosed = _closedDays[day] ?? false;

        if (isClosed) {
          hours[day] = 'Closed';
          closingDays.add(day);
        } else if (openingController.text.isNotEmpty &&
            closingController.text.isNotEmpty) {
          hours[day] = '${openingController.text} - ${closingController.text}';
        }
      });

      // Generate a unique ID for the shop
      final shopId = const Uuid().v4();

      // Upload image if selected
      List<String> photoUrls = [];
      if (_selectedImageBytes != null) {
        final imageUrl = await _uploadImageToFirebase(
          _selectedImageBytes!,
          shopId,
        );
        if (imageUrl != null) {
          photoUrls.add(imageUrl);
        }
      }

      // Construct the full address
      final fullAddress = [
        _buildingNumberController.text,
        _soiController.text,
        _districtController.text,
        _selectedProvince,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      // Create a new shop object
      final newShop = RepairShop(
        id: shopId,
        name: _nameController.text,
        description: _descriptionController.text,
        address: fullAddress,
        area: _areaController.text,
        categories: _selectedCategories,
        rating: 0.0,
        hours: hours,
        closingDays: closingDays,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        irregularHours: _hasIrregularHours,
        approved: false,
        photos: photoUrls,
        subServices: _selectedSubServices,
        timestamp: DateTime.now(),
        buildingName: _buildingNameController.text,
        buildingNumber: _buildingNumberController.text,
        buildingFloor: _buildingFloorController.text,
        soi: _soiController.text,
        district: _districtController.text,
        province: _selectedProvince,
        landmark: _landmarkController.text,
        lineId: _lineIdController.text,
        facebookPage: _facebookPageController.text,
        otherContacts: _otherContactsController.text,
        paymentMethods: _selectedPaymentMethods,
        tryOnAreaAvailable: _tryOnAreaAvailable,
        notesOrConditions: _notesOrConditionsController.text,
        instagramPage: _instagramPageController.text,
      );

      // Submit the shop
      _submitShop(newShop);
    }
  }

  Future<void> _submitShop(RepairShop shop) async {
    try {
      // Use the shop service to add the shop
      final shopService = ShopService();
      final success = await shopService.addShop(shop);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          // Show success dialog
          _showSuccessDialog();
        } else {
          // Show error dialog
          _showErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'shop_submitted_label'.tr(context),
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text('shop_submitted_message_label'.tr(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: Text('ok_label'.tr(context)),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'error'.tr(context),
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text('shop_submit_error_message'.tr(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text('ok_label'.tr(context)),
              ),
            ],
          ),
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    // Get initial coordinates if available
    double? initialLat;
    double? initialLng;

    if (_latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty) {
      initialLat = double.tryParse(_latitudeController.text);
      initialLng = double.tryParse(_longitudeController.text);
    }

    // Navigate to the map picker screen
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              initialLatitude: initialLat,
              initialLongitude: initialLng,
            ),
      ),
    );

    // Update coordinates if a location was selected
    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toStringAsFixed(6);
        _longitudeController.text = result.longitude.toStringAsFixed(6);
      });
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isOpening,
  ) async {
    TimeOfDay? selectedTime =
        isOpening
            ? (_openingTimes[day] ?? TimeOfDay(hour: 9, minute: 0))
            : (_closingTimes[day] ?? TimeOfDay(hour: 18, minute: 0));

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isOpening) {
          _openingTimes[day] = result;
          _openingTimeControllers[day]!.text = result.format(context);

          // If this is Monday and "Same time every day" is checked, update all other days too
          if (day == 'Monday' && _sameTimeEveryDay) {
            for (final otherDay in _openingTimes.keys) {
              if (otherDay != 'Monday' && !(_closedDays[otherDay] ?? false)) {
                _openingTimes[otherDay] = result;
                _openingTimeControllers[otherDay]!.text = result.format(
                  context,
                );
              }
            }
          }
        } else {
          _closingTimes[day] = result;
          _closingTimeControllers[day]!.text = result.format(context);

          // If this is Monday and "Same time every day" is checked, update all other days too
          if (day == 'Monday' && _sameTimeEveryDay) {
            for (final otherDay in _closingTimes.keys) {
              if (otherDay != 'Monday' && !(_closedDays[otherDay] ?? false)) {
                _closingTimes[otherDay] = result;
                _closingTimeControllers[otherDay]!.text = result.format(
                  context,
                );
              }
            }
          }
        }
      });
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      setState(() {
        _isProcessingImage = true;
        _imageError = null;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        setState(() {
          _isProcessingImage = false;
        });
        return;
      }

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      if (kIsWeb) {
        // For web, we'll use the bytes directly since cropping might not work well
        await _compressAndSetImage(imageBytes);
        return;
      }

      // For mobile platforms, proceed with cropping
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.brown,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            minimumAspectRatio: 1.0,
            resetAspectRatioEnabled: false,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );

      if (croppedFile == null) {
        setState(() {
          _isProcessingImage = false;
        });
        return;
      }

      // Read the cropped image bytes
      final croppedBytes = await croppedFile.readAsBytes();

      // Compress the cropped image
      await _compressAndSetImage(croppedBytes);
    } catch (e) {
      setState(() {
        _imageError = 'Error processing image: ${e.toString()}';
        _selectedImageBytes = null;
      });
      appLog('Image processing error', e);
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _compressAndSetImage(Uint8List imageBytes) async {
    try {
      // First compression attempt
      Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 1024,
        minWidth: 1024,
        quality: 85,
      );

      // If still larger than 100KB, compress further
      if (compressedBytes.length > 100 * 1024) {
        compressedBytes = await FlutterImageCompress.compressWithList(
          compressedBytes,
          minHeight: 800,
          minWidth: 800,
          quality: 70,
        );
      }

      // If still larger than 100KB, compress one more time
      if (compressedBytes.length > 100 * 1024) {
        compressedBytes = await FlutterImageCompress.compressWithList(
          compressedBytes,
          minHeight: 600,
          minWidth: 600,
          quality: 60,
        );
      }

      // Final check - if still too large, show error
      if (compressedBytes.length > 100 * 1024) {
        setState(() {
          _imageError = 'Image is too large. Please choose a smaller image.';
          _selectedImageBytes = null;
        });
        return;
      }

      setState(() {
        _selectedImageBytes = compressedBytes;
        _imageError = null;
      });
    } catch (e) {
      setState(() {
        _imageError = 'Failed to process image. Please try again.';
        _selectedImageBytes = null;
      });
      appLog('Error compressing image: $e');
    }
  }

  Future<String?> _uploadImageToFirebase(
    Uint8List imageBytes,
    String shopId,
  ) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      // Generate a unique filename using timestamp and UUID
      final String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      final shopImageRef = storageRef.child('shops/$shopId/$uniqueFileName');

      // Upload the bytes
      await shopImageRef.putData(imageBytes);

      // Get the download URL
      final downloadUrl = await shopImageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      appLog('Error uploading image to Firebase', e);
      return null;
    }
  }

  Widget _buildImageDisplay() {
    if (_isProcessingImage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppConstants.primaryColor),
            const SizedBox(height: 12),
            Text(
              'Processing image...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_selectedImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImageBytes = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          'upload_shop_photo_label'.tr(context),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'shop_photo_format_hint'.tr(context),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
