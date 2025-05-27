import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:wonwonw2/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:async';

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

  // Image variables
  File? _selectedImage;
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
    'jewelry',
  ];

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();

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
          'Add New Shop',
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction
                  Text(
                    'Add a new repair shop to our directory',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Basic Information Section
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),

                  // Shop Name
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'Shop Name',
                    hint: 'Enter the shop name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the shop name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildTextFormField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter a description of the shop services',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Shop Photo Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          child:
                              _isProcessingImage
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: AppConstants.primaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Processing image...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : (_selectedImage != null
                                      ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImage = null;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Upload Shop Photo',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '6x4 landscape format recommended',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      )),
                        ),
                      ),
                      if (_imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
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
                  const SizedBox(height: 24),

                  // Categories
                  _buildCategoriesSelector(),
                  const SizedBox(height: 24),

                  // Location Section
                  _buildSectionTitle('Location Information'),
                  const SizedBox(height: 16),

                  // Address
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter the full address',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Area
                  _buildTextFormField(
                    controller: _areaController,
                    label: 'Area/District',
                    hint: 'Enter the area or district',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the area';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Map Location Picker (replaces latitude/longitude fields)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Left side: Coordinates display
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child:
                                  _latitudeController.text.isNotEmpty &&
                                          _longitudeController.text.isNotEmpty
                                      ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color:
                                                    AppConstants.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Coordinates:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lat: ${_latitudeController.text}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            'Lng: ${_longitudeController.text}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      )
                                      : Center(
                                        child: Text(
                                          'No location selected',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right side: Select button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _openMapPicker(context),
                              icon: const Icon(Icons.map),
                              label: Text(
                                _latitudeController.text.isEmpty
                                    ? 'Select'
                                    : 'Change',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
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
                  const SizedBox(height: 24),

                  // Contact Section
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 16),

                  // Phone
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter the contact phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // Hours Section
                  _buildSectionTitle('Opening Hours'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16),
                    child: Text(
                      'Specify shop hours for each day or mark days as closed.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),

                  // Same time every day checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
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
                                    const SnackBar(
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
                                'Same Time Every Day',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Use Monday's hours for all days except those marked as closed",
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                                'Irregular Opening Hours',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check this if the shop\'s hours may vary. A notice will be displayed to remind customers to call before visiting.',
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
                                'Submit Shop',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppConstants.darkColor,
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
          'Categories',
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
                      } else {
                        _selectedCategories.add(category);
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
              'Please select at least one category',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _getCategoryDisplayName(String category) {
    // Capitalize first letter
    return category[0].toUpperCase() + category.substring(1);
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
                          day,
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
                        'Closed',
                        style: TextStyle(
                          color: isClosed ? Colors.red[700] : Colors.grey[800],
                          fontWeight:
                              isClosed ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (isSyncedWithMonday && !isClosed)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 14,
                                color: AppConstants.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Synced with Monday',
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
                                  'Opening Time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectTime(context, day, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
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
                                              : 'Select time',
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
                                  'Closing Time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectTime(context, day, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
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
                                              : 'Select time',
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        // Show error for categories
        setState(() {});
        return;
      }

      // Check if image is being processed
      if (_isProcessingImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait while the image is being processed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading
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

      // Create a new shop object
      final newShop = RepairShop(
        id: const Uuid().v4(), // Generate a unique ID
        name: _nameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        area: _areaController.text,
        categories: _selectedCategories,
        rating: 0.0, // Default rating for new shops
        hours: hours,
        closingDays: closingDays,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        irregularHours: _hasIrregularHours,
        approved: false, // New shops are not approved by default
        photos: [], // We'd add the photo URL here after Firebase upload
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
              'Shop Submitted',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Thank you for submitting a new shop! Your submission will be reviewed by our team before it appears in the app.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('OK'),
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
              'Error',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'There was an error submitting your shop. Please try again later.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text('OK'),
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
    setState(() {
      _isProcessingImage = true;
      _imageError = null;
    });

    try {
      // Pick image from gallery
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Initial size limit to prevent huge images
        maxHeight: 1080,
      );

      if (pickedFile == null) {
        setState(() {
          _isProcessingImage = false;
        });
        return;
      }

      // Check file size (max 6MB before compression)
      final fileSize = await File(pickedFile.path).length();
      if (fileSize > 6 * 1024 * 1024) {
        setState(() {
          _imageError =
              'Image is too large (max 6MB). Please select a smaller image.';
          _isProcessingImage = false;
        });
        return;
      }

      // Crop image to 6:4 ratio
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 6, ratioY: 4),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Shop Image',
            toolbarColor: AppConstants.primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Shop Image',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) {
        setState(() {
          _isProcessingImage = false;
        });
        return;
      }

      // Compress image to target size (<200KB)
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        targetPath,
        quality: 80, // Start with 80% quality
        minWidth: 1200,
        minHeight: 800,
      );

      if (compressedFile == null) {
        setState(() {
          _imageError = 'Failed to compress image. Please try again.';
          _isProcessingImage = false;
        });
        return;
      }

      // Check if compression achieved target size (<200KB)
      final compressedSize = await compressedFile.length();
      if (compressedSize > 200 * 1024) {
        // Try further compression if still too large
        final extraCompressedPath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_extra.jpg';
        final extraCompressed = await FlutterImageCompress.compressAndGetFile(
          compressedFile.path,
          extraCompressedPath,
          quality: 60, // Lower quality for smaller file
          minWidth: 900,
          minHeight: 600,
        );

        if (extraCompressed != null) {
          setState(() {
            _selectedImage = File(extraCompressed.path);
            _isProcessingImage = false;
          });
        } else {
          setState(() {
            _selectedImage = File(compressedFile.path);
            _isProcessingImage = false;
            _imageError = 'Image size may be larger than recommended (200KB).';
          });
        }
      } else {
        setState(() {
          _selectedImage = File(compressedFile.path);
          _isProcessingImage = false;
        });
      }

      // For debug: Show file size
      final finalSize = await _selectedImage!.length();
      print('Final image size: ${(finalSize / 1024).toStringAsFixed(2)} KB');

      // Note: In a real app, you'd upload this to Firebase Storage
      // For now, we'll just store it locally and print a comment
      print('TODO: Upload image to Firebase Storage');

      /* 
      To implement Firebase Storage upload:
      1. Add firebase_storage package dependency
      2. Initialize Firebase Storage
      3. Upload the image with a reference like 'shops/{shopId}/main.jpg'
      4. Get the download URL
      5. Add the URL to the shop.photos list when creating the shop
      
      Example code:
      ```
      final storageRef = FirebaseStorage.instance.ref();
      final shopImageRef = storageRef.child('shops/${shopId}/main.jpg');
      
      // Upload the file
      await shopImageRef.putFile(_selectedImage!);
      
      // Get the download URL
      final downloadUrl = await shopImageRef.getDownloadURL();
      
      // Add URL to shop photos
      shop.photos.add(downloadUrl);
      ```
      */
    } catch (e) {
      setState(() {
        _imageError = 'Error processing image: ${e.toString()}';
        _isProcessingImage = false;
      });
      print('Image processing error: $e');
    }
  }
}
