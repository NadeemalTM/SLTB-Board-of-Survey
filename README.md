# 🚀 SLTB Board of Survey System

A modern, offline-first Flutter mobile application for equipment survey management.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-Private-red.svg)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Usage Guide](#usage-guide)
- [Development](#development)
- [Contributing](#contributing)

---

## 🎯 Overview

The SLTB Board of Survey System is a comprehensive mobile application designed for field officers to conduct equipment surveys efficiently. The app works completely offline, storing all data locally in SQLite, and uses CSV files for data synchronization.

### Key Highlights:
- ✅ **100% Offline Functionality** - No internet required
- ✅ **SQFlite Database** - Robust local data storage
- ✅ **Barcode Scanning** - Quick asset identification
- ✅ **Photo Capture** - Visual documentation (up to 3 photos per asset)
- ✅ **CSV Import/Export** - Simple data synchronization
- ✅ **Modern UI/UX** - Clean, intuitive interface
- ✅ **Role-Based Access** - Admin and Field Officer roles

---

## ✨ Features

### For Field Officers:
- 📊 **Dashboard with Statistics**
  - Total items, verified, pending counts
  - Status breakdown (Good, Broken, Repairable, etc.)
  - Progress tracking with completion percentage

- 🔍 **Smart Search & Filtering**
  - Search by asset code or description
  - Filter by survey status
  - Filter by verification state

- 📷 **Barcode Scanning**
  - Quick QR/barcode scanning
  - Manual code entry option
  - Instant asset lookup

- ✏️ **Asset Survey**
  - Record physical balance
  - Set asset status
  - Add remarks/notes
  - Capture up to 3 photos
  - Auto-calculate excess/shortage

- ➕ **Add New Items**
  - For assets without existing records
  - Auto-generate unique codes
  - Full survey data capture

- 💾 **Export Work**
  - Export surveyed assets as CSV
  - Share with admin for consolidation

### For Admins:
- 📥 **Import Master List**
  - Bulk import from CSV
  - Preview before import
  - Data validation

- 🔄 **Merge Field Data**
  - Import multiple field officer CSVs
  - Automatic record matching
  - Conflict-free merging

- 📤 **Export Final Report**
  - Complete survey data export
  - Sinhala headers for official reports
  - Includes all survey details

- 📈 **System Overview**
  - Combined statistics from all officers
  - Database management tools

---

## 🏗️ Architecture

### Technology Stack:
- **Framework:** Flutter 3.0+
- **Language:** Dart 3.0+
- **Architecture:** MVVM (Model-View-ViewModel)
- **State Management:** Riverpod 2.4+
- **Database:** SQFlite 2.3+
- **Barcode Scanner:** Mobile Scanner 3.5+
- **Image Handling:** Image Picker 1.0+

### Design Patterns:
- **Singleton:** Database helper
- **Provider:** State management
- **Repository:** Data abstraction
- **Factory:** Model creation

### Layer Structure:
```
┌─────────────────────────────────┐
│         UI Layer (Views)        │  ← Material Design UI
├─────────────────────────────────┤
│    ViewModel Layer (Providers)  │  ← Business Logic
├─────────────────────────────────┤
│   Repository Layer (Repos)      │  ← Data Operations
├─────────────────────────────────┤
│     Data Layer (Database)       │  ← SQFlite + CSV
└─────────────────────────────────┘
```

---

## 🔧 Installation

### Prerequisites:
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android device or emulator

### Step 1: Clone or Copy Files
Copy all the generated files to your project directory:
```
G:\SLTB\SLTB Board of Survey\1\
```

### Step 2: Install Dependencies
```bash
cd "G:\SLTB\SLTB Board of Survey\1"
flutter pub get
```

### Step 3: Configure Permissions

**Android** - Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** - Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera needed for scanning and photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access needed</string>
```

### Step 4: Run the App
```bash
flutter run
```

---

## 📁 Project Structure

See [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) for complete details.

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── constants/           # App constants & enums
│   ├── theme/              # App theming
│   └── utils/              # Utility classes
├── data/
│   ├── models/             # Data models
│   ├── database/           # Database layer
│   └── repositories/       # Business logic
├── providers/              # Riverpod providers
└── views/                  # UI screens
    ├── auth/              # Login screen
    ├── admin/             # Admin screens
    └── field_officer/     # Field officer screens
```

---

## 📖 Usage Guide

### Hardcoded User Accounts:

**Admin:**
- Username: `admin`
- Password: `admin123`

**Field Officers:**
- Username: `officer01` to `officer10`
- Password: `field123`

### Field Officer Workflow:

1. **Login** with field officer credentials
2. **View Dashboard** to see survey progress
3. **Scan Barcode** or search for asset
4. **Update Asset:**
   - Enter physical quantity found
   - Select status (Good/Broken/etc.)
   - Take photos
   - Add remarks
   - Save
5. **Export Your Work** as CSV when ready

### Admin Workflow:

1. **Login** with admin credentials
2. **Import Master CSV:**
   - Prepare CSV with columns: Serial No, Description, Old Code, New Code, Book Balance
   - Import to populate database
3. **Collect Field CSVs** from officers (via USB/email)
4. **Merge Field CSVs** to update master records
5. **Export Final Report** with complete survey data

### CSV Formats:

**Master Import CSV:**
```csv
අංකය,විස්තරය,පැරණි කේත අංකය,නව කේත අංකය,පොත් අනුව ශේෂය
1,Office Chair,OLD-001,NEW-001,5
2,Desk,OLD-002,NEW-002,10
```

**Field Officer Export CSV:**
Contains 16 columns including all survey data, photos, timestamps, etc.

**Admin Final Report CSV:**
Complete data with Sinhala headers for official documentation.

---

## 🛠️ Development

### Key Files to Understand:

1. **[lib/data/models/asset_model.dart](lib/data/models/asset_model.dart)**
   - Asset entity with 17 fields
   - CSV conversion methods
   - Helper utilities

2. **[lib/data/database/database_helper.dart](lib/data/database/database_helper.dart)**
   - Singleton database manager
   - Complete CRUD operations
   - Batch import/export methods

3. **[lib/core/utils/csv_helper.dart](lib/core/utils/csv_helper.dart)**
   - CSV parsing and generation
   - Import/export utilities

4. **[lib/providers/](lib/providers/)**
   - State management with Riverpod
   - Authentication, assets, dashboard providers

5. **[lib/views/field_officer/dashboard_screen.dart](lib/views/field_officer/dashboard_screen.dart)**
   - Main UI for field officers
   - Summary cards, search, filters

### Running Tests:
```bash
flutter test
```

### Building for Release:
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## 📝 Implementation Plan

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for:
- Detailed phase-by-phase implementation guide
- Code examples for remaining screens
- UI/UX mockups
- Testing checklist
- Deployment instructions

### What's Completed: ✅
- ✅ Project structure
- ✅ Database layer (complete CRUD)
- ✅ Asset model with CSV support
- ✅ CSV utilities (import/export)
- ✅ Authentication system (local)
- ✅ State management (Riverpod)
- ✅ Dashboard UI (field officer)
- ✅ Summary cards & statistics
- ✅ Asset list with search/filter
- ✅ Core providers

### What's Remaining: 🚧
- 🚧 Barcode scanner integration
- 🚧 Asset detail/update screen
- 🚧 Add new item screen
- 🚧 Photo capture integration
- 🚧 Admin dashboard screens
- 🚧 CSV import/export UI
- 🚧 Testing & optimization

---

## 🎨 UI/UX Design Principles

1. **Mobile-First:** Optimized for phone screens (5-7 inches)
2. **Material Design 3:** Modern, clean interface
3. **Clear Hierarchy:** Important actions are prominent
4. **Visual Feedback:** Loading states, success/error messages
5. **Offline-First:** No network dependency
6. **Accessibility:** High contrast, readable fonts

### Color Scheme:
- **Primary:** Blue (#2196F3) - Professional, trustworthy
- **Success:** Green (#4CAF50) - Good status
- **Warning:** Orange (#FF9800) - Pending items
- **Error:** Red (#F44336) - Broken items
- **Accent:** Teal (#009688) - Call-to-action

---

## 📊 Database Schema

### Assets Table:
```sql
CREATE TABLE assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  serial_no INTEGER,
  description TEXT NOT NULL,
  old_code TEXT,
  new_code TEXT NOT NULL UNIQUE,
  book_balance INTEGER DEFAULT 0,
  physical_balance INTEGER DEFAULT 0,
  excess INTEGER DEFAULT 0,
  shortage INTEGER DEFAULT 0,
  remarks TEXT,
  survey_status TEXT,
  image_path_1 TEXT,
  image_path_2 TEXT,
  image_path_3 TEXT,
  last_updated_by TEXT,
  last_updated_date TEXT,
  is_new_item INTEGER DEFAULT 0
);

-- Indexes for performance
CREATE INDEX idx_new_code ON assets(new_code);
CREATE INDEX idx_survey_status ON assets(survey_status);
CREATE INDEX idx_last_updated_by ON assets(last_updated_by);
```

---

## 🤝 Contributing

This is a private project for SLTB. For internal contributions:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit for review

---

## 📞 Support

For issues or questions, contact the development team.

---

## 📜 License

Private - All rights reserved by SLTB (Sri Lanka Transport Board)

---

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- Riverpod for elegant state management
- SQFlite for reliable local database
- Mobile Scanner for barcode functionality

---

## 🔮 Future Enhancements

- [ ] Online synchronization with REST API
- [ ] Multi-language support (English/Sinhala toggle)
- [ ] PDF report generation
- [ ] Advanced analytics and charts
- [ ] Signature capture for approvals
- [ ] Barcode generation for new items
- [ ] Offline maps for location tracking

---

**Built with ❤️ using Flutter**

Last Updated: December 26, 2025
Version: 1.0.0
