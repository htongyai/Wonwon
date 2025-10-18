import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/app_colors.dart';
import 'package:wonwonw2/constants/app_text_styles.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/widgets/section_title.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Image variables
  Uint8List? _selectedImageBytes;
  List<String> _existingPhotos = [];
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
  bool _acceptsCash = false;
  bool _acceptsQR = false;
  bool _acceptsCredit = false;

  // Other options
  bool _requiresPurchase = false;
  bool _tryOnAreaAvailable = false;
  String _priceRange = '₿';

  bool _isLoading = false;
  bool _isSaving = false;

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

    // Categories
    _selectedCategories = List.from(shop.categories);

    // Payment methods
    if (shop.paymentMethods != null) {
      _acceptsCash = shop.paymentMethods!.contains('cash');
      _acceptsQR = shop.paymentMethods!.contains('qr');
      _acceptsCredit = shop.paymentMethods!.contains('card');
    }

    // Other options
    _requiresPurchase = shop.requiresPurchase ?? false;
    _tryOnAreaAvailable = shop.tryOnAreaAvailable ?? false;
    _priceRange = shop.priceRange;

    // Hours
    _initializeHours();

    // Photos
    _existingPhotos = List.from(shop.photos);
  }

  void _initializeHours() {
    final shop = widget.shop;
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (final day in days) {
      final hours = shop.hours[day.toLowerCase()] ?? 'Closed';
      if (hours != 'Closed') {
        final parts = hours.split(' - ');
        if (parts.length == 2) {
          _openingTimeControllers[day]!.text = parts[0].trim();
          _closingTimeControllers[day]!.text = parts[1].trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Shop',
          style: AppTextStyles.heading.copyWith(color: AppColors.text),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
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
                'Save',
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
    );
  }

  Widget _buildBasicInformationSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'Basic Information'),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          _buildTextField(
            controller: _nameController,
            label: 'Shop Name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter shop name';
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 3,
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _areaController,
            label: 'Area/Neighborhood',
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
          SectionTitle(text: 'Location'),
          SizedBox(height: ResponsiveSize.getHeight(2)),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'e.g., 13.7563 (you can paste coordinates)',
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
                    labelText: 'Longitude',
                    hintText: '100.5018',
                    prefixIcon: Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'e.g., 100.5018 (you can paste coordinates)',
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
              label: const Text('Pick Location on Map'),
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
          SectionTitle(text: 'Contact Information'),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(controller: _lineIdController, label: 'Line ID'),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _facebookPageController,
            label: 'Facebook Page',
          ),
          SizedBox(height: ResponsiveSize.getHeight(1)),
          _buildTextField(
            controller: _instagramPageController,
            label: 'Instagram Page',
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
          SectionTitle(text: 'Service Categories'),
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
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
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
          SectionTitle(text: 'Opening Hours'),
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

  Widget _buildDayHours(String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _openingTimeControllers[day]!,
                    label: 'Open',
                    hintText: '09:00',
                  ),
                ),
                const SizedBox(width: 8),
                const Text('-'),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _closingTimeControllers[day]!,
                    label: 'Close',
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
          SectionTitle(text: 'Payment Methods'),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          CheckboxListTile(
            title: const Text('Cash'),
            value: _acceptsCash,
            onChanged: (value) {
              setState(() {
                _acceptsCash = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('QR Payment'),
            value: _acceptsQR,
            onChanged: (value) {
              setState(() {
                _acceptsQR = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Credit Card'),
            value: _acceptsCredit,
            onChanged: (value) {
              setState(() {
                _acceptsCredit = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(text: 'Photos'),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          if (_existingPhotos.isNotEmpty) ...[
            Text('Existing Photos:'),
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
                              image: NetworkImage(photo),
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
              label: const Text('Add Photo'),
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
          SectionTitle(text: 'Options'),
          SizedBox(height: ResponsiveSize.getHeight(2)),
          CheckboxListTile(
            title: const Text('Requires Purchase'),
            value: _requiresPurchase,
            onChanged: (value) {
              setState(() {
                _requiresPurchase = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Try-on Area Available'),
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
            decoration: const InputDecoration(
              labelText: 'Price Range',
              border: OutlineInputBorder(),
            ),
            items:
                ['₿', '₿₿', '₿₿₿'].map((range) {
                  return DropdownMenuItem(value: range, child: Text(range));
                }).toList(),
            onChanged: (value) {
              setState(() {
                _priceRange = value ?? '₿';
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
            color: Colors.black.withOpacity(0.05),
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
          _isProcessingImage = true;
          _imageError = null;
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

        setState(() {
          _selectedImageBytes = compressedImage;
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _imageError = 'Error picking image: $e';
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) {
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

      // Prepare payment methods
      List<String> paymentMethods = [];
      if (_acceptsCash) paymentMethods.add('cash');
      if (_acceptsQR) paymentMethods.add('qr');
      if (_acceptsCredit) paymentMethods.add('card');

      // Prepare hours
      Map<String, String> hours = {};
      final days = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      for (final day in days) {
        final dayName = day.substring(0, 1).toUpperCase() + day.substring(1);
        final openingTime = _openingTimeControllers[dayName]!.text.trim();
        final closingTime = _closingTimeControllers[dayName]!.text.trim();

        if (openingTime.isNotEmpty && closingTime.isNotEmpty) {
          hours[day] = '$openingTime - $closingTime';
        } else {
          hours[day] = 'Closed';
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
        subServices: widget.shop.subServices,
        buildingNumber: _buildingNumberController.text.trim(),
        buildingName: _buildingNameController.text.trim(),
        soi: _soiController.text.trim(),
        district: _districtController.text.trim(),
        province: widget.shop.province,
        landmark: _landmarkController.text.trim(),
        lineId: _lineIdController.text.trim(),
        facebookPage: _facebookPageController.text.trim(),
        otherContacts: _otherContactsController.text.trim(),
        paymentMethods: paymentMethods.isNotEmpty ? paymentMethods : null,
        tryOnAreaAvailable: _tryOnAreaAvailable,
        notesOrConditions: _notesOrConditionsController.text.trim(),
        usualOpeningTime: _usualOpeningTimeController.text.trim(),
        instagramPage: _instagramPageController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        buildingFloor: _buildingFloorController.text.trim(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .update(updatedShop.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      appLog('Error updating shop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating shop: $e'),
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
