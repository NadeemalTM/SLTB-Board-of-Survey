# SLTB Board of Survey - High-Level Implementation Plan

## 📋 Overview
This document outlines the complete implementation plan for the SLTB Board of Survey System, a modern offline-first mobile application built with Flutter.

---

## 🎯 Phase 1: Project Setup & Database Foundation ✅

### 1.1 Initialize Flutter Project
```bash
flutter create sltb_board_of_survey
cd sltb_board_of_survey
```

### 1.2 Install Dependencies
```bash
flutter pub add flutter_riverpod sqflite path path_provider csv mobile_scanner image_picker intl file_picker permission_handler flutter_slidable
flutter pub add --dev flutter_lints build_runner riverpod_generator
```

### 1.3 Configure Android Permissions
**File:** `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

### 1.4 Configure iOS Permissions
**File:** `ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan barcodes and take photos of assets</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to select images</string>
```

---

## 🎯 Phase 2: Core Application Structure ✅

### 2.1 Create Folder Structure
✅ Already created - See [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md)

### 2.2 Implement Core Models
✅ **Asset Model** - Complete with all fields and helper methods
✅ **User Model** - Hardcoded accounts with authentication logic
✅ **Database Constants** - Table and column definitions

### 2.3 Implement Database Layer
✅ **DatabaseHelper** - Singleton class with:
- Database initialization and table creation
- CRUD operations (Create, Read, Update, Delete)
- Filtered queries with search
- Dashboard statistics methods
- Batch CSV import/export operations
- Database maintenance utilities

### 2.4 Implement CSV Utilities
✅ **CsvHelper** class with:
- Master CSV parsing (5 columns)
- Field officer CSV parsing (16 columns)
- CSV generation for exports
- Validation and preview methods

---

## 🎯 Phase 3: State Management with Riverpod ✅

### 3.1 Authentication Provider
✅ Manages user login/logout state
- `authProvider` - Current user and authentication state
- Login with username/password validation
- Logout functionality

### 3.2 Asset Provider
✅ Manages asset list and filtering
- `assetListProvider` - Asset list with search/filter state
- Search by code or description
- Filter by status and survey state
- CRUD operations

### 3.3 Dashboard Provider
✅ Manages dashboard statistics
- `dashboardProvider` - Real-time statistics
- Total items, surveyed count, pending count
- Status-wise breakdown
- Completion percentage

---

## 🎯 Phase 4: User Interface Implementation

### 4.1 Authentication UI
**File:** `lib/views/auth/login_screen.dart`

**Implementation Steps:**
1. Create login form with username and password fields
2. Integrate with `authProvider`
3. Show error messages for invalid credentials
4. Navigate to appropriate dashboard based on role
5. Add app branding and logo

**Key Features:**
- Modern Material 3 design
- Input validation
- Loading indicator during authentication
- Remember last username (optional)

---

### 4.2 Field Officer Dashboard ✅
**File:** `lib/views/field_officer/dashboard_screen.dart`

**Completed Features:**
✅ Summary cards showing:
  - Total items, verified, pending
  - Status breakdown (Good, Broken, Repairable)
  - Progress bar with completion percentage

✅ Search bar for filtering assets by code/description

✅ Filter chips for:
  - Survey state (All, Verified, Pending)
  - Status types (Good, Broken, Repairable, etc.)

✅ Asset list with:
  - Status color indicators
  - Asset code and description
  - Survey status and image badges
  - Tap to view details

✅ Floating action buttons:
  - Scan barcode
  - Add new item

✅ Pull-to-refresh functionality

✅ Export button in app bar

---

### 4.3 Barcode Scanning UI
**File:** `lib/views/field_officer/scan_screen.dart`

**Implementation Steps:**
1. **Integrate mobile_scanner package:**
```dart
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            _onBarcodeDetected(barcode.rawValue);
            break;
          }
        },
      ),
    );
  }
}
```

2. **Handle barcode detection:**
   - Query database for asset by `new_code`
   - If found: Navigate to Asset Detail Screen
   - If not found: Show error and option to add new item

3. **Add visual feedback:**
   - Show scanning frame overlay
   - Play sound/vibration on successful scan
   - Display loading indicator while querying

4. **Add manual code entry:**
   - Text field for manual code input
   - Useful when barcode is damaged

---

### 4.4 Asset Detail & Update Screen
**File:** `lib/views/field_officer/asset_detail_screen.dart`

**UI Layout:**

```
┌─────────────────────────────┐
│   Asset Detail              │
├─────────────────────────────┤
│ [Back] Code: ABC123    [✓]  │
├─────────────────────────────┤
│                             │
│  📦 Description:            │
│  Office Chair - Wooden      │
│                             │
│  🏷️ Old Code: OLD-001       │
│  📚 Book Balance: 5         │
│                             │
├─────────────────────────────┤
│  Survey Information         │
├─────────────────────────────┤
│                             │
│  Physical Balance:          │
│  [_____] (Number input)     │
│                             │
│  Status:                    │
│  [Dropdown: Good ▼]         │
│                             │
│  Remarks:                   │
│  [___________________]      │
│  (Text area)                │
│                             │
│  Photos:                    │
│  [📷][📷][📷]               │
│  (Camera buttons)           │
│                             │
│  [📸 Take Photo 1]          │
│  [📸 Take Photo 2]          │
│  [📸 Take Photo 3]          │
│                             │
│  [  Save Changes  ]         │
│                             │
└─────────────────────────────┘
```

**Implementation Steps:**

1. **Display asset information** (read-only):
   - Description, Old Code, Book Balance
   - Show existing survey data if already surveyed

2. **Create update form:**
```dart
final physicalBalanceController = TextEditingController();
String? selectedStatus;
final remarksController = TextEditingController();
List<String?> imagePaths = [null, null, null];

