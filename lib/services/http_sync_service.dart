import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/asset_model.dart';

/// HTTP Service - Connects to PHP API endpoint
/// More reliable than direct MySQL from mobile devices
class HttpSyncService {
  static final HttpSyncService _instance = HttpSyncService._internal();
  factory HttpSyncService() => _instance;
  HttpSyncService._internal();

  // API configuration - PHP runs on Apache (port 80)
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1/sltb'; // Same machine for web
    } else {
      return 'http://172.20.10.3/sltb'; // Computer IP for mobile
    }
  }

  static const int _timeoutSeconds = 10;

  /// Save asset to MySQL via PHP API
  /// Returns true if saved successfully
  Future<bool> saveAsset(AssetModel asset) async {
    try {
      final url = Uri.parse('$_baseUrl/save_asset.php');

      // Extract just the filename from image paths
      String? image1Name = _extractFileName(asset.imagePath1);
      String? image2Name = _extractFileName(asset.imagePath2);
      String? image3Name = _extractFileName(asset.imagePath3);

      final body = jsonEncode({
        'serial_no': asset.serialNo,
        'description': asset.description,
        'old_code': asset.oldCode,
        'new_code': asset.newCode,
        'book_balance': asset.bookBalance,
        'physical_balance': asset.physicalBalance,
        'excess': asset.excess,
        'shortage': asset.shortage,
        'remarks': asset.remarks,
        'survey_status': asset.surveyStatus,
        'image_path_1': image1Name,
        'image_path_2': image2Name,
        'image_path_3': image3Name,
        'entered_by': asset.enteredBy,
        'entered_date': asset.enteredDate,
        'verified_by': asset.verifiedBy,
        'verified_date': asset.verifiedDate,
        'verification_status': asset.verificationStatus,
        'last_updated_by': asset.lastUpdatedBy,
        'last_updated_date': asset.lastUpdatedDate,
        'is_new_item': asset.isNewItem,
      });

      debugPrint('Sending to: $url');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('Asset synced via PHP: ${asset.newCode}');
          return true;
        } else {
          debugPrint('PHP API error: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing to server: $e');
      return false;
    }
  }

  /// Test connection to PHP API
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_baseUrl/save_asset.php');
      final response =
          await http.get(url).timeout(Duration(seconds: _timeoutSeconds));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  /// Extract filename from full path
  String? _extractFileName(String? path) {
    if (path == null || path.isEmpty) return null;
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : null;
  }
}
