import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../data/models/asset_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/survey_status.dart';
import '../../services/storage_service.dart';
import '../../providers/connectivity_provider.dart';

/// Field Officer Verification Screen
/// Used by field officers to verify data entered by regional officers
/// They can edit if needed and confirm the asset details
class FieldOfficerVerificationScreen extends ConsumerStatefulWidget {
  final AssetModel asset;

  const FieldOfficerVerificationScreen({
    super.key,
    required this.asset,
  });

  @override
  ConsumerState<FieldOfficerVerificationScreen> createState() =>
      _FieldOfficerVerificationScreenState();
}

class _FieldOfficerVerificationScreenState
    extends ConsumerState<FieldOfficerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _oldCodeController;
  late TextEditingController _bookBalanceController;
  late TextEditingController _physicalBalanceController;
  late TextEditingController _remarksController;

  late String _selectedStatus;
  String? _image1Path;
  String? _image2Path;
  String? _image3Path;

  bool _isSaving = false;
  bool _isEditing = false; // Toggle between view and edit mode
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;

    _descriptionController = TextEditingController(text: asset.description);
    _oldCodeController = TextEditingController(text: asset.oldCode ?? '');
    _bookBalanceController = TextEditingController(
      text: asset.bookBalance.toString(),
    );
    _physicalBalanceController = TextEditingController(
      text: asset.physicalBalance.toString(),
    );
    _remarksController = TextEditingController(text: asset.remarks ?? '');

    _selectedStatus = SurveyStatus.migrateStatus(asset.surveyStatus);
    _image1Path = asset.imagePath1;
    _image2Path = asset.imagePath2;
    _image3Path = asset.imagePath3;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _oldCodeController.dispose();
    _bookBalanceController.dispose();
    _physicalBalanceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int imageNumber) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        switch (imageNumber) {
          case 1:
            _image1Path = image.path;
            break;
          case 2:
            _image2Path = image.path;
            break;
          case 3:
            _image3Path = image.path;
            break;
        }
      });
    }
  }

  Future<void> _confirmVerification() async {
    // Confirm without any changes
    await _saveChanges(verificationStatus: 'verified');
  }

  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return;
    // Save with edits and mark as needs correction
    await _saveChanges(verificationStatus: 'needs_correction');
  }

  Future<void> _saveChanges({required String verificationStatus}) async {
    setState(() {
      _isSaving = true;
    });

    // Mark as pending in sync tracker
    final syncNotifier = ref.read(syncStatusProvider.notifier);
    final desc = widget.asset.description;
    final newCode = widget.asset.newCode;
    syncNotifier.markPending(newCode, desc);

    try {
      final authState = ref.read(authProvider);
      final username = authState.currentUser?.username ?? 'unknown';

      final bookBalance = int.parse(_bookBalanceController.text);
      final physicalBalance = int.parse(_physicalBalanceController.text);

      // Calculate excess/shortage
      final excess =
          physicalBalance > bookBalance ? physicalBalance - bookBalance : 0;
      final shortage =
          physicalBalance < bookBalance ? bookBalance - physicalBalance : 0;

      final now = DateTime.now().toIso8601String();
      final newCode = widget.asset.newCode;

      // Upload photos to Firebase Storage
      List<String?> photoUrls = [null, null, null];
      if (_image1Path != null || _image2Path != null || _image3Path != null) {
        try {
          final storageService = StorageService();
          photoUrls = await storageService.uploadAllPhotos(
            assetCode: newCode,
            image1Path: _image1Path,
            image2Path: _image2Path,
            image3Path: _image3Path,
          );
        } catch (e) {
          print('[Verification] Photo upload failed: $e');
        }
      }

      // Build the update data for Firestore
      final updateData = <String, dynamic>{
        'description': _descriptionController.text.trim(),
        'oldCode': _oldCodeController.text.trim(),
        'bookBalance': bookBalance,
        'physicalBalance': physicalBalance,
        'excess': excess,
        'shortage': shortage,
        'remarks': _remarksController.text.trim(),
        'status': _selectedStatus,
        'verifiedBy': username,
        'verifiedDate': now,
        'verificationStatus': verificationStatus,
        'lastUpdatedBy': username,
        'lastUpdatedDate': now,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add photo URLs if uploaded successfully
      if (photoUrls[0] != null) updateData['photoUrl1'] = photoUrls[0];
      if (photoUrls[1] != null) updateData['photoUrl2'] = photoUrls[1];
      if (photoUrls[2] != null) updateData['photoUrl3'] = photoUrls[2];

      // Store local paths too
      if (_image1Path != null) updateData['imagePath1'] = _image1Path;
      if (_image2Path != null) updateData['imagePath2'] = _image2Path;
      if (_image3Path != null) updateData['imagePath3'] = _image3Path;

      // Update approval level if verified
      if (verificationStatus == 'verified') {
        updateData['approvalLevel'] = 1;
        updateData['approvalStatus'] = 'Verified by Field Officer';
      }

      // Find and update the document in Firestore
      final firestore = FirebaseFirestore.instance;
      bool updated = false;

      // 1. Try hierarchical: collectionGroup('assets')
      try {
        final snap = await firestore
            .collectionGroup('assets')
            .where('newCode', isEqualTo: newCode)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update(updateData);
          updated = true;
        }
      } catch (e) {
        print('[Verification] CollectionGroup update failed: $e');
      }

      // 2. Try flat collection: survey_YEAR/{docId}
      if (!updated) {
        try {
          final currentYear = DateTime.now().year.toString();
          final collectionName = 'survey_$currentYear';
          final snap = await firestore
              .collection(collectionName)
              .where('newCode', isEqualTo: newCode)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            await snap.docs.first.reference.update(updateData);
            updated = true;
          }
        } catch (e) {
          print('[Verification] Flat collection update failed: $e');
        }
      }

      if (mounted) {
        if (updated) {
          // Mark as synced
          syncNotifier.markSynced(newCode, desc);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                verificationStatus == 'verified'
                    ? '✅ Asset verified & synced'
                    : '✅ Asset updated & synced',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Mark as failed — couldn't find document
          syncNotifier.markFailed(
              newCode, desc, 'Document not found in Firebase');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Could not find asset in Firebase'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Mark as failed
      syncNotifier.markFailed(newCode, desc, e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final bookBalance = int.tryParse(_bookBalanceController.text) ?? 0;
    final physicalBalance = int.tryParse(_physicalBalanceController.text) ?? 0;
    final excess =
        physicalBalance > bookBalance ? physicalBalance - bookBalance : 0;
    final shortage =
        physicalBalance < bookBalance ? bookBalance - physicalBalance : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Asset'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset fields
                  _descriptionController.text = widget.asset.description;
                  _oldCodeController.text = widget.asset.oldCode ?? '';
                  _bookBalanceController.text =
                      widget.asset.bookBalance.toString();
                  _physicalBalanceController.text =
                      widget.asset.physicalBalance.toString();
                  _remarksController.text = widget.asset.remarks ?? '';
                  _selectedStatus =
                      SurveyStatus.migrateStatus(widget.asset.surveyStatus);
                });
              },
              tooltip: 'Cancel Edit',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Asset Info Card
              Card(
                color: const Color(0xFF1A3A2E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Barcode',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  widget.asset.newCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white38),
                      const SizedBox(height: 8),
                      if (widget.asset.enteredBy != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.person,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Entered by: ${widget.asset.enteredBy}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          Icon(
                            _isEditing ? Icons.edit : Icons.visibility,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing
                                ? 'Edit mode - Make corrections'
                                : 'View mode - Review and confirm',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                enabled: _isEditing,
                validator: (value) {
                  if (_isEditing && (value == null || value.trim().isEmpty)) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Old Code
              TextFormField(
                controller: _oldCodeController,
                decoration: const InputDecoration(
                  labelText: 'Old Code',
                  prefixIcon: Icon(Icons.tag),
                ),
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),

              // Book Balance
              TextFormField(
                controller: _bookBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Book Balance',
                  prefixIcon: Icon(Icons.book),
                ),
                keyboardType: TextInputType.number,
                enabled: _isEditing,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (_isEditing && (value == null || value.isEmpty)) {
                    return 'Please enter book balance';
                  }
                  if (_isEditing) {
                    final qty = int.tryParse(value!);
                    if (qty == null || qty < 0) {
                      return 'Please enter valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Physical Balance
              TextFormField(
                controller: _physicalBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Physical Balance',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                enabled: _isEditing,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (_isEditing && (value == null || value.isEmpty)) {
                    return 'Please enter physical balance';
                  }
                  if (_isEditing) {
                    final qty = int.tryParse(value!);
                    if (qty == null || qty < 0) {
                      return 'Please enter valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Calculations Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildCalculationRow(
                      'Excess',
                      excess.toString(),
                      excess > 0 ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    _buildCalculationRow(
                      'Shortage',
                      shortage.toString(),
                      shortage > 0 ? Colors.red : Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Survey Status
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.assignment_turned_in),
                ),
                items: [
                  SurveyStatus.good,
                  SurveyStatus.broken,
                  SurveyStatus.missing,
                ].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 20,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(status.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                enabled: _isEditing,
              ),
              const SizedBox(height: 20),

              // Photos Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPhotoThumbnail(1, _image1Path),
                          _buildPhotoThumbnail(2, _image2Path),
                          _buildPhotoThumbnail(3, _image3Path),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (!_isEditing) ...[
                // Confirm Button (when not editing)
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _confirmVerification,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isSaving ? 'Confirming...' : 'Confirm Correct'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Edit Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Details'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF0C3B2E)),
                    foregroundColor: const Color(0xFF0C3B2E),
                  ),
                ),
              ] else ...[
                // Save Edit Button (when editing)
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEdits,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0C3B2E),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(int number, String? imagePath) {
    return GestureDetector(
      onTap: _isEditing ? () => _pickImage(number) : null,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: imagePath != null && imagePath.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing ? Icons.add_a_photo : Icons.image_not_supported,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photo $number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case SurveyStatus.good:
        return Icons.check_circle;
      case SurveyStatus.broken:
        return Icons.broken_image;
      case SurveyStatus.missing:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case SurveyStatus.good:
        return Colors.green;
      case SurveyStatus.broken:
        return Colors.orange;
      case SurveyStatus.missing:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