// Physical balance input
TextField(
  controller: physicalBalanceController,
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: 'Physical Balance',
    hintText: 'Enter quantity found',
  ),
);

// Status dropdown
DropdownButtonFormField<String>(
  value: selectedStatus,
  items: SurveyStatus.allValues.map((status) {
    return DropdownMenuItem(value: status, child: Text(status));
  }).toList(),
  onChanged: (value) => setState(() => selectedStatus = value),
);
```

3. **Implement photo capture:**
```dart
Future<void> _capturePhoto(int index) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 85,
  );
  
  if (image != null) {
    setState(() => imagePaths[index] = image.path);
  }
}
```

4. **Implement save logic:**
```dart
Future<void> _saveAsset() async {
  final authState = ref.read(authProvider);
  final physicalBalance = int.tryParse(physicalBalanceController.text) ?? 0;
  
  // Calculate excess and shortage
  final differences = AssetModel.calculateDifferences(
    physicalBalance,
    asset.bookBalance,
  );
  
  final updatedAsset = asset.copyWith(
    physicalBalance: physicalBalance,
    excess: differences['excess'],
    shortage: differences['shortage'],
    surveyStatus: selectedStatus,
    remarks: remarksController.text,
    imagePath1: imagePaths[0],
    imagePath2: imagePaths[1],
    imagePath3: imagePaths[2],
    lastUpdatedBy: authState.currentUser?.username,
    lastUpdatedDate: DateTime.now().toIso8601String(),
  );
  
  final success = await ref.read(assetListProvider.notifier).updateAsset(updatedAsset);
  
  if (success) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Asset updated successfully')),
    );
  }
}
```

---

### 4.5 Add New Item Screen
**File:** `lib/views/field_officer/add_item_screen.dart`

**Implementation Steps:**

1. **Create form fields:**
   - Description (required)
   - New Code (auto-generate or manual entry)
   - Physical Balance (required)
   - Status dropdown
   - Remarks
   - Photo capture buttons

2. **Auto-generate new code:**
```dart
String _generateNewCode() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'NEW-$timestamp';
}
```

3. **Save new item:**
```dart
Future<void> _addNewItem() async {
  final authState = ref.read(authProvider);
  
  final newAsset = AssetModel(
    description: descriptionController.text,
    newCode: newCodeController.text,
    physicalBalance: int.tryParse(physicalBalanceController.text) ?? 0,
    surveyStatus: selectedStatus,
    remarks: remarksController.text,
    imagePath1: imagePaths[0],
    imagePath2: imagePaths[1],
    imagePath3: imagePaths[2],
    lastUpdatedBy: authState.currentUser?.username,
    lastUpdatedDate: DateTime.now().toIso8601String(),
    isNewItem: 1, // Mark as new item
  );
  
  final success = await ref.read(assetListProvider.notifier).addAsset(newAsset);
  
  if (success) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New item added successfully')),
    );
  }
}
```

---

### 4.6 Field Officer Export Functionality

**Implementation Steps:**

1. **Create export dialog:**
```dart
void _showExportDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Export My Work'),
      content: Text('Export all assets you have surveyed as CSV?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _exportWork();
          },
          child: Text('Export'),
        ),
      ],
    ),
  );
}
```

2. **Implement export logic:**
```dart
Future<void> _exportWork() async {
  try {
    final authState = ref.read(authProvider);
    final username = authState.currentUser!.username;
    
    // Get modified assets
    final db = DatabaseHelper();
    final assets = await db.getModifiedAssetsByUser(username);
    
    if (assets.isEmpty) {
      _showMessage('No surveyed assets to export');
      return;
    }
    
    // Generate CSV
    final filePath = await CsvHelper.generateFieldOfficerCsv(assets, username);
    
    // Copy to Downloads folder
    final exportPath = await CsvHelper.exportToDownloads(filePath);
    
    _showMessage('Exported ${assets.length} assets to:\n$exportPath');
  } catch (e) {
    _showMessage('Export failed: $e');
  }
}
```

---

## 🎯 Phase 5: Admin Dashboard Implementation

### 5.1 Admin Dashboard
**File:** `lib/views/admin/admin_dashboard.dart`

**UI Components:**
- Overview statistics (all users combined)
- Import Master CSV button
- Import Field CSVs button
- Export Final Report button
- Database management tools

### 5.2 Master CSV Import
**File:** `lib/views/admin/import_csv_screen.dart`

**Implementation:**
```dart
Future<void> _importMasterCsv() async {
  // Pick CSV file
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  
  if (result == null) return;
  
  final filePath = result.files.single.path!;
  
  // Show preview
  final preview = await CsvHelper.getPreview(filePath);
  // Display preview in dialog for confirmation
  
  // Parse CSV
  final assets = await CsvHelper.parseMasterCsv(filePath);
  
  // Batch insert into database
  final db = DatabaseHelper();
  final count = await db.batchInsertFromMasterCsv(assets);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Imported $count assets')),
  );
}
```

### 5.3 Field CSV Merge
**File:** `lib/views/admin/merge_csv_screen.dart`

**Implementation:**
```dart
Future<void> _mergeFieldCsv() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    allowMultiple: true,
  );
  
  if (result == null) return;
  
  int totalUpdated = 0;
  
  for (var file in result.files) {
    final assets = await CsvHelper.parseFieldOfficerCsv(file.path!);
    final db = DatabaseHelper();
    final count = await db.mergeFieldOfficerCsv(assets);
    totalUpdated += count;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Merged $totalUpdated records')),
  );
}
```

### 5.4 Final Report Export
**File:** `lib/views/admin/export_report_screen.dart`

**Implementation:**
```dart
Future<void> _exportFinalReport() async {
  final db = DatabaseHelper();
  final assets = await db.getAllAssetsForExport();
  
  final filePath = await CsvHelper.generateAdminReportCsv(assets);
  final exportPath = await CsvHelper.exportToDownloads(filePath);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Export Complete'),
      content: Text('Final report exported with ${assets.length} assets to:\n$exportPath'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## 🎯 Phase 6: Polish & Testing

### 6.1 UI/UX Enhancements
- [ ] Add loading skeletons for better perceived performance
- [ ] Implement smooth page transitions
- [ ] Add haptic feedback for important actions
- [ ] Implement dark mode support
- [ ] Add animations for card appearances

### 6.2 Error Handling
- [ ] Implement global error handler
- [ ] Add retry mechanisms for failed operations
- [ ] Display user-friendly error messages
- [ ] Log errors for debugging

### 6.3 Testing
- [ ] Unit tests for models and utilities
- [ ] Widget tests for UI components
- [ ] Integration tests for workflows:
  - Login → Scan → Update → Export
  - Admin import → View → Export
- [ ] Manual testing on real devices

### 6.4 Performance Optimization
- [ ] Lazy loading for large asset lists
- [ ] Image compression for photos
- [ ] Database query optimization
- [ ] Memory leak prevention

---

## 🎯 Phase 7: Deployment

### 7.1 App Icon & Splash Screen
- Create app icon (1024x1024)
- Configure launcher icons for Android/iOS
- Design splash screen

### 7.2 Build Configurations
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 7.3 Distribution
- Generate signed APK for Android
- Submit to Google Play Store (optional)
- Or distribute APK directly to field officers

---

## 📱 Key Workflows Summary

### Field Officer Workflow:
1. **Login** → Dashboard with statistics
2. **Scan barcode** → Asset detail screen
3. **Update asset:**
   - Enter physical balance
   - Select status
   - Take photos
   - Add remarks
   - Save
4. **Or Add new item** (items without barcode)
5. **Export CSV** when done

### Admin Workflow:
1. **Login** → Admin dashboard
2. **Import master CSV** → Populates database
3. **Collect field CSVs** from officers
4. **Merge field CSVs** → Updates master records
5. **Export final report** → Complete survey data

---

## 🔒 Security Considerations

1. **Local Authentication:**
   - Passwords are hardcoded (for offline use)
   - Consider encrypting database in production
   - Implement session timeout

2. **Data Integrity:**
   - Validate all user inputs
   - Prevent SQL injection (SQLite prepared statements)
   - Backup database periodically

3. **File Security:**
   - Store photos in app-private directory
   - Validate CSV file structure before importing
   - Handle large files gracefully

---

## 🚀 Future Enhancements

1. **Online Sync (Optional):**
   - Add REST API for cloud sync
   - Implement conflict resolution
   - Real-time collaboration

2. **Advanced Features:**
   - Barcode generation for new items
   - Photo comparison (before/after)
   - Signature capture for approval
   - PDF report generation
   - Multi-language support (English/Sinhala toggle)

3. **Analytics:**
   - Survey completion tracking
   - Officer performance metrics
   - Asset status trends

---

## 📚 Resources & Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [SQFlite Package](https://pub.dev/packages/sqflite)
- [Mobile Scanner Package](https://pub.dev/packages/mobile_scanner)
- [Image Picker Package](https://pub.dev/packages/image_picker)

---

## ✅ Checklist

### Core Features
- [✓] Database schema and helper
- [✓] Asset model with CSV support
- [✓] Authentication system
- [✓] Dashboard with statistics
- [✓] Asset list with filters
- [✓] CSV import/export utilities
- [ ] Barcode scanning
- [ ] Asset detail/update screen
- [ ] Add new item screen
- [ ] Photo capture integration
- [ ] Admin import/export screens

### Testing
- [ ] Database CRUD operations
- [ ] CSV parsing and generation
- [ ] Authentication flow
- [ ] Search and filter functionality
- [ ] Photo capture and storage
- [ ] End-to-end workflows

### Deployment
- [ ] App icon and branding
- [ ] Build and sign APK
- [ ] User documentation
- [ ] Training materials

---

**End of Implementation Plan**
