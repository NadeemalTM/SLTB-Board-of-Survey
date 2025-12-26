import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/models/asset_model.dart';
import '../../data/database/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/survey_status.dart';

/// Add Item Screen - Add new assets found during survey
class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _physicalBalanceController = TextEditingController(text: '1');
  final _remarksController = TextEditingController();
  
  String _selectedStatus = SurveyStatus.verified;
  String? _image1Path;
  String? _image2Path;
  String? _image3Path;
  
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
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

  Future<String> _generateNewCode() async {
    final db = DatabaseHelper.instance;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'NEW-$timestamp';
  }

  Future<void> _saveNewAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authProvider);
      final username = authState.currentUser?.username ?? 'unknown';
      final physicalBalance = int.parse(_physicalBalanceController.text);
      
      // Generate unique new code
      final newCode = await _generateNewCode();

      // Create new asset
      final newAsset = AssetModel(
        serialNo: null, // New items don't have serial numbers yet
        description: _descriptionController.text.trim(),
        oldCode: 'N/A',
        newCode: newCode,
        bookBalance: 0, // New items have no book balance
        physicalBalance: physicalBalance,
        excess: physicalBalance, // All quantity is excess
        shortage: 0,
        remarks: _remarksController.text.trim(),
        surveyStatus: _selectedStatus,
        imagePath1: _image1Path,
        imagePath2: _image2Path,
        imagePath3: _image3Path,
        lastUpdatedBy: username,
        lastUpdatedDate: DateTime.now().toIso8601String(),
        isNewItem: 1, // Mark as new item
      );

      // Save to database
      final db = DatabaseHelper.instance;
      await db.insertAsset(newAsset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New item added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate addition
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
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
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Use this form to add assets found during survey that are not in the master list',
                          style: TextStyle(fontSize: 13),
                        ),
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
                  labelText: 'Description *',
                  hintText: 'Enter item description',
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

              // Physical Balance
              TextFormField(
                controller: _physicalBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  hintText: 'Enter quantity found',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 1) {
                    return 'Please enter a valid quantity (minimum 1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Survey Status
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  prefixIcon: Icon(Icons.assignment_turned_in),
                ),
                items: [
                  SurveyStatus.verified,
                  SurveyStatus.damaged,
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
              const SizedBox(height: 24),

              // Photos Section
              const Text(
                'Photos (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoThumbnail(1, _image1Path),
                  _buildPhotoThumbnail(2, _image2Path),
                  _buildPhotoThumbnail(3, _image3Path),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveNewAsset,
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
                    : const Icon(Icons.add_circle),
                label: Text(_isSaving ? 'Adding...' : 'Add New Item'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
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
      default:
        return Colors.grey;
    }
  }
}

