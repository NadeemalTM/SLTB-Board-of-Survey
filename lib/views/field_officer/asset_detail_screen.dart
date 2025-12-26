import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/models/asset_model.dart';
import '../../data/database/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/survey_status.dart';

/// Asset Detail Screen - View and update asset information
class AssetDetailScreen extends ConsumerStatefulWidget {
  final AssetModel asset;

  const AssetDetailScreen({
    Key? key,
    required this.asset,
  }) : super(key: key);

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  late TextEditingController _physicalBalanceController;
  late TextEditingController _remarksController;
  late String _selectedStatus;
  
  String? _image1Path;
  String? _image2Path;
  String? _image3Path;
  
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _physicalBalanceController = TextEditingController(
      text: widget.asset.physicalBalance?.toString() ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.asset.remarks ?? '',
    );
    _selectedStatus = widget.asset.surveyStatus ?? SurveyStatus.pending;
    _image1Path = widget.asset.imagePath1;
    _image2Path = widget.asset.imagePath2;
    _image3Path = widget.asset.imagePath3;
  }

  @override
  void dispose() {
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

  Future<void> _saveChanges() async {
    // Validate physical balance
    final physicalBalanceText = _physicalBalanceController.text.trim();
    if (physicalBalanceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter physical balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final physicalBalance = int.tryParse(physicalBalanceText);
    if (physicalBalance == null || physicalBalance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid physical balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authProvider);
      final username = authState.currentUser?.username ?? 'unknown';

      // Calculate excess/shortage
      final bookBalance = widget.asset.bookBalance ?? 0;
      final excess = physicalBalance > bookBalance
          ? physicalBalance - bookBalance
          : 0;
      final shortage = physicalBalance < bookBalance
          ? bookBalance - physicalBalance
          : 0;

      // Create updated asset
      final updatedAsset = AssetModel(
        id: widget.asset.id,
        serialNo: widget.asset.serialNo,
        description: widget.asset.description,
        oldCode: widget.asset.oldCode,
        newCode: widget.asset.newCode,
        bookBalance: widget.asset.bookBalance,
        physicalBalance: physicalBalance,
        excess: excess,
        shortage: shortage,
        remarks: _remarksController.text.trim(),
        surveyStatus: _selectedStatus,
        imagePath1: _image1Path,
        imagePath2: _image2Path,
        imagePath3: _image3Path,
        lastUpdatedBy: username,
        lastUpdatedDate: DateTime.now().toIso8601String(),
        isNewItem: widget.asset.isNewItem,
      );

      // Save to database
      final db = DatabaseHelper.instance;
      await db.updateAsset(updatedAsset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
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
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookBalance = widget.asset.bookBalance ?? 0;
    final physicalBalance = int.tryParse(_physicalBalanceController.text) ?? 0;
    final excess = physicalBalance > bookBalance ? physicalBalance - bookBalance : 0;
    final shortage = physicalBalance < bookBalance ? bookBalance - physicalBalance : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
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
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asset Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asset Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow('Serial No', widget.asset.serialNo?.toString() ?? 'N/A'),
                    _buildInfoRow('Description', widget.asset.description),
                    _buildInfoRow('Old Code', widget.asset.oldCode ?? 'N/A'),
                    _buildInfoRow('New Code', widget.asset.newCode),
                    _buildInfoRow('Book Balance', bookBalance.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Survey Data Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Survey Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    
                    // Physical Balance
                    TextField(
                      controller: _physicalBalanceController,
                      decoration: const InputDecoration(
                        labelText: 'Physical Balance',
                        hintText: 'Enter actual quantity found',
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}), // Recalculate
                    ),
                    const SizedBox(height: 16),

                    // Calculations Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
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
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Survey Status',
                        prefixIcon: Icon(Icons.assignment_turned_in),
                      ),
                      items: [
                        SurveyStatus.pending,
                        SurveyStatus.verified,
                        SurveyStatus.damaged,
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
                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        hintText: 'Add any notes or observations',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photos Card
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
                    const Divider(height: 20),
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
              onPressed: _isSaving ? null : _saveChanges,
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
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
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
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
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
              ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case SurveyStatus.verified:
        return Icons.check_circle;
      case SurveyStatus.damaged:
        return Icons.broken_image;
      case SurveyStatus.missing:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case SurveyStatus.verified:
        return Colors.green;
      case SurveyStatus.damaged:
        return Colors.orange;
      case SurveyStatus.missing:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
