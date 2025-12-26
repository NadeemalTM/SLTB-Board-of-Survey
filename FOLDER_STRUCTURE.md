# SLTB Board of Survey - Flutter Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # App-wide constants (DB name, table names, etc.)
│   │   ├── user_roles.dart             # Enum for Admin/Field Officer
│   │   └── survey_status.dart          # Enum for survey statuses
│   │
│   ├── theme/
│   │   ├── app_theme.dart              # Material 3 theme configuration
│   │   └── app_colors.dart             # Color palette
│   │
│   └── utils/
│       ├── csv_helper.dart             # CSV parsing and generation utilities
│       ├── date_formatter.dart         # Date formatting utilities
│       └── file_helper.dart            # File I/O helpers
│
├── data/
│   ├── models/
│   │   ├── asset_model.dart            # Asset entity/model
│   │   └── user_model.dart             # User entity (hardcoded)
│   │
│   ├── database/
│   │   ├── database_helper.dart        # SQFlite database manager
│   │   └── database_constants.dart     # Table/column names
│   │
│   └── repositories/
│       ├── asset_repository.dart       # Business logic for assets
│       └── auth_repository.dart        # Authentication logic (local)
│
├── providers/
│   ├── auth_provider.dart              # Authentication state
│   ├── asset_provider.dart             # Asset list state
│   ├── dashboard_provider.dart         # Dashboard statistics
│   └── scan_provider.dart              # Scanning state
│
├── views/
│   ├── auth/
│   │   ├── login_screen.dart           # Login page
│   │   └── widgets/
│   │       └── login_form.dart         # Login form widget
│   │
│   ├── admin/
│   │   ├── admin_dashboard.dart        # Admin home screen
│   │   ├── import_csv_screen.dart      # Master CSV import
│   │   ├── merge_csv_screen.dart       # Field CSV merge
│   │   └── export_report_screen.dart   # Final report export
│   │
│   ├── field_officer/
│   │   ├── dashboard_screen.dart       # Field officer home (main UI)
│   │   ├── scan_screen.dart            # Barcode scanning screen
│   │   ├── asset_detail_screen.dart    # Asset view/edit screen
│   │   ├── add_item_screen.dart        # Add new item screen
│   │   └── widgets/
│   │       ├── summary_card.dart       # Dashboard stat cards
│   │       ├── asset_list_item.dart    # List item widget
│   │       ├── filter_chip_bar.dart    # Filter chips
│   │       └── photo_capture_widget.dart  # Photo taking widget
│   │
│   └── shared/
│       └── widgets/
│           ├── app_button.dart         # Custom button
│           ├── app_textfield.dart      # Custom text field
│           └── loading_indicator.dart  # Loading spinner
│
└── view_models/
    ├── asset_viewmodel.dart            # Asset CRUD view model
    ├── dashboard_viewmodel.dart        # Dashboard logic
    └── scan_viewmodel.dart             # Scan/update logic
```

## Key Architecture Decisions

### MVVM Pattern
- **Models** (`data/models/`): Plain Dart classes representing data entities
- **Views** (`views/`): UI screens and widgets
- **ViewModels** (`view_models/`): Business logic that mediates between views and data layer
- **Providers** (`providers/`): Riverpod providers for state management

### Data Flow
1. View → ViewModel → Repository → DatabaseHelper → SQFlite
2. SQFlite → DatabaseHelper → Repository → Provider → View

### File Organization Principles
- **Separation of Concerns**: Each layer has a clear responsibility
- **Reusability**: Shared widgets and utilities are centralized
- **Scalability**: Easy to add new features without affecting existing code
- **Testability**: Clean separation makes unit testing straightforward
