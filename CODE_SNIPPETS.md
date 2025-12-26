# 📝 Code Snippets - SLTB Board of Survey

Quick copy-paste code snippets for common tasks.

---

## 🔐 Authentication

### Login Widget
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginButton extends ConsumerWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const LoginButton({
    required this.usernameController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return ElevatedButton(
      onPressed: authState.isLoading
          ? null
          : () async {
              final success = await ref.read(authProvider.notifier).login(
                    usernameController.text,
                    passwordController.text,
                  );

              if (success) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => DashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authState.errorMessage ?? 'Login failed')),
                );
              }
            },
      child: authState.isLoading
          ? CircularProgressIndicator()
          : Text('Login'),
    );
  }
}
```

---

## 📊 Database Operations

### Insert Asset
```dart
final asset = AssetModel(
  serialNo: 1,
  description: 'Office Chair - Wooden',
  oldCode: 'OLD-001',
  newCode: 'NEW-001',
  bookBalance: 5,
);

final db = DatabaseHelper();
final id = await db.insertAsset(asset);
print('Inserted with ID: $id');
```

### Update Asset After Survey
```dart
Future<void> updateAssetSurvey({
  required AssetModel asset,
  required int physicalBalance,
  required String status,
  String? remarks,
  List<String?>? imagePaths,
  required String username,
}) async {
  // Calculate differences
  final differences = AssetModel.calculateDifferences(
    physicalBalance,
    asset.bookBalance,
  );

  // Create updated asset
  final updatedAsset = asset.copyWith(
    physicalBalance: physicalBalance,
    excess: differences['excess'],
    shortage: differences['shortage'],
    surveyStatus: status,
    remarks: remarks,
    imagePath1: imagePaths?[0],
    imagePath2: imagePaths?[1],
    imagePath3: imagePaths?[2],
    lastUpdatedBy: username,
    lastUpdatedDate: DateTime.now().toIso8601String(),
  );

  // Save to database
  final db = DatabaseHelper();
  await db.updateAsset(updatedAsset);
}
```

### Query Assets with Filters
```dart
final db = DatabaseHelper();

// Search by text
final searchResults = await db.getAssetsFiltered(
  searchQuery: 'chair',
);

// Filter by status
final goodItems = await db.getAssetsFiltered(
  surveyStatus: 'Good',
);

// Filter by surveyed state
final pendingItems = await db.getAssetsFiltered(
  isSurveyed: false,
);

// Combine filters
final complexQuery = await db.getAssetsFiltered(
  searchQuery: 'desk',
  surveyStatus: 'Broken',
  updatedBy: 'officer01',
);
```

---

## 📷 Barcode Scanning

### Basic Scanner Implementation
```dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';

class BarcodeScannerWidget extends StatelessWidget {
  final Function(String) onCodeScanned;

  const BarcodeScannerWidget({required this.onCodeScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              onCodeScanned(barcode.rawValue!);
              Navigator.pop(context);
              break;
            }
          }
        },
      ),
    );
  }
}
```

### Handle Scanned Code
```dart
Future<void> handleScannedCode(BuildContext context, String code) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  // Query database
  final db = DatabaseHelper();
  final asset = await db.getAssetByNewCode(code);

  // Hide loading
  Navigator.pop(context);

  if (asset != null) {
    // Navigate to detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetDetailScreen(asset: asset),
      ),
    );
  } else {
    // Show not found dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Asset Not Found'),
        content: Text('No asset found with code: $code'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to add new item with code pre-filled
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddItemScreen(prefilledCode: code),
                ),
              );
            },
            child: Text('Add as New'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📸 Photo Capture

### Single Photo Capture
```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Future<String?> capturePhoto() async {
  final picker = ImagePicker();
  
  try {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    return image?.path;
  } catch (e) {
    print('Error capturing photo: $e');
    return null;
  }
}
```

### Photo Capture Widget
```dart
class PhotoCaptureWidget extends StatefulWidget {
  final Function(String?) onPhotoTaken;
  final String? initialPath;

  const PhotoCaptureWidget({
    required this.onPhotoTaken,
    this.initialPath,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialPath;
  }

  Future<void> _takePicture() async {
    final path = await capturePhoto();
    if (path != null) {
      setState(() => _imagePath = path);
      widget.onPhotoTaken(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _imagePath == null
          ? InkWell(
              onTap: _takePicture,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Take Photo', style: TextStyle(fontSize: 12)),
                ],
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imagePath!),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: Icon(Icons.close, size: 16, color: Colors.white),
                      onPressed: () {
                        setState(() => _imagePath = null);
                        widget.onPhotoTaken(null);
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
```

---

## 📄 CSV Operations

### Import Master CSV
```dart
import 'package:file_picker/file_picker.dart';

Future<void> importMasterCsv(BuildContext context) async {
  // Pick file
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result == null) return;

  final filePath = result.files.single.path!;

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  try {
    // Parse CSV
    final assets = await CsvHelper.parseMasterCsv(filePath);

    // Import to database
    final db = DatabaseHelper();
    final count = await db.batchInsertFromMasterCsv(assets);

    // Hide loading
    Navigator.pop(context);

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully imported $count assets')),
    );
  } catch (e) {
    // Hide loading
    Navigator.pop(context);

    // Show error
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Import Failed'),
        content: Text('Error: $e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Export Field Officer Work
```dart
Future<void> exportFieldWork(
  BuildContext context,
  String username,
) async {
  try {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing export...')),
    );

    // Get modified assets
    final db = DatabaseHelper();
    final assets = await db.getModifiedAssetsByUser(username);

    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No surveyed assets to export')),
      );
      return;
    }

    // Generate CSV
    final filePath = await CsvHelper.generateFieldOfficerCsv(
      assets,
      username,
    );

    // Copy to Downloads
    final exportPath = await CsvHelper.exportToDownloads(filePath);

    // Show success dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Export Successful'),
        content: Text(
          'Exported ${assets.length} assets to:\n\n$exportPath',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export failed: $e')),
    );
  }
}
```

---

## 🎨 UI Components

### Loading Dialog
```dart
void showLoadingDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
      ),
    ),
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.pop(context);
}
```

### Confirmation Dialog
```dart
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return result ?? false;
}
```

### Custom Text Field
```dart
class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
```

### Status Dropdown
```dart
import '../core/constants/survey_status.dart';

