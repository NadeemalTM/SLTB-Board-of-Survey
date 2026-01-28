import 'package:mysql1/mysql1.dart';
import 'package:flutter/foundation.dart';
import '../data/models/asset_model.dart';

/// MySQL Service - Direct connection to MySQL database
/// No PHP/web server required!
class MySqlService {
  static final MySqlService _instance = MySqlService._internal();
  factory MySqlService() => _instance;
  MySqlService._internal();

  // Database configuration
  // For Web/Desktop: use localhost
  // For Android/iOS: use your computer's IP address
  static String get _host {
    if (kIsWeb) {
      return '127.0.0.1'; // Web browser runs on same machine
    } else {
      return '172.20.10.3'; // Android phone connects via network IP
    }
  }
  static const int _port = 3307;              // MySQL port
  static const String _user = 'root';
  static const String _password = '0000';         // Your MySQL password
  static const String _database = 'sltb_survey';
  static const int _timeoutSeconds = 5;       // Connection timeout

  MySqlConnection? _connection;

  /// Get database connection with timeout
  Future<MySqlConnection> _getConnection() async {
    if (_connection != null) {
      return _connection!;
    }

    try {
      final settings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        db: _database,
        timeout: const Duration(seconds: _timeoutSeconds),
      );

      _connection = await MySqlConnection.connect(settings)
          .timeout(const Duration(seconds: _timeoutSeconds));
      debugPrint('MySQL connected successfully to $_host:$_port');
      return _connection!;
    } catch (e) {
      debugPrint('MySQL connection error: $e');
      rethrow;
    }
  }

  /// Close connection
  Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
  }

  /// Save asset to MySQL database
  /// Returns true if saved successfully
  Future<bool> saveAsset(AssetModel asset) async {
    try {
      final conn = await _getConnection();

      // Extract just the filename from image paths
      String? image1Name = _extractFileName(asset.imagePath1);
      String? image2Name = _extractFileName(asset.imagePath2);
      String? image3Name = _extractFileName(asset.imagePath3);

      // Check if asset exists
      var results = await conn.query(
        'SELECT id FROM assets WHERE new_code = ?',
        [asset.newCode],
      );

      if (results.isNotEmpty) {
        // Update existing asset
        await conn.query('''
          UPDATE assets SET 
            serial_no = ?,
            description = ?,
            old_code = ?,
            book_balance = ?,
            physical_balance = ?,
            excess = ?,
            shortage = ?,
            remarks = ?,
            survey_status = ?,
            image_path_1 = ?,
            image_path_2 = ?,
            image_path_3 = ?,
            entered_by = ?,
            entered_date = ?,
            verified_by = ?,
            verified_date = ?,
            verification_status = ?,
            last_updated_by = ?,
            last_updated_date = ?,
            is_new_item = ?
          WHERE new_code = ?
        ''', [
          asset.serialNo,
          asset.description,
          asset.oldCode,
          asset.bookBalance,
          asset.physicalBalance,
          asset.excess,
          asset.shortage,
          asset.remarks,
          asset.surveyStatus,
          image1Name,
          image2Name,
          image3Name,
          asset.enteredBy,
          asset.enteredDate,
          asset.verifiedBy,
          asset.verifiedDate,
          asset.verificationStatus,
          asset.lastUpdatedBy,
          asset.lastUpdatedDate,
          asset.isNewItem,
          asset.newCode,
        ]);
        debugPrint('Asset updated in MySQL: ${asset.newCode}');
      } else {
        // Insert new asset
        await conn.query('''
          INSERT INTO assets (
            serial_no, description, old_code, new_code,
            book_balance, physical_balance, excess, shortage,
            remarks, survey_status,
            image_path_1, image_path_2, image_path_3,
            entered_by, entered_date, verified_by, verified_date,
            verification_status, last_updated_by, last_updated_date, is_new_item
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          asset.serialNo,
          asset.description,
          asset.oldCode,
          asset.newCode,
          asset.bookBalance,
          asset.physicalBalance,
          asset.excess,
          asset.shortage,
          asset.remarks,
          asset.surveyStatus,
          image1Name,
          image2Name,
          image3Name,
          asset.enteredBy,
          asset.enteredDate,
          asset.verifiedBy,
          asset.verifiedDate,
          asset.verificationStatus,
          asset.lastUpdatedBy,
          asset.lastUpdatedDate,
          asset.isNewItem,
        ]);
        debugPrint('Asset inserted in MySQL: ${asset.newCode}');
      }

      return true;
    } catch (e) {
      debugPrint('Error saving to MySQL: $e');
      return false;
    }
  }

  /// Extract filename from full path
  String? _extractFileName(String? path) {
    if (path == null || path.isEmpty) return null;
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : null;
  }

  /// Test connection
  Future<bool> testConnection() async {
    try {
      final conn = await _getConnection();
      var results = await conn.query('SELECT 1');
      return results.isNotEmpty;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
}
