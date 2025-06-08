import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/models/repair_record.dart';

class LogRepairScreen extends StatefulWidget {
  final RepairShop shop;
  const LogRepairScreen({Key? key, required this.shop}) : super(key: key);

  @override
  State<LogRepairScreen> createState() => _LogRepairScreenState();
}

class _LogRepairScreenState extends State<LogRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;
    setState(() {
      _isSubmitting = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
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
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
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
      appBar: AppBar(title: const Text('Log Repair')), // TODO: Localize
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Shop: ${widget.shop.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(labelText: 'Item Fixed'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (THB)'),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
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
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (days)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
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
