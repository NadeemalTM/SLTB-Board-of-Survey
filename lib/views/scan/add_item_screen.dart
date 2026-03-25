import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../core/constants/survey_status.dart';
import '../../widgets/region_selector.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../providers/connectivity_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final String? scannedCode;
  const AddItemScreen({super.key, this.scannedCode});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _newCodeController;
  final TextEditingController _oldCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bookBalanceController =
      TextEditingController(text: '0');
  final TextEditingController _physicalBalanceController =
      TextEditingController(text: '1');

  String _selectedStatus = SurveyStatus.good;

  // Dropdown Variables
  String _selectedMainRegion = "";
  String _selectedSubRegion = "";

  final List<String?> _images = [null, null, null];
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    String initialCode =
        widget.scannedCode ?? 'NEW-${DateTime.now().millisecondsSinceEpoch}';
    _newCodeController = TextEditingController(text: initialCode);

    // --- AUTO-FILL LOGIC ---
    // Read the current user from the provider
    final authState = ref.read(authProvider);
    final user = authState.user;

    // If user exists and IS NOT an Admin, pre-fill the main region
    // Sub-region is left for manual selection unless the user has one assigned
    if (user != null && !user.isAdmin) {
      _selectedMainRegion = user.mainRegion;
      // Only pre-fill sub-region if the user has one in their profile
      if (user.subRegion.isNotEmpty) {
        _selectedSubRegion = user.subRegion;
      }
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70, // Optimized compression standard
      );
      if (image != null) {
        setState(() => _images[index] = image.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveToCloud() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Region (Even if locked, these variables must be set)
    if (_selectedMainRegion.isEmpty || _selectedSubRegion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Region Configuration Error. Contact Admin.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Mark as pending in sync tracker
    final syncNotifier = ref.read(syncStatusProvider.notifier);
    final assetCode = _newCodeController.text;
    final assetDesc = _descriptionController.text;
    syncNotifier.markPending(assetCode, assetDesc);

    try {
      final firestore = FirestoreService();
      // Upload photos to Firebase Storage
      List<String?> photoUrls = [null, null, null];
      try {
        final storageService = StorageService();
        photoUrls = await storageService.uploadAllPhotos(
          assetCode: assetCode,
          image1Path: _images[0],
          image2Path: _images[1],
          image3Path: _images[2],
        );
      } catch (e) {
        print('[AddItem] Photo upload failed: $e');
      }

      // Filter valid download URLs
      final List<String> photoDownloadUrls =
          photoUrls.where((url) => url != null).cast<String>().toList();

      await firestore.addAsset(
        newCode: assetCode,
        oldCode: _oldCodeController.text,
        description: assetDesc,
        mainRegion: _selectedMainRegion,
        subRegion: _selectedSubRegion,
        bookBalance: int.parse(_bookBalanceController.text),
        physicalBalance: int.parse(_physicalBalanceController.text),
        status: _selectedStatus,
        imagePaths: photoDownloadUrls, // Save URLs explicitly instead of local files
        photoUrls: photoDownloadUrls,
      );

      // Mark as synced
      syncNotifier.markSynced(assetCode, assetDesc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('\u2705 Asset Saved & Synced to Cloud!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Mark as failed
      syncNotifier.markFailed(assetCode, assetDesc, e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u274c Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to check role in the build method
    final authState = ref.watch(authProvider);
    final isOfficer = authState.user != null && !authState.user!.isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IDENTIFICATION
              _buildSectionHeader("Identification"),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _newCodeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'New Code (Barcode)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFEEEEEE),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oldCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Old Code (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.history),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // DETAILS
              _buildSectionHeader("Details"),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // --- REGION SELECTOR ---
                      // Officers: main region is locked, sub-region is selectable
                      // Admins: both are fully selectable
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RegionSelector(
                          lockedMainRegion:
                              isOfficer && _selectedMainRegion.isNotEmpty
                                  ? _selectedMainRegion
                                  : null,
                          initialMainRegion: _selectedMainRegion.isNotEmpty
                              ? _selectedMainRegion
                              : null,
                          initialSubRegion: _selectedSubRegion.isNotEmpty
                              ? _selectedSubRegion
                              : null,
                          onSelectionChanged: (main, sub) {
                            setState(() {
                              _selectedMainRegion = main;
                              _selectedSubRegion = sub;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ... (Audit Data and Photos sections remain exactly the same) ...
              // Copy the rest of your UI code here (Audit Data, Photos, Save Button)
              // to keep the file complete.

              // AUDIT DATA
              _buildSectionHeader("Audit Data"),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bookBalanceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Book Bal.',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _physicalBalanceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Physical Bal. *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Condition',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_turned_in),
                        ),
                        items: [
                          SurveyStatus.good,
                          SurveyStatus.broken,
                          SurveyStatus.missing,
                          'To be Disposed',
                        ]
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.toUpperCase())))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedStatus = val!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // PHOTOS
              _buildSectionHeader("Evidence (3 Photos)"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPhotoBox(0),
                  _buildPhotoBox(1),
                  _buildPhotoBox(2),
                ],
              ),
              const SizedBox(height: 32),

              // SAVE BUTTON
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveToCloud,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C3B2E),
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    _isSaving ? "SAVING..." : "SAVE ASSET",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildPhotoBox(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
          image: _images[index] != null
              ? DecorationImage(
                  image: _images[index]!.startsWith('http')
                      ? NetworkImage(_images[index]!) as ImageProvider
                      : FileImage(File(_images[index]!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _images[index] == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text("Photo ${index + 1}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              )
            : null,
      ),
    );
  }
}