class StatusDropdown extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;

  const StatusDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Survey Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: SurveyStatus.values.map((status) {
        return DropdownMenuItem(
          value: status.englishLabel,
          child: Text(status.englishLabel),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a status';
        }
        return null;
      },
    );
  }
}
```

---

## 📈 Statistics

### Get Dashboard Stats
```dart
Future<Map<String, dynamic>> getDashboardStats() async {
  final db = DatabaseHelper();

  final total = await db.getTotalCount();
  final surveyed = await db.getSurveyedCount();
  final pending = total - surveyed;
  final statusCounts = await db.getCountByStatus();
  final newItems = await db.getNewItemsCount();
  final completion = total > 0 ? (surveyed / total) * 100 : 0.0;

  return {
    'total': total,
    'surveyed': surveyed,
    'pending': pending,
    'statusCounts': statusCounts,
    'newItems': newItems,
    'completion': completion,
  };
}
```

### Display Stats in UI
```dart
FutureBuilder<Map<String, dynamic>>(
  future: getDashboardStats(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      return Text('Error loading stats');
    }

    final stats = snapshot.data!;

    return Column(
      children: [
        Text('Total: ${stats['total']}'),
        Text('Surveyed: ${stats['surveyed']}'),
        Text('Pending: ${stats['pending']}'),
        Text('Good: ${stats['statusCounts']['Good'] ?? 0}'),
        Text('Broken: ${stats['statusCounts']['Broken'] ?? 0}'),
        LinearProgressIndicator(
          value: stats['completion'] / 100,
        ),
        Text('${stats['completion'].toStringAsFixed(1)}% Complete'),
      ],
    );
  },
);
```

---

## 🔄 State Management

### Using Riverpod Provider
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// In a ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Watch state (rebuilds on change)
  final authState = ref.watch(authProvider);
  
  // Read once (doesn't rebuild)
  final username = ref.read(authProvider).currentUser?.username;
  
  // Call provider method
  ref.read(authProvider.notifier).logout();
  
  return Text('User: ${authState.currentUser?.displayName}');
}
```

### Refresh Data
```dart
// In ConsumerStatefulWidget
Future<void> _refreshData() async {
  await ref.read(dashboardProvider.notifier).refresh();
  await ref.read(assetListProvider.notifier).loadAssets();
}

// Use with RefreshIndicator
RefreshIndicator(
  onRefresh: _refreshData,
  child: ListView(...),
);
```

---

## ✅ Form Validation

### Form with Validation
```dart
class AssetUpdateForm extends StatefulWidget {
  @override
  State<AssetUpdateForm> createState() => _AssetUpdateFormState();
}

class _AssetUpdateFormState extends State<AssetUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _physicalBalanceController = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _physicalBalanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Process form
      final physicalBalance = int.parse(_physicalBalanceController.text);
      // ... save to database
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _physicalBalanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Physical Balance'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter physical balance';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

---

**Happy Coding! 🚀**

*Copy these snippets into your project as needed.*
