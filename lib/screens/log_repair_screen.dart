import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/models/repair_record.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/models/repair_sub_service.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';

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
  int? _satisfactionRating;
  String? _selectedCategory;
  String? _selectedSubService;
  Map<String, List<RepairSubService>> _subServices = {};

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
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedCategory == null ||
        _selectedSubService == null)
      return;

    setState(() {
      _isSubmitting = true;
    });
    if (!isLoggedIn || currentUser == null) return;
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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('repairRecords')
        .doc(record.id)
        .set(record.toMap());
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('log_repair'.tr(context))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                          Text(
                            widget.shop.area,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
                          Text(
                            widget.shop.phoneNumber!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items:
                    widget.shop.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
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
                        value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSubService,
                  items:
                      (_subServices[_selectedCategory] ?? []).map((subService) {
                        return DropdownMenuItem(
                          value: subService.id,
                          child: Text(subService.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubService = value;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a service' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item Fixed',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (THB)',
                  border: OutlineInputBorder(),
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
                    Text(
                      _selectedDate == null
                          ? 'Repair Date'
                          : 'Repair Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 20),
                      label: const Text('Select Date'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textAlignVertical: TextAlignVertical.top,
              ),
              const SizedBox(height: 16),
              const Text(
                'How satisfied were you with the repair?',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
