import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/section_title.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';

class EditShopScreen extends StatefulWidget {
  final RepairShop shop;

  const EditShopScreen({Key? key, required this.shop}) : super(key: key);

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isProcessingImage = false;
  String? _imageError;
  File? _imageFile;
  final ShopService _shopService = ShopService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _soiController = TextEditingController();
  final _districtController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _lineIdController = TextEditingController();
  final _facebookPageController = TextEditingController();
  final _instagramPageController = TextEditingController();
  final _otherContactsController = TextEditingController();
  final _notesOrConditionsController = TextEditingController();
  final _buildingFloorController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Categories and services
  final List<String> _categories = [
    'Motorcycle Repair',
    'Car Repair',
    'Bicycle Repair',
    'Electronics Repair',
    'Appliance Repair',
    'Other',
  ];
  final Set<String> _selectedCategories = {};
  late Map<String, List<String>> _selectedSubServices;

  // Opening hours
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final Map<String, TimeOfDay?> _openingTimes = {};
  final Map<String, TimeOfDay?> _closingTimes = {};
  final Map<String, bool> _closedDays = {};
  final Map<String, TextEditingController> _openingTimeControllers = {};
  final Map<String, TextEditingController> _closingTimeControllers = {};
  bool _sameTimeEveryDay = false;
  bool _hasIrregularHours = false;

  // Payment methods
  final Set<String> _selectedPaymentMethods = {};
  bool _tryOnAreaAvailable = false;

