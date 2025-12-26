# 🚀 Quick Start Guide - SLTB Board of Survey

## ⚡ Get Started in 5 Minutes

### Step 1: Open Project in VS Code
1. Open VS Code
2. File → Open Folder
3. Navigate to: `G:\SLTB\SLTB Board of Survey\1`
4. Click "Select Folder"

### Step 2: Install Flutter Extension
1. Open Extensions (Ctrl+Shift+X)
2. Search for "Flutter"
3. Install the Flutter extension by Dart Code

### Step 3: Install Dependencies
Open terminal in VS Code (Ctrl+`) and run:
```bash
flutter pub get
```

### Step 4: Create Main Entry Point
Create `lib/main.dart` with minimal code to test:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/field_officer/dashboard_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLTB Survey',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
```

### Step 5: Run the App
```bash
flutter run
```

---

## 📂 What You Have

### ✅ Completed Files:

**Models:**
- `lib/data/models/asset_model.dart` - Complete asset entity
- `lib/data/models/user_model.dart` - User accounts (hardcoded)

**Database:**
- `lib/data/database/database_helper.dart` - Full CRUD operations
- `lib/data/database/database_constants.dart` - Table definitions

**Utilities:**
- `lib/core/utils/csv_helper.dart` - CSV import/export
- `lib/core/constants/survey_status.dart` - Status enum

**Providers (State Management):**
- `lib/providers/auth_provider.dart` - Authentication
- `lib/providers/asset_provider.dart` - Asset list
- `lib/providers/dashboard_provider.dart` - Statistics

**UI Components:**
- `lib/views/field_officer/dashboard_screen.dart` - Main dashboard
- `lib/views/field_officer/widgets/summary_card.dart` - Stat cards
- `lib/views/field_officer/widgets/asset_list_item.dart` - List items
- `lib/views/field_officer/widgets/filter_chip_bar.dart` - Filters
- `lib/views/field_officer/scan_screen.dart` - Placeholder
- `lib/views/field_officer/add_item_screen.dart` - Placeholder

**Configuration:**
- `pubspec.yaml` - All dependencies

**Documentation:**
- `README.md` - Project overview
- `FOLDER_STRUCTURE.md` - Architecture
- `IMPLEMENTATION_PLAN.md` - Detailed guide

---

## 🎯 Next Steps

### Priority 1: Complete Core Screens

#### 1. Implement Barcode Scanner
Edit: `lib/views/field_officer/scan_screen.dart`
- Add MobileScanner widget
- Query database on scan
- Navigate to detail screen

#### 2. Create Asset Detail Screen
Create: `lib/views/field_officer/asset_detail_screen.dart`
- Display asset info
- Form for physical balance
- Status dropdown
- Photo capture
- Save button

#### 3. Create Add Item Screen
Edit: `lib/views/field_officer/add_item_screen.dart`
- Form for new assets
- Auto-generate code
- Photo capture
- Save as new item

### Priority 2: Admin Screens

#### 4. Create Admin Dashboard
Create: `lib/views/admin/admin_dashboard.dart`
- Overview statistics
- Import/Export buttons

#### 5. CSV Import/Export UIs
Create admin screens for:
- Master CSV import
- Field CSV merge
- Final report export

### Priority 3: Polish

#### 6. Add Login Screen
Create: `lib/views/auth/login_screen.dart`
- Username/password fields
- Role-based navigation

#### 7. Testing
- Test database operations
- Test CSV import/export
- Test barcode scanning
- End-to-end workflows

---

## 💡 Quick Tips

### Test Database:
```dart
// In main.dart or any widget
final db = DatabaseHelper();

// Insert test asset
final asset = AssetModel(
  description: 'Test Chair',
  newCode: 'TEST-001',
  bookBalance: 5,
);
await db.insertAsset(asset);

// Retrieve
final found = await db.getAssetByNewCode('TEST-001');
print(found);
```

### Test CSV Export:
```dart
final assets = await db.getAllAssets();
final path = await CsvHelper.generateFieldOfficerCsv(assets, 'officer01');
print('Exported to: $path');
```

### Hot Reload:
- Press `r` in terminal for hot reload
- Press `R` for full restart
- Press `q` to quit

---

## 🐛 Troubleshooting

### Issue: Dependencies not installing
**Solution:**
```bash
flutter clean
flutter pub get
```

### Issue: Android build fails
**Solution:**
- Check Android SDK is installed
- Update Android Studio
- Check `android/app/build.gradle` minSdkVersion is 21+

### Issue: iOS build fails
**Solution:**
```bash
cd ios
pod install
cd ..
flutter run
```

### Issue: Database not persisting
**Solution:**
- Check permissions in AndroidManifest.xml
- Use actual device instead of emulator
- Check path_provider is working

---

## 📚 Useful Commands

```bash
# Check Flutter installation
flutter doctor

# List connected devices
flutter devices

# Build APK
flutter build apk

# Run with verbose logging
flutter run --verbose

# Clear cache
flutter clean

# Update dependencies
flutter pub upgrade
```

---

## 🎓 Learning Resources

1. **Flutter Basics:**
   - https://flutter.dev/docs/get-started/codelab

2. **Riverpod State Management:**
   - https://riverpod.dev/docs/getting_started

3. **SQFlite Database:**
   - https://pub.dev/packages/sqflite

4. **Mobile Scanner:**
   - https://pub.dev/packages/mobile_scanner

---

## ✅ Current Status

| Feature | Status |
|---------|--------|
| Database Schema | ✅ Complete |
| CRUD Operations | ✅ Complete |
| CSV Import/Export | ✅ Complete |
| Authentication | ✅ Complete |
| Dashboard UI | ✅ Complete |
| Search & Filter | ✅ Complete |
| Barcode Scanner | 🚧 Pending |
| Asset Detail Screen | 🚧 Pending |
| Add Item Screen | 🚧 Pending |
| Photo Capture | 🚧 Pending |
| Admin Screens | 🚧 Pending |

**Progress: ~60% Complete**

---

## 🎉 You're Ready!

You now have a solid foundation for the SLTB Board of Survey app. Follow the **IMPLEMENTATION_PLAN.md** to complete the remaining screens.

**Happy Coding! 🚀**
