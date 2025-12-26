import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/asset_model.dart';

/// CSV Helper - Handles CSV file parsing and generation
/// 
/// Provides utilities for importing master asset lists and 
/// exporting survey data in CSV format.
class CsvHelper {
  // CSV headers for master import
  static const List<String> masterCsvHeaders = [
    'අංකය', // Serial No
    'විස්තරය', // Description
    'පැරණි කේත අංකය', // Old Code
    'නව කේත අංකය', // New Code
    'පොත් අනුව ශේෂය', // Book Balance
  ];

  // CSV headers for field officer export
  static const List<String> fieldOfficerCsvHeaders = [
    'Serial No',
    'Description',
    'Old Code',
    'New Code',
    'Book Balance',
    'Physical Balance',
    'Excess',
    'Shortage',
    'Survey Status',
    'Remarks',
    'Image 1',
    'Image 2',
    'Image 3',
    'Updated By',
    'Updated Date',
    'Is New Item',
  ];

  // CSV headers for final admin report
  static const List<String> adminReportCsvHeaders = [
    'අංකය', // Serial No
    'විස්තරය', // Description
    'පැරණි කේත අංකය', // Old Code
    'නව කේත අංකය', // New Code
    'පොත් අනුව ශේෂය', // Book Balance
    'භෞතික අගය', // Physical Balance
    'අතිරික්තය', // Excess
    'හිඟය', // Shortage
    'තත්වය', // Survey Status
    'සටහන්', // Remarks
    'පින්තූරය 1', // Image 1
    'පින්තූරය 2', // Image 2
    'පින්තූරය 3', // Image 3
    'යාවත්කාල කළ නිලධාරී', // Updated By
    'යාවත්කාල කළ දිනය', // Updated Date
    'නව අයිතමය', // Is New Item
  ];

  /// Parse master CSV file and return list of AssetModels
  /// Expected format: serial_no, description, old_code, new_code, book_balance
  static Future<List<AssetModel>> parseMasterCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('CSV file not found: $filePath');
      }

      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
      );

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header row if present (check if first row matches header pattern)
      int startRow = 0;
      if (csvData[0].any((cell) => cell.toString().contains('අංකය') || 
          cell.toString().toLowerCase().contains('serial'))) {
        startRow = 1;
      }

      List<AssetModel> assets = [];
      for (int i = startRow; i < csvData.length; i++) {
        try {
          final row = csvData[i];
          if (row.length >= 5) {
            assets.add(AssetModel.fromCsvRow(row));
          }
        } catch (e) {
          // Log individual row error but continue parsing
          print('Error parsing row $i: $e');
        }
      }

      return assets;
    } catch (e) {
      throw Exception('Failed to parse master CSV: $e');
    }
  }

  /// Parse field officer CSV and return list of AssetModels
  /// This CSV contains full asset data including survey fields
  static Future<List<AssetModel>> parseFieldOfficerCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('CSV file not found: $filePath');
      }

      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
      );

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header row
      int startRow = 1;
      List<AssetModel> assets = [];

      for (int i = startRow; i < csvData.length; i++) {
        try {
          final row = csvData[i];
          if (row.length >= 16) {
            // Parse complete asset with all fields
            assets.add(AssetModel(
              serialNo: int.tryParse(row[0].toString()),
              description: row[1].toString(),
              oldCode: row[2].toString(),
              newCode: row[3].toString(),
              bookBalance: int.tryParse(row[4].toString()) ?? 0,
              physicalBalance: int.tryParse(row[5].toString()) ?? 0,
              excess: int.tryParse(row[6].toString()) ?? 0,
              shortage: int.tryParse(row[7].toString()) ?? 0,
              surveyStatus: row[8].toString(),
              remarks: row[9].toString(),
              imagePath1: row[10].toString().isEmpty ? null : row[10].toString(),
              imagePath2: row[11].toString().isEmpty ? null : row[11].toString(),
              imagePath3: row[12].toString().isEmpty ? null : row[12].toString(),
              lastUpdatedBy: row[13].toString(),
              lastUpdatedDate: row[14].toString(),
              isNewItem: int.tryParse(row[15].toString()) ?? 0,
            ));
          }
        } catch (e) {
          print('Error parsing row $i: $e');
        }
      }

      return assets;
    } catch (e) {
      throw Exception('Failed to parse field officer CSV: $e');
    }
  }

  /// Generate CSV file for field officer export
  /// Contains only modified/added assets
  static Future<String> generateFieldOfficerCsv(
    List<AssetModel> assets,
    String username,
  ) async {
    try {
      List<List<dynamic>> rows = [];

      // Add header row
      rows.add(fieldOfficerCsvHeaders);

      // Add data rows
      for (var asset in assets) {
        rows.add(asset.toCsvRow());
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'field_export_${username}_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate field officer CSV: $e');
    }
  }

  /// Generate CSV file for admin final report
  /// Contains all assets with complete survey data
  static Future<String> generateAdminReportCsv(List<AssetModel> assets) async {
    try {
      List<List<dynamic>> rows = [];

      // Add header row (Sinhala)
      rows.add(adminReportCsvHeaders);

      // Add data rows
      for (var asset in assets) {
        rows.add(asset.toCsvRow());
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'final_report_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate admin report CSV: $e');
    }
  }

  /// Export CSV to external storage (Downloads folder)
  /// Returns the new file path
  static Future<String> exportToDownloads(String sourcePath) async {
    try {
      // Get external storage directory (Android)
      // For iOS, this will use the app's documents directory
      Directory? externalDir;
      
      if (Platform.isAndroid) {
        externalDir = Directory('/storage/emulated/0/Download');
        if (!await externalDir.exists()) {
          externalDir = await getExternalStorageDirectory();
        }
      } else {
        externalDir = await getApplicationDocumentsDirectory();
      }

      if (externalDir == null) {
        throw Exception('Could not access external storage');
      }

      final sourceFile = File(sourcePath);
      final fileName = sourcePath.split('/').last;
      final destPath = '${externalDir.path}/$fileName';

      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      throw Exception('Failed to export to downloads: $e');
    }
  }

  /// Validate CSV structure before importing
  static Future<bool> validateMasterCsv(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty) return false;
      if (csvData.first.length < 5) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get preview of CSV data (first 5 rows)
  static Future<List<List<dynamic>>> getPreview(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      return csvData.take(5).toList();
    } catch (e) {
      throw Exception('Failed to get CSV preview: $e');
    }
  }
}