  // Province selection
  String _selectedProvince = 'Bangkok';
  final List<String> _provinces = [
    'Bangkok',
    'Chiang Mai',
    'Phuket',
    'Pattaya',
    // Add more provinces as needed
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // Initialize controllers with existing shop data
    _nameController.text = widget.shop.name;
    _descriptionController.text = widget.shop.description;
    _buildingNumberController.text = widget.shop.buildingNumber ?? '';
    _soiController.text = widget.shop.soi ?? '';
    _districtController.text = widget.shop.district ?? '';
    _landmarkController.text = widget.shop.landmark ?? '';
    _lineIdController.text = widget.shop.lineId ?? '';
    _facebookPageController.text = widget.shop.facebookPage ?? '';
    _instagramPageController.text = widget.shop.instagramPage ?? '';
    _otherContactsController.text = widget.shop.otherContacts ?? '';
    _notesOrConditionsController.text = widget.shop.notesOrConditions ?? '';
    _buildingFloorController.text = widget.shop.buildingFloor ?? '';
    _latitudeController.text = widget.shop.latitude.toString();
    _longitudeController.text = widget.shop.longitude.toString();

    // Initialize categories and sub-services
    _selectedCategories.addAll(widget.shop.categories);
    _selectedSubServices = Map.fromEntries(
      widget.shop.subServices.entries.map(
        (e) => MapEntry(e.key, List<String>.from(e.value)),
      ),
    );

    // Initialize opening hours
    for (final day in _days) {
      _openingTimeControllers[day] = TextEditingController();
      _closingTimeControllers[day] = TextEditingController();

      final hours = widget.shop.hours[day.toLowerCase()];
      if (hours != null) {
        final parts = hours.split(' - ');
        if (parts.length == 2) {
          final openingTime = _parseTimeString(parts[0]);
          final closingTime = _parseTimeString(parts[1]);
          if (openingTime != null && closingTime != null) {
            _openingTimes[day] = openingTime;
            _closingTimes[day] = closingTime;
            _openingTimeControllers[day]?.text = parts[0];
            _closingTimeControllers[day]?.text = parts[1];
          }
        }
      }
      _closedDays[day] = widget.shop.closingDays.contains(day.toLowerCase());
    }

    // Initialize other fields
    _selectedPaymentMethods.addAll(widget.shop.paymentMethods ?? []);
    _tryOnAreaAvailable = widget.shop.tryOnAreaAvailable ?? false;
    _selectedProvince = widget.shop.province ?? 'Bangkok';
    _hasIrregularHours = widget.shop.irregularHours;
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Invalid time format
    }
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buildingNumberController.dispose();
    _soiController.dispose();
    _districtController.dispose();
    _landmarkController.dispose();
    _lineIdController.dispose();
    _facebookPageController.dispose();
    _instagramPageController.dispose();
    _otherContactsController.dispose();
    _notesOrConditionsController.dispose();
    _buildingFloorController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    for (final controller in _openingTimeControllers.values) {
      controller.dispose();
    }
    for (final controller in _closingTimeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create updated shop data
      final updatedShop = RepairShop(
        id: widget.shop.id,
        name: _nameController.text,
        description: _descriptionController.text,
        address: widget.shop.address, // Keep existing address
        area: widget.shop.area, // Keep existing area
        categories: _selectedCategories.toList(),
        rating: widget.shop.rating, // Keep existing rating
        reviewCount: widget.shop.reviewCount, // Keep existing review count
        amenities: widget.shop.amenities, // Keep existing amenities
        hours: Map.fromEntries(
          _days.map(
            (day) => MapEntry(
              day.toLowerCase(),
              _closedDays[day] ?? false
                  ? 'Closed'
                  : '${_openingTimeControllers[day]?.text} - ${_closingTimeControllers[day]?.text}',
            ),
          ),
        ),
        closingDays:
            _days
                .where((day) => _closedDays[day] ?? false)
                .map((day) => day.toLowerCase())
                .toList(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        durationMinutes: widget.shop.durationMinutes, // Keep existing duration
        requiresPurchase: widget.shop.requiresPurchase, // Keep existing value
        photos: widget.shop.photos, // Keep existing photos
        priceRange: widget.shop.priceRange, // Keep existing price range
        features: widget.shop.features, // Keep existing features
        approved: widget.shop.approved, // Keep existing approval status
        irregularHours: _hasIrregularHours,
        subServices: _selectedSubServices,
        timestamp: widget.shop.timestamp, // Keep existing timestamp
        buildingNumber: _buildingNumberController.text,
        buildingName: widget.shop.buildingName, // Keep existing building name
        soi: _soiController.text,
        district: _districtController.text,
        province: _selectedProvince,
        landmark: _landmarkController.text,
        lineId: _lineIdController.text,
        facebookPage: _facebookPageController.text,
        otherContacts: _otherContactsController.text,
        paymentMethods: _selectedPaymentMethods.toList(),
        tryOnAreaAvailable: _tryOnAreaAvailable,
        notesOrConditions: _notesOrConditionsController.text,
        usualOpeningTime:
            widget.shop.usualOpeningTime, // Keep existing usual times
        usualClosingTime: widget.shop.usualClosingTime,
        instagramPage: _instagramPageController.text,
        phoneNumber: widget.shop.phoneNumber, // Keep existing phone number
        buildingFloor: _buildingFloorController.text,
      );

      // Update shop in the database
      await _shopService.updateShop(updatedShop);

      if (mounted) {
        Navigator.pop(context, updatedShop);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update shop: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickAndCropImage() async {
    try {
      setState(() {
        _isProcessingImage = true;
        _imageError = null;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          compressQuality: 80,
          maxWidth: 1200,
          maxHeight: 675,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: AppConstants.primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imageFile = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      setState(() {
        _imageError = 'Failed to process image. Please try again.';
      });
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              initialLatitude:
                  double.tryParse(_latitudeController.text) ??
                  AppConstants.defaultLatitude,
              initialLongitude:
                  double.tryParse(_longitudeController.text) ??
                  AppConstants.defaultLongitude,
            ),
      ),
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        _latitudeController.text = result['latitude']!.toString();
        _longitudeController.text = result['longitude']!.toString();
      });
    }
  }

  Widget _buildImageDisplay() {
    if (_isProcessingImage) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }

    if (widget.shop.photos.isNotEmpty) {
      return Image.network(
        widget.shop.photos.first,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Add Shop Photo',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _categories.map((category) {
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
              backgroundColor: Colors.grey[200],
              selectedColor: AppConstants.primaryColor.withOpacity(0.2),
              checkmarkColor: AppConstants.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppConstants.primaryColor : Colors.black87,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildOpeningHoursFields() {
    return Column(
      children:
          _days.map((day) {
            final isClosed = _closedDays[day] ?? false;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isClosed,
                          onChanged: (value) {
                            setState(() {
                              _closedDays[day] = value ?? false;
                              if (value ?? false) {
                                _openingTimes[day] = null;
                                _closingTimes[day] = null;
                                _openingTimeControllers[day]?.clear();
                                _closingTimeControllers[day]?.clear();
                              }
                            });
                          },
                        ),
                        const Text('Closed'),
                      ],
                    ),
                    if (!isClosed) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _openingTimeControllers[day],
                              decoration: const InputDecoration(
                                labelText: 'Opening Time',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              readOnly: true,
                              onTap: () => _selectTime(context, day, true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _closingTimeControllers[day],
                              decoration: const InputDecoration(
                                labelText: 'Closing Time',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              readOnly: true,
                              onTap: () => _selectTime(context, day, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isOpening,
  ) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime:
          isOpening
              ? _openingTimes[day] ?? const TimeOfDay(hour: 9, minute: 0)
              : _closingTimes[day] ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (selectedTime != null) {
      setState(() {
        if (isOpening) {
          _openingTimes[day] = selectedTime;
          _openingTimeControllers[day]?.text = _formatTimeOfDay(selectedTime);
        } else {
          _closingTimes[day] = selectedTime;
          _closingTimeControllers[day]?.text = _formatTimeOfDay(selectedTime);
        }
      });
    }
  }

  void _onDeleteShopPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Shop'),
            content: const Text(
              'Are you sure you want to delete this shop? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      try {
        final success = await _shopService.deleteShop(widget.shop.id);
        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shop deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          throw Exception('Failed to delete shop');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submitForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            const SectionTitle(text: 'Basic Information'),
            const SizedBox(height: 16),
            _buildImageDisplay(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickAndCropImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload New Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (_imageError != null) ...[
              const SizedBox(height: 8),
              Text(
                _imageError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                hintText: 'Enter shop name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a shop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter shop description',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Categories Section
            const SectionTitle(text: 'Categories'),
            const SizedBox(height: 16),
            _buildCategoriesSelector(),
            const SizedBox(height: 24),

            // Location Section
            const SectionTitle(text: 'Location'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buildingNumberController,
              decoration: const InputDecoration(
                labelText: 'Building Number',
                hintText: 'Enter building number',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _soiController,
              decoration: const InputDecoration(
                labelText: 'Soi',
                hintText: 'Enter soi',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                hintText: 'Enter district',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              decoration: const InputDecoration(labelText: 'Province'),
              items:
                  _provinces.map((province) {
                    return DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvince = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark',
                hintText: 'Enter nearby landmark',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: 'Enter latitude',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter latitude';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: 'Enter longitude',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter longitude';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openMapPicker(context),
              icon: const Icon(Icons.map),
              label: const Text('Pick Location on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            const SectionTitle(text: 'Contact Information'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lineIdController,
              decoration: const InputDecoration(
                labelText: 'Line ID',
                hintText: 'Enter Line ID',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facebookPageController,
              decoration: const InputDecoration(
                labelText: 'Facebook Page',
                hintText: 'Enter Facebook page URL',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instagramPageController,
              decoration: const InputDecoration(
                labelText: 'Instagram Page',
                hintText: 'Enter Instagram page URL',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherContactsController,
              decoration: const InputDecoration(
                labelText: 'Other Contacts',
                hintText: 'Enter other contact information',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Payment Methods Section
            const SectionTitle(text: 'Payment Methods'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ['Cash', 'Credit Card', 'Mobile Banking', 'PromptPay'].map((
                    method,
                  ) {
                    final isSelected = _selectedPaymentMethods.contains(method);
                    return FilterChip(
                      label: Text(method),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPaymentMethods.add(method);
                          } else {
                            _selectedPaymentMethods.remove(method);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppConstants.primaryColor,
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? AppConstants.primaryColor
                                : Colors.black87,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Try-on Area Available'),
              value: _tryOnAreaAvailable,
              onChanged: (value) {
                setState(() {
                  _tryOnAreaAvailable = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Opening Hours Section
            const SectionTitle(text: 'Opening Hours'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Irregular Hours'),
              value: _hasIrregularHours,
              onChanged: (value) {
                setState(() {
                  _hasIrregularHours = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildOpeningHoursFields(),
            const SizedBox(height: 24),

            // Additional Information Section
            const SectionTitle(text: 'Additional Information'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesOrConditionsController,
              decoration: const InputDecoration(
                labelText: 'Notes or Conditions',
                hintText: 'Enter any additional notes or conditions',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
            ),
            const SizedBox(height: 32),

            // Delete Shop Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _onDeleteShopPressed,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete Shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
