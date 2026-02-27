import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/models/asset_model.dart';
import '../../data/database/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/survey_status.dart';
import '../../services/http_sync_service.dart';
import '../../services/storage_service.dart';

/// Regional Officer Asset Entry Screen
/// Used to enter complete asset details including physical count, status, photos
class RegionAssetEntryScreen extends ConsumerStatefulWidget {
  final AssetModel? asset; // Null if creating new
  final String scannedCode;

  const RegionAssetEntryScreen({
    super.key,
    this.asset,
    required this.scannedCode,
  });

  @override
  ConsumerState<RegionAssetEntryScreen> createState() =>
      _RegionAssetEntryScreenState();
}

class _RegionAssetEntryScreenState
    extends ConsumerState<RegionAssetEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _oldCodeController;
  late TextEditingController _bookBalanceController;
  late TextEditingController _physicalBalanceController;
  late TextEditingController _remarksController;

  String _selectedStatus = SurveyStatus.good;
  String? _image1Path;
  String? _image2Path;
  String? _image3Path;

  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;

    _descriptionController = TextEditingController(
      text: asset?.description ?? '',
    );
    _oldCodeController = TextEditingController(
      text: asset?.oldCode ?? '',
    );
    _bookBalanceController = TextEditingController(
      text: asset?.bookBalance.toString() ?? '0',
    );
    _physicalBalanceController = TextEditingController(
      text: asset?.physicalBalance.toString() ?? '',
    );
    _remarksController = TextEditingController(
      text: asset?.remarks ?? '',
    );

    _selectedStatus = SurveyStatus.migrateStatus(asset?.surveyStatus);
    _image1Path = asset?.imagePath1;
    _image2Path = asset?.imagePath2;
    _image3Path = asset?.imagePath3;
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

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

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

      final AssetModel assetToSave;

      if (widget.asset != null) {
        // Update existing asset
        assetToSave = widget.asset!.copyWith(
          description: _descriptionController.text.trim(),
          oldCode: _oldCodeController.text.trim(),
          bookBalance: bookBalance,
          physicalBalance: physicalBalance,
          excess: excess,
          shortage: shortage,
          remarks: _remarksController.text.trim(),
          surveyStatus: _selectedStatus,
          imagePath1: _image1Path,
          imagePath2: _image2Path,
          imagePath3: _image3Path,
          enteredBy: widget.asset!.enteredBy ?? username,
          enteredDate: widget.asset!.enteredDate ?? now,
          verificationStatus: 'pending', // Reset to pending when updated
          lastUpdatedBy: username,
          lastUpdatedDate: now,
        );
      } else {
        // Create new asset
        assetToSave = AssetModel(
          serialNo: null, // Can be added later
          description: _descriptionController.text.trim(),
          oldCode: _oldCodeController.text.trim().isEmpty
              ? null
              : _oldCodeController.text.trim(),
          newCode: widget.scannedCode,
          bookBalance: bookBalance,
          physicalBalance: physicalBalance,
          excess: excess,
          shortage: shortage,
          remarks: _remarksController.text.trim(),
          surveyStatus: _selectedStatus,
          imagePath1: _image1Path,
          imagePath2: _image2Path,
          imagePath3: _image3Path,
          enteredBy: username,
          enteredDate: now,
          verificationStatus: 'pending',
          lastUpdatedBy: username,
          lastUpdatedDate: now,
          isNewItem: widget.asset == null ? 1 : widget.asset!.isNewItem,
        );
      }

      // Upload photos to Firebase Storage
      List<String?> photoUrls = [null, null, null];
      try {
        final storageService = StorageService();
        photoUrls = await storageService.uploadAllPhotos(
          assetCode: widget.scannedCode,
          image1Path: _image1Path,
          image2Path: _image2Path,
          image3Path: _image3Path,
        );
      } catch (e) {
        print('[RegionEntry] Photo upload failed: $e');
      }

      // Save to local database
      final db = DatabaseHelper.instance;
      if (widget.asset != null) {
        await db.updateAsset(assetToSave);
      } else {
        await db.insertAsset(assetToSave);
      }

      // Sync to MySQL via PHP API
      bool synced = await HttpSyncService().saveAsset(assetToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.asset != null
                ? 'Asset updated${synced ? ' & synced to MySQL' : ' (local only)'}'
                : 'Asset saved${synced ? ' & synced to MySQL' : ' (local only)'}'),
            backgroundColor: synced ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${e.toString()}'),
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
    final isNewAsset = widget.asset == null;
    final bookBalance = int.tryParse(_bookBalanceController.text) ?? 0;
    final physicalBalance = int.tryParse(_physicalBalanceController.text) ?? 0;
    final excess =
        physicalBalance > bookBalance ? physicalBalance - bookBalance : 0;
    final shortage =
        physicalBalance < bookBalance ? bookBalance - physicalBalance : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewAsset ? 'Enter New Asset' : 'Edit Asset'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAsset,
            tooltip: 'Save Asset',
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
              // Info Card
              Card(
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2, color: Color(0xFF0C3B2E)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Barcode',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  widget.scannedCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isNewAsset) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'New asset - Enter all details',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Enter asset description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                  hintText: 'Enter old code (optional)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Book Balance
              TextFormField(
                controller: _bookBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Book Balance *',
                  hintText: 'Enter quantity as per records',
                  prefixIcon: Icon(Icons.book),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}), // Recalculate
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter book balance';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 0) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Physical Balance
              TextFormField(
                controller: _physicalBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Physical Balance *',
                  hintText: 'Enter actual quantity found',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}), // Recalculate
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter physical balance';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 0) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Calculations Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    _buildCalculationRow(
                      'Excess',
                      excess.toString(),
                      excess > 0
                          ? Colors.green
                          : const Color.fromARGB(255, 0, 0, 0),
                    ),
                    const SizedBox(height: 8),
                    _buildCalculationRow(
                      'Shortage',
                      shortage.toString(),
                      shortage > 0
                          ? Colors.red
                          : const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Survey Status
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
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
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Add any notes or observations',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
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

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAsset,
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
                label: Text(_isSaving ? 'Saving...' : 'Save Asset'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0C3B2E),
                  foregroundColor: Colors.white,
                ),
              ),
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
      onTap: () => _pickImage(number),
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
                child: imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPhotoPlaceholder(number),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPhotoPlaceholder(number),
                      ),
              )
            : _buildPhotoPlaceholder(number),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(int number) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          'Photo $number',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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
