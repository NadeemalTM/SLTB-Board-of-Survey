import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import '../../data/models/asset_model.dart'; // Not needed for Firebase direct write
// import '../../data/database/database_helper.dart'; // REMOVED
import '../../services/firestore_service.dart'; // ADDED
import '../../core/constants/survey_status.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final String? scannedCode; // Added to accept code from scanner

  const AddItemScreen({Key? key, this.scannedCode}) : super(key: key);

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _codeController;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(); // ADDED
  final _physicalBalanceController = TextEditingController(text: '1');
  final _remarksController = TextEditingController();
  
  String _selectedStatus = SurveyStatus.good;
  
  // Images (UI Only for now - uploading requires Firebase Storage)
  String? _image1Path;
  String? _image2Path;
  String? _image3Path;
  final ImagePicker _picker = ImagePicker();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // If a code was scanned, use it. Otherwise, generate a "NEW" code.
    String initialCode = widget.scannedCode ?? 'NEW-${DateTime.now().millisecondsSinceEpoch}';
    _codeController = TextEditingController(text: initialCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _physicalBalanceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int imageNumber) async {
    // This part works for UI, but won't upload to cloud yet
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Reduced quality for faster processing
    );

    if (image != null) {
      setState(() {
        switch (imageNumber) {
          case 1: _image1Path = image.path; break;
          case 2: _image2Path = image.path; break;
          case 3: _image3Path = image.path; break;
        }
      });
    }
  }

  Future<void> _saveNewAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // --- NEW FIREBASE LOGIC ---
      final firestore = FirestoreService();
      
      await firestore.addAsset(
        _codeController.text,
        _descriptionController.text,
        int.parse(_physicalBalanceController.text),
        _locationController.text,
      );

      // Note: We are currently ignoring 'SurveyStatus' and 'Remarks' 
      // in the simple addAsset function. 
      // You can update FirestoreService later to accept these extra fields.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset Saved to Cloud!'), backgroundColor: Colors.green),
        );
        // Return to Dashboard (Pop twice: Close Add Screen, Close Scan Screen)
        Navigator.pop(context); 
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barcode Field (Read Only)
              TextFormField(
                controller: _codeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Barcode / Asset ID',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black12,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Ex: Dell Monitor 24"',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              // 3. Location (CRITICAL FOR DATABASE)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Ex: Room 203',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),

              // 4. Quantity
              TextFormField(
                controller: _physicalBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 16),

              // 5. Condition
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment_turned_in),
                ),
                items: [
                  SurveyStatus.good,
                  SurveyStatus.broken,
                  SurveyStatus.missing,
                ].map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.toUpperCase()),
                )).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveNewAsset,
                icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.cloud_upload),
                label: Text(_isSaving ? 'Saving to Cloud...' : 'SAVE ASSET'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}